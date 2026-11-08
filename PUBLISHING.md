# Publishing to the Plugin Marketplace

The Prusa Plugin Marketplace is in beta. Plugins are published from GitHub with the action
[prusa3d/plugin-marketplace-publish](https://github.com/prusa3d/plugin-marketplace-publish);
the template is the repository [prusa3d/plugin-marketplace-example](https://github.com/prusa3d/plugin-marketplace-example).

The name, description and links (`web`, `repo`) in the catalogue are taken from `manifest.json`
on the first release. Later they are changed in the author console, where every edit is
moderated. The changelog comes from the GitHub release notes.

## Before the first release

1. **Author profile.** Sign in to [plugin-marketplace.prusa3d.com](https://plugin-marketplace.prusa3d.com)
   and become an author. Put the author id from *Profile* into `manifest.json` as `author`
   (already set).
2. **Plugin id.** It cannot be changed after the first release. The id is
   `io.github.molekuly3d.molecules`: the namespace `io.github.<repository owner>` needs no
   verification, but only GitHub Actions in a repository owned by `molekuly3d` can publish it
   (trusted publishing, step 4). A domain id such as `cz.vscht.…` would need the domain proven
   under *Namespaces*. No part of the id may start with a digit: PrusaSlicer rejects
   `cz.vscht.3dmolekuly.…` and `io.github.3d-molekuly.…` as "not in reverse DNS form", which is
   why the GitHub organization was renamed from `3D-Molekuly` to `molekuly3d`.
3. **Signing key.** Create an RSA key pair and register `public_key.pem` in the console under
   *Signing keys*. Never commit the private key (`.gitignore` already ignores `*.pem`).

   ```bash
   openssl genpkey -algorithm RSA -out private_key.pem -pkeyopt rsa_keygen_bits:2048
   openssl rsa -pubout -in private_key.pem -out public_key.pem
   ```

4. **Trusted publishing.** In the console under *Trusted publishing*, add:
   - Plugin id: `io.github.molekuly3d.molecules`
   - GitHub repository: `molekuly3d/3d-molekuly-prusaslicer-plugin`
   - Workflow file: `release.yml`
   - Environment: `release`
5. **`release` environment on GitHub.** Allow only `v*` tags, add yourself as a required
   reviewer and store the key there:

   ```bash
   gh secret set PRUSA_SLICER_PLUGIN_MARKETPLACE_SIGNING_KEY --env release < private_key.pem
   ```

6. **Workflow.** `.github/workflows/release.yml` (taken from the example repository) is already
   set up for the `io.github.molekuly3d.molecules` folder.

## Releasing a new version

Bump `version` in `manifest.json`, commit, and create a GitHub release whose tag is that
version:

```bash
gh release create v0.4.0 --title "3D Molecules 0.4.0" --notes-file CHANGELOG.md
```

A pre-release (`--prerelease`) goes to the beta channel. Every release is reviewed before it
becomes public.

## Uploading a bundle manually

Only for ids in a namespace verified under *Namespaces*. An `io.github.*` id such as this
plugin's can only be published from GitHub Actions (the console rejects a manual upload with
"outside your namespaces"), so use a GitHub release instead.

The console's *Publish* page accepts a signed zip with `manifest.json`, `manifest.txt` and
`manifest.sig` at its root (flat layout, no folder inside). A plain zip of the plugin folder or of
the repository is rejected with "bundle is missing manifest.json at its root". PrusaSlicer's CLI
builds a correct one:

```bash
PrusaSlicer plugin sign -P /path/to/private_key.pem io.github.molekuly3d.molecules
```

On macOS the binary is `/Applications/PrusaSlicer-<version>.app/Contents/MacOS/PrusaSlicer`. The
command writes `manifest.txt` and `manifest.sig` into the folder and `io.github.molekuly3d.molecules.zip`
next to it; upload that zip. Both are ignored by `.gitignore`, so delete them or leave them
untracked. The key used must be registered under *Signing keys*.

## Catalogue texts

Ready to paste into the author console. The name, short description and links are taken from
`manifest.json` on the first release.

**Name (manifest `name`):**

> 3D Molecules

**Short description (manifest `description`):**

> Multicolor 3D-printable molecule models (Spheres, Ball-and-Stick, Sticks) from a built-in
> library or pasted XYZ/MOL data. Simplified offline version of 3dmolekuly.vscht.cz, where you
> will find PubChem/PDB/CIF search, structure drawing, moving joints and spheres split for gluing.

**Long description (author console):**

> **Print molecules in color, straight from PrusaSlicer.**
>
> 3D Molecules builds a print-ready model of a molecule on your bed in a few clicks. Every
> element gets its own filament, matched to its CPK color: oxygen goes to your red filament,
> nitrogen to blue, hydrogen to white. Ideal for chemistry and biology classes, open days and
> anyone who wants to hold a molecule in their hand.
>
> **What you get**
>
> - 15 ready-made molecules with real 3D geometry from PubChem: water, methane, ammonia, carbon
>   dioxide, ethene, ethyne, ethanol, acetic acid, sulfuric acid, cyclohexane, benzene, glucose,
>   paracetamol, aspirin and caffeine.
> - Your own structures: paste XYZ coordinates or a MOL/SDF file (V2000 or V3000), e.g. a 3D SDF
>   downloaded from PubChem.
> - Three model types: Spheres (space-filling), Ball-and-Stick with double and triple bonds,
>   and Sticks.
> - Scale in mm per ångström or a target size in mm, atom and bond thickness, hydrogens on or
>   off, and a flattened bottom for better bed adhesion.
> - Multicolor out of the box on MMU3, INDX and XL multi-tool printers; set up your filaments
>   first and the plugin picks the closest color for each element.
> - Czech and English menu entries.
>
> **Want more?** The full web app at **3dmolekuly.vscht.cz** also searches PubChem, PDB and the
> Crystallography Open Database, imports PDB and CIF files, lets you draw a structure, and
> creates print-in-place moving joints and spheres split for gluing.
>
> Made by the 3D Molecules team at UCT Prague and the First Faculty of Medicine, Charles
> University.

**Category:** Education

**Tags / keywords (if the console asks for them):** chemistry, molecule, education, science,
multicolor, MMU, ball-and-stick, CPK, PubChem

**Screenshot captions:**

1. *Caffeine as a Ball-and-Stick model, colored by element on a five-tool Prusa XL.*
2. *The plugin dialog: pick a molecule, model type, scale and filament assignment.*
3. *Paste your own structure in XYZ or MOL/SDF format.*
4. *Space-filling (Spheres) and Sticks models of the same molecule.*

**Release notes for the first release (v0.4.0):**

> First public release of 3D Molecules for PrusaSlicer 3.0.
>
> - Built-in library of 15 molecules with PubChem 3D geometry.
> - Custom structures in XYZ and MOL/SDF (V2000 and V3000).
> - Spheres, Ball-and-Stick and Sticks models with the same settings as 3dmolekuly.vscht.cz.
> - Multicolor: elements are matched to your filaments by CPK color.
> - Czech and English menu entries.
>
> Known issues in PrusaSlicer 3.0 alpha: pasting a very long text into *Custom structure* breaks
> the dialog rendering, so paste one molecule at a time; restart PrusaSlicer after updating the
> plugin.

**Long description in Czech (if the console allows localized texts):**

> Vytvořte vícebarevný 3D model molekuly k tisku přímo v PrusaSlicer. Vyberte jednu z 15
> molekul (voda, kofein, aspirin, glukóza…) nebo vložte vlastní strukturu ve formátu XYZ či
> MOL/SDF. Na výběr jsou modely Spheres, Ball-and-Stick a Sticks se stejným nastavením jako ve
> webové aplikaci 3dmolekuly.vscht.cz (VŠCHT Praha a 1. LF UK). Každý prvek dostane vlastní
> filament podle své CPK barvy.
>
> Plná verze na **3dmolekuly.vscht.cz** umí navíc vyhledávání v PubChem, import PDB a CIF,
> kreslení vzorců, otočné klouby a koule pro lepení.

**Category:** Education
