'Includes only what it needs to. (Smaller executable)
Framework brl.FileSystem
Import BRL.Retro
Import pub.FreeProcess
Include "CRC16.bmx"
Include "functions.bmx"

'Main Program
Print "SBITools v0.3.1 - http://kippykip.com"
Global Prog:Int = 0

'Check for psxt001z.exe
If(FileType("psxt001z.exe") <> 1) Then RuntimeError("psxt001z.exe is missing! Please download it from GitHub")

'Are there arguments?
If(Len(AppArgs) > 1)
	If(Lower(AppArgs[1]) = "-sbi2sub" And Len(AppArgs) >= 4)
		Prog:Int = 1
	ElseIf(Lower(AppArgs[1]) = "-lsd2sub" And Len(AppArgs) >= 4)
		Prog:Int = 2
	ElseIf(Lower(AppArgs[1]) = "-cue2ccd" And Len(AppArgs) >= 3)
		Prog:Int = 3
	ElseIf(Lower(AppArgs[1]) = "-singletrack" And Len(AppArgs) >= 3)
		Prog:Int = 4
	ElseIf(Lower(AppArgs[1]) = "-lsd2sbi" And Len(AppArgs) >= 3)
		Prog:Int = 5
	ElseIf(Lower(AppArgs[1]) = "-sbi2lsd" And Len(AppArgs) >= 3)
		Prog:Int = 6
	EndIf
EndIf

