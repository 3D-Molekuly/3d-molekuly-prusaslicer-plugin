# Vydání v Plugin Marketplace

Prusa Plugin Marketplace je v betě. Plugin se vydává z GitHubu přes akci
[prusa3d/plugin-marketplace-publish](https://github.com/prusa3d/plugin-marketplace-publish),
vzorem je repozitář [prusa3d/plugin-marketplace-example](https://github.com/prusa3d/plugin-marketplace-example).

Název, popis a odkazy (`web`, `repo`) v katalogu se při prvním vydání převezmou z
`manifest.json`. Později se mění v autorské konzoli, kde každou změnu schvaluje moderátor.
Changelog tvoří poznámky k vydání na GitHubu.

## Před prvním vydáním

1. **Autorský profil.** Přihlaste se na [plugin-marketplace.prusa3d.com](https://plugin-marketplace.prusa3d.com)
   a staňte se autorem. ID autora z *Profile* zapište do `manifest.json` jako `author`
   (teď je tam provizorně `KubiV`).
2. **ID pluginu.** Po prvním vydání se už nedá změnit. Současné
   `cz.vscht.3dmolekuly.molecules` vyžaduje ověřit vlastnictví domény `3dmolekuly.vscht.cz` v
   konzoli pod *Namespaces*. Bez ověření jde použít `io.github.<účet>.molecules`.
3. **Podpisový klíč.** Vytvořte pár RSA klíčů a `public_key.pem` zaregistrujte v konzoli pod
   *Signing keys*. Soukromý klíč nikdy necommitujte.

   ```bash
   openssl genpkey -algorithm RSA -out private_key.pem -pkeyopt rsa_keygen_bits:2048
   openssl rsa -pubout -in private_key.pem -out public_key.pem
   ```

4. **Trusted publishing.** V konzoli přidejte ID pluginu, `<owner>/<repo>`, workflow
   `release.yml` a prostředí `release`.
5. **Prostředí `release` na GitHubu.** Povolte jen tagy `v*`, nastavte se jako povinného
   schvalovatele a uložte klíč:

   ```bash
   gh secret set PRUSA_SLICER_PLUGIN_MARKETPLACE_SIGNING_KEY --env release < private_key.pem
   ```

6. **Workflow.** Zkopírujte `.github/workflows/release.yml` z ukázkového repozitáře a nastavte
   `path: prusaslicer-plugin/cz.vscht.3dmolekuly.molecules`.

## Vydání nové verze

Zvyšte `version` v `manifest.json`, commitněte a vytvořte GitHub release s tagem stejné verze:

```bash
gh release create v0.2.0 --title "3D molekuly 0.2.0" --notes-file prusaslicer-plugin/CHANGELOG.md
```

Předběžná verze (`--prerelease`) jde do beta kanálu. Každé vydání před zveřejněním projde
kontrolou.

## Texty pro katalog

**Krátký popis (manifest `description`):**

> Multicolor 3D-printable molecule models (Spheres, Ball-and-Stick, Sticks) from a built-in
> library or pasted XYZ/MOL data. Simplified offline version of 3dmolekuly.vscht.cz, where you
> will find PubChem/PDB/CIF search, structure drawing, moving joints and spheres split for gluing.

**Delší popis (autorská konzole):**

> Vytvořte vícebarevný 3D model molekuly k tisku přímo v PrusaSlicer. Vyberte jednu z 15
> molekul (voda, kofein, aspirin, glukóza…) nebo vložte vlastní strukturu ve formátu XYZ či
> MOL/SDF. Na výběr jsou modely Spheres, Ball-and-Stick a Sticks se stejným nastavením jako ve
> webové aplikaci 3dmolekuly.vscht.cz (VŠCHT Praha a 1. LF UK). Každý prvek dostane vlastní
> filament.
>
> Plná verze na **3dmolekuly.vscht.cz** umí navíc vyhledávání v PubChem, import PDB a CIF,
> kreslení vzorců, otočné klouby a koule pro lepení.

**Kategorie:** Education
