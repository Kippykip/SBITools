
# SBITools
SBITools v0.2 - http://kippykip.com

**Description:**
   This is a small set of conversion tools written in BlitzMax to reconstruct .SUB files using .SBI/.LSD files, and can even convert a full BIN/CUE/SBI emulator setup into a IMG/CCD/SUB setup which can be put into popular CD Burning programs such as CloneCD.
   This way, LibCrypt protected games dumped in other formats can still be burned as 1:1 copies on a real Sony PlayStation console again with the LibCrypt changes fully intact.
   **These tools are only intended for intended for PlayStation images, there's no telling how these tools would react to standard Mode 1 PC disc images.**

**Requirements:**
   psxt001z, to be in the same directory as SBITools
   It can be downloaded from: http://redump.org/download/psxt001z-0.21b1.7z
   Source Code: https://github.com/Dremora/psxt001z
   It's pre-included in the "Releases" section for SBITools
   https://github.com/Kippykip/SBITools/releases

**Arguments:**
> SBITools.exe -sbi cuefile subchannel.sbi
> SBITools.exe -lsd cuefile subchannel.lsd
> SBITools.exe -cue2ccd cuefile

**Argument Definitions:**

    -sbi: Patches an images subchannel with a .SBI file.
    -lsd: Patches an images subchannel with a .LSD file.
	    Both -sbi and -lsd export the patched .SUB file to:
	    \SUB\GAMENAME\GAMENAME.SUB
    -cue2ccd: Converts a 'BIN/CUE/SBI|LSD' setup into a 'IMG/CCD/CUE/SUB' setup.
	    This makes burning LibCrypt games easily possible with software such
	    as CloneCD"
	    It exports the converted files to the "\CCD\GAMENAME\" directory

**Notes:** 
   It's ***very important*** to note, SBI files do not contain the CRC16 bytes, which is needed for certain games such as V-Rally 2: Championship Edition, MediEvil and most likely a few others. Most LibCrypt games I've tested don't check for this though.  
   
   Regardless, SBITools v0.2 now partially reconstructs the CRC16 using a XOR of $0080 although it's not a perfect reconstruction for the whole SubChannel in anyway (as that's impossible). 
   Until I find a way to recreate it enough to be playable, some games may not work (I know MediEvil is one of them!)  I obviously can't test every game to see if it passes LibCrypt, so in the meantime if you're a purist like me, definitely go for .LSD files instead. They're the superior format (and I'm not sure why they weren't the standard instead of .SBI)
They can be easily found on http://redump.org/disc/DISCID#/lsd

   Remember to ***ALWAYS*** test games converted with the **-cue2ccd** function on an emulator before you burn! I personally recommend using BizHawk (which uses Mednafen) and opening the converted game from the .CCD file. 
   Do ***NOT*** run the game in BizHawk from the .CUE file! The LibCrypt copy protection will kick in if you do that!
   
**Upcoming**
 - Add a -**cdd2cue** function to reverse the process, just in case.
 - Add support for image files that have the tracks seperated (Such as "CoolGame (Track 1).bin, CoolGame (Track 2).bin, CoolGame (Track 3).bin") etc.
 - Maybe even remove the need for psxt001z too as it's only used for
   generating blank .SUB subchannel, although it is a very useful tool to have in combination with SBITools.
 - Add a .LSD to .SBI converter, maybe the inverse too if I find a way to perfectly recreate it.
 - Add full XOR support for SBI CRC16 recreation.

**Version History**

    Version 0.2
	    - .SUB patch functions now also add the CD Audio track data to the subchannel. 
		  Although this change now requires you to specify a .CUE file instead of a Binary 
		  file for -SBI and -LSD functions. SUB files are now exported to the \SUB directory
		  in these functions too.
		- The -SBI function now recreates some of the CRC16 bytes required for handful of games,
		  although still not 100% compatible.
		- Command line functions are no longer case sensitive. (oops)
		- Added -cue2ccd, which allows you to do a full burnable conversion.
    Version 0.1
	    - Initial release
# SBI File Format Specifications

    *HEADER*
    [4 BYTES] SUB\0
    
    *CONTINUOUS*
    [1 BYTE] Minutes (In HEX -> Text)
    [1 BYTE] Seconds (In HEX -> Text)
    [1 BYTE] Frames (In HEX -> Text)
    [1 BYTE] Dummy byte, always a 01 (according to psxt001z source)
    [10 BYTES] QSUB Data
    
    Example:
    S   B   I   NUL MIN SEC FRA DUM [              QSUB                  ]
    53  42  49  00  03  08  05  01  41  01  01  07  06  05  00  23  08  05
I'm unsure why they didn't include the modified CRC16 bytes in SBI, as it's extremely important.
# LSD File Format Specifications

    *CONTINUOUS*
    [1 BYTE] Minutes (In HEX -> Text)
    [1 BYTE] Seconds (In HEX -> Text)
    [1 BYTE] Frames (In HEX -> Text)
    [10 BYTES] QSUB Data
    [2 BYTES] CRC-16
    
    Example:
    MIN SEC FRA [                 QSUB               ]  [CRC16]
    03  08  05  41  01  01  07  06  05  00  23  08  05  38  39
    
# LibCrypt failed check, causes and effects
Here's a list of what LibCrypt'ed games will do to the player when it realises the SubChannel data isn't correct. Obviously these aren't all the LibCrypted games (check on Redump.org for that), these are just games I've personally tested and some I've been told about.
Look out for these effects when testing games modified with SBITools on an accurate PSX emulator such as BizHawk. *(Run from .CCD)*

**Ape Escape (PAL)**
Main menu navigation will be completely disabled, making you unable to start the game.
**Crash Team Racing (PAL)**
Game will hang once at the end of the loading screen (for the level itself).
**Crash Team Racing (PAL)**
Game will hang once at the end of the loading screen (for the level itself).
**Legacy of Kain: Soul Reaver (PAL)** 
The game will hang when you're introduced with the combat tutorial when the camera pans to show the enemies.
**Lucky Luke: Western Fever (PAL)** 
The game stops when you get to the Mexican guy blocking the bridge, he just won't move from there, ever. Even when you complete the quest.
**MediEvil (PAL)**
Will have a disc error icon upon loading The Hilltop Mausoleum. Interesting to note this was actually the *FIRST* game to use LibCrypt.
 **MediEvil 2** - Will also have the same disc error icon as above, except upon loading Kensington.
**PGA European Tour Golf (PAL)**
In the third hole of the first tournament or by selecting some holes, the game will get stuck in "demo" mode (and will not you play anything).
**Resident Evil 3: Nemesis (PAL)**
Will hang at the "Game contains violence and gore" screen.
**Spyro 3: Year of the Dragon**
Interesting case for this one, the game will eventually randomly delete eggs, reset progress with unlocked characters, remove sheep in boss battles, change the language and even tell you off for playing a "hacked copy" + more.
Interesting to note that the game also detected early LibCrypt knockout PPF patches back when the game was first released as it had checksum checks throughout the game, which caused the same effects above.
**This is Football (PAL)**
Hangs on the loading screen going ingame.
**V-Rally: Championship Edition 2 (PAL)**
The game will endlessly load on the heartbeat loading screen (with no disc activity).
**Wip3out (PAL)**
The game will freeze when passing the finish line.
# CloneCD LibCrypt Ripping guide
TODO
# CloneCD LibCrypt Burning guide
TODO