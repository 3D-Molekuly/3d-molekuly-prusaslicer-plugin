-- Chemistry and geometry helpers for the molecule plugin.
-- Pure Lua (no PrusaSlicer API), so it can be tested with a plain interpreter.

local M = {}

-- Van der Waals radii in pm (same table as the web app's FALLBACK_ELEMENTS).
M.VDW_RADII_PM = {
    H = 120, He = 140, Li = 182, Be = 153, B = 192, C = 170, N = 155, O = 152, F = 147,
    Na = 227, Mg = 173, Al = 184, Si = 210, P = 180, S = 180, Cl = 175, K = 275, Ca = 231,
    Ti = 187, Mn = 197, Fe = 194, Co = 192, Ni = 163, Cu = 140, Zn = 139, Se = 190,
    Br = 185, Ag = 172, I = 198, Pt = 175, Au = 166
}

-- Covalent radii in Å, used to infer bonds when the input has only coordinates.
M.COVALENT_RADII = {
    H = 0.31, He = 0.28, Li = 1.28, Be = 0.96, B = 0.84, C = 0.76, N = 0.71, O = 0.66, F = 0.57,
    Ne = 0.58, Na = 1.66, Mg = 1.41, Al = 1.21, Si = 1.11, P = 1.07, S = 1.05, Cl = 1.02,
    Ar = 1.06, K = 2.03, Ca = 1.76, Ti = 1.60, Mn = 1.39, Fe = 1.32, Co = 1.26, Ni = 1.24,
    Cu = 1.32, Zn = 1.22, Se = 1.20, Br = 1.20, Ag = 1.45, I = 1.39, Pt = 1.36, Au = 1.36
}

-- Elements get filaments in this order when coloring by element.
local COLOR_PRIORITY = { "C", "H", "O", "N", "S", "P", "Cl", "F", "Br", "I" }

-- Raises an error the plugin shows to the user in their language (see generator.lua).
function M.fail(key, arg)
    error({ key = key, arg = arg }, 0)
end

local BOND_TOLERANCE = 0.42
local MIN_BOND_DIST = 0.4
M.MAX_ATOMS = 1000

local function normalize_element(raw)
    local s = raw:gsub("[^%a]", "")
    if #s == 0 then return nil end
    return s:sub(1, 1):upper() .. s:sub(2, 2):lower()
end

local function split_lines(text)
    -- PrusaSlicer's text field is single line, so ";" and "|" also separate lines.
    local normalized = text:gsub("\\n", "\n"):gsub("[;|]", "\n")
    local lines = {}
    for line in (normalized .. "\n"):gmatch("(.-)\r?\n") do
        table.insert(lines, line)
    end
    return lines
end

local function words(line)
    local out = {}
    for w in line:gmatch("%S+") do table.insert(out, w) end
    return out
end

-- MOL/SDF (V2000). Parsed by whitespace, so it survives pasting into one line.
local function parse_molfile(lines)
    local counts_idx
    for i, line in ipairs(lines) do
        if line:find("V2000") then counts_idx = i break end
    end
    local counts = words(lines[counts_idx])
    local na, nb = tonumber(counts[1]), tonumber(counts[2])
    if not na or not nb then M.fail("mol_counts") end
    local mol = { atoms = {}, bonds = {} }
    for i = 1, na do
        local w = words(lines[counts_idx + i] or "")
        local x, y, z = tonumber(w[1]), tonumber(w[2]), tonumber(w[3])
        local el = w[4] and normalize_element(w[4])
        if not (x and y and z and el) then M.fail("mol_atom", i) end
        table.insert(mol.atoms, { el, x, y, z })
    end
    for i = 1, nb do
        local w = words(lines[counts_idx + na + i] or "")
        local a, b, order = tonumber(w[1]), tonumber(w[2]), tonumber(w[3])
        if not (a and b and order) then M.fail("mol_bond", i) end
        -- Aromatic (4) and other query bond types are drawn as single bonds.
        table.insert(mol.bonds, { a, b, (order >= 1 and order <= 3) and order or 1 })
    end
    return mol
end

-- XYZ: lines "El x y z"; a leading atom count and comment line are skipped.
local function parse_xyz(lines)
    local mol = { atoms = {} }
    for _, line in ipairs(lines) do
        local w = words(line)
        local el = w[1] and normalize_element(w[1])
        local x, y, z = tonumber(w[2]), tonumber(w[3]), tonumber(w[4])
        if el and x and y and z then
            table.insert(mol.atoms, { el, x, y, z })
        end
    end
    if #mol.atoms == 0 then
        M.fail("unknown_format")
    end
    mol.bonds = M.infer_bonds(mol.atoms)
    return mol
end

function M.parse(text)
    local lines = split_lines(text)
    for _, line in ipairs(lines) do
        if line:find("V2000") then return parse_molfile(lines) end
    end
    if text:find("V3000") then M.fail("v3000") end
    return parse_xyz(lines)
end

function M.infer_bonds(atoms)
    local bonds = {}
    for i = 1, #atoms do
        local a = atoms[i]
        local ra = M.COVALENT_RADII[a[1]] or 0.77
        for j = i + 1, #atoms do
            local b = atoms[j]
            local rb = M.COVALENT_RADII[b[1]] or 0.77
            local dx, dy, dz = a[2] - b[2], a[3] - b[3], a[4] - b[4]
            local d2 = dx * dx + dy * dy + dz * dz
            local max_d = ra + rb + BOND_TOLERANCE
            if d2 >= MIN_BOND_DIST ^ 2 and d2 <= max_d ^ 2 and not (a[1] == "H" and b[1] == "H") then
                table.insert(bonds, { i, j, 1 })
            end
        end
    end
    return bonds
end

function M.remove_hydrogens(mol)
    local map, atoms, bonds = {}, {}, {}
    for i, a in ipairs(mol.atoms) do
        if a[1] ~= "H" then
            table.insert(atoms, a)
            map[i] = #atoms
        end
    end
    for _, b in ipairs(mol.bonds) do
        if map[b[1]] and map[b[2]] then
            table.insert(bonds, { map[b[1]], map[b[2]], b[3] })
        end
    end
    return { atoms = atoms, bonds = bonds }
end

-- Maps each element to a filament number (1..max_filaments) by COLOR_PRIORITY,
-- then alphabetically; elements beyond max_filaments share the last one.
function M.assign_filaments(atoms, max_filaments)
    local present = {}
    for _, a in ipairs(atoms) do present[a[1]] = true end
    local ordered, seen = {}, {}
    for _, el in ipairs(COLOR_PRIORITY) do
        if present[el] then table.insert(ordered, el) seen[el] = true end
    end
    local rest = {}
    for el in pairs(present) do
        if not seen[el] then table.insert(rest, el) end
    end
    table.sort(rest)
    for _, el in ipairs(rest) do table.insert(ordered, el) end
    local map = {}
    for i, el in ipairs(ordered) do map[el] = math.min(i, max_filaments) end
    return map, ordered
end

-- Vector helpers -------------------------------------------------------------

local function sub(a, b) return { a[1] - b[1], a[2] - b[2], a[3] - b[3] } end
local function add(a, b) return { a[1] + b[1], a[2] + b[2], a[3] + b[3] } end
local function mul(a, s) return { a[1] * s, a[2] * s, a[3] * s } end
local function len(a) return math.sqrt(a[1] ^ 2 + a[2] ^ 2 + a[3] ^ 2) end
local function cross(a, b)
    return { a[2] * b[3] - a[3] * b[2], a[3] * b[1] - a[1] * b[3], a[1] * b[2] - a[2] * b[1] }
end

-- Rotation that turns +Z into the unit vector d: first about Y by theta, then about Z by phi.
-- Matches PrusaSlicer's rotation order (X, then Y, then Z; right-handed, degrees).
function M.z_to_direction(d)
    local theta = math.deg(math.acos(math.max(-1, math.min(1, d[3]))))
    -- math.atan2 exists in Lua 5.1/LuaJIT, two-argument math.atan in 5.3+.
    local phi = math.deg((math.atan2 or math.atan)(d[2], d[1]))
    if math.abs(d[1]) < 1e-9 and math.abs(d[2]) < 1e-9 then phi = 0 end
    return { x = 0, y = theta, z = phi }
end

-- Applies rotate{x, y, z} (degrees) to point p, in PrusaSlicer's order.
function M.rotate_point(p, r)
    local function rot(v, axis, deg)
        local a = math.rad(deg or 0)
        local c, s = math.cos(a), math.sin(a)
        local x, y, z = v[1], v[2], v[3]
        if axis == "x" then return { x, c * y - s * z, s * y + c * z } end
        if axis == "y" then return { c * x + s * z, y, -s * x + c * z } end
        return { c * x - s * y, s * x + c * y, z }
    end
    return rot(rot(rot(p, "x", r.x), "y", r.y), "z", r.z)
end

-- Builds the list of primitives in millimetres:
--   { kind = "sphere", r, center, element }
--   { kind = "cylinder", r, from, to, element }
-- opts mirror the web app's settings and formulas (threejsMolecules3.ts):
--   style ("spheres" | "ball_and_stick" | "sticks"), scale (mm per Å),
--   factor (multiplication factor), bond_factor (bond diameter factor),
--   multiple_bonds (bool).
function M.build_primitives(mol, opts)
    local prims = {}
    local pos = {}
    for i, a in ipairs(mol.atoms) do
        pos[i] = { a[2] * opts.scale, a[3] * opts.scale, a[4] * opts.scale }
    end

    local bond_radius
    if opts.style == "sticks" then
        bond_radius = 0.2 * opts.factor * opts.scale
    else
        bond_radius = 0.5 * opts.bond_factor * opts.scale
    end

    for i, a in ipairs(mol.atoms) do
        local size = (M.VDW_RADII_PM[a[1]] or 170) / 150
        local r
        if opts.style == "spheres" then
            r = size * opts.factor * opts.scale
        elseif opts.style == "sticks" then
            r = bond_radius
        else
            r = size * opts.factor * 0.4 * opts.scale
        end
        table.insert(prims, { kind = "sphere", r = r, center = pos[i], element = a[1] })
    end

    if opts.style == "spheres" then return prims end

    opts = setmetatable({ bond_radius = bond_radius }, { __index = opts })
    for _, b in ipairs(mol.bonds) do
        local ia, ib, order = b[1], b[2], b[3]
        local pa, pb = pos[ia], pos[ib]
        local dir = sub(pb, pa)
        if len(dir) > 1e-6 then
            local mid = mul(add(pa, pb), 0.5)
            local offsets = { { 0, 0, 0 } }
            local r = opts.bond_radius
            if opts.multiple_bonds and opts.style == "ball_and_stick" and order > 1 then
                local up = { 0, 0, 1 }
                if math.abs(dir[3] / len(dir)) > 0.99 then up = { 1, 0, 0 } end
                -- The web offsets parallel bonds by 2 bond radii. Keep them well inside the
                -- smaller atom so they stay attached when printed, thinning them if needed.
                local spacing = math.min(r * 2, 0.7 * math.min(prims[ia].r, prims[ib].r))
                r = math.min(r, 0.6 * spacing)
                local shift = cross(dir, up)
                shift = mul(shift, spacing / len(shift))
                if order == 2 then
                    offsets = { shift, mul(shift, -1) }
                else
                    offsets = { { 0, 0, 0 }, shift, mul(shift, -1) }
                end
            end
            for _, o in ipairs(offsets) do
                -- Each atom owns the half of the bond nearest to it, so halves take the atom's color.
                table.insert(prims, { kind = "cylinder", r = r,
                    from = add(pa, o), to = add(mid, o), element = mol.atoms[ia][1] })
                table.insert(prims, { kind = "cylinder", r = r,
                    from = add(pb, o), to = add(mid, o), element = mol.atoms[ib][1] })
            end
        end
    end
    return prims
end

-- Lowest point of the model, used to drop it onto the bed.
function M.min_z(prims)
    local m = math.huge
    for _, p in ipairs(prims) do
        if p.kind == "sphere" then
            m = math.min(m, p.center[3] - p.r)
        else
            m = math.min(m, p.from[3] - p.r, p.to[3] - p.r)
        end
    end
    return m
end

function M.bounds(prims)
    local lo, hi = { math.huge, math.huge, math.huge }, { -math.huge, -math.huge, -math.huge }
    for _, p in ipairs(prims) do
        local pts = p.kind == "sphere" and { p.center } or { p.from, p.to }
        for _, c in ipairs(pts) do
            for k = 1, 3 do
                lo[k] = math.min(lo[k], c[k] - p.r)
                hi[k] = math.max(hi[k], c[k] + p.r)
            end
        end
    end
    return lo, hi
end

-- Facet angle in degrees for api.make_sphere/make_cylinder. The slicer's default of 1°
-- gives ~82k triangles per sphere; this keeps the chord error under ~0.02 mm instead.
function M.facet_angle(r)
    local fa = 2 * math.deg(math.acos(math.max(0, 1 - 0.02 / r)))
    return math.max(3, math.min(15, fa))
end

M.sub, M.add, M.mul, M.len = sub, add, mul, len

return M
