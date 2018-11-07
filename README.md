


# SBITools
SBITools v0.3 - http://kippykip.com

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

>SBITools.exe -cue2ccd cuefile.cue

>SBITools.exe -lsd2sub cuefile.cue subchannel.lsd

>SBITools.exe -lsd2sbi subchannel.lsd

>SBITools.exe -sbi2sub cuefile.cue subchannel.sbi

>SBITools.exe -sbi2lsd subchannel.sbi

>SBITools.exe -singletrack cuefile
		
		
**Argument Definitions:**



	-cue2ccd: Converts a 'BIN/CUE/SBI|LSD' setup into a 'IMG/CCD/CUE/SUB' setup.
	    This makes burning LibCrypt games easily possible with software such
	    as CloneCD. SBI/LSD files are loaded from the same directory as the .CUE
	    file under the same name.
	-lsd2sub: Creates a patched .SUB subchannel with a .LSD file.
	-lsd2sbi: Converts a .SBI subchannel patch to a .LSD subchannel patch.
	-sbi2sub: Creates a patched .SUB subchannel with a .SBI file.
	-sbi2lsd: Converts a .SBI subchannel patch to a .LSD subchannel patch.
	    NOTE: This cannot perfectly reconstruct the missing CRC16 bytes!
	-singletrack: Converts a seperate track BIN/CUE setup into a single track BIN/CUE setup.

**Notes:** 
.SBI files do not actually contain the **CRC16** needed for some LibCrypt games, however since SBITools v0.2.1, the conversion functions recreate a CRC16 the same way **Mednafen** does by making a false CRC16 hash with "bitwise exclusive or", as LibCrypt only checks if it's the wrong hash in order to start the game. 
Every LibCrypt game I own that I've tested now works fine with SBITool's SBI functions.

While this is enough to start a LibCrypt game, if you're a purist like me and want the original CRC16 bytes anyway, definitely go for .LSD files instead. They're the superior format (and I'm not sure why they weren't the standard instead of .SBI)
They can be found on http://redump.org/disc/DISCID#/lsd
I've bundled them all on the [releases page](https://github.com/Kippykip/SBITools/releases) and in the repository.

   Remember to ***ALWAYS*** test games converted with the **-cue2ccd** function on an emulator before you burn! I personally recommend using BizHawk (which uses Mednafen) and opening the converted game from the .CCD file. 
   Do ***NOT*** run the game in BizHawk from a .CUE file! The LibCrypt copy protection will kick in if you do that!
   
**Upcoming**
 - Add a -**cdd2cue** function to reverse the process, just in case.
 - Maybe even remove the need for psxt001z too as it's only used for
   generating blank .SUB subchannels, although it is a very useful tool to have in combination with SBITools.

**Version History**

    Version 0.3
        - BIN/CUE setups with seperated tracks are now fully supported!
        - Renamed -SBI & -LSD to -SBI2SUB & -LSD2SUB
        - Added -singletrack conversion command, -CUE2CCD uses this automatically if necessary.
        - Added drag and drop .BAT files for -SINGLETRACK and -CUE2CCD, since they will be used the most.
        - Added -SBI2LSD and -LSD2SBI conversion functions
        - -SBI2SUB & -LSD2SUB no longer export in subfolders (since it only exports 1 file anyways.)
        - SBITools now includes all known LibCrypt LSD patches in the "LSD Patches" directory
    Version 0.2.1
        - SBI Patching functions were modified to now work with every game.
        - Cleaned up a tiny bit of code in CRC16.bmx
    Version 0.2
        - .SUB patch functions now also add the CD Audio track data to the subchannel. 
          Although this change now requires you to specify a .CUE file instead of a Binary file for -SBI and -LSD functions. SUB files are now exported to the \SUB directory
          in these functions too.
        - The -SBI function now recreates some of the CRC16 bytes required for handful of games,
          although still not 100% compatible.
        - Command line functions are no longer case sensitive. (oops)
        - Added -cue2ccd, which allows you to do a full burnable conversion.
    Version 0.1
        - Initial release
