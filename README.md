# 3D molekuly – plugin pro PrusaSlicer 3.0

Zjednodušená offline verze webové aplikace [3dmolekuly.vscht.cz](https://3dmolekuly.vscht.cz)
přímo v PrusaSlicer. Vytvoří vícebarevný 3D model molekuly připravený k tisku.

> **Plná verze je na webu.** [3dmolekuly.vscht.cz](https://3dmolekuly.vscht.cz) umí navíc
> vyhledávání v PubChem, import PDB a CIF, kreslení strukturních vzorců, otočné klouby
> (Ball-and-Stick MOVING JOINTS), koule rozdělené pro lepení a export 3MF/STL.

*English version below.*

## Instalace

- **Z Plugin Marketplace:** v PrusaSlicer otevřete Plugin Marketplace, vyhledejte
  „3D molekuly“ a klikněte na *Install*.
- **Ručně (vývoj):** zkopírujte složku `cz.vscht.3dmolekuly.molecules` do
  `~/Library/Application Support/PrusaSlicer3/lua/` (macOS; vývojové sestavení používá
  `PrusaSlicer3-dev`) a v PrusaSlicer zvolte *Rescan plugins*.

Plugin najdete v menu **3D molekuly · 3D Molecules → Vytvořit model (CZ)**. Anglická verze je v položce **Create model (EN)**.

## Použití

1. Vyberte molekulu ze seznamu, nebo vložte vlastní strukturu (viz níže).
2. Zvolte typ zobrazení a nastavení.
3. Potvrďte. Model se vloží na aktuální podložku.

### Nastavení

Názvy, výchozí hodnoty a výpočty velikostí odpovídají webové aplikaci.

| Nastavení | Výchozí | Význam |
|---|---|---|
| Molekula | Kofein | Vestavěná knihovna 15 molekul (3D struktury z PubChem). |
| Vlastní struktura (XYZ nebo MOL) | prázdné | Když není prázdné, má přednost před knihovnou. |
| Typ zobrazení | Ball-and-Stick | `Spheres` (kalotový), `Ball-and-Stick` (kuličky a tyčinky), `Sticks` (tyčinkový). |
| Měřítko modelu (mm / Å) | 10 | Kolik milimetrů odpovídá 1 Å. |
| Největší rozměr [mm] | 0 | Je-li větší než 0, model se zvětší nebo zmenší tak, aby jeho nejdelší strana měla tuto délku. Měřítko se pak nepoužije. |
| Násobící faktor | 1 | Velikost atomů (u `Sticks` tloušťka tyčinek). |
| Násobící faktor vazby | 0,4 | Tloušťka vazeb u `Ball-and-Stick` (průměr = faktor × měřítko). |
| Vodíky | ano | Vypnutím se odstraní atomy H i jejich vazby. |
| Zobrazit násobné vazby | ano | Dvojné a trojné vazby jako 2 nebo 3 rovnoběžné tyčinky. |
| Barvy podle prvků | ano | Každý prvek dostane vlastní filament (viz Vícebarevný tisk). |
| Počet filamentů | 0 | 0 = jeden filament na prvek. Jinak prvky nad tento počet sdílejí poslední filament. |
| Seříznout spodek [mm] | 0 | Seřízne spodní část modelu pro lepší přilnavost k podložce. |

### Vlastní struktura

Pole je jednořádkové, proto se řádky oddělují středníkem `;` (funguje i `|` nebo `\n`).

**XYZ:** každý řádek ve tvaru `prvek x y z` (souřadnice v Å). Úvodní řádek s počtem
atomů a řádek s komentářem se přeskočí. Vazby plugin dopočítá podle vzdálenosti atomů
(kovalentní poloměry), všechny jsou jednoduché.

```
O 0 0 0; H 0.96 0 0; H -0.24 0.93 0
```

**MOL / SDF (V2000 i V3000):** obsah souboru, například *3D SDF* stažený z PubChem. Obsahuje
vazby i jejich násobnost. Ze souboru s více molekulami se použije první. Soubory s 2D souřadnicemi
(všechna z = 0) dají plochý model, 3D tvar z 2D vzorce dopočítá jen web.

Plugin zvládne nejvýše 1000 atomů.

Když strukturu nejde přečíst, plugin místo modelu vloží na podložku text s popisem chyby
(PrusaSlicer chyby pluginů jinak nezobrazuje). Text pak smažte.

### Vícebarevný tisk

Při zapnutých barvách dostane každý prvek vlastní filament. Nastavení *Přiřazení filamentů*:

- **Podle CPK barev filamentů** (výchozí): plugin přečte barvy filamentů na tiskárně a každému
  prvku přiřadí filament s nejbližší barvou k jeho CPK barvě (stejné barvy jako na webu: C šedá,
  H bílá, O červená, N modrá, S žlutá…). Hledá přiřazení s nejmenším celkovým rozdílem barev,
  takže typické prvky dostanou „svou“ barvu a prvek bez vhodného filamentu (např. C bez šedé)
  dostane zbývající. Když je prvků víc než filamentů, sdílí zbylé prvky nejbližší barvu.
- **Postupně (C, H, O, N…)**: pořadí C, H, O, N, S, P, Cl, F, Br, I a pak ostatní abecedně.
  Použije se i tehdy, když barvy filamentů nejde přečíst.

Barvy filamentů se čtou při spuštění pluginu, takže filamenty nastavte předem. Filamenty se přiřadí i na tiskárně s jedním nástrojem. Pro tisk
pak přidejte odpovídající počet filamentů (MMU, INDX), nebo omezte počet barev nastavením
*Počet filamentů*.

Každá polovina vazby má barvu atomu, ke kterému patří, stejně jako na webu.

**Barvy uvidíte jen s více filamenty.** Plugin přiřadí čísla filamentů vždy, ale tiskárna
s jedním filamentem (např. CORE One bez MMU3) vykreslí celý model barvou toho jediného filamentu.
Postup pro vícebarevný model:

1. V panelu podložky (vpravo nahoře) změňte tiskárnu na variantu s více filamenty, např.
   *CORE One + MMU3* nebo *CORE One INDX*.
2. Nastavte filamenty a jejich barvy, např. podle CPK: C šedá, H bílá, O červená, N modrá.
3. Model se obarví sám. Čísla filamentů v něm už jsou, plugin není potřeba spouštět znovu.

Plugin nemůže filamenty přidat ani nastavit jejich barvu. API v PrusaSlicer 3.0 umí zapisovat jen
číselná nastavení, barva filamentu je text a seznam filamentů je dán tiskárnou.

Části nejsou pojmenované podle atomů a nejdou sloučit do jednoho dílu na prvek, protože to plugin
API v PrusaSlicer 3.0 neumožňuje. Plugin je proto aspoň seřadí: všechny části jednoho prvku
(atomy i poloviny vazeb) jsou v seznamu pohromadě v pořadí čísel filamentů.

## Omezení oproti webu

Plugin běží v sandboxu PrusaSlicer bez přístupu k internetu a k souborům. Proto:

- **Nevyhledává v PubChem ani PDB.** Strukturu stáhněte jinde a vložte ji do pole
  *Vlastní struktura*.
- **Neumí otočné klouby ani koule pro lepení.** Ty jsou jen na webu.
- **Části modelu nejsou pojmenované podle atomů.** Plugin API v PrusaSlicer 3.0 zatím
  neumožňuje pojmenovat části objektu.

## Známé problémy (PrusaSlicer 3.0 alpha)

- **Dlouhý text v poli *Vlastní struktura* rozbije vykreslení dialogu.** Po vložení velkého
  souboru (např. SDF se stovkami molekul) se dialog zobrazí jako změť bílých čar. Model se přesto
  vytvoří, ale vkládejte jen jednu molekulu: u SDF text od názvu po řádek `M  END`. Jde o chybu
  dialogu v PrusaSlicer, plugin ji obejít nemůže.
- **Popisky dialogu musí být jednořádkové.** Víceřádkový popisek rozbije vykreslení stejně.
- **Přejmenování položek menu pluginu za běhu může shodit PrusaSlicer** (po *Rescan plugins*
  zůstane v nativním menu na macOS stará položka). Po aktualizaci pluginu PrusaSlicer restartujte.
- **Chyby pluginů PrusaSlicer nezobrazuje**, jen je zapisuje do logu
  (`~/Library/Application Support/PrusaSlicer3/shared_runtime/log.txt`, u vývojového sestavení
  `PrusaSlicer3-dev`). Plugin proto chybu
  vypíše jako text na podložku.

---

# 3D Molecules – PrusaSlicer 3.0 plugin

A simplified, offline version of [3dmolekuly.vscht.cz](https://3dmolekuly.vscht.cz) inside
PrusaSlicer. It builds a multicolor, print-ready 3D model of a molecule.

> **The full version is on the web.** [3dmolekuly.vscht.cz](https://3dmolekuly.vscht.cz) adds
> PubChem search, PDB and CIF import, structure drawing, moving joints, spheres split for gluing
> and 3MF/STL export.

**Usage:** menu **3D molekuly · 3D Molecules → Create model (EN)**. Pick a molecule from the built-in library
(15 molecules with PubChem 3D conformers) or paste your own structure:

- **XYZ:** `element x y z` per line in Å, lines separated by `;`. Bonds are inferred from
  covalent radii.
- **MOL/SDF V2000 or V3000:** e.g. a PubChem *3D SDF*. Bond orders are kept; from a multi-record
  SDF only the first molecule is used. 2D files (all z = 0) give a flat model.

Model types (`Spheres`, `Ball-and-Stick`, `Sticks`), scale (mm per Å, default 10), size
factors and defaults match the web app. *Largest dimension* fits the longest side of the model
to the given length. With *Color by element* on, every element gets its own filament; to see
and print the colors, switch the printer to a multi-filament setup (e.g. *CORE One + MMU3* or
*INDX*). The plugin cannot add filaments or set their colors.

**Known issues (PrusaSlicer 3.0 alpha):** pasting a very long text (e.g. an SDF with hundreds of
molecules) into *Custom structure* breaks the dialog rendering, so paste one molecule only;
multi-line labels break it as well; plugin errors are only logged, so the plugin embosses them
onto the bed; restart PrusaSlicer after updating the plugin.

**Limitations:** the plugin runs in PrusaSlicer's sandbox with no network or file access, so it
cannot search PubChem; moving joints and spheres split for gluing are web-only; volumes cannot
be named after atoms with the current plugin API.

## Development

```
prusaslicer-plugin/
├── README.md                          this file (not shipped)
├── PUBLISHING.md                      how to publish to the Plugin Marketplace (not shipped)
└── cz.vscht.3dmolekuly.molecules/     the plugin bundle: everything in it ships
    ├── manifest.json
    ├── molecule_cs.lua, molecule_en.lua  menu entries: dialog labels per language
    ├── generator.lua                  model assembly and error messages (PrusaSlicer API)
    ├── chem.lua                       parsing, bond inference, geometry (pure Lua)
    └── library.lua                    built-in molecules, generated from PubChem 3D SDF
```

`chem.lua` has no PrusaSlicer dependencies, so the geometry can be tested with a plain
`lua` interpreter. The API reference is `src/slic3r-shared/src/Slic3r/App/Lua/ProjectApi.cpp`
in the [PrusaSlicer repository](https://github.com/prusa3d/PrusaSlicer).
