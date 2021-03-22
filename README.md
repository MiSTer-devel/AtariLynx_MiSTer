# [Atari Lynx](https://en.wikipedia.org/wiki/Atari_Lynx) for [MiSTer Platform](https://github.com/MiSTer-devel/Main_MiSTer/wiki)


# HW Requirements
SDRam module of any size is required

# Bootrom
You need to add the Bootrom file(often called lynxboot.img) to the AtariLynx Folder and name it: boot.rom

Checksum for valid Bootrom:

SHA-1:
E4ED47FAE31693E016B081C6BDA48DA5B70D7CCB

MD5:
FCD403DB69F54290B51035D82F835E7B

# Status
All official games should be playable.
Most Homebrew works.

# Features
- Savestates
- FastForward - speed up game by factor 4, hold button or tap Button to toggle
- CPU GPU Turbo - give games additional computation power
- Rewind: go back up to 80 seconds in time
- Orientation: rotate video by 90 or 270 degree
- 240p mode: doubled resolution, mainly for CRT output

# Rotation
Lynx has built in rotation, supported by most games, using the Joypad Keys "Option2" + "Pause"

# Savestates
Core provides 4 slots to save the state. The first slot gets saved to disk and automatically loaded (but not applied)
upon next load of game. Rest 3 slots are residing only in memory for temporary use.
First slot save/restore is available from OSD as well. 

Hotkeys for save states:
- Alt-F1..F4 - save the state
- F1...F4 - restore

# Rewind
To use rewind, turn on the OSD Option "Rewind Capture" and map the rewind button.
You may have to restart the game for the function to work properly.
Attention: Rewind capture will slow down your game by about 0.5% and may lead to light audio stutter.
Rewind capture is not compatible to "Pause when OSD is open", so pause is disabled when Rewind capture is on.

# Missing features
Comlynx/UART only implemented for Interrupts
Custom external EEPROM not supported(not used in official games, only homebrew)