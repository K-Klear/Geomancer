# Geomancer

This is tool originally made for generating volumes for use in the Pistol Mix editor from .png images, but the focus has shifted to make other changes to the map files easier. More functions are coming in later versions.

---

## How to use

There are various tabs representing the data found in the map zip. They will become available as you import relevant files. Note that the Sequences tab never becomes active as I'm not currently aware of any useful edits to this file, but I put it there in case of future developments.

### Import / Export

Import a Pistol Mix zip file, a directory containing extracted files or specific files one-by-one. After making changes in other tabs, you can export them from here. Geomancer will create a new folder and place the modified files there. You have to add them to a map file manually afterwards.

### Level info

This lets you set any enemy, obstacle and materials sets, switch the map to stationary and set preview time. It icludes choices not available in the official editor.

### Events, BPM

Add or modify no-beat sections, event triggers and tempo sections. Note that one tempo section will always be present, representing the BPM set in Pistol Mix. Values outside of the range of the map can break BPM. Geomancer will try to limit values to song length if level.pw is loaded.

### Models

Set models to any of the known working materials, sort them and set them to dynamic if needed. Note that the file will refuse to load if previously modified to include dynamic objects. This will be fixed in a later release.

### Enemies

This tab lets you change all instances of an enemy type to a different one. For example, if you want to have Fyling Skulls in your level, use an enemy type that is not present in the level otherwise (say, Mounted Enemy) and then replace them all from here. If your map has all enemy types, you'll have to do the replacement manually.

### Geo / collisions

This lets you replace either the visual or collision data of geo in your map for that from a different map. Useful for invisible walls.

### Volumes

Currently the only function is to create geo "slices" from PNG files. Create one or more png files with dimensions exactly 167 x 166, name each with a number representing the Z position you want the geo slice to appear and place them in a folder. From there you can import them using the Load images button.

A preview will show, with a pink/green graphic representing the small walkway and no-geo corridor around the player. You can adjust range of how much of the image is generated as volumes. You can also adjust the Z scale of the generated volumes (Depth) and the processing order. By default (1500) they will block the player's path if they cross it, so keep that in mind.

The radio buttons "white" and "alpha" can be used to switch between brightness and alpha values in the image detemining whether a pixel is geo or empty, though the alpha setting is currently not shown on the image preview. Also note that the "white" mode currently only reads the r value of the pixel, so colour pictures can have messy results.

In the top right corner you can choose to generate additive, subtractive or both types of volumes or invert the picture.

When you're ready, press the Create volumes button. This will generate the volume data, but you still need to export it in the Import/export tab. The volumes will be added to the loaded do_not_ship.pw_meta file and exported as such. You will need to open the map in Pistol Mix and generate geo for this to have any effect. Note that many of the other changes possible in geomacer (notably setting models as dynamic, messing around with tempo sections or adding extra enemy types) can render the map impossible to open, so you'll want to generate this volume data separately in case you want to do other changes.

---

This tool is provided as is. Use at your own risk, though there isn't any, really. If you need help, shoot me a message and I might help you out, but keep in mind the tool is still very early in development, so issues are expected.

Made with Defold, using extensions by Björn Ritzl, Sven Andersson and Sergey Lerg. 

---

This project is licensed under the terms of the
DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, version 3,
as published by theiostream on March 2012, as it follows:

0. You just DO WHAT THE FUCK YOU WANT TO.