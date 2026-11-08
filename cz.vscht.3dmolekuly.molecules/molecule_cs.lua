-- Czech menu entry. Labels, model types and defaults follow the web app
-- (src/lib/translations/cs.json); the logic lives in generator.lua.

info = {
    id = "molecule_cs",
    type = "project.plugin",
    title = "3D model molekuly · plná verze na 3dmolekuly.vscht.cz",
    menu = "3D molekuly · 3D Molecules/Vytvořit model (CZ)",
    params = {
        {name = "molecule", label = "Molekula", type = "combobox", default = "Kofein",
         allowed_values = {
            "Vlastní struktura (pole níže)",
            -- Must match `name` in library.lua.
            "Voda (H₂O)", "Methan (CH₄)", "Amoniak (NH₃)", "Oxid uhličitý (CO₂)", "Ethen (C₂H₄)",
            "Ethyn (C₂H₂)", "Ethanol", "Kyselina octová", "Kyselina sírová", "Cyklohexan", "Benzen",
            "Glukóza", "Paracetamol", "Aspirin", "Kofein"
         }},
        {name = "custom", label = "Vlastní struktura (XYZ: O 0 0 0; H 0.96 0 0 … nebo MOL)", type = "string", default = ""},
        {name = "style", label = "Typ zobrazení", type = "combobox", default = "Ball-and-Stick",
         allowed_values = {"Spheres", "Ball-and-Stick", "Sticks"}},
        {name = "scale", label = "Měřítko modelu (mm / Å)", type = "float", default = 10},
        {name = "max_size", label = "Největší rozměr  [mm]  (0 = podle měřítka)", type = "float", default = 0},
        {name = "factor", label = "Násobící faktor", type = "float", default = 1},
        {name = "bond_factor", label = "Násobící faktor vazby", type = "float", default = 0.4},
        {name = "hydrogens", label = "Vodíky", type = "bool", default = true},
        {name = "multiple_bonds", label = "Zobrazit násobné vazby", type = "bool", default = true},
        {name = "colors", label = "Barvy podle prvků (více filamentů)", type = "bool", default = true},
        {name = "filament_mode", label = "Přiřazení filamentů", type = "combobox", default = "Podle CPK barev filamentů",
         allowed_values = {"Podle CPK barev filamentů", "Postupně (C, H, O, N…)"}},
        {name = "filaments", label = "Počet filamentů  (0 = jeden na prvek)", type = "int", default = 0},
        {name = "flatten", label = "Seříznout spodek  [mm]", type = "float", default = 0}
    }
}

function execute(opts)
    require('generator').run(opts, "cs")
end
