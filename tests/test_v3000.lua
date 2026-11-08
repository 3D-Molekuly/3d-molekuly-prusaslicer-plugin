package.path = arg[1] .. "/?.lua;" .. package.path
local chem = require('chem')
local f = io.open(arg[2]); local text = f:read("a"); f:close()
local fails = 0
local function check(c, m) if not c then fails = fails + 1; print("FAIL: " .. m) end end
for label, t in pairs({ newlines = text, stripped = text:gsub("\r?\n", ""), crlf = text:gsub("\n", "\r\n"), spaces = text:gsub("\n", " ") }) do
    local ok, mol = pcall(chem.parse, t)
    check(ok, label .. " parsed: " .. tostring(ok or (type(mol) == "table" and mol.key or mol)))
    if ok then
        check(#mol.atoms == 21, label .. " atoms " .. #mol.atoms)
        check(#mol.bonds == 23, label .. " bonds " .. #mol.bonds)
        local o = {} for _, a in ipairs(mol.atoms) do o[a[1]] = (o[a[1]] or 0) + 1 end
        check(o.C == 16 and o.O == 5, label .. " composition C" .. tostring(o.C) .. " O" .. tostring(o.O))
        local dbl = 0 for _, b in ipairs(mol.bonds) do if b[3] == 2 then dbl = dbl + 1 end end
        check(dbl == 8, label .. " double bonds " .. dbl)
        check(mol.bonds[1][1] == 1 and mol.bonds[1][2] == 2 and mol.bonds[23][1] == 18, label .. " bond endpoints")
    end
end
-- Garbage inside V30 block raises a localized error
local ok, err = pcall(chem.parse, "M  V30 BEGIN ATOM M  V30 1 O x y z M  V30 END ATOM")
check(not ok and type(err) == "table" and err.key == "mol_atom", "bad atom line -> mol_atom")
print(fails == 0 and "OK" or (fails .. " failures"))
