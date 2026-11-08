# Changelog

## 0.3.1

- Části modelu jsou v seznamu seřazené podle prvků (C, H, O, N…), každý prvek včetně svých
  polovin vazeb tvoří jeden blok v pořadí čísel filamentů.
- Nápověda k poli *Vlastní struktura* přímo v dialogu (formát XYZ s příkladem, MOL/SDF).
- Oprava: plugin se po aktualizaci na 0.3.0 neotevřel (generator.lua volal `require` při načítání).

## 0.3.0

- Anglická verze: položka menu *Create model (EN)* s popisky a názvy molekul podle anglického webu.
  Menu pluginu se jmenuje *3D molekuly · 3D Molecules*.
- Chybová hlášení (např. nerozpoznaná vlastní struktura) se zobrazí jako text na podložce.
  PrusaSlicer chyby pluginů jinak jen zapisuje do logu, takže to vypadalo, že se nic nestalo.
- Oprava: desetinné výchozí hodnoty (Násobící faktor vazby 0,4) mohly dorazit jako 0 a plugin
  skončil chybou. Nulové nebo chybějící faktory se teď nahradí výchozími hodnotami webu.

## 0.2.0

- Vícebarevný model i na tiskárně s jedním nástrojem: každý prvek dostane vlastní filament,
  nové nastavení *Počet filamentů*.
- Nové nastavení *Největší rozměr [mm]*: model se zvětší nebo zmenší na zadanou velikost.
- Násobné vazby zůstávají uvnitř atomů, aby se při tisku neoddělily.
- Názvy typů zobrazení a nastavení sjednocené s webem 3dmolekuly.vscht.cz.
- Oprava: celý model leží na podložce (první atom se dříve posunul nahoru).
- Výrazně menší projekt: koule a válce mají rozlišení podle velikosti.

## 0.1.0

- První verze: knihovna 15 molekul, vlastní struktura XYZ/MOL, typy Spheres, Ball-and-Stick
  a Sticks.
