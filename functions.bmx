'PS1 Discs are stored in MODE2, meaning they have 2352 bytes per sector.
Function GetSectorsBySize(Size:Int)
	Return Size / 2352
End Function

'Minutes, Seconds, Frames to Sector number
Function MSFToSector:Int(Minutes:Int, Seconds:Int, Frames:Int)
	'75 frames in a second for CD Audio, for some reason.
	Local Calc:Int = Minutes * 60 * 75 + Seconds:Int * 75 + Frames:Int
	Return Calc
End Function

Function SectorToMSF:Int[] (Sector:Int)
	Local MSF:Int[3]
	Local Minutes:Int = (Sector / 60 / 75)
	Local Seconds:Int = ((Sector - Minutes * 60 * 75) / 75)
	Local Frames:Int = (Sector - Minutes * 60 * 75 - Seconds * 75)
	MSF:Int[0] = Minutes:Int
	MSF:Int[1] = Seconds:Int
	MSF:Int[2] = Frames:Int
	Return MSF
End Function

Function NumberToHexMSF:Byte(Number:Int)
	Local HexStr:String = "$000000"
	If(Number:Int <= 9)
		HexStr:String = HexStr:String + "0" + Number
	Else
		HexStr:String = HexStr:String + Number
	EndIf
	Return Byte(HexStr.ToInt())
End Function

'Converts a Sector to a byte offset for a .SUB file
Function SectorToSUBOffset:Int(Sector:Int)
	'.SUB files have 96 bytes in each sector, with a 12 byte FF'd header at the beginning.
	'Subtracting 150 is for the 2 second lead-in they have, for whatever reason.
	'http://forum.imgburn.com/index.php?/topic/2122-how-to-convert-mmssff-to-bytes/&do=findComment&comment=25842
	Return (Sector - 150) * 96 + 12
End Function

'Patches a .SUB file with a SBI
Function SBIToSub(SBIPath:String, SUB:TBank)
	Local SBIFile:TStream = ReadFile(SBIPath:String)
	
	'Did the SUB file load?
	If(SUB:TBank)
		'4801107 = [SUB\0] header as an int
		If(SBIFile:TStream And ReadInt(SBIFile) = 4801107)
			While Not Eof(SBIFile:TStream)
				Local SBI_Minutes:Int
				Local SBI_Seconds:Int
				Local SBI_Frames:Int
				
				'Next 3 bytes are the MSF. For some reason the true number is stored in raw HEX.
				'Thankfully BMX can convert from HEX strings to numbers easily.
				SBI_Minutes:Int = Int(Hex(ReadByte(SBIFile:TStream)))
				SBI_Seconds:Int = Int(Hex(ReadByte(SBIFile:TStream)))
				SBI_Frames:Int = Int(Hex(ReadByte(SBIFile:TStream)))
				
				'Convert that MSF to a Sector
				Local SectorMSF:Int = MSFToSector(SBI_Minutes:Int, SBI_Seconds:Int, SBI_Frames:Int)
				'Get the offset that the SBI will replace in the SUB file
				Local ReplaceOffset:Int = SectorToSUBOffset(SectorMSF)
				
				'Dummy byte, it will always be 01 (maybe, I was reading the psxt001z SRC afterall)
				'If it's not, it must of misaligned somehow
				If(ReadByte(SBIFile:TStream) <> 1)
					RuntimeError("Odd contents in SBI file!")
				endif
				
				'The next 10 bytes are the replacement QSUB bytes
				Local QSub:Byte[10]
				For Local i = 0 To 10 - 1
					'Get the byte, and replace the destination part in the .SUB with the offsets above.
					Local Replacement:Byte = ReadByte(SBIFile:TStream)
					PokeByte(SUB, ReplaceOffset + i, Replacement)
					QSub[i] = Replacement
				Next
				Print "Replaced 10 byte QSUB at MSF: " + SBI_Minutes:Int + ":" + SBI_Seconds:Int + ":" + SBI_Frames:Int + " (sector: " + SectorMSF:Int + ") at offset: " + Hex(ReplaceOffset:Int)
				
				'Now we have to recalculate the CRC16 if we want to make all the games fully work.
				'Although stupidly, the modified CRC16 on LibCrypt games are not included in SBIs, and different LibCrypt games generate them differently
				'Lets assume it needs recalculating, with a 0080 XOR, although some use 8001 but there's no way to easily check. Why did they make this a standard?
				Local SUB_CRC16:Short = CRC16(QSub)
				'0080 XOR is whatmost LibCrypt games use according to ReDump
				Local SUB_CRCA:Byte = (SUB_CRC16 + $0080) Shr 8
				Local SUB_CRCB:Byte = (SUB_CRC16 + $0080) - (SUB_CRCA Shl 8)
				'Have to do it this way as PokeShort will reverse to little endian or something
				PokeByte(SUB, ReplaceOffset:Int + 10, SUB_CRCA)
				PokeByte(SUB, ReplaceOffset:Int + 11, SUB_CRCB)
				Print "Added 2 byte LibCrypt CRC16 to QSUB with a value of: " + Right(Hex(SUB_CRC16:Short + $0080), 4)
			Wend
			'Run the SUB audio tracks function
			GenSubCDDA(SUB)
			Print "Finished SBI -> SUB Patching!"
		Else
			RuntimeError("Not a valid SBI file.")
		EndIf
	Else
		RuntimeError("Not a valid SUB file.")
	EndIf
