-- V2000 SDF pasted into PrusaSlicer's single-line field: line breaks may be kept, dropped,
-- or replaced by spaces or separators. Fixture: adenosine (PubChem CID 60961, 3D).
package.path = arg[1] .. "/?.lua;" .. package.path
local chem = require('chem')
local f = io.open(arg[2]); local text = f:read("a"); f:close()
local fails = 0
local function check(c, m) if not c then fails = fails + 1; print("FAIL: " .. m) end end
local variants = {
    newlines = text,
    stripped = text:gsub("\r?\n", ""),
    crlf = text:gsub("\n", "\r\n"),
    spaces = text:gsub("\n", " "),
    semicolons = text:gsub("\n", ";"),
    molblock_only = text:match("^(.-M  END)"):gsub("\n", ""),
}
for label, t in pairs(variants) do
    local ok, mol = pcall(chem.parse, t)
    check(ok, label .. " parsed: " .. tostring(ok or (type(mol) == "table" and mol.key or mol)))
    if ok then
        check(#mol.atoms == 32, label .. " atoms " .. #mol.atoms)
        check(#mol.bonds == 34, label .. " bonds " .. #mol.bonds)
        local o = {} for _, a in ipairs(mol.atoms) do o[a[1]] = (o[a[1]] or 0) + 1 end
        check(o.C == 10 and o.H == 13 and o.N == 5 and o.O == 4, label .. " composition")
        local dbl = 0 for _, b in ipairs(mol.bonds) do if b[3] == 2 then dbl = dbl + 1 end end
        check(dbl == 4, label .. " double bonds " .. dbl)
        check(mol.bonds[1][1] == 1 and mol.bonds[1][2] == 11
            and mol.bonds[34][1] == 19 and mol.bonds[34][2] == 30, label .. " bond endpoints")
        check(mol.atoms[32][2] == -5.6254 and mol.atoms[32][4] == 0.4170, label .. " last atom")
    end
end
print(fails == 0 and "OK" or (fails .. " failures"))