## SBI File Format Specifications

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
## LSD File Format Specifications

    *CONTINUOUS*
    [1 BYTE] Minutes (In HEX -> Text)
    [1 BYTE] Seconds (In HEX -> Text)
    [1 BYTE] Frames (In HEX -> Text)
    [10 BYTES] QSUB Data
    [2 BYTES] CRC-16
    
    Example:
    MIN SEC FRA [                 QSUB               ]  [CRC16]
    03  08  05  41  01  01  07  06  05  00  23  08  05  38  39
    
## LibCrypt failed check, causes and effects
Here's a list of what LibCrypt'ed games will do to the player when it realises the SubChannel data isn't correct. Obviously these aren't all the LibCrypted games (check on Redump.org for that), these are just games I've personally tested and some I've been told about.
Look out for these effects when testing games modified with SBITools on an accurate PSX emulator such as BizHawk. *(Run from .CCD)*

**Ape Escape (PAL)**\
Main menu navigation will be completely disabled, making you unable to start the game.

**Crash Team Racing (PAL)**\
Game will hang once at the end of the loading screen (for the level itself).

**Legacy of Kain: Soul Reaver (PAL)**\
The game will hang when you're introduced with the combat tutorial when the camera pans to show the enemies.

**Lucky Luke: Western Fever (PAL)**\
The game stops when you get to the Mexican guy blocking the bridge, he just won't move from there, ever. Even when you complete the quest.
The game also has anti-cracking protection where the game will block a path with a fallen tree + maybe more.

**MediEvil (PAL)**\
Will have a disc error icon upon loading The Hilltop Mausoleum. Interesting to note this was actually the *FIRST* game to use LibCrypt.

**MediEvil 2**\
Will also have the same disc error icon as above, except upon loading Kensington.

**PGA European Tour Golf (PAL)**\
In the third hole of the first tournament or by selecting some holes, the game will get stuck in "demo" mode (and will not you play anything).

**Resident Evil 3: Nemesis (PAL)**\
Will hang at the "Game contains violence and gore" screen.

**Spyro 3: Year of the Dragon**\
Interesting case for this one, the game will eventually randomly delete eggs, reset progress with unlocked characters, remove sheep in boss battles, change the language and even tell you off for playing a "hacked copy" + more.
Interesting to note that the game also detected early LibCrypt knockout PPF patches back when the game was first released as it had checksum checks throughout the game, which caused the same effects above.

**This is Football (PAL)**\
Hangs on the loading screen going ingame.

**V-Rally: Championship Edition 2 (PAL)**\
The game will endlessly load on the heartbeat loading screen (with no disc activity).

**Wip3out (PAL)**\
The game will freeze when passing the finish line.

## CloneCD PSX LibCrypt Ripping guide
In order to rip LibCrypt protected drives, you need a CD drive that's able to read subchannels in the first place.