End Function

'Patches a .SUB file with a LSD
Function LSDToSub:TBank(LSDPath:String, SUB:TBank)
	Local LSDFile:TStream = ReadFile(LSDPath:String)
	
	'Did the SUB file load?
	If(SUB:TBank)
		'4801107 = [SUB ] header
		If(LSDFile:TStream)
			While Not Eof(LSDFile:TStream)
				Local LSD_Minutes:Int
				Local LSD_Seconds:Int
				Local LSD_Frames:Int
				
				'Next 3 bytes are the MSF. For some reason the true number is stored in raw HEX.
				'Thankfully BMX can convert from HEX strings to numbers easily.
				LSD_Minutes:Int = Int(Hex(ReadByte(LSDFile:TStream)))
				LSD_Seconds:Int = Int(Hex(ReadByte(LSDFile:TStream)))
				LSD_Frames:Int = Int(Hex(ReadByte(LSDFile:TStream)))
				
				'Convert that MSF to a Sector
				Local SectorMSF:Int = MSFToSector(LSD_Minutes:Int, LSD_Seconds:Int, LSD_Frames:Int)
				'Get the offset that the LSD will replace in the SUB file
				Local ReplaceOffset:Int = SectorToSUBOffset(SectorMSF)
				
				'The next 10 bytes are the replacement bytes
				For Local i = 0 To 12 - 1
					'Get the byte, and replace the destination part in the .SUB with the offsets above.
					Local Replacement:Byte = ReadByte(LSDFile:TStream)
					PokeByte(SUB, ReplaceOffset:Int + i, Replacement:Byte)
				Next
				Print "Replaced 12 byte subchannel at MSF: " + LSD_Minutes:Int + ":" + LSD_Seconds:Int + ":" + LSD_Frames:Int + " (sector: " + SectorMSF:Int + ") at offset: " + Hex(ReplaceOffset:Int)
			Wend
			'Run the SUB audio tracks function
			GenSubCDDA(SUB)
			Print "Finished LSD -> Patching!"
		Else
			RuntimeError("Not a valid LSD file.")
		EndIf
	Else
		RuntimeError("Not a valid SUB file.")
	EndIf
End Function

