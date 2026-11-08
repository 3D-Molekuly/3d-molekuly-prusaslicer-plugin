-- Shared implementation of the Czech and English menu entries (molecule_cs.lua, molecule_en.lua).
-- Kept out of the plugin files because PrusaSlicer reads `info` without `require`.

-- PrusaSlicer loads every .lua file of the bundle in an engine without `require` to look for
-- `info`, so modules are resolved lazily on first use instead of at load time.
local chem = setmetatable({}, { __index = function(_, key) return require('chem')[key] end })

local M = {}

local MESSAGES = {
    cs = {
        prefix = "3D molekuly – chyba: ",
        need_input = "vyberte molekulu nebo vložte strukturu XYZ či MOL",
        not_found = "molekula nenalezena: %s",
        no_atoms = "struktura neobsahuje žádné atomy",
        too_many = "příliš mnoho atomů: %s (nejvýše %s)",
        mol_counts = "MOL: nelze přečíst počet atomů a vazeb",
        mol_atom = "MOL: chybný řádek atomu %s",
        mol_bond = "MOL: chybný řádek vazby %s",
        unknown_format = "nerozpoznaný formát, vložte XYZ (O 0 0 0; H 0.96 0 0) nebo MOL",
        v3000 = "MOL V3000 není podporován, použijte V2000 nebo XYZ",
        internal = "%s"
    },
    en = {
        prefix = "3D Molecules – error: ",
        need_input = "pick a molecule or paste an XYZ or MOL structure",
        not_found = "molecule not found: %s",
        no_atoms = "the structure contains no atoms",
        too_many = "too many atoms: %s (at most %s)",
        mol_counts = "MOL: cannot read the atom and bond counts",
        mol_atom = "MOL: invalid atom line %s",
        mol_bond = "MOL: invalid bond line %s",
        unknown_format = "unknown format, paste XYZ (O 0 0 0; H 0.96 0 0) or MOL",
        v3000 = "MOL V3000 is not supported, use V2000 or XYZ",
        internal = "%s"
    }
}

-- Defaults match the web app; used when the dialog hands over a missing or non-positive value.
local DEFAULTS = { scale = 10, factor = 1, bond_factor = 0.4 }

local STYLES = {
    ["Spheres"] = "spheres",
    ["Ball-and-Stick"] = "ball_and_stick",
    ["Sticks"] = "sticks"
}

local function center_of(bb)
    return { (bb.min_x + bb.max_x) / 2, (bb.min_y + bb.max_y) / 2, (bb.min_z + bb.max_z) / 2 }
end

local function vec(t) return { x = t[1], y = t[2], z = t[3] } end

local function positive(value, default)
    if type(value) == "number" and value > 0 then return value end
    return default
end

local function number(value)
    return type(value) == "number" and value or 0
end

local function load_molecule(opts)
    if type(opts.custom) == "string" and opts.custom:find("%S") then
        return chem.parse(opts.custom)
    end
    for _, mol in ipairs(require('library')) do
        if mol.name == opts.molecule or mol.name_en == opts.molecule then return mol end
    end
    chem.fail("need_input")
end