Step 1: Open up CloneCD and click on **Read to Image file**\
![Read to Image file](https://i.imgur.com/eOXsaej.png)

Step 2: Click on the drive you want to use to rip.\
![Copy from CD-Reader to Image file](https://i.imgur.com/lSy8l50.png)\

Step 3: Right click in an empty space and select **New**
Rename it to anything you like, I just name mine **PS1**.\
![New Profile](https://i.imgur.com/d3exNev.png)

Step 4: Right click on your new profile and select **Edit**
Make sure **Read SubChannel Data from Data Tracks** is checked, and uncheck **Regenerate Data Sectors.**\
![Data Read Settings](https://i.imgur.com/LUlJQ6m.png)\
On the **Audio Read Settings** tab, change your **Audio Extraction Quality** is set to **Best (Slowest)**
Optionally you can also set **Read Speed Audio** to something slow to ensure accuracy.\
![Audio Read Settings](https://i.imgur.com/zTi8AMY.png)\
If you want to make sure you have a perfect rip, on the **Error Handling** tab, check **Abort on Read Error**. 
CloneCD will stop  the rip if it finds any bad sectors (basically physical damage) on the disc. 

Step 5: Change the path to where you would like to save, and you can optionally tick **Create "Cue-Sheet".**
I personally check this option so I can always easily hand convert a **.IMG/.CUE** setup into a more common **.BIN/.CUE** setup if I really need to.
You can easily do so by renaming the **.IMG** extension to **.BIN** (identical format), then editing the **.CUE** file in a text editor to change the path to the newly renamed **.BIN** file.\
**Note! - It's a bad idea to do this to LibCrypt protected games, as a BIN/CUE setup cannot read .SUB subchannel files! Making any LibCrypt protected game trigger it's protection!**\
![Select Image Path](https://i.imgur.com/4oit3v2.png)

Step 6: Wait for it to finish ripping and if there's no bad sectors, you should have a working dump!
You can test to see if your LibCrypt dump works by launching an accurate PlayStation emulator (I use **BizHawk**) and opening the **.CCD** file in the emulator.\
![Opening the .CDD dump](https://i.imgur.com/7zxtpZB.png)\
Test whether the LibCrypt protection is triggered, if it isn't then **Congrats!** You have made a successful LibCrypt Dump!\
![Resident Evil 3 Title Screen](https://i.imgur.com/BifjGHV.png)

If you intentionally want to trigger the LibCrypt protection, you can do so by opening the **.CUE** file instead of the **.CCD** which is an easy way for testing.\
![Opening the .CUE dump](https://i.imgur.com/0YB0LiF.png)\
![LibCrypt Copy Protection in Action](https://i.imgur.com/avZdFAF.png)


## CloneCD PSX LibCrypt Burning guide
To burn LibCrypt games successfully, you will need to have a CD burner that supports either **RAW-DAO-16** or **RAW-SAO-16**. You can check for so in Step 3.

Step 1: Select **Write from ImageFile**\
![Write from ImageFile](https://i.imgur.com/IoQv9VF.png)

Step 2: Open the file via the **.CCD** file, and leave **Delete after a successful write** unchecked of course.\
![Opening the .CCD file](https://i.imgur.com/bKtoXAc.png)\
**MAKE ABSOLUTELY SURE YOU *DO NOT BURN FROM A .CUE FILE!***\
**Doing so WILL trigger the LibCrypt copy protection! Only open it from the *.CCD* file!**
Also make absolutely sure that there's a **.SUB** file under the same name and located in the same folder like so:\
![SUB file](https://i.imgur.com/0AVNR7X.png)\
If there's no **.SUB**, or if you burn from the **.CUE** file then the LibCrypt copy protection will trigger and you'll burn a coaster!


Step 3: Be sure to note what your CD Burner supports. Most nowadays support both **RAW-DAO** and **RAW-SAO**.\
![RAW Modes](https://i.imgur.com/Rpt6jA0.png)\
To change it, right click on the CD drive you want to burn from, and click on **Settings ...**\
![Drive Settings](https://i.imgur.com/afT7J8p.png)\
And depending what your drive supports above, select either **RAW DAO** or **RAW SAO**. If your drive supports both modes, then just use **RAW DAO**.\
![Write Mode](https://i.imgur.com/8lLBCIQ.png)\
Whatever you do, do ***NOT*** select **RAW SAO+SUB** or plain **SAO**, it will trigger the LibCrypt protection and you'll burn a coaster instead!

Step 4: Change the write speed as low as you can go, the Sony PlayStation reads at **2X** so it's a good idea to write at that speed. I usually burn at **4X** as it reads just fine.
However most drives can only burn as slow as **16X** nowadays, for the most part this works just fine but definitely don't go above that. Otherwise the PlayStation will have trouble reading the disc and will skip on FMVs.

Step 5: Create a new profile (or edit the existing PS1 profile if you followed the **CloneCD PSX LibCrypt Ripping guide**)\
![Edit a profile](https://i.imgur.com/eJwQKoh.png)

And be absolutely sure to check **Don't Repair SubChannel Data!**
If you don't then CloneCD will ruin the LibCrypt SubChannel by repairing it which of course will result in the copy protection being triggered where you'll end up with a coaster. Sony's LibCrypt copy protection works by corrupting certain parts of the SubChannel in the first place, it checks whether they're modified or not, and if it isn't modified exactly, then it will trigger the protection.\
**TL;DR**: check this box.\
![Don't repair SubChannel data](https://i.imgur.com/mZsNspu.png)\
Click **OK** in this menu and click **OK** on the main screen with this edited profile selected and it'll begin burning.

Step 6: After the disc is burned, try it in a modded Sony PlayStation and hope for the best, cross fingers!
If it works then **HOORAY!**\
![A burned copy of MediEvil protected level running on a real Sony PlayStation](https://i.imgur.com/L6UaxTa.png)


If it doesn't work, you can try changing between **RAW DAO** and **RAW SAO** (if your drive supports both), also be sure you followed all the above instructions exactly. If it *still* doesn't work, check in an emulator such as **BizHawk** to make sure the **.CCD/.SUB** setup you're burning even works in the first place. If the protection triggers in the emulator, then there's your problem.\
![LibCrypt protection in action](https://i.imgur.com/v73KGvI.png)\
If that's not the problem and you're *still* burning coasters, then I'm sorry to say but your CD Burner is not burning the SubChannels exactly the same way they were ripped. You will have to try it on another CD burner. 
Based on personal experience, I find the **HP LightScribe** CD burners burn Sony PlayStation games really well.

If you manage to get one of these, then you have a completely different problem.\
![Anti-Modchip screen](https://i.imgur.com/wDFnDYN.png)\
In order to fix this, you will have to upgrade the modchip in your Sony PlayStation to one with **stealth capabilities**.

The MultiMode 3 (MM3) is the best choice in my opinion, as it supports every PlayStation model out there ***EXCEPT*** the **PAL PSone Slim**. If you have one of those, you'll need a **ONEChip** instead.
If you need a guide on how to wire and even make your own modchip, [I've written up a full guide on my website.](https://kippykip.com/index.php?threads/playstation-1-modchip-hex-dumps-mm3-and-onechip-and-more.500/)\
Alternatively, there is a DIY open source modchip that uses an Arduino. The project is called [PSNee and is on github.](https://github.com/kalymos/PsNee)

## Additional Credits and Sources:
**qnorsten**: For creating a script to grab all .LSD files from ReDump.org\
**LoStraniero91, krHACKen**: For explaining some LibCrypt cause and effects.\
**dizzzy**: For general assistance/important emulator advice.\
**themabus**: SBI Format and XOR information on a [forum thread.](http://forum.redump.org/post/17317/#p17317)\
**Mednafen**: Workaround for using SBI files without the original CRC16 bytes, and CRC16 function.\
**Dremora**: Explanation and whereabouts of .LSD files, creator of [psxt001z](https://github.com/Dremora/psxt001z/)\
*And everyone else at the ReDump team!*\
[PSX RAW-DAO/RAW-SAO Information](https://forum.redfox.bz/threads/ps1-psone-backups.25000/)

## Support:
I really do hope you enjoy **SBITools** as much as I did making it!
If you support the work I've put in, and want me to see more of these type of projects, you can support me with donations.  I'd gladly appreciate it! ![OH BOI](https://kippykip.com/styles/sleek/xenforo/smilies/k_dance.gif)  
  
**Crypto Addresses**:  
**ETH:** 0xb9D6c74986c5dC372CBA6d1cb8a099910557Ab62  
**LTC:** LYru8N52kX3zTzbsMX5jmxB1bFoMsARUCo  
**BTC:** 18zvRocGqCBfWAVWqJDzf4UNFZUhc93aQ2  
**XLM:** GBUYHTDZWL22SP6OHV5U5WB33KQYFZBY2LMJO3RTUQQS5SUZNQXT322X  
**DASH:** Xg2VSf2Via9whT6K6U6wGkECKACxPBa7MT  
**0x:** 0xb9D6c74986c5dC372CBA6d1cb8a099910557Ab62  
**TRX:** TQbZ6TxdNTJtZ7djJ3R7Sv1gB2DaeA5Bqy
