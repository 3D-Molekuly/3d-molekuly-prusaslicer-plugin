# Changelog

## 0.4.0

- Filaments are assigned by **CPK color**: the plugin reads the filament colors of the printer
  and gives each element the filament with the closest color (O red, N blue, H white…). New
  setting *Filament assignment*: *Closest CPK color* (default) or *In order (C, H, O, N…)*.
  When the colors cannot be read, the order is used.

## 0.3.2

- *Custom structure* also reads MOL/SDF **V3000** (e.g. a DataWarrior export). From a file with
  several molecules the first one is used. It also works when the field drops line breaks on
  paste.
- Fix: the multi-line label of the *Custom structure* field broke the dialog rendering. The hint
  is now a short single line.

## 0.3.1

- Volumes in the object list are sorted by element (C, H, O, N…): each element, including its
  bond halves, forms one block in filament order.
- Hint for the *Custom structure* field right in the dialog (XYZ format with an example,
  MOL/SDF).
- Fix: the plugin did not open after updating to 0.3.0 (`generator.lua` called `require` while
  being loaded).

## 0.3.0

- English version: the menu entry *Create model (EN)* with labels and molecule names taken from
  the English web app. The plugin menu is called *3D molekuly · 3D Molecules*.
- Error messages (e.g. an unrecognized custom structure) are shown as text on the bed.
  PrusaSlicer only writes plugin errors to the log, so it looked as if nothing happened.
- Fix: decimal defaults (*Bond Diameter Factor* 0.4) could arrive as 0 and the plugin failed.
  Zero or missing factors are now replaced with the web app's defaults.

## 0.2.0

- Multicolor model even on a single-tool printer: every element gets its own filament, new
  setting *Number of filaments*.
- New setting *Largest dimension [mm]*: the model is scaled to the given size.
- Multiple bonds stay inside the atoms so they do not come apart when printed.
- Model type and setting names aligned with the web app 3dmolekuly.vscht.cz.
- Fix: the whole model sits on the bed (the first atom used to be shifted up).
- Much smaller projects: spheres and cylinders get a resolution based on their size.

## 0.1.0

- First version: library of 15 molecules, custom XYZ/MOL structure, Spheres, Ball-and-Stick and
  Sticks model types.