'Generates SUB information about all the CD tracks
Function GenSubCDDA(SUB:TBank)
	Local TotalTracks:Int = CUE.CountCDDA
	If(TotalTracks > 0)
		Print "Adding CD Audio track data to subchannel"
		Local ReplaceOffset:Int
		
		'We need to get the offset to start writing the leadin and tracks
		'Although we gotta loop through our CUE list to find it
		For Local CueFile:CUE = EachIn CUE.List:TList
			If(CueFile.TrackType = "AUDIO")
				If(CueFile.Track = 2 And CueFile.Index = 1) 'We'll use index one so we can use SectorToSUBOffset
					ReplaceOffset:Int = SectorToSUBOffset(CueFile.Sector)
				EndIf
			EndIf
		Next
		
		'Track 2 is also where the audio starts
		For Local CDDA_TrackID:Int = 2 To TotalTracks + 1 ' Have to add one so it does the final track (As TotalTracks doesn't count the data one)
			'Start generating the reversal like 2 second lead-in part at the beginning of the CDDA audio soundtrack
			Print "Adding '2 second lead-in' for Track: " + CDDA_TrackID
			For Local i = 0 To 150 - 1
				Local Countdown:Int = 150 - i
				Local CountdownMSF:Int[] = SectorToMSF(Countdown)
				Local BinarySeconds:Byte = CountdownMSF[1]
				Local BinaryFrames:Byte = CountdownMSF[2]
				Local QSub:Byte[10]
				
				'Change the QSUB header, XxxCD means countdown
				'[01] [TrackID] [00] [MinCD] [SecCD] [FraCD] [00] [Minutes] [Seconds] [Frame] [CRC16]-[CRC16]
				PokeByte(SUB, ReplaceOffset + (i * 96), 1)
				PokeByte(SUB, ReplaceOffset + (i * 96) + 1, NumberToHexMSF(CDDA_TrackID)) 'Track
				PokeByte(SUB, ReplaceOffset + (i * 96) + 2, 0)
				PokeByte(SUB, ReplaceOffset + (i * 96) + 3, 0) 'MinCD, Eh just put zero, the leadin will never have minutes
				PokeByte(SUB, ReplaceOffset + (i * 96) + 4, NumberToHexMSF(BinarySeconds)) 'SecCD, Seconds Countdown
				PokeByte(SUB, ReplaceOffset + (i * 96) + 5, NumberToHexMSF(BinaryFrames)) 'FraCD, Frames Countdown
				
				'Fill the QSUB array and CRC16 it
				QSub[0] = PeekByte(SUB, ReplaceOffset + (i * 96))
				QSub[1] = PeekByte(SUB, ReplaceOffset + (i * 96) + 1)
				QSub[2] = PeekByte(SUB, ReplaceOffset + (i * 96) + 2)
				QSub[3] = PeekByte(SUB, ReplaceOffset + (i * 96) + 3)
				QSub[4] = PeekByte(SUB, ReplaceOffset + (i * 96) + 4)
				QSub[5] = PeekByte(SUB, ReplaceOffset + (i * 96) + 5)
				QSub[6] = PeekByte(SUB, ReplaceOffset + (i * 96) + 6)
				QSub[7] = PeekByte(SUB, ReplaceOffset + (i * 96) + 7)
				QSub[8] = PeekByte(SUB, ReplaceOffset + (i * 96) + 8)
				QSub[9] = PeekByte(SUB, ReplaceOffset + (i * 96) + 9)
				
				Local SUB_CRC16:Short = CRC16(QSub)
				Local SUB_CRCA:Byte = SUB_CRC16 Shr 8
				Local SUB_CRCB:Byte = SUB_CRC16 - (SUB_CRCA Shl 8)
				
				PokeByte(SUB, ReplaceOffset + (i * 96) + 10, SUB_CRCA)
				PokeByte(SUB, ReplaceOffset + (i * 96) + 11, SUB_CRCB)
			Next
			
			'Alright, lets add actual CD Audio track data to the subchanel
			ReplaceOffset = ReplaceOffset + (150 * 96) 'Start on the part after the leadin
			'[01] [TrackID] [01] [Minutes] [Seconds] [Frame] [00] [Minutes Index1/Unchanged] [Seconds Index1/Unchanged] [Frame Index1/Unchanged] [CRC16]
			
			Local TrackA:CUE
			Local TrackB:CUE
			Local QSub:Byte[10]
			Print "Adding timecode data for Track: " + CDDA_TrackID
					
			'Lets get the important tracks, so we can calculate the size after
			For Local CueFile:CUE = EachIn CUE.List:TList
				If(CueFile.TrackType = "AUDIO")
					If(CueFile.Track = CDDA_TrackID:Int And CueFile.Index = 1) 'If it = CurrentTrack Index 1
						TrackA:CUE = CueFile:CUE
					ElseIf(CueFile.Track = CDDA_TrackID:Int + 1 And CueFile.Index = 0) 'If it = the one after the Current Track at Index 0
						TrackB:CUE = CueFile:CUE
					EndIf
				EndIf
			Next
			
			'Check if we're on the last track, then we can get the sector difference 
			Local SectorSize:Int
			If(CDDA_TrackID < TotalTracks + 1)
				SectorSize:Int = TrackB.Sector - TrackA.Sector
			Else
				SectorSize:Int = (BankSize(SUB) / 96) - TrackA.Sector
			EndIf
			
			For Local i = 0 To SectorSize - 1
				PokeByte(SUB, ReplaceOffset + (i * 96), 1) 'Just a 1
				PokeByte(SUB, ReplaceOffset + (i * 96) + 1, NumberToHexMSF(CDDA_TrackID)) 'Track ID
				PokeByte(SUB, ReplaceOffset + (i * 96) + 2, 1) 'Looks like after the reverse lead-in thing, this is now always a 1
				
				'Alright lets write the MSF of the current sector
				Local MSF[] = SectorToMSF(i)
				'Now write it!
				PokeByte(SUB, ReplaceOffset + (i * 96) + 3, NumberToHexMSF(MSF[0])) 'Minutes
				PokeByte(SUB, ReplaceOffset + (i * 96) + 4, NumberToHexMSF(MSF[1])) 'Seconds
				PokeByte(SUB, ReplaceOffset + (i * 96) + 5, NumberToHexMSF(MSF[2])) 'Frames
				
				'Fill the QSub array and CRC16 it
				QSub[0] = PeekByte(SUB, ReplaceOffset + (i * 96))
				QSub[1] = PeekByte(SUB, ReplaceOffset + (i * 96) + 1)
				QSub[2] = PeekByte(SUB, ReplaceOffset + (i * 96) + 2)
				QSub[3] = PeekByte(SUB, ReplaceOffset + (i * 96) + 3)
				QSub[4] = PeekByte(SUB, ReplaceOffset + (i * 96) + 4)
				QSub[5] = PeekByte(SUB, ReplaceOffset + (i * 96) + 5)
				QSub[6] = PeekByte(SUB, ReplaceOffset + (i * 96) + 6)
				QSub[7] = PeekByte(SUB, ReplaceOffset + (i * 96) + 7)
				QSub[8] = PeekByte(SUB, ReplaceOffset + (i * 96) + 8)
				QSub[9] = PeekByte(SUB, ReplaceOffset + (i * 96) + 9)
				
				Local SUB_CRC16:Short = CRC16(QSub)
				Local SUB_CRCA:Byte = SUB_CRC16 Shr 8
				Local SUB_CRCB:Byte = SUB_CRC16 - (SUB_CRCA Shl 8)
				
				PokeByte(SUB, ReplaceOffset + (i * 96) + 10, SUB_CRCA)
				PokeByte(SUB, ReplaceOffset + (i * 96) + 11, SUB_CRCB)
			Next		
			'Move the ReplaceOffset position
			ReplaceOffset = ReplaceOffset + (SectorSize * 96)
		Next
		Print "Finished adding CD Audio subchannel data!"
	EndIf
