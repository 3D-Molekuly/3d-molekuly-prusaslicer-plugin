import sys, pathlib
src = pathlib.Path(sys.argv[1]); out = pathlib.Path(sys.argv[2])
names = [("water","Voda (H₂O)","Water (H₂O)"),("methane","Methan (CH₄)","Methane (CH₄)"),("ammonia","Amoniak (NH₃)","Ammonia (NH₃)"),
 ("carbon_dioxide","Oxid uhličitý (CO₂)","Carbon dioxide (CO₂)"),("ethylene","Ethen (C₂H₄)","Ethene (C₂H₄)"),("acetylene","Ethyn (C₂H₂)","Ethyne (C₂H₂)"),
 ("ethanol","Ethanol","Ethanol"),("acetic_acid","Kyselina octová","Acetic acid"),("sulfuric_acid","Kyselina sírová","Sulfuric acid"),
 ("cyclohexane","Cyklohexan","Cyclohexane"),("benzene","Benzen","Benzene"),("glucose","Glukóza","Glucose"),
 ("paracetamol","Paracetamol","Paracetamol"),("aspirin","Aspirin","Aspirin"),("caffeine","Kofein","Caffeine")]
L = ["-- Generated from PubChem 3D conformers (pubchem.ncbi.nlm.nih.gov).",
     "-- name: Czech, name_en: English (keep in sync with the menus in molecule_cs.lua and molecule_en.lua).",
     "-- atoms: {element, x, y, z} in Å; bonds: {atom index, atom index, order}.","","return {"]
for key, label, label_en in names:
    lines = (src / f"{key}.sdf").read_text().splitlines()
    na, nb = int(lines[3][0:3]), int(lines[3][3:6])
    atoms = [(l[31:34].strip(), float(l[0:10]), float(l[10:20]), float(l[20:30])) for l in lines[4:4+na]]
    bonds = [(int(l[0:3]), int(l[3:6]), int(l[6:9])) for l in lines[4+na:4+na+nb]]
    L.append(f'    {{\n        name = "{label}",\n        name_en = "{label_en}",')
    L.append("        atoms = {" + ", ".join(f'{{"{e}",{x:.4f},{y:.4f},{z:.4f}}}' for e,x,y,z in atoms) + "},")
    L.append("        bonds = {" + ", ".join(f"{{{a},{b},{o}}}" for a,b,o in bonds) + "}\n    },")
L.append("}")
out.write_text("\n".join(L) + "\n")
