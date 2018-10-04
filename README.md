
# SBITools
SBITools v0.1 - http://kippykip.com

**Description:**

    This is a small set of conversion tools written in BlitzMax to convert .SBI/.LSD files back into .SUB files, which can be read into popular CD Burning software such as CloneCD.
    This way, LibCrypt protected games dumped in other formats can still be burned as 1:1 copies on a real Sony PlayStation console again with the LibCrypt changes intact.

**Requirements:**

    psxt001z, to be in the same directory as SBITools
    It can be downloaded from: http://redump.org/download/psxt001z-0.21b1.7z
    Source Code: https://github.com/Dremora/psxt001z

**Arguments:**
> SBITools.exe -sbi image.(bin/img) subchannel.sbi subchannel.sub
> SBITools.exe -lsd image.(bin/img) subchannel.lsd subchannel.sub

**Example:**
>SBITools.exe -sbi MediEvil.bin "MediEvil (Europe).sbi" MediEvil.sub


**Note:** 

    The .SUB path will be overridden if it exists! Be careful.
    I'm planning on making a BIN/CUE/SBI -> IMG/CUE/CCD/SUB function for the future.
    Maybe even remove the need for psxt001z too as it's only used for generating a blank .SUB subchannel initially.
		
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

Note: CRC16 is not needed to start LibCrypt games, but it is modified on LibCrypt'ed games.
