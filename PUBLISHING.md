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
   (it is a placeholder `KubiV` for now).
2. **Plugin id.** It cannot be changed after the first release. The current
   `cz.vscht.3dmolekuly.molecules` requires proving ownership of the domain
   `3dmolekuly.vscht.cz` in the console under *Namespaces*. Without that,
   `io.github.<account>.molecules` can be used.
3. **Signing key.** Create an RSA key pair and register `public_key.pem` in the console under
   *Signing keys*. Never commit the private key (`.gitignore` already ignores `*.pem`).

   ```bash
   openssl genpkey -algorithm RSA -out private_key.pem -pkeyopt rsa_keygen_bits:2048
   openssl rsa -pubout -in private_key.pem -out public_key.pem
   ```

4. **Trusted publishing.** In the console, add the plugin id, `<owner>/<repo>`, the workflow
   `release.yml` and the environment `release`.
5. **`release` environment on GitHub.** Allow only `v*` tags, add yourself as a required
   reviewer and store the key there:

   ```bash
   gh secret set PRUSA_SLICER_PLUGIN_MARKETPLACE_SIGNING_KEY --env release < private_key.pem
   ```

6. **Workflow.** `.github/workflows/release.yml` (taken from the example repository) is already
   set up for the `cz.vscht.3dmolekuly.molecules` folder.

## Releasing a new version

Bump `version` in `manifest.json`, commit, and create a GitHub release whose tag is that
version:

```bash
gh release create v0.4.0 --title "3D Molecules 0.4.0" --notes-file CHANGELOG.md
```

A pre-release (`--prerelease`) goes to the beta channel. Every release is reviewed before it
becomes public.

## Catalogue texts

**Short description (manifest `description`):**

> Multicolor 3D-printable molecule models (Spheres, Ball-and-Stick, Sticks) from a built-in
> library or pasted XYZ/MOL data. Simplified offline version of 3dmolekuly.vscht.cz, where you
> will find PubChem/PDB/CIF search, structure drawing, moving joints and spheres split for gluing.

**Long description (author console):**

> Create a multicolor, print-ready 3D model of a molecule right in PrusaSlicer. Pick one of 15
> molecules (water, caffeine, aspirin, glucose…) or paste your own structure in XYZ or MOL/SDF
> format. Choose Spheres, Ball-and-Stick or Sticks with the same settings as the web app
> 3dmolekuly.vscht.cz (UCT Prague and the First Faculty of Medicine, Charles University). Every
> element gets its own filament, matched to its CPK color.
>
> The full version at **3dmolekuly.vscht.cz** also offers PubChem search, PDB and CIF import,
> structure drawing, moving joints and spheres split for gluing.

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
