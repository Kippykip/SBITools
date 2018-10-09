'Includes only what it needs to. (Smaller executable)
Framework brl.FileSystem
Import BRL.Retro
Import pub.FreeProcess
Include "CRC16.bmx"
Include "functions.bmx"

'Main Program
Print "SBITools v0.2 - http://kippykip.com"
Global Prog:Int = 0

'Check for psxt001z.exe
If(FileType("psxt001z.exe") <> 1) Then RuntimeError("psxt001z.exe is missing! Please download it from GitHub")

'Are there arguments?
If(Len(AppArgs) > 1)
	If(Lower(AppArgs[1]) = "-sbi" And Len(AppArgs) >= 4)
		Prog:Int = 1
	ElseIf(Lower(AppArgs[1]) = "-lsd" And Len(AppArgs) >= 4)
		Prog:Int = 2
	ElseIf(Lower(AppArgs[1]) = "-cue2ccd" And Len(AppArgs) >= 3)
		Prog:Int = 3
	EndIf
EndIf

Select Prog
	
	Case 1 'SBI to SUB
		'Safeguard
		If(FileType(AppArgs[3]) <> 1) Then RuntimeError("SBI subchannel doesn't exist!")
		'Add the cue file
		Local CuePath:String = AppArgs[2].Replace("/", "\")
		If(FileType(CuePath:String) <> 1) Then RuntimeError("Missing CUE file!")
		CUE.AddCue(CuePath:String)
		Local FDRPath:String[] = CuePath.Split("\")
		Local BaseName:String = CUE.GetBinPath(FDRPath) 'This gives us the BaseName (filename before .cue) and also adds the binary locaton to CUE.BinaryFN	
	
		'Lets make an export folder
		Print "Exporting to: 'SUB\" + BaseName:String + "'\."
		If(FileType("SUB") <> 2) 'Does a CCD folder exist?
			CreateDir("SUB")
			Print "Directory 'SUB' doesn't exist! Creating..."
		EndIf
		If(FileType("SUB\" + BaseName:String) <> 2) 'Does BaseName folder exist?
			CreateDir("SUB\" + BaseName:String)
			Print "Directory 'SUB\" + BaseName:String + "' doesn't exist! Creating..."
		EndIf
		
		'Get the sector count
		Local Sectors:Int = GetSectorsBySize(Int(FileSize(CUE.BinPath + CUE.BinaryFN)))
		Print "Image contains " + Sectors:Int + " sectors..."
		'Launch psxt001z with the following arguments
		GenSub("SUB\" + BaseName:String + "\" + BaseName + ".sub", Sectors:Int)
		
		'Load it
		Local Subchannel:TBank = LoadBank("SUB\" + BaseName:String + "\" + BaseName + ".sub")
		If Not(Subchannel) Then RuntimeError("Error reading created .SUB subchannel...")
		'Launch the conversion function
		SBIToSub(AppArgs[3], Subchannel)
		SaveBank(Subchannel, "SUB\" + BaseName:String + "\" + BaseName + ".sub") 'Save the modified SUB
		'Hopefully everything worked
		Delay 2000
	Case 2 'LSD to SUB
		'Safeguard
		If(FileType(AppArgs[3]) <> 1) Then RuntimeError("LSD subchannel doesn't exist!")
		'Add the cue file
		Local CuePath:String = AppArgs[2].Replace("/", "\")
		If(FileType(CuePath:String) <> 1) Then RuntimeError("Missing CUE file!")
		CUE.AddCue(CuePath:String)
		Local FDRPath:String[] = CuePath.Split("\")
		Local BaseName:String = CUE.GetBinPath(FDRPath) 'This gives us the BaseName (filename before .cue) and also adds the binary locaton to CUE.BinaryFN	
	
		'Lets make an export folder
		Print "Exporting to: 'SUB\" + BaseName:String + "'\."
		If(FileType("SUB") <> 2) 'Does a CCD folder exist?
			CreateDir("SUB")
			Print "Directory 'SUB' doesn't exist! Creating..."
		EndIf
		If(FileType("SUB\" + BaseName:String) <> 2) 'Does BaseName folder exist?
			CreateDir("SUB\" + BaseName:String)
			Print "Directory 'SUB\" + BaseName:String + "' doesn't exist! Creating..."
		EndIf
		
		'Get the sector count
		Local Sectors:Int = GetSectorsBySize(Int(FileSize(CUE.BinPath + CUE.BinaryFN)))
		Print "Image contains " + Sectors:Int + " sectors..."
		'Launch psxt001z with the following arguments
		GenSub("SUB\" + BaseName:String + "\" + BaseName + ".sub", Sectors:Int)
		'Load it
		Local Subchannel:TBank = LoadBank("SUB\" + BaseName:String + "\" + BaseName + ".sub")
		If Not(Subchannel) Then RuntimeError("Error reading created .SUB subchannel...")
		'Launch the conversion function
		LSDToSub(AppArgs[3], Subchannel)
		SaveBank(Subchannel, "SUB\" + BaseName:String + "\" + BaseName + ".sub") 'Save the modified SUB
		'Hopefully everything worked
		Delay 2000
	Case 3 'CCD Generator
		'This was pretty handy
		'https://books.google.com.au/books?id=76HVAwAAQBAJ&pg=PA233&lpg=PA233&dq=entry+1+clonecd&source=bl&ots=XEUM8fr_Sp&sig=GxJHxBp5AEFxbVgNMiGt69lB8Ds&hl=en&sa=X&ved=2ahUKEwjU5rqs_ezdAhVNITQIHTtxCyYQ6AEwA3oECAYQAQ#v=onepage&q=entry%201%20clonecd&f=false
		
		'Add the cue file
		Local CuePath:String = AppArgs[2].Replace("/", "\")
		If(FileType(CuePath:String) <> 1) Then RuntimeError("Missing CUE file!")
		CUE.AddCue(CuePath:String)
		Local FDRPath:String[] = CuePath.Split("\")
		Local BaseName:String = CUE.GetBinPath(FDRPath) 'This gives us the BaseName (filename before .cue) and also adds the binary locaton to CUE.BinaryFN	

		'Useful CUE information we'll use below
		Local TrackCount:Int = CUE.CountCDDA()
		Local TotalSectors:Int = GetSectorsBySize(Int(FileSize(CUE.BinPath:String + CUE.BinaryFN)))
		'Local TotalMSF:Int[] = SectorToMSF(TotalSectors:Int) 'Not used right now
		Local TotalMSFLeadin:Int[] = SectorToMSF(TotalSectors:Int + 150)
		
		'Lets make an export folder
		Print "Exporting to: 'CCD\" + BaseName:String + "'\."
		If(FileType("CCD") <> 2) 'Does a CCD folder exist?
			CreateDir("CCD")
			Print "Directory 'CCD' doesn't exist! Creating..."
		EndIf
		If(FileType("CCD\" + BaseName:String) <> 2) 'Does the basename folder exist?
			CreateDir("CCD\" + BaseName:String)
			Print "Directory 'CCD\" + BaseName:String + "' doesn't exist! Creating..."
		EndIf
		
		Print "Creating CCD file"
		Local CCDFile:TStream = WriteFile("CCD\" + BaseName:String + "\" + BaseName:String + ".ccd")
		
		'0x04, otherwise if there are music tracks it's 0x00
		Local Control:String = "Control=0x04"
		If(TrackCount:Int > 0)
			Control:String = "Control=0x00"
		EndIf
		
		'Here we go! Header
		Print "Writing CCD headers"
		WriteLine(CCDFile, "[CloneCD]")
		WriteLine(CCDFile, "Version=3")
		WriteLine(CCDFile, "[Disc]")
		WriteLine(CCDFile, "TocEntries=" + (4 + TrackCount:Int)) 'Toc = 4 always, if the image has CD tracks then it 4 + MusicTrackCount, not including the data track I guess.
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
		WriteLine(CCDFile, "PMin=" + (TrackCount:Int + 1)) 'Number of total tracks, why this is stored in PMin I have no idea. It was listed in a Google book thing.
		WriteLine(CCDFile, "PSec=0") 'CDDA always 0
		WriteLine(CCDFile, "PFrame=0") 'CDDA always 0
		WriteLine(CCDFile, "PLBA=" + (MSFToSector(TrackCount:Int + 1, 0, 0) - 150)) 'MSF of above, but take -150 (ALBA)
		
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
		WriteLine(CCDFile, "PLBA=" + TotalSectors) 'It's just the total Sector count
		
		'Always the same
		WriteLine(CCDFile, "[Entry 3]")
		WriteLine(CCDFile, "Session=1")
		WriteLine(CCDFile, "Point=0x01")
		WriteLine(CCDFile, "ADR=0x01")
		WriteLine(CCDFile, "Control=0x04")
		WriteLine(CCDFile, "TrackNo=0")
		WriteLine(CCDFile, "AMin=0")
		WriteLine(CCDFile, "ASec=0")
		WriteLine(CCDFile, "AFrame=0")
		WriteLine(CCDFile, "ALBA=-150")
		WriteLine(CCDFile, "Zero=0")
		WriteLine(CCDFile, "PMin=0")
		WriteLine(CCDFile, "PSec=2")
		WriteLine(CCDFile, "PFrame=0")
		WriteLine(CCDFile, "PLBA=0")
		
		'Loop through all the audio tracks
		Local CurrentEntry:Int = 4
		For Local CueFile:CUE = EachIn CUE.List:TList
			'Is current track in the loop an AUDIO type with index 1?
			If(CueFile.TrackType = "AUDIO" And CueFile.Index = 1)
				WriteLine(CCDFile, "[Entry " + CurrentEntry:Int + "]")
				WriteLine(CCDFile, "Session=1")
				'Increases everytime, starts off at 2. It's a byte in HEX. Lowercase
				'BMX's HEX function makes a 8 character string, so we have to cut it
				WriteLine(CCDFile, "Point=0x" + Lower(Right(Hex(CurrentEntry:Int - 2), 2)))
				WriteLine(CCDFile, "ADR=0x01")
				WriteLine(CCDFile, "Control=0x00")
				WriteLine(CCDFile, "TrackNo=0")
				WriteLine(CCDFile, "AMin=0")
				WriteLine(CCDFile, "ASec=0")
				WriteLine(CCDFile, "AFrame=0")
				WriteLine(CCDFile, "ALBA=-150")
				WriteLine(CCDFile, "Zero=0")
				
				'MSF for this is just PLBA conversion + 150 (2 second leadin once again)
				Local EntryMSF[] = SectorToMSF(CueFile.Sector + 150)
				
				WriteLine(CCDFile, "PMin=" + EntryMSF[0])
				WriteLine(CCDFile, "PSec=" + EntryMSF[1]) 'PLBA conversion + 150
				WriteLine(CCDFile, "PFrame=" + EntryMSF[2]) 'PLBA conversion + 150
				WriteLine(CCDFile, "PLBA=" + CueFile.Sector) 'Seems to just be the sector count for TRACK AUDIO, INDEX 1
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
			WriteLine(CCDFile, "INDEX " + CueFile.Index + "=" + CueFile.Sector)
		Next
		CloseFile(CCDFile)
		Print "Done writing CCD!"
		
		'Alright, now lets make a modified cue
		Print "Creating modified CUE"
		CUE.EditBinPath(CuePath, BaseName:String + ".img", "CCD\" + BaseName:String + "\" + BaseName:String + ".cue")
		Print "Done writing CUE!"
		
		'Copy the image under the new name
		Print "Copying image (This will take a moment)"
		CopyFile(CUE.BinPath:String + CUE.BinaryFN, "CCD\" + BaseName:String + "\" + BaseName:String + ".img")
		
		'Time to run psxt001z
		GenSub("CCD\" + BaseName:String + "\" + BaseName:String + ".sub", TotalSectors:Int)
		
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
			Print "LibCrypt .SBI/.LSD patches not found in CUE directory! Ignoring patching..."
			
			'Load the subchannel
			Local Subchannel:TBank = LoadBank("CCD\" + BaseName + "\" + BaseName + ".sub")
			If Not(Subchannel) Then RuntimeError("Error loading subchannel!") 'Did it load?
			GenSubCDDA(Subchannel) 'Run the SUB audio tracks function
			SaveBank(Subchannel, "CCD\" + BaseName:String + "\" + BaseName + ".sub") 'Save the modified SUB
		EndIf
		
		
		Print "Done converting!"
		Print "Everything exported to: '" + "CCD\" + BaseName + "\'"
		Delay 2000
	Default 'No arguments
		Print "Missing command line!"
		Print ""
		Print "SBITools.exe -sbi cuefile subchannel.sbi"
		Print "SBITools.exe -lsd cuefile subchannel.lsd"
		Print "SBITools.exe -cue2ccd cuefile"
		Print ""
		Print "Definitions:"
		Print "-sbi: Patches an images subchannel with a .SBI file."
		Print "-lsd: Patches an images subchannel with a .LSD file."
		Print "-cue2ccd: Converts a 'BIN/CUE/SBI|LSD' setup into a 'IMG/CCD/CUE/SUB' setup."
		Print "    This makes burning LibCrypt games easily possible with software such"
		Print "    as CloneCD"
		Print ""
		Print "Examples:"
		Print "SBITools.exe -sbi " + Chr(34) + "C:\CoolGameRips\VRally2.CUE" + Chr(34) + " " + Chr(34) + "C:\CoolGameRips\sbipatches\V-Rally - Championship Edition 2 (Europe) (En,Fr,De).sbi" + Chr(34)
		Print ""
		Print "SBITools.exe -lsd " + Chr(34) + "C:\CoolGameRips\MediEvil.CUE" + Chr(34) + " " + Chr(34) + "C:\CoolGameRips\sbipatches\MediEvil (Europe).lsd" + Chr(34)
		Print ""
		Print "SBITools.exe -cue2ccd " + Chr(34) + "C:\CoolGameRips\MediEvil.CUE" + Chr(34)
		Delay 1000
End Select