local function build(opts)
    local volume_type = VolumeType or api.VolumeType
    local scale = positive(opts.scale, DEFAULTS.scale)
    local max_size = number(opts.max_size)
    local flatten = math.max(number(opts.flatten), 0)

    local mol = load_molecule(opts)
    if not opts.hydrogens then mol = chem.remove_hydrogens(mol) end
    if #mol.atoms == 0 then chem.fail("no_atoms") end
    if #mol.atoms > chem.MAX_ATOMS then chem.fail("too_many", { #mol.atoms, chem.MAX_ATOMS }) end

    local build_opts = {
        style = STYLES[opts.style] or "ball_and_stick",
        scale = scale,
        factor = positive(opts.factor, DEFAULTS.factor),
        bond_factor = positive(opts.bond_factor, DEFAULTS.bond_factor),
        multiple_bonds = opts.multiple_bonds
    }
    local prims = chem.build_primitives(mol, build_opts)
    if max_size > 0 then
        -- Every size is proportional to the scale, so rescaling once hits the target exactly.
        local lo, hi = chem.bounds(prims)
        local extent = math.max(hi[1] - lo[1], hi[2] - lo[2], hi[3] - lo[3])
        build_opts.scale = scale * max_size / extent
        prims = chem.build_primitives(mol, build_opts)
    end

    -- Filaments are assigned even on a single-tool printer: the slicer then asks for the
    -- missing filaments (MMU, INDX or a manual filament change), as with the web's 3MF.
    local max_filaments = number(opts.filaments) > 0 and opts.filaments or math.huge
    local filament, elements = chem.assign_filaments(mol.atoms, max_filaments)
    local use_colors = opts.colors and #elements > 1

    -- Volumes cannot be merged or named through the API, so at least keep each element's
    -- atoms and bond halves next to each other in the object list, in filament order.
    local grouped = {}
    for _, el in ipairs(elements) do
        for _, p in ipairs(prims) do
            if p.element == el then table.insert(grouped, p) end
        end
    end
    prims = grouped

    -- The slicer leaves the instance at z = 0 and the top-level translate moves only the
    -- main volume, so every volume gets an absolute position with the cut plane at z = 0.
    local cut_z = chem.min_z(prims) + flatten
    local offset = { 0, 0, -cut_z }

    local volumes = {}
    for _, p in ipairs(prims) do
        local vol
        if p.kind == "sphere" then
            local mesh = api.make_sphere(p.r, chem.facet_angle(p.r))
            local c = center_of(mesh:bounds())
            vol = { mesh = mesh, translate = vec(chem.sub(chem.add(p.center, offset), c)) }
        else
            local axis = chem.sub(p.to, p.from)
            local length = chem.len(axis)
            local mesh = api.make_cylinder(p.r, length, chem.facet_angle(p.r))
            local bb = mesh:bounds()
            -- Whatever the primitive's origin, rotate it so the cylinder's base center ends up at p.from.
            local rotate = chem.z_to_direction(chem.mul(axis, 1 / length))
            local base = chem.rotate_point({ (bb.min_x + bb.max_x) / 2, (bb.min_y + bb.max_y) / 2, bb.min_z }, rotate)
            vol = { mesh = mesh, rotate = rotate, translate = vec(chem.sub(chem.add(p.from, offset), base)) }
        end
        if use_colors then
            -- A volume with params defaults to a modifier, so keep it a printed part explicitly.
            vol.type = volume_type.Solid
            vol.params = { extruder = filament[p.element] }
        end
        table.insert(volumes, vol)
    end

    if flatten > 0 then
        local lo, hi = chem.bounds(prims)
        local margin, depth = 5, flatten + 5
        local cube = api.make_cube(hi[1] - lo[1] + 2 * margin, hi[2] - lo[2] + 2 * margin, depth)
        local cb = cube:bounds()
        table.insert(volumes, {
            mesh = cube,
            type = volume_type.Negative,
            translate = { x = lo[1] - margin - cb.min_x, y = lo[2] - margin - cb.min_y, z = -depth - cb.min_z }
        })
    end

    -- The first atom is the object's main mesh; its translate/rotate are top-level keys.
    local main = table.remove(volumes, 1)
    api.project:add_object{
        mesh = main.mesh,
        translate = main.translate,
        other_volumes = volumes,
        object_params = use_colors and { extruder = main.params.extruder } or nil
    }
end

function M.message(err, lang)
    local texts = MESSAGES[lang] or MESSAGES.en
    if type(err) == "table" and err.key and texts[err.key] then
        local args = type(err.arg) == "table" and err.arg or { err.arg }
        for i, a in ipairs(args) do args[i] = tostring(a) end
        local unpack_args = table.unpack or unpack
        return texts.prefix .. string.format(texts[err.key], unpack_args(args))
    end
    return texts.prefix .. string.format(texts.internal, tostring(err))
end

-- PrusaSlicer only logs plugin errors, so the message is also embossed onto the bed:
-- otherwise a mistyped structure looks like nothing happened.
function M.run(opts, lang)
    local ok, err = pcall(build, opts)
    if ok then return end
    local built, text = pcall(M.message, err, lang)
    if not built then text = tostring(err) end
    print(text)
    pcall(function()
        api.project:add_object{
            mesh = api.emboss_text{ font = api.get_default_font(), text = text, depth = 1 }
        }
    end)
end

return M
