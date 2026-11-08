-- English menu entry. Labels, model types and defaults follow the web app
-- (src/lib/translations/en.json); the logic lives in generator.lua.

info = {
    id = "molecule_en",
    type = "project.plugin",
    title = "3D molecule model · full version at 3dmolekuly.vscht.cz",
    menu = "3D molekuly · 3D Molecules/Create model (EN)",
    params = {
        {name = "molecule", label = "Molecule", type = "combobox", default = "Caffeine",
         allowed_values = {
            "Custom structure (field below)",
            -- Must match `name_en` in library.lua.
            "Water (H₂O)", "Methane (CH₄)", "Ammonia (NH₃)", "Carbon dioxide (CO₂)", "Ethene (C₂H₄)",
            "Ethyne (C₂H₂)", "Ethanol", "Acetic acid", "Sulfuric acid", "Cyclohexane", "Benzene",
            "Glucose", "Paracetamol", "Aspirin", "Caffeine"
         }},
        {name = "custom", label = "Custom structure (XYZ: O 0 0 0; H 0.96 0 0 … or MOL)", type = "string", default = ""},
        {name = "style", label = "Select Model Type", type = "combobox", default = "Ball-and-Stick",
         allowed_values = {"Spheres", "Ball-and-Stick", "Sticks"}},
        {name = "scale", label = "Print Model Scale (mm / Å)", type = "float", default = 10},
        {name = "max_size", label = "Largest dimension  [mm]  (0 = use scale)", type = "float", default = 0},
        {name = "factor", label = "Multiplication Factor", type = "float", default = 1},
        {name = "bond_factor", label = "Bond Diameter Factor", type = "float", default = 0.4},
        {name = "hydrogens", label = "Hydrogens", type = "bool", default = true},
        {name = "multiple_bonds", label = "Show Multiple Bonds", type = "bool", default = true},
        {name = "colors", label = "Color by element (multiple filaments)", type = "bool", default = true},
        {name = "filament_mode", label = "Filament assignment", type = "combobox", default = "Closest CPK color",
         allowed_values = {"Closest CPK color", "In order (C, H, O, N…)"}},
        {name = "filaments", label = "Number of filaments  (0 = one per element)", type = "int", default = 0},
        {name = "flatten", label = "Flatten bottom  [mm]", type = "float", default = 0}
    }
}

function execute(opts)
    require('generator').run(opts, "en")
end
