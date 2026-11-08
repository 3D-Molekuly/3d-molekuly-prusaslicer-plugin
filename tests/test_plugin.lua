-- Mock of PrusaSlicer's ProjectApi.cpp semantics:
--  * top-level translate/rotate apply to the main volume only; the instance stays at z = 0
--  * a volume with params and no type becomes a Modifier
local DIR, CYL_MODE, SDF = arg[1], arg[2], arg[3]
package.path = DIR .. "/?.lua;" .. package.path
local chem = require('chem')

local function mesh(points) return { pts = points, bounds = function(self)
    local b = { min_x = 1e9, min_y = 1e9, min_z = 1e9, max_x = -1e9, max_y = -1e9, max_z = -1e9 }
    for _, p in ipairs(self.pts) do
        b.min_x = math.min(b.min_x, p[1]); b.max_x = math.max(b.max_x, p[1])
        b.min_y = math.min(b.min_y, p[2]); b.max_y = math.max(b.max_y, p[2])
        b.min_z = math.min(b.min_z, p[3]); b.max_z = math.max(b.max_z, p[3])
    end
    return b end } end

local TOOLS = 5
local added
VolumeType = { Solid = "solid", Negative = "neg", Modifier = "mod" }
api = {
    get_default_font = function() return "font" end,
    emboss_text = function(o) local m = mesh({{0,0,0},{10,2,o.depth}}); m.text = o.text; return m end,
    make_sphere = function(r, fa) assert(fa and fa >= 3 and fa <= 15, "fa"); local m = mesh({{-r,-r,-r},{r,r,r}}); m.kind = "sphere"; return m end,
    make_cylinder = function(r, h, fa)
        assert(fa, "fa")
        local z0 = CYL_MODE == "center" and -h/2 or 0
        local m = mesh({{-r,-r,z0},{r,r,z0+h}}); m.axis = {{0,0,z0},{0,0,z0+h}}; return m end,
    make_cube = function(x, y, z) return mesh({{0,0,0},{x,y,z}}) end,
    project = { current_bed = function() return {
                    printer_config = function() local t = {} for i = 1, TOOLS do t[i] = i end return { tools = t } end,
                    material_presets = function(self, slot)
                        if not FILAMENT_COLORS or slot >= #FILAMENT_COLORS then error("out of range") end
                        return { value = function(_, key)
                            if key ~= COLOR_KEY then error("Invalid preset item name") end
                            return FILAMENT_COLORS[slot + 1] end }
                    end,
                    tool_print_presets = function(self, slot) return { value = function() error("no") end } end } end,
                add_object = function(self, o)
                    local vols = { { mesh = o.mesh, translate = o.translate or {}, rotate = o.rotate, type = "solid" } }
                    for _, v in ipairs(o.other_volumes or {}) do
                        v.type = v.type or (v.params and "mod" or "solid"); table.insert(vols, v)
                    end
                    added = { vols = vols, object_params = o.object_params } end },
}
-- PrusaSlicer runs every .lua file of the bundle in a bare engine without `require` or `api`
-- to read `info`; each file must load there without errors.
local bare_files = {}
for f in io.popen('ls "' .. DIR .. '"'):lines() do if f:match("%.lua$") then table.insert(bare_files, f) end end
assert(#bare_files >= 5, "found lua files")
for _, f in ipairs(bare_files) do
    local env = setmetatable({}, { __index = function(_, k) if k == "require" or k == "api" or k == "VolumeType" then error("no " .. k .. " at load") end return _G[k] end })
    local chunk = assert(loadfile(DIR .. "/" .. f, "t", env))
    local ok, err = pcall(chunk)
    if not ok then print("FAIL: bare load " .. f .. ": " .. tostring(err)); os.exit(1) end
    if f:match("^molecule_") then assert(env.info and env.execute, f) end
end
dofile(DIR .. "/molecule_en.lua")
local info_en, execute_en = info, execute
dofile(DIR .. "/molecule_cs.lua")

local function world(v, p)
    local q = v.rotate and chem.rotate_point(p, v.rotate) or p
    local t = v.translate or {}
    return { q[1] + (t.x or 0), q[2] + (t.y or 0), q[3] + (t.z or 0) }
end

local defaults = {}
for _, p in ipairs(info.params) do defaults[p.name] = p.default end
local function run(over)
    local o = {}; for k, v in pairs(defaults) do o[k] = v end; for k, v in pairs(over) do o[k] = v end
    added = nil; execute(o); return added, o
end

local fails = 0
local function check(cond, msg) if not cond then fails = fails + 1; print("FAIL: " .. msg) end end

local style_ids = { Spheres = "spheres", ["Ball-and-Stick"] = "ball_and_stick", Sticks = "sticks" }
for _, mol in ipairs(require('library')) do
    for style, sid in pairs(style_ids) do
        local obj, o = run({ molecule = mol.name, style = style })
        local prims = chem.build_primitives(mol, { style = sid, scale = o.scale, factor = o.factor,
            bond_factor = o.bond_factor, multiple_bonds = o.multiple_bonds })
        local _, order = chem.assign_filaments(mol.atoms, math.huge)
        local grouped = {}
        for _, el in ipairs(order) do for _, q in ipairs(prims) do if q.element == el then table.insert(grouped, q) end end end
        prims = grouped
        -- each element forms one contiguous block in the object list
        local seen_el, last = {}, nil
        for _, q in ipairs(prims) do
            if q.element ~= last then check(not seen_el[q.element], mol.name .. " element block " .. q.element); seen_el[q.element] = true; last = q.element end
        end
        check(#obj.vols == #prims, mol.name .. " volume count")
        local offset = { 0, 0, -chem.min_z(prims) }
        local maxerr, minz = 0, math.huge
        for i, p in ipairs(prims) do
            local v = obj.vols[i]
            check(v.type == "solid", mol.name .. " volume " .. i .. " is printed part")
            if p.kind == "sphere" then
                local c = world(v, {0,0,0})
                maxerr = math.max(maxerr, chem.len(chem.sub(c, chem.add(p.center, offset))))
                minz = math.min(minz, c[3] - p.r)
            else
                local a, b = world(v, v.mesh.axis[1]), world(v, v.mesh.axis[2])
                maxerr = math.max(maxerr, chem.len(chem.sub(a, chem.add(p.from, offset))), chem.len(chem.sub(b, chem.add(p.to, offset))))
            end
        end
        check(maxerr < 1e-6, string.format("%s / %s placement error %.2e", mol.name, style, maxerr))
        check(minz >= -1e-9, mol.name .. " / " .. style .. " not below bed: " .. minz)
    end
end

-- Coloring: caffeine has C, H, N, O -> filaments 1..4, all volumes stay printed parts
local obj = run({ molecule = "Kofein" })
local seen = {}
for i = 2, #obj.vols do seen[obj.vols[i].params.extruder] = true; check(obj.vols[i].type == "solid", "colored volume solid") end
check(seen[1] and seen[2] and seen[3] and seen[4] and not seen[5], "caffeine filament mapping")
check(obj.object_params and obj.object_params.extruder, "main atom extruder")
TOOLS = 1
obj = run({ molecule = "Kofein" })
check(obj.object_params and obj.vols[2].params, "single tool: still colored")
TOOLS = 5
obj = run({ molecule = "Kofein", filaments = 2 })
local mx = 0
for i = 2, #obj.vols do mx = math.max(mx, obj.vols[i].params.extruder) end
check(mx == 2, "filament cap 2")
obj = run({ molecule = "Kofein", colors = false })
check(obj.object_params == nil and obj.vols[2].params == nil, "colors off")

-- Fit to size: largest extent equals max_size
for _, sty in ipairs({ "Spheres", "Ball-and-Stick", "Sticks" }) do
    obj = run({ molecule = "Aspirin", style = sty, max_size = 80 })
    local lo, hi = { 1e9, 1e9, 1e9 }, { -1e9, -1e9, -1e9 }
    for _, v in ipairs(obj.vols) do
        local b = v.mesh:bounds()
        for _, c in ipairs({ { b.min_x, b.min_y, b.min_z }, { b.max_x, b.max_y, b.max_z } }) do
            if not v.rotate then
                local w = world(v, c)
                for k = 1, 3 do lo[k] = math.min(lo[k], w[k]); hi[k] = math.max(hi[k], w[k]) end
            end
        end
    end
    -- spheres alone define the extent closely enough for Spheres/Ball-and-Stick
    local ext = math.max(hi[1] - lo[1], hi[2] - lo[2], hi[3] - lo[3])
    check(ext <= 80 + 1e-6 and ext > 60, sty .. " fit to 80 mm, spheres extent " .. ext)
end

-- Multiple bonds stay inside both atoms: spacing + radius < smaller atom radius
for _, mol in ipairs(require('library')) do
    local pr = chem.build_primitives(mol, { style = "ball_and_stick", scale = 10, factor = 1, bond_factor = 0.4, multiple_bonds = true })
    for _, c in ipairs(pr) do
        if c.kind == "cylinder" then
            local nearest, rr = math.huge, 0
            for i = 1, #mol.atoms do
                local dd = chem.len(chem.sub(c.from, pr[i].center))
                if dd < nearest then nearest, rr = dd, pr[i].r end
            end
            check(nearest + c.r * 0.5 < rr, mol.name .. " bond attached (offset " .. nearest .. ", atom r " .. rr .. ")")
        end
    end
end

-- Bond radius follows web: Ball-and-Stick 0.5 * 0.4 * 10 = 2 mm, Sticks 0.2 * 1 * 10 = 2 mm
local m = require('library')[1]
local p = chem.build_primitives(m, { style = "ball_and_stick", scale = 10, factor = 1, bond_factor = 0.4, multiple_bonds = true })
check(math.abs(p[#p].r - 2) < 1e-9 and math.abs(p[1].r - 152/150*0.4*10) < 1e-9, "ball-and-stick radii")

obj = run({ custom = "3; voda; O 0 0 0; H 0.96 0 0; H -0.24 0.93 0" })
check(#obj.vols == 3 + 4, "custom XYZ water")
local f = io.open(SDF); local sdf = f:read("a"); f:close()
check(run({ custom = sdf }) ~= nil, "custom MOL")
local mm = chem.parse(sdf); check(#mm.atoms == 3 and mm.bonds[1][3] == 2, "CO2 double bond")

obj = run({ molecule = "Methan (CH₄)", hydrogens = false, flatten = 2 })
check(#obj.vols == 2 and obj.vols[2].type == "neg", "methane w/o H + cut cube")
local cube = obj.vols[2]
check(math.abs(cube.translate.z + cube.mesh:bounds().max_z) < 1e-9, "cut cube top at z = 0")
check(math.abs(world(obj.vols[1], {0,0,0})[3] - (152 == 0 and 0 or (170/150*0.4*10 - 2))) < 1e-9, "carbon sunk 2 mm")

-- CPK matching against the XL 5T filaments from the screenshot
COLOR_KEY = "filament_colour"
FILAMENT_COLORS = { "#FF8000", "#E6007E", "#00B4E6", "#E52421", "#FFE14D" }
obj = run({ molecule = "Kofein" })
local by_el = {}
local caffeine = nil
for _, m in ipairs(require('library')) do if m.name == "Kofein" then caffeine = m end end
local _, order = chem.assign_filaments_by_color(caffeine.atoms, FILAMENT_COLORS)
local fmap = chem.assign_filaments_by_color(caffeine.atoms, FILAMENT_COLORS)
check(fmap.O == 4 and fmap.N == 3, "CPK: O red(4) N cyan(3), got O" .. tostring(fmap.O) .. " N" .. tostring(fmap.N))
local seen_f = {}
for _, el in ipairs({ "C", "H", "O", "N" }) do check(not seen_f[fmap[el]], "CPK distinct filament for " .. el); seen_f[fmap[el]] = true end
print("CPK caffeine map: C" .. fmap.C .. " H" .. fmap.H .. " O" .. fmap.O .. " N" .. fmap.N)
-- the plugin applies it to volumes
local ext = {}
for i = 2, #obj.vols do ext[obj.vols[i].params.extruder] = true end
check(ext[3] and ext[4], "volumes use CPK filaments")
-- order mode ignores colors
obj = run({ molecule = "Kofein", filament_mode = "Postupně (C, H, O, N…)" })
check(obj.object_params.extruder == 1, "order mode: C on filament 1")
-- colors stored under the other key / unreadable -> fallback to order
COLOR_KEY = "nope"
obj = run({ molecule = "Kofein" })
check(obj.object_params.extruder == 1, "unreadable colors fall back to order")
-- more elements than filaments share the closest one
COLOR_KEY = "filament_colour"; FILAMENT_COLORS = { "#FF0000", "#FFFFFF" }
fmap = chem.assign_filaments_by_color(caffeine.atoms, FILAMENT_COLORS)
check(fmap.O == 1 and fmap.H == 2 and fmap.C and fmap.N, "2 filaments shared")
FILAMENT_COLORS = nil

-- Errors are embossed onto the bed instead of raised
obj = run({ molecule = "Vlastní struktura (pole níže)" })
check(obj and obj.vols[1].mesh.text and obj.vols[1].mesh.text:find("vyberte molekulu"), "empty custom -> CZ error text")
obj = run({ custom = "hello world" })
check(obj and obj.vols[1].mesh.text:find("nerozpoznaný formát"), "garbage -> CZ error text")
obj = run({ custom = "2;x;C 0 0 0" .. string.rep("; C 0 0 0", 1000) })
check(obj and obj.vols[1].mesh.text:find("1001"), "too many atoms text: " .. tostring(obj and obj.vols[1].mesh.text))

-- Zero / missing factors fall back to the web defaults
obj = run({ molecule = "Kofein", bond_factor = 0, factor = 0, scale = 0 })
check(obj and #obj.vols > 24 and not obj.vols[1].mesh.text, "zero factors fall back to defaults")

-- English entry: same model, English error text
local o = {}; for _, p in ipairs(info_en.params) do o[p.name] = p.default end
added = nil; execute_en(o)
local cz = run({ molecule = "Kofein" })
check(added and #added.vols == #cz.vols, "EN caffeine equals CZ caffeine")
o.molecule = "Custom structure (field below)"; added = nil; execute_en(o)
check(added and added.vols[1].mesh.text:find("pick a molecule"), "EN error text")

-- Combobox lists match the library
local lib = require('library')
local function names(inf) for _, p in ipairs(inf.params) do if p.name == "molecule" then return p.allowed_values end end end
local cs_names, en_names = names(info), names(info_en)
check(#cs_names == #lib + 1 and #en_names == #lib + 1, "combobox sizes")
for i, m in ipairs(lib) do
    check(cs_names[i + 1] == m.name, "cs name " .. m.name)
    check(en_names[i + 1] == m.name_en, "en name " .. m.name_en)
end
print(fails == 0 and ("OK (" .. CYL_MODE .. ")") or (fails .. " failures"))
