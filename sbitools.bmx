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
		'4801107 = [SUB ] header
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
				
				'Dummy byte, it will always be 01 (maybe, I was reading the psxt001z SRC)
				'If it's not, it must of misaligned somehow
				If(ReadByte(SBIFile:TStream) <> 1)
					RuntimeError("Odd contents in SBI file!")
				endif
				
				'The next 10 bytes are the replacement bytes
				For Local i = 0 To 10 - 1
					'Get the byte, and replace the destination part in the .SUB with the offsets above.
					Local Replacement:Byte = ReadByte(SBIFile:TStream)
					PokeByte(SUB:TBank, ReplaceOffset:Int + i, Replacement:Byte)
				Next
				Print "Replaced 10 byte subchannel at MSF: " + SBI_Minutes:Int + ":" + SBI_Seconds:Int + ":" + SBI_Frames:Int + " (sector: " + SectorMSF:Int + ") at offset: " + Hex(ReplaceOffset:Int)
			Wend
			Print "Finished!"
			Delay 2000
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
					PokeByte(SUB:TBank, ReplaceOffset:Int + i, Replacement:Byte)
				Next
				Print "Replaced 12 byte subchannel at MSF: " + LSD_Minutes:Int + ":" + LSD_Seconds:Int + ":" + LSD_Frames:Int + " (sector: " + SectorMSF:Int + ") at offset: " + Hex(ReplaceOffset:Int)
			Wend
			Print "Finished!"
			Delay 2000
		Else
			RuntimeError("Not a valid LSD file.")
		EndIf
	Else
		RuntimeError("Not a valid SUB file.")
	EndIf
End Function

Function GenSub(FileName:String, Sectors:Int)
	'For some reason BMX can't start psxt001z directly
	Print "Generating blank .SUB with psxt001z"
	Local psxtoolz:TProcess = CreateProcess:TProcess("cmd /c psxt001z --sub " + FileName:String + " " + Sectors:Int)
	While(ProcessStatus(psxtoolz:TProcess) = 1)
		Delay 1000
	Wend
End Function

'Main Program
Print "SBITools v0.1 - http://kippykip.com"
Global Prog:Int = 0

'Are there arguments?
If(Len(AppArgs) > 1)
	If(AppArgs[1] = "-sbi" And Len(AppArgs) >= 5)
		Prog:Int = 1
	ElseIf(AppArgs[1] = "-lsd" And Len(AppArgs) >= 5)
		Prog:Int = 2
	EndIf
EndIf

Select Prog
	
	Case 1 'SBI to SUB
		'Safeguards
		If(FileType(AppArgs[2]) <> 1) Then RuntimeError("Image doesn't exist!")
		If(FileType(AppArgs[3]) <> 1) Then RuntimeError("SBI subchannel doesn't exist!")
		If(FileType(AppArgs[4])) Then DeleteFile(AppArgs[4])
		If(FileType("psxt001z.exe") <> 1) Then RuntimeError("psxt001z.exe is missing! Please download it from GitHub")
		'Get the sector count
		Local Sectors:Int = GetSectorsBySize(Int(FileSize(AppArgs[2])))
		Print "Image contains " + Sectors:Int + " sectors..."
		'Launch psxt001z with the following arguments
		GenSub(AppArgs[4], Sectors:Int)
		'Load it
		Local Subchannel:TBank = LoadBank(AppArgs[4])
		If Not(Subchannel) Then RuntimeError("Error reading created .SUB subchannel...")
		'Launch the conversion function
		SBIToSub(AppArgs[3], Subchannel)
		SaveBank(Subchannel, AppArgs[4])
		'Hopefully everything worked
	Case 2 'LSD to SUB
		'Safeguards
		If(FileType(AppArgs[2]) <> 1) Then RuntimeError("Image doesn't exist!")
		If(FileType(AppArgs[3]) <> 1) Then RuntimeError("LSD subchannel doesn't exist!")
		If(FileType(AppArgs[4])) Then DeleteFile(AppArgs[4])
		If(FileType("psxt001z.exe") <> 1) Then RuntimeError("psxt001z.exe is missing! Please download it from GitHub")
		'Get the sector count
		Local Sectors:Int = GetSectorsBySize(Int(FileSize(AppArgs[2])))
		Print "Image contains " + Sectors:Int + " sectors..."
		'Launch psxt001z with the following arguments
		GenSub(AppArgs[4], Sectors:Int)
		'Load it
		Local Subchannel:TBank = LoadBank(AppArgs[4])
		If Not(Subchannel) Then RuntimeError("Error reading created .SUB subchannel...")
		'Launch the conversion function
		LSDToSub(AppArgs[3], Subchannel)
		SaveBank(Subchannel, AppArgs[4])
		'Hopefully everything worked
	Default 'No arguments
		Print "Missing command line!"
		Print ""
		Print "SBITools.exe -sbi image.(bin/img) subchannel.sbi subchannel.sub"
		Print "SBITools.exe -lsd image.(bin/img) subchannel.lsd subchannel.sub"
		Print ""
		Print "Example:"
		'Chr:String(34) is a double quote.
		Print "SBITools.exe -sbi MediEvil.bin " + Chr:String(34) + "MediEvil (Europe).sbi" + Chr:String(34) + " MediEvil.sub"
		Delay 4000
End Select