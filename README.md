# 3D Molecules – PrusaSlicer 3.0 plugin

A simplified, offline version of the web app [3dmolekuly.vscht.cz](https://3dmolekuly.vscht.cz)
right inside PrusaSlicer. It builds a multicolor, print-ready 3D model of a molecule.

> **The full version is on the web.** [3dmolekuly.vscht.cz](https://3dmolekuly.vscht.cz) also
> offers PubChem search, PDB and CIF import, structure drawing, print-in-place moving joints
> (Ball-and-Stick MOVING JOINTS), spheres split for gluing and 3MF/STL export.

## Installation

- **From the Plugin Marketplace:** in PrusaSlicer open the Plugin Marketplace, search for
  "3D molekuly" and click *Install*.
- **Manually (development):** copy the `cz.vscht.3dmolekuly.molecules` folder to
  `~/Library/Application Support/PrusaSlicer3/lua/` (macOS; development builds use
  `PrusaSlicer3-dev`) and restart PrusaSlicer.

The plugin is in the menu **3D molekuly · 3D Molecules**, with two entries:
**Create model (EN)** in English and **Vytvořit model (CZ)** in Czech.

## Usage

1. Pick a molecule from the list, or paste your own structure (see below).
2. Choose the model type and settings.
3. Confirm. The model is placed on the current bed.

### Settings

Names, defaults and size formulas match the web app. Czech labels are in brackets.

| Setting | Default | Meaning |
|---|---|---|
| Molecule *(Molekula)* | Caffeine | Built-in library of 15 molecules (3D structures from PubChem). |
| Custom structure *(Vlastní struktura)* | empty | When filled in, it overrides the selected molecule. |
| Select Model Type *(Typ zobrazení)* | Ball-and-Stick | `Spheres` (space-filling), `Ball-and-Stick`, `Sticks`. |
| Print Model Scale (mm / Å) *(Měřítko modelu)* | 10 | How many millimetres one ångström takes. |
| Largest dimension [mm] *(Největší rozměr)* | 0 | When above 0, the model is scaled so that its longest side has this length; the scale is then ignored. |
| Multiplication Factor *(Násobící faktor)* | 1 | Atom size (stick thickness for `Sticks`). |
| Bond Diameter Factor *(Násobící faktor vazby)* | 0.4 | Bond thickness for `Ball-and-Stick` (diameter = factor × scale). |
| Hydrogens *(Vodíky)* | on | Off removes H atoms and their bonds. |
| Show Multiple Bonds *(Zobrazit násobné vazby)* | on | Double and triple bonds as 2 or 3 parallel sticks. |
| Color by element *(Barvy podle prvků)* | on | Every element gets its own filament (see Multicolor printing). |
| Filament assignment *(Přiřazení filamentů)* | Closest CPK color | How elements are matched to filaments (see Multicolor printing). |
| Number of filaments *(Počet filamentů)* | 0 | 0 = one filament per element. Otherwise elements beyond this number share the last filament. |
| Flatten bottom [mm] *(Seříznout spodek)* | 0 | Cuts off the bottom of the model for better bed adhesion. |

### Custom structure

The field is a single line, so lines are separated with a semicolon `;` (`|` or `\n` work too).

**XYZ:** one atom per line as `element x y z` (coordinates in Å). A leading atom count and a
comment line are skipped. Bonds are inferred from atom distances (covalent radii), all of them
single.

```
O 0 0 0; H 0.96 0 0; H -0.24 0.93 0
```

**MOL / SDF (V2000 and V3000):** the file contents, e.g. a *3D SDF* downloaded from PubChem.
Bonds and bond orders are kept. From a file with several molecules only the first one is used.
Files with 2D coordinates (all z = 0) give a flat model; only the web app computes a 3D shape
from a 2D drawing.

The plugin handles at most 1000 atoms.

When a structure cannot be read, the plugin places a text with the error message on the bed
instead of the model (PrusaSlicer does not show plugin errors otherwise). Delete the text
afterwards.

### Multicolor printing

With *Color by element* on, every element gets its own filament. *Filament assignment*:

- **Closest CPK color** (default): the plugin reads the filament colors of the printer and gives
  each element the filament closest to its CPK color (the same colors as the web app: C gray,
  H white, O red, N blue, S yellow…). It looks for the assignment with the smallest total color
  difference, so typical elements get "their" color and an element without a suitable filament
  (e.g. C without a gray one) gets what is left. When there are more elements than filaments,
  the remaining elements share the closest color.
- **In order (C, H, O, N…)**: the order C, H, O, N, S, P, Cl, F, Br, I, then the rest
  alphabetically. Also used when the filament colors cannot be read.

Filament colors are read when the plugin runs, so set up the filaments first. Filaments are
assigned even on a single-tool printer; to print, add the matching number of filaments (MMU,
INDX) or limit the number of colors with *Number of filaments*.

Each half of a bond takes the color of the atom it belongs to, as in the web app.

**Colors only show up with multiple filaments.** The plugin always assigns filament numbers, but
a single-filament printer (e.g. a CORE One without MMU3) renders the whole model in the color of
its only filament. To get a multicolor model:

1. In the bed panel (top right), switch the printer to a multi-filament variant, e.g.
   *CORE One + MMU3* or *CORE One INDX*.
2. Set the filaments and their colors, e.g. by CPK: C gray, H white, O red, N blue.
3. The model is colored automatically. The filament numbers are already in it, there is no need
   to run the plugin again.

The plugin cannot add filaments or set their colors. The PrusaSlicer 3.0 plugin API can only
write numeric settings, the filament color is text, and the list of filaments comes from the
printer.

Volumes are not named after atoms and cannot be merged into one part per element, because the
PrusaSlicer 3.0 plugin API does not allow it. The plugin therefore at least sorts them: all
volumes of one element (atoms and bond halves) are next to each other in the object list, in
filament order.

## Limitations compared to the web app

The plugin runs in PrusaSlicer's sandbox without network or file access. Therefore:

- **It does not search PubChem or PDB.** Download the structure elsewhere and paste it into
  *Custom structure*.
- **No moving joints or spheres split for gluing.** These are web-only.
- **Volumes are not named after atoms.** The PrusaSlicer 3.0 plugin API cannot name volumes yet.

## Known issues (PrusaSlicer 3.0 alpha)

- **A long text in *Custom structure* breaks the dialog rendering.** After pasting a large file
  (e.g. an SDF with hundreds of molecules) the dialog turns into a tangle of white lines. The
  model is still created, but paste one molecule only: for an SDF, the text from the name down
  to the `M  END` line. This is a bug in the PrusaSlicer dialog that the plugin cannot work
  around.
- **Dialog labels must be single-line.** A multi-line label breaks the rendering the same way.
- **Renaming the plugin's menu entries at runtime can crash PrusaSlicer** (after *Rescan
  plugins* the old entry stays in the native macOS menu). Restart PrusaSlicer after updating
  the plugin.
- **PrusaSlicer does not show plugin errors**, it only writes them to the log
  (`~/Library/Application Support/PrusaSlicer3/shared_runtime/log.txt`, `PrusaSlicer3-dev` for
  development builds). The plugin therefore prints the error as text on the bed.

## Development

```
3d-molekuly-prusaslicer-plugin/
├── README.md, CHANGELOG.md, PUBLISHING.md  docs (not shipped)
├── .github/workflows/
│   ├── check.yml                      tests + dry-run bundle on every push
│   └── release.yml                    signs and publishes on a GitHub release
├── tests/                             run.sh, tests against a mocked PrusaSlicer API
├── tools/                             sdf2lua.py + PubChem 3D SDF for the built-in library
└── cz.vscht.3dmolekuly.molecules/     the plugin bundle: everything in it ships
    ├── manifest.json
    ├── molecule_cs.lua, molecule_en.lua  menu entries: dialog labels per language
    ├── generator.lua                  model assembly and error messages (PrusaSlicer API)
    ├── chem.lua                       parsing, bond inference, geometry, CPK colors (pure Lua)
    └── library.lua                    built-in molecules, generated from PubChem 3D SDF
```

Run the tests (needs `lua5.4` and/or `luajit`):

```bash
tests/run.sh
```

Regenerate the built-in library after changing `tools/pubchem/` or the names in `tools/sdf2lua.py`
(keep the menu lists in `molecule_cs.lua` and `molecule_en.lua` in sync):

```bash
python3 tools/sdf2lua.py tools/pubchem cz.vscht.3dmolekuly.molecules/library.lua
```

`chem.lua` has no PrusaSlicer dependencies, so the geometry can be tested with a plain
`lua` interpreter. The API reference is `src/slic3r-shared/src/Slic3r/App/Lua/ProjectApi.cpp`
in the [PrusaSlicer repository](https://github.com/prusa3d/PrusaSlicer).

Publishing to the Plugin Marketplace is described in [PUBLISHING.md](PUBLISHING.md).