Select Prog
	Case 1 'SBI to SUB
		'Safeguard
		If(FileType(AppArgs[3]) <> 1) Then RuntimeError("SBI subchannel doesn't exist!")
		'Add the cue file
		CUE.AddCue(AppArgs[2])
		Local BaseName:String = CUE.GetBinPath(CUE.FDRPath) 'This gives us the BaseName (filename before .cue) and also adds the binary locaton to CUE.BinaryFN	
	
		'Lets make an export folder
		Print "Exporting to: 'SUB\" + BaseName:String + "'\."
		If(FileType("SUB") <> 2) 'Does a SUB folder exist?
			CreateDir("SUB")
			Print "Directory 'SUB' doesn't exist! Creating..."
		EndIf
		
		'Get the sector count
		Print "Image contains " + CUE.MultiSectorCount + " sectors..."
		'Launch psxt001z with the following arguments
		GenSub("SUB\" + BaseName + ".sub", CUE.MultiSectorCount)
		
		'Load it
		Local Subchannel:TBank = LoadBank("SUB\" + BaseName + ".sub")
		If Not(Subchannel) Then RuntimeError("Error reading created .SUB subchannel...")
		'Launch the conversion function
		SBIToSub(AppArgs[3], Subchannel)
		SaveBank(Subchannel, "SUB\" + BaseName + ".sub") 'Save the modified SUB
		'Hopefully everything worked
		OpenDir(".\SUB\") 'Open the directory!
	Case 2 'LSD to SUB
		'Safeguard
		If(FileType(AppArgs[3]) <> 1) Then RuntimeError("LSD subchannel doesn't exist!")
		'Add the cue file
		CUE.AddCue(AppArgs[2])
		Local BaseName:String = CUE.GetBinPath(CUE.FDRPath) 'This gives us the BaseName (filename before .cue) and also adds the binary locaton to CUE.BinaryFN	
	
		'Lets make an export folder
		Print "Exporting to: 'CCD\" + BaseName:String + ".SUB'."
		If(FileType("SUB") <> 2) 'Does a SUB folder exist?
			CreateDir("SUB")
			Print "Directory 'SUB' doesn't exist! Creating..."
		EndIf
		
		'Get the sector count
		Print "Image contains " + CUE.MultiSectorCount + " sectors..."
		'Launch psxt001z with the following arguments
		GenSub("SUB\" + BaseName + ".sub", CUE.MultiSectorCount)
		'Load it
		Local Subchannel:TBank = LoadBank("SUB\" + BaseName + ".sub")
		If Not(Subchannel) Then RuntimeError("Error reading created .SUB subchannel...")
		'Launch the conversion function
		LSDToSub(AppArgs[3], Subchannel)
		SaveBank(Subchannel, "SUB\" + BaseName + ".sub") 'Save the modified SUB
		'Hopefully everything worked
		OpenDir(".\SUB\") 'Open the directory!
	Case 3 'CCD Generator
		'This was pretty handy
		'https://books.google.com.au/books?id=76HVAwAAQBAJ&pg=PA233&lpg=PA233&dq=entry+1+clonecd&source=bl&ots=XEUM8fr_Sp&sig=GxJHxBp5AEFxbVgNMiGt69lB8Ds&hl=en&sa=X&ved=2ahUKEwjU5rqs_ezdAhVNITQIHTtxCyYQ6AEwA3oECAYQAQ#v=onepage&q=entry%201%20clonecd&f=false
		
		'Add the cue file
		CUE.AddCue(AppArgs[2])
		Local BaseName:String = CUE.GetBinPath(CUE.FDRPath) 'This gives us the BaseName (filename before .cue) and also adds the binary locaton to CUE.BinaryFN	

		'Useful CUE information we'll use below
		Local TrackCount:Int = CUE.CountCDDA(True) 'How many tracks in general are there?
		Local TrackCountCDDA:Int = CUE.CountCDDA() 'How many cd audio tracks are there?
		Local TotalMSFLeadin:Int[] = SectorToMSF(CUE.MultiSectorCount + 150)
		
		'Lets make an export folder
		Print "Exporting to: 'CCD\" + BaseName:String + ".SUB'."
		If(FileType("CCD") <> 2) 'Does a CCD folder exist?
			CreateDir("CCD")
			Print "Directory 'CCD' doesn't exist! Creating..."
		EndIf
		If(FileType("CCD\" + BaseName:String) <> 2) 'Does the basename folder exist?
			CreateDir("CCD\" + BaseName:String)
			Print "Directory 'CCD\" + BaseName:String + "' doesn't exist! Creating..."
		EndIf
		
		Print "Creating CCD file"
		Local CCDFile:TStream = WriteFile("CCD\" + BaseName + "\" + BaseName + ".ccd")
		
		'0x04, otherwise if there are music tracks it's 0x00
		Local Control:String = "Control=0x04"
		If(TrackCountCDDA:Int > 0)
			Control:String = "Control=0x00"
		EndIf
		
		'Here we go! Header
		Print "Writing CCD headers"
		WriteLine(CCDFile, "[CloneCD]")
		WriteLine(CCDFile, "Version=3")
		WriteLine(CCDFile, "[Disc]")
		WriteLine(CCDFile, "TocEntries=" + (3 + TrackCount)) 'Toc = Almost always 4, unless there's extra audio/data tracks in it
		WriteLine(CCDFile, "Sessions=1")
		WriteLine(CCDFile, "DataTracksScrambled=0")
		WriteLine(CCDFile, "CDTextLength=0")
		WriteLine(CCDFile, "[Session 1]")
		WriteLine(CCDFile, "PreGapMode=2") 'PS1 games are MODE2
		WriteLine(CCDFile, "PreGapSubC=1") 'Hell yeah we want a subchannel
		
		'Entry 0, Always the same for PS1 dumps I believe
		Print "Writing CCD Entries"
		WriteLine(CCDFile, "[Entry 0]")
		WriteLine(CCDFile, "Session=1")
		WriteLine(CCDFile, "Point=0xa0")
		WriteLine(CCDFile, "ADR=0x01")
		WriteLine(CCDFile, "Control=0x04")
		WriteLine(CCDFile, "TrackNo=0")
		WriteLine(CCDFile, "AMin=0")
		WriteLine(CCDFile, "ASec=0")
		WriteLine(CCDFile, "AFrame=0")
		WriteLine(CCDFile, "ALBA=-150")
		WriteLine(CCDFile, "Zero=0")
		WriteLine(CCDFile, "PMin=1")
		WriteLine(CCDFile, "PSec=32")
		WriteLine(CCDFile, "PFrame=0")
		WriteLine(CCDFile, "PLBA=6750")
		
		'Entry 1
		WriteLine(CCDFile, "[Entry 1]")
		WriteLine(CCDFile, "Session=1")
		WriteLine(CCDFile, "Point=0xa1")
		WriteLine(CCDFile, "ADR=0x01")
		'Control var is used here
		WriteLine(CCDFile, Control:String)
		WriteLine(CCDFile, "TrackNo=0")
		WriteLine(CCDFile, "AMin=0")
		WriteLine(CCDFile, "ASec=0")
		WriteLine(CCDFile, "AFrame=0")
		WriteLine(CCDFile, "ALBA=-150")
		WriteLine(CCDFile, "Zero=0")
		WriteLine(CCDFile, "PMin=" + TrackCount) 'Number of total tracks, why this is stored in PMin I have no idea. It was listed in a Google book thing.
		WriteLine(CCDFile, "PSec=0") 'CDDA always 0
		WriteLine(CCDFile, "PFrame=0") 'CDDA always 0
		WriteLine(CCDFile, "PLBA=" + (MSFToSector(TrackCount, 0, 0) - 150)) 'MSF of above, but take -150 (ALBA)
		
		'Entry 2
		WriteLine(CCDFile, "[Entry 2]")
		WriteLine(CCDFile, "Session=1")
		WriteLine(CCDFile, "Point=0xa2")
		WriteLine(CCDFile, "ADR=0x01")
		'Control var is used here too
		WriteLine(CCDFile, Control)
		WriteLine(CCDFile, "TrackNo=0")
		WriteLine(CCDFile, "AMin=0")
		WriteLine(CCDFile, "ASec=0")
		WriteLine(CCDFile, "AFrame=0")
		WriteLine(CCDFile, "ALBA=-150")
		WriteLine(CCDFile, "Zero=0")
		WriteLine(CCDFile, "PMin=" + TotalMSFLeadin[0]) 'Minutes of the PLBA underneath, although 2 second leadin
		WriteLine(CCDFile, "PSec=" + TotalMSFLeadin[1]) 'Seconds of the PLBA underneath, although 2 second leadin
		WriteLine(CCDFile, "PFrame=" + TotalMSFLeadin[2]) 'Frames of the PLBA underneath, although 2 second leadin
		WriteLine(CCDFile, "PLBA=" + CUE.MultiSectorCount) 'It's just the total Sector count
		
		'Loop through all the audio tracks
		Local CurrentEntry:Int = 3
		For Local CueFile:CUE = EachIn CUE.List:TList
			'Is current track in the loop an AUDIO type with index 1?
			'If(CueFile.TrackType = "AUDIO" And CueFile.Index = 1)
			If(CueFile.Index = 1)
				WriteLine(CCDFile, "[Entry " + CurrentEntry:Int + "]")
				WriteLine(CCDFile, "Session=1")
				'Increases everytime, starts off at 2. It's a byte in HEX. Lowercase
				'BMX's HEX function makes a 8 character string, so we have to cut it
				WriteLine(CCDFile, "Point=0x" + Lower(Right(Hex(CurrentEntry:Int - 2), 2)))
				WriteLine(CCDFile, "ADR=0x01")
				'Audio tracks are 00, Data tracks are 04?
				If(CueFile.TrackType = "AUDIO")
					WriteLine(CCDFile, "Control=0x00")
				Else
					WriteLine(CCDFile, "Control=0x04")
				EndIf
				WriteLine(CCDFile, "TrackNo=0")
				WriteLine(CCDFile, "AMin=0")
				WriteLine(CCDFile, "ASec=0")
				WriteLine(CCDFile, "AFrame=0")
				WriteLine(CCDFile, "ALBA=-150")
				WriteLine(CCDFile, "Zero=0")
				
				'Well, it seems every data track after track 1 doesn't have the 150 sector (2 second) leadin. Audio tracks do have the leadin though.
				If(CueFile.Sector > 150 And CueFile.TrackType = "MODE2/2352")
					'Just a plain MSF to PLBA conversion, with the above varibles
					Local EntryMSF[] = SectorToMSF(CueFile.Sector)
					WriteLine(CCDFile, "PMin=" + EntryMSF[0])
					WriteLine(CCDFile, "PSec=" + EntryMSF[1]) 'PLBA conversion + 150
					WriteLine(CCDFile, "PFrame=" + EntryMSF[2]) 'PLBA conversion + 150
					WriteLine(CCDFile, "PLBA=" + (CueFile.Sector - 150)) 'Seems to just be the sector count for the current track as INDEX 1 but with the leadin removed
				Else 'The CDDA tracks do though
					'Just a plain MSF to PLBA conversion with a 2 second leadin
					Local EntryMSF[] = SectorToMSF(CueFile.Sector + 150)
					WriteLine(CCDFile, "PMin=" + EntryMSF[0])
					WriteLine(CCDFile, "PSec=" + EntryMSF[1]) 'PLBA conversion + 150
					WriteLine(CCDFile, "PFrame=" + EntryMSF[2]) 'PLBA conversion + 150
					'No leadin stuff here
					WriteLine(CCDFile, "PLBA=" + CueFile.Sector) 'Seems to just be the sector count for the current track as INDEX 1
				EndIf
				CurrentEntry = CurrentEntry + 1 'Increase the Entry count
			EndIf
		Next
		
		'Basically just reading the cuefile as sectors instead of MSF at this point
		Print "Writing TRACK info"
		Local CurrentTrack:Int = 0
		'Loop through all the listings again
		For Local CueFile:CUE = EachIn CUE.List:TList
			'Does this current loop have a different track number?
			If(CueFile.Track <> CurrentTrack)
				CurrentTrack = CueFile.Track
				WriteLine(CCDFile, "[TRACK " + CurrentTrack:Int + "]")
				'Is this track an Audio track?
				If(CueFile.TrackType = "AUDIO")
					WriteLine(CCDFile, "MODE=0")
				Else
					'Then it's probably the data track
					WriteLine(CCDFile, "MODE=2")
				EndIf
			EndIf
			If(CueFile.TrackType = "MODE2/2352")
				If(CueFile.Sector > 150)
					WriteLine(CCDFile, "INDEX " + CueFile.Index + "=" + (CueFile.Sector - 150))
				Else
					WriteLine(CCDFile, "INDEX " + CueFile.Index + "=" + CueFile.Sector)
				EndIf
			Else
				WriteLine(CCDFile, "INDEX " + CueFile.Index + "=" + CueFile.Sector)
			EndIf
		Next
		
		
		CloseFile(CCDFile)
		Print "Done writing CCD!"
				
		'If it's a multitrack, combine it!
		If(CUE.IsMultiTrack)
			Print "Merging image (This will take a moment)"
			'Local MergedImage:TStream = WriteFile("CCD\" + BaseName:String + "\" + BaseName:String + ".img")
			'CopyStream
			CUE.MergeImage("CCD\" + BaseName:String + "\" + BaseName:String + ".img")
		Else
			Print "Copying image (This will take a moment)"
			CopyFile(CUE.BinPath + CUE.BinaryFN, "CCD\" + BaseName:String + "\" + BaseName:String + ".img")
			'Print "BinPath:" + CUE.BinPath
			'Print "BinaryFN:" + CUE.BinaryFN
		EndIf
		
		'Alright, now lets make a modified cue
		Print "Creating modified CUE"
		CUE.ExportCue("CCD\" + BaseName:String + "\" + BaseName:String + ".cue", BaseName:String + ".img")
		Print "Done writing CUE!"
		
		'Time to run psxt001z
		GenSub("CCD\" + BaseName:String + "\" + BaseName:String + ".sub", CUE.MultiSectorCount)
		
		'LibCrypt + CDDA audio Patching
		'SBI file found
		If(FileType(CUE.BinPath + BaseName + ".sbi")) 'SBI file found
			Print "LibCrypt patch '" + BaseName + ".sbi' was found! Patching subchannel..."
			'Load the subchannel
			Local Subchannel:TBank = LoadBank("CCD\" + BaseName + "\" + BaseName + ".sub")
			If Not(Subchannel) Then RuntimeError("Error loading subchannel!") 'Did it load?
			SBIToSub(CUE.BinPath + BaseName + ".sbi", Subchannel) 'Run the patching function
			SaveBank(Subchannel, "CCD\" + BaseName + "\" + BaseName:String + ".sub") 'Save the modified SUB
		'LSD file found
		ElseIf(FileType(CUE.BinPath + BaseName + ".lsd"))
			Print "LibCrypt patch '" + BaseName + ".lsd' was found! Patching subchannel..."
			'Load the subchannel
			Local Subchannel:TBank = LoadBank("CCD\" + BaseName + "\" + BaseName + ".sub")
			If Not(Subchannel) Then RuntimeError("Error loading subchannel!") 'Did it load?
			LSDToSub(CUE.BinPath + BaseName:String + ".lsd", Subchannel) 'Run the patching function
			SaveBank(Subchannel, "CCD\" + BaseName + "\" + BaseName + ".sub") 'Save the modified SUB
		Else 'No patches found...
			Print "Could not find '" + CUE.BinPath + BaseName + ".sbi'! Skipping..."
			Print "Could not find '" + CUE.BinPath + BaseName + ".lsd'! Skipping..."
			Print "LibCrypt .SBI/.LSD patches not found in CUE directory! Ignoring .SUB patching..."
			
			'Load the subchannel
			Local Subchannel:TBank = LoadBank("CCD\" + BaseName + "\" + BaseName + ".sub")
			If Not(Subchannel) Then RuntimeError("Error loading subchannel!") 'Did it load?
			GenSubCDDA(Subchannel) 'Run the SUB audio tracks function
			SaveBank(Subchannel, "CCD\" + BaseName:String + "\" + BaseName + ".sub") 'Save the modified SUB
		EndIf
		
		Print "Done converting!"
		Print "Everything exported to: '" + "CCD\" + BaseName + "\'"
		OpenDir(".\CCD\" + BaseName + "\") 'Open the directory!
	Case 4 'Single Track CUE converter
		'Add the cue file
		CUE.AddCue(AppArgs[2])
		Local BaseName:String = CUE.GetBinPath(CUE.FDRPath) 'This gives us the BaseName (filename before .cue) and also adds the binary locaton to CUE.BinaryFN	
		
		'Lets make an export folder
		Print "Exporting to: 'CUE\" + BaseName:String + "'\."
		If(FileType("CUE") <> 2) 'Does a CUE folder exist?
			CreateDir("CUE")
			Print "Directory 'CUE' doesn't exist! Creating..."
		EndIf
		If(FileType("CUE\" + BaseName:String) <> 2) 'Does the basename folder exist?
			CreateDir("CUE\" + BaseName:String)
			Print "Directory 'CUE\" + BaseName:String + "' doesn't exist! Creating..."
		EndIf
		
		'Should be multitrack
		If(CUE.IsMultiTrack)
			Print "Merging image (This will take a moment)"
			CUE.MergeImage("CUE\" + BaseName:String + "\" + BaseName:String + ".bin")
		Else
			RuntimeError("BIN/CUE setup is already single track binary!")
		EndIf
		
		'Alright, now lets make a modified cue
		Print "Creating modified CUE"
		CUE.ExportCue("CUE\" + BaseName:String + "\" + BaseName:String + ".cue", BaseName:String + ".bin")
		Print "Done writing CUE!"
		
		'SBI file found
		If(FileType(CUE.BinPath + BaseName + ".sbi")) 'SBI file found
			Print "LibCrypt patch '" + BaseName + ".sbi' was found! Copying..."
			CopyFile(CUE.BinPath + BaseName + ".sbi", "CUE\" + BaseName:String + "\" + BaseName:String + ".sbi")
		'LSD file found
		ElseIf(FileType(CUE.BinPath + BaseName + ".lsd"))
			Print "LibCrypt patch '" + BaseName + ".lsd' was found! Copying..."
			CopyFile(CUE.BinPath + BaseName + ".lsd", "CUE\" + BaseName:String + "\" + BaseName:String + ".lsd")
		Else
			Print "No LibCrypt .LSD/.SBI patches were found. Ignoring..."
		EndIf
		Print "Finished!"
		OpenDir(".\CUE\" + BaseName + "\") 'Open the directory!
	Case 5 'LSD2SBI
		'Does it exist?
		If(FileType(AppArgs[2]) <> 1) Then RuntimeError(".LSD subchannel doesn't exist!")
		
		'Split the path and fix the slashes etc
		Local FDRPath:String[] = AppArgs[2].Replace("/", "\").Split("\")
		'This just gets the name of the lsd. Say if it was "C:\CoolGame.lsd", this would return "CoolGame"
		Local BaseName:String = Left(FDRPath[Len(FDRPath) - 1], Len(FDRPath[Len(FDRPath) - 1]) - 4)
		
		'Lets make an export folder
		Print "Exporting as: 'SBI\" + BaseName:String + ".sbi'."
		If(FileType("SBI") <> 2) 'Does a SBI folder exist?
			CreateDir("SBI")
			Print "Directory 'SBI' doesn't exist! Creating..."
		EndIf
		
		'Set the vars!
		Local LSDFile:TStream = ReadFile(AppArgs[2])
		Local SBIFile:TStream = WriteFile("SBI\" + BaseName + ".sbi")
		If Not (SBIFile) Then RuntimeError("Error writing SBI!")
		
		'Begin writing SBI header
		Print "Writing SBI header..."
		WriteString(SBIFile, "SBI")
		WriteByte(SBIFile, 0)
		
		'Loop through the whole LSD file!
		Print "Writing QSUB's..."
		While Not(Eof(LSDFile))
			WriteByte(SBIFile, ReadByte(LSDFile)) 'Minutes
			WriteByte(SBIFile, ReadByte(LSDFile)) 'Seconds
			WriteByte(SBIFile, ReadByte(LSDFile)) 'Frames
			WriteByte(SBIFile, 1) 'Dummy byte
			
			'QSUB
			For Local x = 0 To 9
				WriteByte(SBIFile, ReadByte(LSDFile))
			Next
			
			'CRC16, unused for SBI conversion
			ReadByte(LSDFile)
			ReadByte(LSDFile)
		Wend
		
		'Done!
		CloseFile(LSDFile)
		CloseFile(SBIFile)
		Print "Finished!"
		OpenDir(".\SBI\") 'Open the directory!
	Case 6 'SBI2LSD
		'Does it exist?
		If(FileType(AppArgs[2]) <> 1) Then RuntimeError(".SBI subchannel doesn't exist!")
		
		'Split the path and fix the slashes etc
		Local FDRPath:String[] = AppArgs[2].Replace("/", "\").Split("\")
		'This just gets the name of the lsd. Say if it was "C:\CoolGame.lsd", this would return "CoolGame"
		Local BaseName:String = Left(FDRPath[Len(FDRPath) - 1], Len(FDRPath[Len(FDRPath) - 1]) - 4)
		
		'Lets make an export folder
		Print "Exporting as: 'LSD\" + BaseName:String + ".lsd'."
		If(FileType("LSD") <> 2) 'Does a LSD folder exist?
			CreateDir("LSD")
			Print "Directory 'LSD' doesn't exist! Creating..."
		EndIf
		
		'Set the vars!
		Local SBIFile:TStream = ReadFile(AppArgs[2])
		'4801107 = [SUB\0] header as an int
		If(ReadInt(SBIFile) <> 4801107) Then RuntimeError("This isn't a valid SBI file!")
		
		'Now 
		Local LSDFile:TStream = WriteFile("LSD\" + BaseName + ".lsd")
		If Not (LSDFile) Then RuntimeError("Error writing LSD!")
				
		'Loop through the whole SBI file!
		Print "Writing QSUB's/CRC16's..."
		While Not(Eof(SBIFile))
			WriteByte(LSDFile, ReadByte(SBIFile)) 'Minutes
			WriteByte(LSDFile, ReadByte(SBIFile)) 'Seconds
			WriteByte(LSDFile, ReadByte(SBIFile)) 'Frames
			ReadByte(SBIFile) 'Dummy byte
			
			'QSUB
			Local QSub:Byte[10]
			For Local x = 0 To 9
				QSub[x] = ReadByte(SBIFile)
				WriteByte(LSDFile, QSub[x]) 'QSUB Byte
			Next
			
			'CRC16 regeneration
			Local SUB_CRC16:Short = ~CRC16(QSub)
			Local SUB_CRCA:Byte = (SUB_CRC16) Shr 8
			Local SUB_CRCB:Byte = (SUB_CRC16) - (SUB_CRCA Shl 8)
			'Have to do it this way as PokeShort will reverse to little endian or something
			WriteByte(LSDFile, SUB_CRCA)
			WriteByte(LSDFile, SUB_CRCB)
		Wend
		
		'Done!
		CloseFile(LSDFile)
		CloseFile(SBIFile)
		Print "Finished!"
		OpenDir(".\LSD\") 'Open the directory!

	Default 'No arguments
		Print "Missing command line!"
		Print ""
		Print "SBITools.exe -cue2ccd cuefile.cue"
		Print "SBITools.exe -lsd2sub cuefile.cue subchannel.lsd"
		Print "SBITools.exe -lsd2sbi subchannel.lsd"
		Print "SBITools.exe -sbi2sub cuefile.cue subchannel.sbi"
		Print "SBITools.exe -sbi2lsd subchannel.sbi"
		Print "SBITools.exe -singletrack cuefile"
		Print ""
		Print "Definitions:"
		Print "-cue2ccd: Converts a 'BIN/CUE/SBI|LSD' setup into a 'IMG/CCD/CUE/SUB' setup."
		Print "    This makes burning LibCrypt games easily possible with software such"
		Print "    as CloneCD. SBI/LSD files are loaded from the same directory as the .CUE"
		Print "    file under the same name."
		Print "-lsd2sub: Creates a patched .SUB subchannel with a .LSD file."
		Print "-lsd2sbi: Converts a .SBI subchannel patch to a .LSD subchannel patch."
		Print "-sbi2sub: Creates a patched .SUB subchannel with a .SBI file."
		Print "-sbi2lsd: Converts a .SBI subchannel patch to a .LSD subchannel patch."
		Print "    NOTE: This cannot perfectly reconstruct the missing CRC16 bytes!"
		Print "-singletrack: Converts a seperate track BIN/CUE setup into a single track"
		Print "    BIN/CUE setup."
		Print ""
		Print "Examples:"
		Print "SBITools.exe -cue2ccd " + Chr(34) + "C:\CoolGameRips\MediEvil.CUE" + Chr(34)
		Print ""
		Print "SBITools.exe -sbi2sub " + Chr(34) + "C:\CoolGameRips\VRally2.CUE" + Chr(34) + " " + Chr(34) + "C:\CoolGameRips\sbipatches\V-Rally - Championship Edition 2 (Europe) (En,Fr,De).sbi" + Chr(34)
		Print ""
		Print "SBITools.exe -lsd2sub " + Chr(34) + "C:\CoolGameRips\MediEvil.CUE" + Chr(34) + " " + Chr(34) + "C:\CoolGameRips\sbipatches\MediEvil (Europe).lsd" + Chr(34)
		Print ""
		Print "SBITools.exe -sbi2lsd " + Chr(34) + "C:\CoolGameRips\sbipatches\V-Rally - Championship Edition 2 (Europe) (En,Fr,De).sbi" + Chr(34)
		Print ""
		Print "SBITools.exe -lsd2sbi " + Chr(34) + "C:\CoolGameRips\sbipatches\MediEvil (Europe).lsd" + Chr(34)
		Print ""
		Print "SBITools.exe -singletrack " + Chr(34) + "C:\CoolGameRips\VRally2.CUE" + Chr(34)
		Delay 1000
End Select
