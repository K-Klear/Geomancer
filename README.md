# Geomancer

This is tool for generating volumes for use in the Pistol Mix editor from .png images. Currently it can create vertical slices of geo out of volumes, with more functions coming in later versions.

---

## How to use

Place one or more .png images into the "input" folder. They need to be exactly 167 x 166. Black and white works best. Each pixel represents the smallest geo unit available in Pistol Mix. The images need to be named according to the Z level where you want the volumes to appear. The tool currently looks for images named from -16 to 3600. Any other files will be ignored. The tool comes with a few test images, so take a look at those if you're not sure how to format yours.

Click the "Load images" button to get started. A preview will show, with a pink/green graphic representing the small walkway and no-geo corridor around the player. You can adjust range of how much of the image is generated as volumes, offset the results. You can also adjust the Z scale of the generated volumes (Depth) and the processing order. By default (1500) they will block the player's path if they cross it, so keep that in mind.

The radio buttons "white" and "alpha" can be used to switch between brightness and alpha values in the image detemining whether a pixel is geo or empty, though the alpha setting is currently not shown on the image preview. Also note that the "white" mode currently only reads the r value of the pixel, so colour pictures can have messy results.

In the top right corner you can choose to generate additive, subtractive or both types of volumes or invert the picture.

When you're ready, press the Create volumes button.  This will generate (or overwrite) two files in the "output" folder:

- volume_data.txt contains the new volumes only. You can manually insert them into an existing map. Note that each volume has a groupIndex value which is used by PM to group them together. Geomancer will group the volumes created from each image together starting from 1 and incrementing by one. The map will refuse to load if the indices don't start from 1 and have any gaps in them, so keep that in mind. You may need to adjust these if you're merging this data into a map already containing other volumes.

do_not_ship.pw_meta is a hopefully fully functional file which you can just copy into any map's zip and it will have the newly generated volumes. This will also erase any existing information about world sections, pre-existing volumes, decor groups and maybe more, so you probably don't want to use this outside of a brand new map.

Once you have the generated data in a Pistol Whip map, load it in Pistol Mix and if it opens, the new volumes should be present. Generate geo and hopefully it will end up looking like the base images.

---

This tool is provided as is. Use at your own risk, though there isn't any, really. If you need help, shoot me a message and I might help you out, but keep in mind the tool is still very early in development, so issues are expected.

Made with Defold, using extensions by Björn Ritzl.

---

This project is licensed under the terms of the
DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, version 3,
as published by theiostream on March 2012, as it follows:

0. You just DO WHAT THE FUCK YOU WANT TO.