End Function

Function GenSub(FileName:String, Sectors:Int)
	'For some reason BMX can't start psxt001z directly
	Print "Generating blank .SUB with psxt001z"
	If(FileType("psxt001z.exe") <> 1) Then RuntimeError("psxt001z.exe is missing! Please download it from GitHub")
	'If the subchannel already exists, delete it.
	'Psxt001z doesn't override it
	If(FileType(FileName:String)) Then DeleteFile(FileName:String)
	Local psxtoolz:TProcess = CreateProcess:TProcess("cmd /c psxt001z --sub " + Chr(34) + FileName:String + Chr(34) + " " + Sectors:Int)

	While(ProcessStatus(psxtoolz:TProcess) = 1)
		Delay 1000
	Wend
End Function

'Cue Type
Type CUE
	Global List:TList = CreateList()
	Global BinaryFN:String
	Global BinPath:String
	Field Track:Int
	Field TrackType:String
	Field Index:Int
	Field MSF:Int[3]
	Field Sector:Int
	
	'Add a track index
	Function AddListing(Track:Int, TrackType:String, Index:Int, Minutes:Int, Seconds:Int, Frames:Int)
		Local CUETrack:CUE = New CUE
		CUETrack.Track = Track
		CUETrack.TrackType = TrackType
		CUETrack.Index = Index
		CUETrack.MSF[0] = Minutes
		CUETrack.MSF[1] = Seconds
		CUETrack.MSF[2] = Frames
		CUETrack.Sector = MSFToSector(Minutes, Seconds, Frames)
		ListAddLast(List:TList, CUETrack)
	EndFunction
	Function AddCue(CuePath:String)
		'Open the file
		Local CueFile:TStream = ReadFile(CuePath:String)
		'Did it load?
		If(CueFile)
			Local CurrentTrack:Int = 0
			Local CurrentTrackType:String
			
			'Barry: What? What is this...?			
			'Jill: What is it?
			'Barry: A CUE!
			'Barry: Jill, see if you can't find any other CUES, I'll be examining this...
			'Barry: I hope this is not a BIN file!
			If(ReadByte(CueFile) = 0)
				RuntimeError("This doesn't seem to be a cue file!")
			Else
				SeekStream(CueFile, 0) 'Go back to the start.
			EndIf
			
			While Not(Eof(CueFile))
				Local Line:String = Upper(ReadLine(CueFile))

				'Remove any spaces at the beginning
				While(Line.StartsWith(" "))
					Line = Right(Line, Len(Line) - 1)
				Wend
				
				'This is the header
				If(Line.StartsWith("FILE"))
					'Check for Multi BIN, cuesheets
					If(BinaryFN = Null)
						Local Split:String[] = Line.Split(Chr(34)) 'Split the quotes
						BinaryFN = Split[1] 'Set the filename the CUE links to in our global
					Else
						RuntimeError("SBITools currently doesn't support multi track .BIN files") 'TODO
					EndIf
				ElseIf(Line.StartsWith("TRACK"))
					Local Split:String[] = Line.Replace("  ", " ").Split(" ") 'Split the spaces, get rid of most duplicate spaces if there are any
					'Set the current track and track type for when the next loop happens
					CurrentTrack = Int(Split[1])
					CurrentTrackType = Split[2]
					'AddListing
				ElseIf(Line.StartsWith("INDEX"))
					Local Split:String[] = Line.Split(" ") 'Split the spaces
					Local MSF:String[] = Split[2].Split(":") 'Split the colons from the MSF XX:XX:XX
					AddListing(CurrentTrack, CurrentTrackType, Int(Split[1]), Int(MSF[0]), Int(MSF[1]), Int(MSF[2]))
				EndIf
			Wend
			'Done using this file
			CloseFile(CueFile)
		Else
			RuntimeError(".CUE file doesn't exist!")
		EndIf
	End Function
	'Counts all the tracks, excluding the data track.
	Function CountCDDA:Int()
		Local TrackCount:Int = 0
		For Local CueFile:CUE = EachIn CUE.List:TList
			If(CueFile.Index = 0)
				TrackCount:Int = TrackCount:Int + 1
			EndIf
		Next
		Return TrackCount:Int
	End Function
	Function EditBinPath(CuePath:String, NewBinPath:String, ExportPath:String)
		Local NewCueFile:TStream = WriteFile(ExportPath:String)
		Local CueFile:TStream = ReadFile(CuePath:String)
		'Did it work?
		If(NewCueFile)
			If(CueFile)
				While Not(Eof(CueFile))
					Local Line:String = Upper(ReadLine(CueFile))
					'Is it the FILE header?
					If(Line.StartsWith("FILE"))
						'Change the path
						WriteLine(NewCueFile:TStream, "FILE " + Chr(34) + NewBinPath:String + Chr(34) + " BINARY")
					Else 'Otherwise just write what was on the old one
						WriteLine(NewCueFile:TStream, Line:String)
					EndIf
				Wend
				'Free them from memory
				CloseFile(CueFile)
				CloseFile(NewCueFile)
			Else
				RuntimeError("Couldn't find .CUE file")
			EndIf
		Else
			RuntimeError("Error creating new .CUE file")
		EndIf
	End Function
	
	'Lets get the path to the .BIN file, or .IMG, whatever using the CUE's BaseName + FDRPath array, or by any means possible.
	Function GetBinPath:String(FDRPath:String[])
		'This just gets the name of the cue. Say if it was "C:\CoolGame.cue", this would return "CoolGame"
		Local BaseName:String = Left(FDRPath[Len(FDRPath) - 1], Len(FDRPath[Len(FDRPath) - 1]) - 4)
		
		'Sometimes in rare cases .CUE files contain the full path to the file, or maybe it could reside next to this very SBITools, lets check for that first
		'Therefore does the Binary file exist with the exact path written in the cue? - Most likely not but lets check anyway
		If(FileType(CUE.BinaryFN) = 1)
			CUE.BinPath:String = CUE.BinaryFN
		Else 'Nope it didn't, lets search it the proper way
			For Local i = 0 To Len(FDRPath:String[]) - 2 'Take 1 so it doesn't overflow, take another to remove the CUE filename for this string.
				CUE.BinPath:String = CUE.BinPath:String + FDRPath:String[i] + "\"
			Next
		EndIf
		'Still couldn't find it after all that subfolder searching?
		If(FileType(BinPath + CUE.BinaryFN) <> 1)
			'Then maybe the user renamed both files without editing inside the .CUE
			'Lets try looking for it with the BaseName variable (what the .cue is called before the extension)
			If(FileType(BinPath + BaseName + ".bin") <> 1) 'Does it exist as a bin?
				CUE.BinaryFN = BinPath + BaseName + ".bin"
			ElseIf(FileType(BinPath + BaseName + ".img") <> 1)	'Or maybe as a img even? 
				CUE.BinaryFN = BinPath + BaseName + ".img"
			Else
				RuntimeError("Can't find the .BIN/.IMG image file anywhere!")
			EndIf
		EndIf
		Return BaseName 'Return the BaseName because it's very useful
	EndFunction
	
	'Resets everything
	Function Clean()
		BinaryFN:String = Null
		BinPath:String = Null
		ClearList(List:TList)
	End Function
EndType
