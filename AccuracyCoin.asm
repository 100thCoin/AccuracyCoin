	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;              AccuracyCoin               ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	; This ROM is a collection of accuracy tests on an NROM cartridge.
	; NOTE: While most of these tests are universal to all revisions of the NES board, CPU, and PPU, there are a handful of tests that are not going to pass on all revisions.
	; To be more specific, these tests were designed for an RP2A03G APU/CPU, and an RP2C02G PPU.
	; Additionally, if you run this ROM on your console with a flash cart, you might fail some tests. Notably, the open bus tests fail on an Everdrive N8 Pro.
	
	; If you are looking for a specific test, consider CRTL + F searching for "TestPages:", as thats where the list of tests is.
	; The format for the tests as they are stored in the ROM is:
	; table "Name of test", $FF, Address_To_Store_Test_Results, Address_To_Jump_To_In_Order_To_Run_The_Test
	; so to easily find the code for a test, you can search for the "Address_To_Jump_To_In_Order_To_Run_The_Test:" routine for a given test.
	
	; NOTE: The NMI and IRQ vectors both point to RAM. This allows me to create tests that have different NMI/IRQ routines.
	
	;;;; HEADER AND COMPILER STUFF ;;;;
	.inesprg 2  ; 2 banks
	.ineschr 1  ; 
	.inesmap 0  ; mapper 0 = NROM
	.inesmir 1  ; background mirroring, vertical
	;;;; CONSTANTS ;;;;	

flag_c = $1
flag_z = $2
flag_i = $4
flag_d = $8
flag_v = $40
flag_n = $80	
	
byte0 = $0
byte1 = $1
byte2 = $2
byte3 = $3

suitePointer = $5
dontSetPointer = $7

byte8 = $8
byte9 = $9

byteF = $F; immediate use. Store something here and use it in the same function. If a JSR happens, assume this value is stale.
currentSubTest = $10
initialSubTest = $11
result_DMADMASync_PreTest = $12
menuTabXPos = $14
menuCursorXPos = $15
menuCursorYPos = $16
menuHeight = $17
controller = $18
controller_New = $19
JSRFromRAM = $1A
JSRFromRAM1 = $1B
JSRFromRAM2 = $1C
JSRFromRAM3 = $1D

TestResultPointer = $1E

Test_UnOp_OperandTargetAddrLo = $20
Test_UnOp_OperandTargetAddrHi = $21
Test_UnOp_ValueAtAddressForTest = $22
Test_UnOp_A = $23
Test_UnOp_X = $24
Test_UnOp_Y = $25
Test_UnOp_FlagsInit = $26
Test_UnOp_SP = $27
Test_UnOp_ExpectedResultAddrLo = $28
Test_UnOp_ExpectedResultAddrHi = $29
Test_UnOp_ValueAtAddressResult = $2A
Test_UnOp_CMP = $2B
Test_UnOp_CPX = $2C
Test_UnOp_CPY = $2D
Test_UnOp_CM_Flags = $2E
Test_UnOp_CPS = $2F
Test_UnOp_IndirectPointerLo = $30
Test_UnOp_IndirectPointerHi = $31
Test_UnOp_CycleDelayPostDMA = $32

HighlightTextPrinted = $33
AutomateTestSuite = $34
RunningAllTests = $35
PostAllTestScreen = $36
PostAllTestTally = $37
PostAllPassTally = $38
PrintDecimalTensCheck = $39
result_VblankSync_PreTest = $3A
DebugMode = $3B

Reserverd_41 = $41 ; Used in the Implied Dummy Reads. It's probably best we never actually use this.

PostDMACyclesUntilTestInstruction = 14


Test_ZeroPageReserved = $50 ; through $5F
Test_ZeroPageReserved2 = $60 ; through $6F (rarely used, but let's still avoid putting engine stuff here.)


TESTHighlightTextCopy = $7A

suiteAttributeCopy = $7E

suitePointerList = $80

suiteExecPointerList = $A0

Reserverd_C1 = $C1 ; Used in the Implied Dummy Reads. It's probably best we never actually use this.


Reserved_C8 = $C8; For my "unofficial opcodes are correct length" tests, I use [Two-Byte-Opcode][INY], and then check the value of Y. Since INY is $C8, I'd like to avoid corrupting something stored in byte C8.

Reserverd_E1 = $E1 ; Used in the Implied Dummy Reads. It's probably best we never actually use this.


Copy_X2 = $ED	; These are exclusively used to keep registers from before RunTest from being modified during a test, so they can be restored after the test.
Copy_Y2 = $EE	; ^
Copy_A2 = $EF	; ^

PPUCTRL_COPY = $F0
PPUMASK_COPY = $F1

Copy_SP = $FA
Copy_SP2 = $FB
Copy_Flags = $FC
Copy_X = $FD
Copy_Y = $FE
Copy_A = $FF


PowerOnRAM = $300
PowerOnVRAM = $320
PowerOnPalette = $340
PowerOnTest_PPUReset = $360 ; 1 byte. Pass/fail the PPU Reset flag test.
PowerOn_A = $370
PowerOn_X = $371
PowerOn_Y = $372
PowerOn_SP = $373
PowerOn_P = $374

result_Unimplemented = $0400
result_CPUInstr = $0401
result_UnofficialInstr = $0402
result_RAMMirror = $0403
result_PPURegMirror = $0404
result_ROMnotWritable = $0405
result_DummyReads = $0406
result_DummyWrites = $0407
result_OpenBus = $0408

result_UnOp_SLO_03 = $409
result_UnOp_SLO_07 = $40A
result_UnOp_SLO_0F = $40B
result_UnOp_SLO_13 = $40C
result_UnOp_SLO_17 = $40D
result_UnOp_SLO_1B = $40E
result_UnOp_SLO_1F = $40F

result_UnOp_ANC_0B	= $410
result_UnOp_ANC_2B	= $411
result_UnOp_ASR_4B	= $412
result_UnOp_ARR_6B	= $413
result_UnOp_ANE_8B	= $414
result_UnOp_LXA_AB	= $415
result_UnOp_AXS_CB	= $416
result_UnOp_SBC_EB	= $417
result_UnOp_Magic   = $3FB ; page 3 omits the test from the all-test-result-table.

result_UnOp_RLA_23 = $419
result_UnOp_RLA_27 = $41A
result_UnOp_RLA_2F = $41B
result_UnOp_RLA_33 = $41C
result_UnOp_RLA_37 = $41D
result_UnOp_RLA_3B = $41E
result_UnOp_RLA_3F = $41F

result_UnOp_SRE_43 = $420
result_UnOp_SRE_47 = $421
result_UnOp_SRE_4F = $422
result_UnOp_SRE_53 = $423
result_UnOp_SRE_57 = $424
result_UnOp_SRE_5B = $425
result_UnOp_SRE_5F = $426

result_UnOp_RRA_63 = $427
result_UnOp_RRA_67 = $428
result_UnOp_RRA_6F = $429
result_UnOp_RRA_73 = $42A
result_UnOp_RRA_77 = $42B
result_UnOp_RRA_7B = $42C
result_UnOp_RRA_7F = $42D

result_UnOp_SAX_83 = $42E
result_UnOp_SAX_87 = $42F
result_UnOp_SAX_8F = $430
result_UnOp_SAX_9F = $431
result_UnOp_LAX_A3 = $432
result_UnOp_LAX_A7 = $433
result_UnOp_LAX_AF = $434
result_UnOp_LAX_B3 = $435
result_UnOp_LAX_B7 = $436
result_UnOp_LAX_BF = $437

result_UnOp_DCP_C3 = $438
result_UnOp_DCP_C7 = $439
result_UnOp_DCP_CF = $43A
result_UnOp_DCP_D3 = $43B
result_UnOp_DCP_D7 = $43C
result_UnOp_DCP_DB = $43D
result_UnOp_DCP_DF = $43E

result_UnOp_ISC_E3 = $43F
result_UnOp_ISC_E7 = $440
result_UnOp_ISC_EF = $441
result_UnOp_ISC_F3 = $442
result_UnOp_ISC_F7 = $443
result_UnOp_ISC_FB = $444
result_UnOp_ISC_FF = $445

result_UnOp_SHA_93 = $446
result_UnOp_SHA_9F = $447
result_UnOp_SHS_9B = $448
result_UnOp_SHY_9C = $449
result_UnOp_SHX_9E = $44A
result_UnOp_LAE_BB = $44B

result_DMA_Plus_2007R = $44C
result_ProgramCounter_Wraparound = $44D
result_PPUOpenBus = $044E
result_DMA_Plus_2007W = $44F

result_VBlank_Beginning = $450
result_VBlank_End = $451
result_NMI_Control = $452
result_NMI_Timing = $453
result_NMI_Suppression = $454
result_NMI_VBL_End = $455
result_NMI_Disabled_VBL_Start = $456

result_Sprite0Hit_Behavior = $457
result_ArbitrarySpriteZero = $458
result_SprOverflow_Behavior = $459
result_MisalignedOAM_Behavior = $45A
result_Address2004_Behavior = $45B
result_APURegActivation = $45C
result_DMA_Plus_4015R = $45D
result_DMA_Plus_4016R = $45E
result_ControllerStrobing = $45F

result_InstructionTiming = $460
result_IFlagLatency = $461
result_NmiAndBrk = $462
result_NmiAndIrq = $463

result_RMW2007 = $464

result_APULengthCounter = $465
result_APULengthTable = $466
result_FrameCounterIRQ = $467
result_FrameCounter4Step = $468
result_FrameCounter5Step = $469
result_DeltaModulationChannel = $46A
result_DMABusConflict = $46B
result_DMA_Plus_OpenBus = $46C

result_ImpliedDummyRead = $46D

result_AddrMode_AbsIndex = $46E
result_AddrMode_ZPgIndex = $46F
result_AddrMode_Indirect = $470
result_AddrMode_IndIndeX = $471
result_AddrMode_IndIndeY = $472
result_AddrMode_Relative = $473

result_DecimalFlag = $474
result_BFlag = $475

result_PPUReadBuffer = $476

result_PowOn_CPURAM = $03FC	; page 3 omits the test from the all-test-result-table.
result_PowOn_CPUReg = $03FD ; page 3 omits the test from the all-test-result-table.
result_PowOn_PPURAM = $03FE ; page 3 omits the test from the all-test-result-table.
result_PowOn_PPUPal = $03FF ; page 3 omits the test from the all-test-result-table.
result_PowOn_PPUReset = $0418

;$500 is dedicated to RAM needed for tests.
;$600 is dedicated to the IRQ routine
;$700 is dedicated to the NMI routine.

	;;;; ASSEMBLY CODE ;;;;
	.org $8000
	; The open bus test needs to make sure an inaccurate emulation of open bus will fall into test code, so this function here is a fail condition of the open bus test.
OpenBusTestFakedOpenBusBehavior:
	NOP	; An incorrect implementation of open bus might execute all the way to here from address $5000.
	NOP	; The two NOPS are for alignment, and this BRK takes the PC to some "test failed" handler.
	BRK	;
	
CannotWriteToROM_01:
	.byte $01; This value is used in the "Cannot write to ROM" test.
	
RESET:	; This ROM, despite the guidance of the NesDev Wiki's "startup code", writes a bunch of uninitialized registers, and reads uninitialized RAM. Intentionally.
	STA PowerOn_A	; For use in TEST_PowerOnState_CPU_Registers
	STY PowerOn_Y
	STX PowerOn_X
	TSX
	STX PowerOn_SP
	PHP
	PLA
	AND #$CF
	STA PowerOn_P
RESET_SkipPowerOnTests:

	SEI
	CLD
	LDX #$EF ; Due to some tests modifying the stack pointer, it's convenient to put it at EF instead of FF.
	TXS		 ; This prevents some tests where the resulting stack pointer is 00 from pushing data, and overwriting the bottom of the stack.
	LDA #$40
	STA $4017
TEST_PPUResetFlag:
	;;; Test 1 [PPU Reset Flag]: Are PPU Registers writable before the first pre-render line? ;;;
	; They shouldn't be, as that's the job of the PPU Reset Flag!
	; Let's see if the PPU Reset flag exists.
	LDA #$27
	STA $2006 ; "magic address"
	LDA #$BF
	STA $2006 ; PPUADDR = $27BF
	LDA #$5A ; "magic number". All over this ROM, you will frequently see me using the value $5A for tests. That's 01011010 in binary, and I just assume that if something goes wrong, it won't stumble on that number by random chance.
	STA $2007
	; Okay, I'll be back in 2 frames to check on you...
	LDX #$FF
	LDA $2002
VblLoop:
	LDA $2002
	BPL VblLoop
	INX
	BEQ VblLoop
	; Now that the PPU is responsive, let's copy the resting values.
	JSR Read32NametableBytes
	JSR ReadPaletteRAM
	
	; Let's also see if the magic number was written, to verify if the reset flag exists.
	; It's worth noting that in its current state, this test fails on my console.
	LDA #6
	STA PowerOnTest_PPUReset ; set to FAIL (error code $1) by default. Overwrite with PASS if it passes.
	LDA #$27
	STA $2006
	LDA #$BF
	STA $2006
	LDA $2007 ; load buffer
	LDA $2007 ; read buffer
	CMP #$5A
	BEQ PostResetFlagTest
	; The value of $5A was not written to VRAM, so the reset flag does exist!
	LDA #1
	STA PowerOnTest_PPUReset ; Store a passing result here.
	;; End of test ;;
PostResetFlagTest:
	
	JSR DisableRendering
	
	; With those values copied for future reference, let's overwrite the nametable.
	JSR SetUpDefaultPalette
	JSR ClearNametable
	JSR ClearRAMExceptPage3
ReloadMainMenu:
	JSR ClearPage2
	LDA #02
	STA $4014 ; Set up OAM
	
	LDA #0
	STA <dontSetPointer
	; set up the NMI routine.
	JSR SetUpNMIRoutineForMainMenu
	
	LDA #$20
	STA <JSRFromRAM
	LDA #$60
	STA <JSRFromRAM3
	
	LDA #0
	STA $100 ; initialize the placeholder test results.
	; and also initialize the "print tests" results, as these tests use page 3, which is mostly uninitilized.
	STA result_UnOp_Magic
	STA result_PowOn_CPURAM
	STA result_PowOn_CPUReg
	STA result_PowOn_PPURAM
	STA result_PowOn_PPUPal
	
	STA $6000 ; An incorrect open bus implementation might end up executing address $6000, so let's initialzie these 3 bytes to BRKs.
	STA $6001 ; Though I would prefer if this was a NES 2.0 cartridge without any PRG RAM, so writing here might do nothing anyway.
	STA $6002 ; There's still a good chance an emulator doesn't support NES 2.0 and just puts PRG RAM here anyway.
	
	JSR WaitForVBlank
	JSR TEST_VblankSync_PreTest; ; Initialize result_VblankSync_PreTest
	JSR DMASync ; Initialize result_DMADMASync_PreTest
	
	
	LDA #$FF
	STA <menuCursorYPos
	
	LDA #Low(Suite_CPUBehavior)
	STA <suitePointer
	LDA #High(Suite_CPUBehavior)
	STA <suitePointer+1
	JSR LoadSuiteMenu
	JSR DrawPageNumber
	JSR WaitForVBlank
	JSR ResetScroll
	JSR EnableRendering_BG
	JSR EnableNMI
		
InfiniteLoop:
	JMP InfiniteLoop	; This is the spinning loop while I wait for the NMI to occur.
;;;;;;;;;;;;;;;;;;;;
	
	.org $8100
	; Menu Data

	; Here is how the pages of tests are organized.
TableTable:
	.word Suite_CPUBehavior
	.word Suite_CPUInstructions
	.word Suite_UnofficialOps_SLO
	.word Suite_UnofficialOps_RLA
	.word Suite_UnofficialOps_SRE
	.word Suite_UnofficialOps_RRA
	.word Suite_UnofficialOps__AX
	.word Suite_UnofficialOps_DCP
	.word Suite_UnofficialOps_ISC
	.word Suite_UnofficialOps_SH_
	.word Suite_UnofficialOps_Immediates
	.word Suite_CPUInterrupts
	.word Suite_DMATests
	.word Suite_APUTiming
	.word Suite_PowerOnState
	.word Suite_PPUBehavior
	.word Suite_PPUTiming
	.word Suite_SpriteZeroHits
	.word Suite_PPUMisc
	.word Suite_CPUBehavior2
EndTableTable:

	; I'm not a huge fan of using macros in this ROM, since they make the asm code look different than the compiled bytes, and thus harder to debug.
	; This macro is just a series of bytes and words though, so it's not too hard to read.
table .macro
	.byte \1
	.byte \2
	.word \3
	.word \4
	.endm

TestPages:	; I just made this label for ease of searching.

	;; CPU Behavior ;;
Suite_CPUBehavior:
	.byte "CPU Behavior", $FF
	table "ROM is not writable", 	 $FF, result_ROMnotWritable, TEST_ROMnotWritable
	table "RAM Mirroring", 			 $FF, result_RAMMirror, TEST_RamMirroring
	table "PC Wraparound",           $FF, result_ProgramCounter_Wraparound, Test_ProgramCounter_Wraparound
	table "The Decimal Flag",		 $FF, result_DecimalFlag, TEST_DecimalFlag
	table "The B Flag",              $FF, result_BFlag, TEST_BFlag
	table "Dummy read cycles", 		 $FF, result_DummyReads, TEST_DummyReads
	table "Dummy write cycles", 	 $FF, result_DummyWrites, TEST_DummyWrites
	table "Open Bus", 				 $FF, result_OpenBus, TEST_OpenBus
	table "Unofficial Instructions", $FF, result_UnofficialInstr, TEST_UnofficialInstructionsExist
	.byte $FF
	
Suite_CPUInstructions:
	.byte "Addressing mode wraparound", $FF
	table "Absolute Indexed",  $FF, result_AddrMode_AbsIndex, TEST_AddrMode_AbsIndex
	table "Zero Page Indexed", $FF, result_AddrMode_ZPgIndex, TEST_AddrMode_ZPgIndex
	table "Indirect",          $FF, result_AddrMode_Indirect, TEST_AddrMode_Indirect
	table "Indirect, X",       $FF, result_AddrMode_IndIndeX, TEST_AddrMode_IndIndeX
	table "Indirect, Y",       $FF, result_AddrMode_IndIndeY, TEST_AddrMode_IndIndeY
	table "Relative",          $FF, result_AddrMode_Relative, TEST_AddrMode_Relative
	.byte $FF
	
	;; Unofficial Instructions: SLO ;;
Suite_UnofficialOps_SLO:
	.byte "Unofficial Instructions: SLO", $FF
	table "$03   SLO indirect,X", $FF, result_UnOp_SLO_03, TEST_SLO_03
	table "$07   SLO zeropage",   $FF, result_UnOp_SLO_07, TEST_SLO_07
	table "$0F   SLO absolute",   $FF, result_UnOp_SLO_0F, TEST_SLO_0F
	table "$13   SLO indirect,Y", $FF, result_UnOp_SLO_13, TEST_SLO_13
	table "$17   SLO zeropage,X", $FF, result_UnOp_SLO_17, TEST_SLO_17
	table "$1B   SLO absolute,Y", $FF, result_UnOp_SLO_1B, TEST_SLO_1B
	table "$1F   SLO absolute,X", $FF, result_UnOp_SLO_1F, TEST_SLO_1F
	.byte $FF
	
	;; Unofficial Instructions: RLA ;;
Suite_UnofficialOps_RLA:
	.byte "Unofficial Instructions: RLA", $FF
	table "$23   RLA indirect,X", $FF, result_UnOp_RLA_23, TEST_RLA_23
	table "$27   RLA zeropage",   $FF, result_UnOp_RLA_27, TEST_RLA_27
	table "$2F   RLA absolute",   $FF, result_UnOp_RLA_2F, TEST_RLA_2F
	table "$33   RLA indirect,Y", $FF, result_UnOp_RLA_33, TEST_RLA_33
	table "$37   RLA zeropage,X", $FF, result_UnOp_RLA_37, TEST_RLA_37
	table "$3B   RLA absolute,Y", $FF, result_UnOp_RLA_3B, TEST_RLA_3B
	table "$3F   RLA absolute,X", $FF, result_UnOp_RLA_3F, TEST_RLA_3F
	.byte $FF
	
	;; Unofficial Instructions: SRE ;;
Suite_UnofficialOps_SRE:
	.byte "Unofficial Instructions: SRE", $FF
	table "$43   SRE indirect,X", $FF, result_UnOp_SRE_43, TEST_SRE_43
	table "$47   SRE zeropage",   $FF, result_UnOp_SRE_47, TEST_SRE_47
	table "$4F   SRE absolute",   $FF, result_UnOp_SRE_4F, TEST_SRE_4F
	table "$53   SRE indirect,Y", $FF, result_UnOp_SRE_53, TEST_SRE_53
	table "$57   SRE zeropage,X", $FF, result_UnOp_SRE_57, TEST_SRE_57
	table "$5B   SRE absolute,Y", $FF, result_UnOp_SRE_5B, TEST_SRE_5B
	table "$5F   SRE absolute,X", $FF, result_UnOp_SRE_5F, TEST_SRE_5F
	.byte $FF
	
	;; Unofficial Instructions: RRA ;;
Suite_UnofficialOps_RRA:
	.byte "Unofficial Instructions: RRA", $FF
	table "$63   RRA indirect,X", $FF, result_UnOp_RRA_63, TEST_RRA_63
	table "$67   RRA zeropage",   $FF, result_UnOp_RRA_67, TEST_RRA_67
	table "$6F   RRA absolute",   $FF, result_UnOp_RRA_6F, TEST_RRA_6F
	table "$73   RRA indirect,Y", $FF, result_UnOp_RRA_73, TEST_RRA_73
	table "$77   RRA zeropage,X", $FF, result_UnOp_RRA_77, TEST_RRA_77
	table "$7B   RRA absolute,Y", $FF, result_UnOp_RRA_7B, TEST_RRA_7B
	table "$7F   RRA absolute,X", $FF, result_UnOp_RRA_7F, TEST_RRA_7F
	.byte $FF
	
	;; Unofficial Instructions: .AX ;;
Suite_UnofficialOps__AX:
	.byte "Unofficial Instructions: *AX", $FF
	table "$83   SAX indirect,X", $FF, result_UnOp_SAX_83, TEST_SAX_83
	table "$87   SAX zeropage",   $FF, result_UnOp_SAX_87, TEST_SAX_87
	table "$8F   SAX absolute",   $FF, result_UnOp_SAX_8F, TEST_SAX_8F
	table "$97   SAX zeropage,Y", $FF, result_UnOp_SAX_9F, TEST_SAX_97
	table "$A3   LAX indirect,X", $FF, result_UnOp_LAX_A3, TEST_LAX_A3
	table "$A7   LAX zeropage",   $FF, result_UnOp_LAX_A7, TEST_LAX_A7
	table "$AF   LAX absolute",   $FF, result_UnOp_LAX_AF, TEST_LAX_AF
	table "$B3   LAX indirect,Y", $FF, result_UnOp_LAX_B3, TEST_LAX_B3
	table "$B7   LAX zeropage,X", $FF, result_UnOp_LAX_B7, TEST_LAX_B7
	table "$BF   LAX absolute,X", $FF, result_UnOp_LAX_BF, TEST_LAX_BF
	.byte $FF
	
	;; Unofficial Instructions: DCP ;;
Suite_UnofficialOps_DCP:
	.byte "Unofficial Instructions: DCP", $FF
	table "$C3   DCP indirect,X", $FF, result_UnOp_DCP_C3, TEST_DCP_C3
	table "$C7   DCP zeropage",   $FF, result_UnOp_DCP_C7, TEST_DCP_C7
	table "$CF   DCP absolute",   $FF, result_UnOp_DCP_CF, TEST_DCP_CF
	table "$C3   DCP indirect,Y", $FF, result_UnOp_DCP_D3, TEST_DCP_D3
	table "$B7   DCP zeropage,X", $FF, result_UnOp_DCP_D7, TEST_DCP_D7
	table "$BB   DCP absolute,Y", $FF, result_UnOp_DCP_DB, TEST_DCP_DB
	table "$BF   DCP absolute,X", $FF, result_UnOp_DCP_DF, TEST_DCP_DF
	.byte $FF
	
	;; Unofficial Instructions: ISC ;;
Suite_UnofficialOps_ISC:
	.byte "Unofficial Instructions: ISC", $FF
	table "$E3   ISC indirect,X", $FF, result_UnOp_ISC_E3, TEST_ISC_E3
	table "$E7   ISC zeropage",   $FF, result_UnOp_ISC_E7, TEST_ISC_E7
	table "$EF   ISC absolute",   $FF, result_UnOp_ISC_EF, TEST_ISC_EF
	table "$F3   ISC indirect,Y", $FF, result_UnOp_ISC_F3, TEST_ISC_F3
	table "$F7   ISC zeropage,X", $FF, result_UnOp_ISC_F7, TEST_ISC_F7
	table "$FB   ISC absolute,Y", $FF, result_UnOp_ISC_FB, TEST_ISC_FB
	table "$FF   ISC absolute,X", $FF, result_UnOp_ISC_FF, TEST_ISC_FF
	.byte $FF
	
	;; Unofficial Instructions: SH_ ;;
Suite_UnofficialOps_SH_:
	.byte "Unofficial Instructions: SH*", $FF
	table "$93   SHA indirect,Y", $FF, result_UnOp_SHA_93, TEST_SHA_93
	table "$9F   SHA absolute,Y", $FF, result_UnOp_SHA_9F, TEST_SHA_9F
	table "$9B   SHS absolute,Y", $FF, result_UnOp_SHS_9B, TEST_SHS_9B
	table "$9C   SHY absolute,X", $FF, result_UnOp_SHY_9C, TEST_SHY_9C
	table "$9E   SHX absolute,Y", $FF, result_UnOp_SHX_9E, TEST_SHX_9E
	table "$BB   LAE absolute,Y", $FF, result_UnOp_LAE_BB, TEST_LAE_BB
	.byte $FF
	
	;; Unofficial Instructions: The Immediate group ;;
Suite_UnofficialOps_Immediates:
	.byte "Unofficial Immediates", $FF
	table "$0B   ANC Immediate", $FF, result_UnOp_ANC_0B, TEST_ANC_0B
	table "$2B   ANC Immediate", $FF, result_UnOp_ANC_2B, TEST_ANC_2B
	table "$4B   ASR Immediate", $FF, result_UnOp_ASR_4B, TEST_ASR_4B
	table "$6B   ARR Immediate", $FF, result_UnOp_ARR_6B, TEST_ARR_6B
	table "$8B   ANE Immediate", $FF, result_UnOp_ANE_8B, TEST_ANE_8B
	table "$AB   LXA Immediate", $FF, result_UnOp_LXA_AB, TEST_LXA_AB
	table "$CB   AXS Immediate", $FF, result_UnOp_AXS_CB, TEST_AXS_CB
	table "$EB   SBC Immediate", $FF, result_UnOp_SBC_EB, TEST_SBC_EB
	table "Print magic values",  $FF, result_UnOp_Magic, TEST_MAGIC
	.byte $FF
	
	;; CPU Interrupts ;;
Suite_CPUInterrupts:
	.byte "CPU Interrupts", $FF
	table "Interrupt flag latency", $FF, result_IFlagLatency, TEST_IFlagLatency
	table "NMI Overlap BRK", $FF, result_NmiAndBrk, TEST_NmiAndBrk
	table "NMI Overlap IRQ", $FF, result_NmiAndIrq, TEST_NmiAndIrq
	.byte $FF
	
	;; APU Timing ;;
Suite_APUTiming:
	.byte "APU Timing", $FF
	table "Length Counter", $FF, result_APULengthCounter, TEST_APULengthCounter
	table "Length Table", $FF, result_APULengthTable, TEST_APULengthTable
	table "Frame Counter IRQ", $FF, result_FrameCounterIRQ, TEST_FrameCounterIRQ
	table "Frame Counter 4-step", $FF, result_FrameCounter4Step, TEST_FrameCounter4Step
	table "Frame Counter 5-step", $FF, result_FrameCounter5Step, TEST_FrameCounter5Step
	table "Delta Modulation Channel", $FF, result_DeltaModulationChannel, TEST_DeltaModulationChannel
	.byte $FF
	
	;; DMA Tests ;;
Suite_DMATests:
	.byte "APU Registers and DMA tests", $FF	
	table "DMA + Open Bus", $FF, result_DMA_Plus_OpenBus, TEST_DMA_Plus_OpenBus
	table "DMA + $2007 Read", $FF, result_DMA_Plus_2007R, TEST_DMA_Plus_2007R
	table "DMA + $2007 Write", $FF, result_DMA_Plus_2007W, TEST_DMA_Plus_2007W
	table "DMA + $4015 Read", $FF, result_DMA_Plus_4015R, TEST_DMA_Plus_4015R
	table "DMA + $4016 Read", $FF, result_DMA_Plus_4016R, TEST_DMA_Plus_4016R
	table "Controller Strobing", $FF, result_ControllerStrobing, TEST_ControllerStrobing
	table "APU Register Activation", $FF, result_APURegActivation, TEST_APURegActivation
	table "DMC DMA Bus Conflicts", $FF, result_DMABusConflict, TEST_DMABusConflict
	.byte $FF

	;; Power On State ;;
Suite_PowerOnState:
	.byte "Power On State", $FF
	table "PPU Reset Flag", $FF, result_PowOn_PPUReset, TEST_PowerOnState_PPU_ResetFlag
	table "CPU RAM", $FF, result_PowOn_CPURAM, TEST_PowerOnState_CPU_RAM
	table "CPU Registers", $FF, result_PowOn_CPUReg, TEST_PowerOnState_CPU_Registers
	table "PPU RAM", $FF, result_PowOn_PPURAM, TEST_PowerOnState_PPU_RAM
	table "Palette RAM", $FF, result_PowOn_PPUPal, TEST_PowerOnState_PPU_Palette
	.byte $FF
	
	;; PPU Behavior ;;
Suite_PPUBehavior:
	.byte "PPU Behavior", $FF
	table "PPU Register Mirroring",  $FF, result_PPURegMirror, TEST_PPURegMirroring
	table "PPU Register Open Bus",	 $FF, result_PPUOpenBus, TEST_PPU_Open_Bus
	table "PPU Read Buffer", $FF, result_PPUReadBuffer, TEST_PPUReadBuffer
	.byte $FF
	
	;; PPU VBL Timing ;;
Suite_PPUTiming:
	.byte "PPU VBlank Timing", $FF
	table "VBlank beginning", $FF, result_VBlank_Beginning, TEST_VBlank_Beginning
	table "VBlank end", $FF, result_VBlank_End, TEST_VBlank_End
	table "NMI Control", $FF, result_NMI_Control, TEST_NMI_Control
	table "NMI Timing", $FF, result_NMI_Timing, TEST_NMI_Timing
	table "NMI Suppression", $FF, result_NMI_Suppression, TEST_NMI_Suppression
	table "NMI at VBlank end", $FF, result_NMI_VBL_End, TEST_NMI_VBL_End
	table "NMI disabled at VBlank", $FF, result_NMI_Disabled_VBL_Start, TEST_NMI_Disabled_VBL_Start
	table "Instruction Timing", 	 $FF, result_InstructionTiming, TEST_InstructionTiming
	.byte $FF
	
	;; Sprite Zero Hits ;;
Suite_SpriteZeroHits:
	.byte "Sprite Evaluation", $FF
	table "Sprite 0 Hit behavior", $FF, result_Sprite0Hit_Behavior, TEST_Sprite0Hit_Behavior
	table "Arbitrary Sprite zero", $FF, result_ArbitrarySpriteZero, TEST_ArbitrarySpriteZero
	table "Sprite overflow behavior", $FF, result_SprOverflow_Behavior, TEST_SprOverflow_Behavior
	table "Misaligned OAM behavior", $FF, result_MisalignedOAM_Behavior, TEST_MisalignedOAM_Behavior
	table "Address $2004 behavior", $FF, result_Address2004_Behavior, TEST_Address2004_Behavior
	.byte $FF
	
	;; PPU Misc ;;
Suite_PPUMisc:
	.byte "PPU Misc.", $FF
	table "RMW $2007 Extra Write", $FF, result_RMW2007, TEST_RMW2007
	;table "Palette Corruption", $FF, result_Unimplemented, DebugTest
	.byte $FF
	
Suite_CPUBehavior2:
	.byte "CPU Behavior 2", $FF
	table "Implied Dummy Reads",	 $FF, result_ImpliedDummyRead, TEST_ImpliedDummyRead
	.byte $FF


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;           MORE ENGINE STUFF             ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; I ran out of space in the engine section from $F000 - $FFFF, so I put some extra stuff here.

AutomaticallyRunEveryTestInROM:   ; This function is used to run every test in the ROM automatically.
	LDA #1
	STA <RunningAllTests          ; The "RunningAllTests" variable is used to prevent any graphical changes to the "running all tests screen".
	JSR DisableNMI                ; Disable the NMI.
	JSR DisableRendering
	JSR ClearNametable
	JSR PrintText
	.word $21E8
	.byte "Running test 0", $FF
	LDY #0
	STY <PostAllTestTally
AutomaticallyRunEntireROM_Loop:
	STY <menuTabXPos
	JSR SetUpSuitePointer         ; Set up the suite pointer.
	JSR LoadSuiteMenuNoRendering  ; Set up the menuHeight, and all the pointers for these tests and results.
	LDX #0
AutomaticallyRunEntireROM_Loop2:  ; Run every test on page Y.
	TXA
	PHA
	ASL A
	TAX
	LDA <suitePointerList+1,X
	STA <$00
	PLA
	TAX
	LDA <$00
	CMP #3	; if the page used to store the results is page 3 instead of page 4, we skip this test.
	BEQ AERROP_RT_Skip
	STX <menuCursorYPos           ; The "menuCursorYPos" variable is used inside RunTest to determing what code to run.
	JSR RunTest                   ; Run the test at index X of page Y.
	JSR WaitForVBlank
	TXA
	PHA
	LDA #$21
	STA $2006
	LDA #$F5
	STA $2006
	INC <PostAllTestTally
	LDA <PostAllTestTally
	JSR PrintByteDecimal_MinDigits
	JSR ResetScroll
	PLA
	TAX
AERROP_RT_Skip:
	INX                           ; increment X until X=MenuHeight.
	CPX <menuHeight
	BNE AutomaticallyRunEntireROM_Loop2
	                              ; That was all the tests on page Y.
	INY                           ; Y++
	CPY #((EndTableTable - TableTable)/2) ; Compare Y with the total page count.
	BNE AutomaticallyRunEntireROM_Loop    ; And loop if there are more pages to run.
	; All tests are complete!
	JSR WaitForVBlank             ; Wait for vblank for the PPU register writes.
	LDA #0
	STA <RunningAllTests          ; Clear the "RunningAllTests" variable
	JSR ResetScroll               ; Reset the PPU scroll.
	; Let's draw a menu to render the results!
	JSR DisableRendering
	JSR ClearPage2
	LDA #1
	STA <$10 ; this is "currentSubTest" but since all the tests are over, let's use this to count the number of sprites I'm adding to OAM. Set to 1 by default just to avoid sprite zero hits on the menu.
	LDA #0
	STA <PostAllPassTally
	STA <PostAllTestTally
	JSR ClearNametable	
	JSR SetPPUADDRFromWord
	.byte $20, $E5
	LDA #$D0	; Upper left corner.
	STA $2007
	LDA #$D5	; horizontal bar.
	LDX #0
AREROM_MenuLoop1:
	STA $2007
	INX
	CPX #((EndTableTable - TableTable)/2) ; Compare X with the total page count.
	BNE AREROM_MenuLoop1
	LDA #$D1	; Upper right corner.
	STA $2007
	; And the tallest page has 10 tests, so let's make this ten tiles tall.
	JSR SetPPUADDRFromWord
	.byte $22, $45
	LDA #$D2	; Bottom left corner.
	STA $2007
	LDA #$D5	; horizontal bar.
	LDX #0
AREROM_MenuLoop2:
	STA $2007
	INX
	CPX #((EndTableTable - TableTable)/2) ; Compare X with the total page count.
	BNE AREROM_MenuLoop2
	LDA #$D3	; Bottom right corner.
	STA $2007
	; And set up the horizontal bars.
	LDA #4
	STA $2000	; keep NMI disabled, but set the increment mode to 32 instead of 1.
	JSR SetPPUADDRFromWord
	.byte $21, $05
	LDA #$D4	; horizontal bar.
	LDX #0
AREROM_MenuLoop3:
	STA $2007
	INX
	CPX #10 ; once X = 11, stop.
	BNE AREROM_MenuLoop3
	JSR SetPPUADDRFromWord
	.byte $21, $05+((EndTableTable - TableTable)/2)+1
	LDA #$D4	; horizontal bar.
	LDX #0
AREROM_MenuLoop4:
	STA $2007
	INX
	CPX #10 ; once X = 11, stop.
	BNE AREROM_MenuLoop4
	; Now to print the results of each test in columns corresponding to the pages and indexes into the pages.
	
AREROM_PageColumnLoop1:
	STY <menuTabXPos
	JSR SetUpSuitePointer         ; Set up the suite pointer.
	JSR LoadSuiteMenuNoRendering  ; Set up the menuHeight, and all the pointers for these tests and results.
	; set the v register to 2106 + Y
	LDA #$21
	STA $2006
	TYA
	CLC
	ADC #06
	STA $2006
	LDX #0
AREROM_PageColumnLoop2:           ; Check results of every test on the page Y.
	; Check for the "print" tests, like "CPU RAM at power on", which isn't really testing anything. These don't need to be counted.
	TXA
	PHA
	ASL A
	TAX
	LDA <suitePointerList+1,X
	STA <$00
	PLA
	TAX
	LDA <$00
	CMP #3	; if the page used to store the results is page 3 instead of page 4, we skip this test.
	BEQ AERROP_Skip
	INC <PostAllTestTally
	STX <Copy_X
	TXA
	ASL A
	TAX
	LDA [suitePointerList,X]	; read the result of test X of page Y
	AND #01
	BEQ AREROM_PrintFail ; If the result isn't 1, print the error code
	; and if it passes, print a blue square.
	INC <PostAllPassTally ; also increment the "pass tally"
	LDA #$FE
	STA $2007
	; If this test has multiple pass conditions (SHA/SHS tests, for instance) let's put a sprite here.
	LDA [suitePointerList,X]	; read the result of test X of page Y
	AND #$FE
	BEQ AERROP_Next	; Check if theres an "error code". If not, move on.
	; If so, let's figure out what the coordinates of this test is.
	; X is, humorously going to give us the Y coordinate, and Y is likewise the X coordinate.
	; starting at X coordinate $30, and Y coodinate $40 (-1)
	; Each value of X or Y translates to 8 pixels.
	PHA
	STX <Copy_X2
	LDA <$10	; load the OAM index
	ASL A
	ASL A
	TAX			; transfer to X
	LDA <Copy_X2
	ASL A
	ASL A		; multiply by 4 (X is already multiplied by 2 here)
	CLC
	ADC #$40
	SEC
	SBC #01		; subtract by 1.
	STA $200,X
	; The "error code" will be the pattern.	
	PLA
	LSR A
	LSR A
	STA $201,X
	; The attirbutes will simply be: palette 1.
	LDA #1
	STA $202,X
	; and the X position
	TYA
	ASL A
	ASL A
	ASL A		; multiply by 8
	CLC
	ADC #$30
	STA $203,X
	INC <$10
	LDX <Copy_X2
	JMP AERROP_Next
AREROM_PrintFail:
	LDA [suitePointerList,X]	; read the result again to get the error code.
	LSR A	; shift error code into A
	LSR A
	ORA #$40	; to make it red in the table, ORA $40
	STA $2007
AERROP_Next:
	LDX <Copy_X
AERROP_Skip:
	INX                           ; increment X until X=MenuHeight.
	CPX <menuHeight
	BNE AREROM_PageColumnLoop2
	                              ; That was all the tests on page Y.
	INY                           ; Y++
	CPY #((EndTableTable - TableTable)/2) ; Compare Y with the total page count.
	BEQ AREROM_PageColumnLoopEnd    ; And loop if there are more pages to run.
	JMP AREROM_PageColumnLoop1
AREROM_PageColumnLoopEnd:
	LDA #0
	STA $2000	; keep NMI disabled, but set the increment mode back to 1.
	; and set up attributes for this table.
	JSR SetPPUADDRFromWord
	.byte $23, $D1
	LDX #0
AERROP_AttributeLoop:
	LDA AERROP_Attributes, X
	STA $2007
	INX
	CPX #22
	BNE AERROP_AttributeLoop

	; Let's print how many tests passed.
	JSR PrintText
	.word $2285
	.byte "Tests passed:", $FF
	;     "Tests passed: xyz / xyz"
	JSR SetPPUADDRFromWord
	.byte $22, $93
	LDA <PostAllPassTally
	JSR PrintByteDecimal_MinDigits
	LDA #$24
	LDX #$33
	STA $2007
	STX $2007
	STA $2007
	LDA <PostAllTestTally
	JSR PrintByteDecimal_MinDigits

	; I'd like to also like to label each of these columns with a page number.
	JSR PrintText
	.word $206E
	.byte "Page", $FF
	JSR PrintText
	.word $20A6
	.byte "12345678911111111112", $FF
	JSR PrintText
	.word $20CF
	.byte "01234567890", $FF

	LDA #0
	STA <menuTabXPos

	JSR WaitForVBlank
	JSR SetUpAllTestMenuPalette
	
	LDA #$4C
	STA $700
	LDA #LOW(PressStartToContinue)
	STA $701
	LDA #HIGH(PressStartToContinue)
	STA $702
	
	JSR ResetScrollAndWaitForVBlank
	LDA #2
	STA $4014
	JSR EnableRendering
	JSR EnableNMI                 ; And enable the MNI.
	RTS
;;;;;;;

AERROP_Attributes:
	.byte $CC, $FF, $FF, $FF, $FF, $33, $00, $00
	.byte $CC, $FF, $FF, $FF, $FF, $33, $00, $00
	.byte $0C, $0F, $0F, $0F, $0F, $03
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PressStartToContinue:
	JSR ReadController1
	LDA <controller_New
	AND #$10
	BEQ PressStartToContinue_End
	JSR SetUpDefaultPalette
	JSR DisableNMI
	JSR DisableRendering
	JSR ClearNametable
	LDX #$EF ; Due to some tests modifying the stack pointer, it's convenient to put it at EF instead of FF.
	TXS		 ; This prevents some tests where the resulting stack pointer is 00 from pushing data, and overwriting the bottom of the stack.
	JMP ReloadMainMenu
PressStartToContinue_End:
	RTI
	
DMASyncWith48:
	; This fuction very relaibly exits with exactly 50 CPU cycles until the DMA occurs.
	; However, it relies on open bus behavior, with the consequence of an infinite loop if not correctly emulated.
	STA <Copy_A
	LDA #$4F ; loop, max speed.
	STA $4010
	LDA #0
	STA $4011 ; minimum value of DMC
	LDA #$BC
	STA $4012 ; Sample address $EF00.
	LDA #0
	STA $4013 ; 1 byte length.
	LDA #$10
	STA $4015 ; Start the DMC DMA loop
	NOP
	NOP
DMASync48_Loop:
	LDA $4000 ; Open bus! Either we will read $40 from the high byte, or $00 from the DMA.
	;	[Read AD] [Read 00] [Read 40] [DMA PUT (1)] [DMA GET (2)] [DMA PUT (3)] [DMA GET (4)] [Read open bus (5)]
	CMP #$48
	BNE DMASync48_Loop ; If the DMA occurs, BIT $5000 will read $40 (Setting overflow flag) ; +2 (7)
	LDA #$0F ; don't loop, continue at max speed. +2 (9)
	STA $4010 
	LDA <$00  
	LDA Copy_A
	JSR Clockslide_100
	JSR Clockslide_100
	JSR Clockslide_100
	JSR Clockslide_50
	NOP
	CMP <$C9
	RTS 
	
DMASyncWith60:
	; This fuction very relaibly exits with exactly 50 CPU cycles until the DMA occurs.
	; However, it relies on open bus behavior, with the consequence of an infinite loop if not correctly emulated.
	STA <Copy_A
	LDA #$4F ; loop, max speed.
	STA $4010
	LDA #0
	STA $4011 ; minimum value of DMC
	LDA #$BB
	STA $4012 ; Sample address $EEC0.
	LDA #0
	STA $4013 ; 1 byte length.
	LDA #$10
	STA $4015 ; Start the DMC DMA loop
	NOP
	NOP
DMASync60_Loop:
	LDA $4000 ; Open bus! Either we will read $40 from the high byte, or $00 from the DMA.
	;	[Read AD] [Read 00] [Read 40] [DMA PUT (1)] [DMA GET (2)] [DMA PUT (3)] [DMA GET (4)] [Read open bus (5)]
	CMP #$60
	BNE DMASync60_Loop ; If the DMA occurs, BIT $5000 will read $40 (Setting overflow flag) ; +2 (7)
	LDA #$0F ; don't loop, continue at max speed. +2 (9)
	STA $4010 
	LDA <$00  
	LDA Copy_A
	JSR Clockslide_100
	JSR Clockslide_100
	JSR Clockslide_100
	JSR Clockslide_50
	NOP
	CMP <$C9
	RTS 
	
DMASyncWithA5:
	; This fuction very relaibly exits with exactly 50 CPU cycles until the DMA occurs.
	; However, it relies on open bus behavior, with the consequence of an infinite loop if not correctly emulated.
	STA <Copy_A
	LDA #$4F ; loop, max speed.
	STA $4010
	LDA #0
	STA $4011 ; minimum value of DMC
	LDA #$BA
	STA $4012 ; Sample address $EEC0.
	LDA #0
	STA $4013 ; 1 byte length.
	LDA #$10
	STA $4015 ; Start the DMC DMA loop
	NOP
	NOP
DMASyncA5_Loop:
	LDA $4000 ; Open bus! Either we will read $40 from the high byte, or $00 from the DMA.
	;	[Read AD] [Read 00] [Read 40] [DMA PUT (1)] [DMA GET (2)] [DMA PUT (3)] [DMA GET (4)] [Read open bus (5)]
	CMP #$A5
	BNE DMASyncA5_Loop ; If the DMA occurs, BIT $5000 will read $40 (Setting overflow flag) ; +2 (7)
	LDA #$0F ; don't loop, continue at max speed. +2 (9)
	STA $4010 
	LDA <$00  
	LDA Copy_A
	JSR Clockslide_100
	JSR Clockslide_100
	JSR Clockslide_100
	JSR Clockslide_50
	NOP
	CMP <$C9
	RTS 
	
DMASyncWith68:
	; This fuction very relaibly exits with exactly 50 CPU cycles until the DMA occurs.
	; However, it relies on open bus behavior, with the consequence of an infinite loop if not correctly emulated.
	STA <Copy_A
	LDA #$4F ; loop, max speed.
	STA $4010
	LDA #0
	STA $4011 ; minimum value of DMC
	LDA #$B9
	STA $4012 ; Sample address $EEC0.
	LDA #0
	STA $4013 ; 1 byte length.
	LDA #$10
	STA $4015 ; Start the DMC DMA loop
	NOP
	NOP
DMASync68_Loop:
	LDA $4000 ; Open bus! Either we will read $40 from the high byte, or $00 from the DMA.
	;	[Read AD] [Read 00] [Read 40] [DMA PUT (1)] [DMA GET (2)] [DMA PUT (3)] [DMA GET (4)] [Read open bus (5)]
	CMP #$68
	BNE DMASync68_Loop ; If the DMA occurs, BIT $5000 will read $40 (Setting overflow flag) ; +2 (7)
	LDA #$0F ; don't loop, continue at max speed. +2 (9)
	STA $4010 
	LDA <$00  
	LDA Copy_A
	JSR Clockslide_100
	JSR Clockslide_100
	JSR Clockslide_100
	JSR Clockslide_50
	NOP
	CMP <$C9
	RTS 
	
	
	.bank 1
	.org $A000
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                 TESTS                   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
DebugTest:
	LDA #02 ; FAIL! (Error code 0 will let me know the test isn't implemented yet, hence it ran DebugTest.)
	RTS
;;;;;;;
	
TEST_RamMirroring:
	; The $500 page is cleared to all zeroes before the test.
	
	;;; Test 1 [RAM Mirroring]: Reading from mirrors. ;;;
	; When the address bus is in the range $0000 to $1FFF, the CPU will read from RAM.
	; However, RAM only has $800 bytes of memory.
	; When reading from $800 through $1FFF, the CPU still reads from RAM, but only using the lower eleven bits for the address.
	; Therefore, reading from address $0800 is the same thing as reading from $0000. Likewise, $1000 and $1800 also read address $0000.
	; These are referred to as "mirrors" of address $0000. Likewise, $1FFF is a mirror of $07FF, and so on.
	LDA #1
	STA $501 ; Store 1 at $501
	LDA #2
	STA $580 ; Store 2 at $580
	LDA $D01 ; Read from a mirror of $501
	CMP #1
	BNE TEST_Fail ; if any value other than 1 is read, that's a fail.
	LDA $1D80 ; Read from a mirror of $580
	CMP #2
	BNE TEST_Fail ; if any value other than 2 is read, that's a fail.
	INC <currentSubTest 
	
	;;; Test 2 [RAM Mirroring]: writing to mirrors. ;;;
	; The description of test 1 only mentions reading from mirrors, but writing to them follows the exact same behavior.
	LDA #3
	STA $1D02 ; write to a mirror of $502
	LDA #4
	STA $DDD ; write to a mirror of $5DD
	LDA $502 ; Read $502
	CMP #3
	BNE TEST_Fail ; if any value other than 3 is read, that's a fail.
	LDA $5DD ; Read $5DD 
	CMP #4
	BNE TEST_Fail ; if any value other than 3 is read, that's a fail.
	;; END OF TEST ;;	
	LDA #01 ; PASS!
	RTS
;;;;;;;

TEST_Fail:
	LDA <currentSubTest
	ASL A
	ASL A
	ORA #02 ; Fail
	RTS
;;;;;;;

TEST_OpenBus:	
	;;; Test 1 [Open Bus]: Reading from open bus is not all zeroes. ;;;
	; Alright. What is "Open Bus"?
	; When reading from an address that isn't mapped to memory, the data pins are left "floating".
	; Let's learn about the data bus.
	; For instance, imagine LDA <$00. This is a 3 cycle instruction.
	; 1. Fetch the opcode:
	;	- The value of the PC is transferred to the Address Bus, and that address is read. The PC is also incremented.
	;	- When reading from memory, the value that gets read is placed on the data bus, which carries the 8-bit value to the CPU.
	;	- So in this example of LDA <$00, the value read is $A5, so the data bus holds $A5.
	; 2. Fetch the operand:
	;	- The value of the PC is transferred to the Address Bus, and that address is read. The PC is also incremented.
	;	- In this case, the value read is $00, which sets up the address bus for the third cycle of the LDA zeroPage instruction.
	; 3. Read from target address:
	;	- Read the value determined by the address bus. (in this case, that's address $0000)
	;	- The value at address $0000 is put on the data bus, and the CPU takes this value and overwrites the value of the A Register.
	;	
	; Great! So that's how the data bus works. But what happens if you read from somewhere not mapped to anything?
	; Let's see how LDA $5000 works. This has 4 cycles.
	; 1. Fetch the opcode: (The data bus now holds $AD)
	; 2. Fetch the first operand: (The data bus now holds $00)
	; 3. Fetch the second operand: (The data bus now holds $50)
	; 4. Read from target address:
	;	- Since there's nothing mapped to address $5000, the data bus is left floating, and nothing changes.
	;	- Since the value of the data bus is unchanged, it still holds the value $50, which was set during the third cycle.
	;
	; And that's how open bus works!
	; Open bus is typically from $4000 to $7FFF. (Except for addresses $4015 (APU_STATUS), $4016 (Controller port 1), and $4017 (Controller port 2)
	; If the cartridge has "PRG RAM", which is typically from $6000 to $7FFF, then those addresses wouldn't be open bus since they are mapped to something.
	; This cartridge doesn't have any PRG RAM, but I'm only going to test from the $4018 to $5FFF range.
	; Most emulators assume that (unless specified) the cartridge has PRG RAM from $6000 to $7FFF.
	;
	; This test only checks for open bus from $4020 through $5FFF. 
	; Though I think it should be implied that $6000 through $7FFF should be open bus as well, the iNES format implies 8 KiB of PRG RAM at $6000–$7FFF
	; Therefore this ROM needs to be NES 2.0 just to guarantee the open bus there, assuming the emulator is NES 2.0 compliant.
	;
	; anyway, some emulators might just assume reading from this range always returns 00, which is incorrect. Let's test for that!
	LDA $5000
	BEQ TEST_Fail
	LDA $4654
	BEQ TEST_Fail
	INC <currentSubTest 
	
	;;; Test 2 [Open Bus]: Reading from open bus always returns the high byte of the address read. ;;;
	; As explained above, when reading from one of these addresses, the second operand is the value that remains on the databus.
	; so, reading from $5501 should set A to $55, as the high byte is the most recently read value.	
	LDA $5501
	CMP #$55
	BNE TEST_Fail
	LDA $4020
	CMP #$40
	BNE TEST_Fail
	LDA $5FFF
	CMP #$5F
	BNE TEST_Fail
	INC <currentSubTest
	
	;;; Test 3 [Open Bus]: Indexed addressing crossing a page boundary does not update the data bus. ;;;
	; But the rule of "the high byte is the value returned" isn't always the case.
	; As you can see, using an offset to cross a page boundary will not update the data bus!
	LDY #$10
	LDA $50F8, Y ; This offset changes the high byte of the value read, but not the data bus. (Read from $5108, the value read should be $50)
	CMP #$50
	BNE TEST_Fail
	INC <currentSubTest
	
	;;; Test 4 [Open Bus]: The upper 3 bits when reading from the controller are open bus. ;;;
	; This is just checking to see if the controllers have the open bus bits.
	LDA $4016
	AND #$E0
	CMP #$40 ; When running LDA $4016, bit 6 is likely to be set.
	BNE TEST_Fail
	LDA $4017
	AND #$E0
	CMP #$40 ; When running LDA $4017, bit 6 is likely to be set.
	BNE TEST_Fail
	; This doubles as a test of dummy read cycles, and the PPU Databus.
	LDA #$F0
	STA $2002	; Set the PPU databus to $F0
	LDX #$17
	LDA $3FFF, X ; dummy read $2006. (The data bus is now $F0) The offset moves the address bus to $4016, reading from controller 1 when the databus was $F0.
	AND #$E0
	CMP #$E0 ; However, in this case, the open bus bits are all set.
	BNE TEST_Fail
	INX		 ; We're going to run a similar trick with controller 2, but instead of dummy reading a mirror of $2006, it will dummy read a mirror of $2007. Let's set up the ppu read buffer.
	JSR WaitForVBlank
	LDA #0
	STA <dontSetPointer
	JSR PrintCHR	; The PrintCHR function will read the 2 byte word, and following bytes up until it reads $FF (a terminator) and then fix the return address such that RTS returns to the byte after the terminator.
	.word $2400
	.byte $F0, $FF
	; PrintCHR will return here. The .word $2400 and ,byte $F0, $FF don't get executed.
	BEQ TEST_OpenBus_ContinueTest4 ; Skip to TEST_OpenBus_ContinueTest4
	;; If you are reading this for test 4, just ignore these next few lines. ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TEST_OpenBusA0A0:              ; This is a fail-safe for test 8. It needed to be at address $A0A0.	         ;;
	SEI						   ; The RTI instruction pulled off some junk and we need to re-set the i flag.  ;;
	LDX #1                     ; X=1, which is used to tell test 8 that it failed.                           ;;
	JMP TEST_OpenBus_PostTest8 ; Jump to the end of test 8.                                                  ;;
TEST_OpenBus_ContinueTest4:    ; Anyway, that was the greatest crime against programming I've ever commited. ;;
	;; And now, back to your regularly scheduled program. ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	JSR SetPPUADDRFromWord
	.byte $24, $00
	; SetPPUADDRFromWord will return here.
	LDA $2007 ; empty PPU buffer
	LDA $3FFF, X ; dummy read $2007 (The data bus is now $F0) The offset moves the address bus to $4017, reading from controller 1 when the databus was $F0.
	PHA
	JSR ResetScroll	; And reset the scroll, since we just moved "v" to $2400.
	PLA
	AND #$E0
	CMP #$E0 ; However, in this case, the open bus bits are all set.
	BNE TEST_Fail2
	INC <currentSubTest
	
	;;; Test 5 [Open Bus]: The databus actually exists, and the open bus behavior isn't being faked. ;;;
	; This is tested by moving the program counter to open bus, and running a very choreographed function.
	; Here is what is expected to run in open bus:
	; LSR <$56, X
	; RTS
	;
	; Here's what could go wrong:
	; Open bus behavior could be faked, specifically by always returning the high byte from this address range.
	; in which case, `LSR <$56, X` will run until $5700, running `SRE <$57, X` until $5800, running `CLI` until $5900, and so on.
	; In that case, once the PC reaches $6000, it will run RTS, however the falgs and stuff will be wrong, so we can check for that.
	;	-In theory we already ruled this behavior out with previous tests... but who knows. A lot could go wrong with emulation.
	;
	; It's also possible the same thing will happen, but instead of RTS, it runs BRK. Either way, that's a fail.
	; Since that's a possibility, set up the IRQ routine.
	;
	; It's also possible the JSR instruction does things out of order, leaving the wrong value on the data bus. I can't really predict what will happen then, but just so we're clear:
	; Here are all the cycles of JSR. (Simplified. JSR is actually a super odd instruction. I recommend looking at it in visual 6502 some time.)
	; 1: Read the opcode.
	; 2: Read the first operand.
	; 3: Dummy read from stack.
	; 4: Push PC High to the stack.
	; 5: Push PC Low to the stack.
	; 6: Read the second operand.

	LDX #0
TEST_OpenBus_PrepIRQLoop:
	LDA TEST_OpenBus_IRQRoutine,X ; TEST_OpenBus_IRQRoutine can be found at the end of this test. It's just a bunch of PLA's and a JMP to TEST_Fail.
	STA $600, X
	INX
	CPX #8
	BNE TEST_OpenBus_PrepIRQLoop
	; and prep for the test:
	LDA #$C0 ; this will get ROR'ed into an RTS instruction... hopefully.
	STA <$56 ; store it in RAM, ready for the test.
	LDX #0	 ; X needs to be zero for this.
	JSR $5600; open bus!
	; We made it back safely
	; if a BRK occured (possibly at $6000), or if we executed into $8000, we failed.
	LDA <$56
	CMP #$60
	BNE TEST_Fail2
	INC <currentSubTest 
	
	;;; Test 6 [Open Bus]: Dummy Reads update databus, test by reading $4015 ;;;
	; On second thought... this was already tested by the controller reading test, wasn't it?
	; Oh well.
	; This doubles as a test of dummy read cycles, and the PPU Databus. Here's what happens.
	; LDA $3FFF, X (X=$16)
	; 1: fetch opcode 
	; 2: fetch low byte
	; 3: fetch high byte, add the X offset to the low byte
	; 4: READ $3F15, then fix the high byte
	; 5: READ $4015.
	;
	; $3F15 is a mirror of $2005, which when read returns PPU Open Bus.
	; So we need to set the PPU Bus to something first.
	LDA #0
	STA $2002
	LDX #$16
	; let's run the test.
	LDA $3FFF,X 
	AND #$20 ; Let's only check bit 5, since that's the open bus bit of address $4015
	CMP #$00 ; bit 5 is a zero, since that was what was read from $3F15
	BNE TEST_Fail2
	; Let's set the PPU Bus to $FF and run it again!
	LDA #$FF
	STA $2002
	LDA $3FFF,X
	AND #$20 ; Again, only check bit 5.
	CMP #$20 ; Bit 5 was set when reading from the PPU Bus, so bit 5 of $4015 should be set.
	BNE TEST_Fail2 
	INC <currentSubTest 
	
	;;; Test 7 [Open Bus]: Reading from $4015 does not update the databus. ;;;
	; Address $4015 is special. All the values read here are internal to the 2A03 chip, so the databus isn't used. 
	;
	; LDA $40FF, X (X=$16)
	; 1: fetch opcode 
	; 2: fetch low byte
	; 3: fetch high byte, add the X offset to the low byte
	; 4: READ $4015, then fix the high byte
	; 5: READ $4115.
	;
	; The value read from $4015 will be zero, but that does NOT change the databus!
	; Therefore, the value read from $4115 will still be $40 from when the high byte was fetched.
	LDA $40FF,X
	CMP #$40
	BNE TEST_Fail2
	INC <currentSubTest 
	
	;;; Test 8 [Open Bus]: Writing always updates the databus, even writing to $4015 ;;;
	; LSR <56,X
	; 	$CD >> 1 = $66 + Carry set
	; ROR <$66
	;	$22 >> 1 = $91
	; STA ($91),Y
	; A=60 -> ($15, $40)
	;
	; How could this one go wrong? Well, if writing to $4015 does not update the databus, this will run RTI instead of RTS.
	; We can prep for this by pushing $A0 to the stack, so if an RTI occurs, we'll return to TEST_OpenBusA0A0
	LDX #0
	LDY #0
	LDA #$CD
	STA <$56 ; $56 = #$CD
	LDA #$22
	STA <$66 ; $66 = #$22
	LDA <$91 ; Push these to the stack
	PHA
	LDA <$92 ; These are important bytes for the test selection menu, so we'll restore these after the test.
	PHA
	LDA #$15
	STA <$91
	LDA #$40
	STA <$92 ; ($91) = $4015
	LDA #$A0
	PHA
	LDA #$60 ; A = the value of RTS
	JSR $5600 ; Jump to open bus to run this!
	; and if we made it back here, the test worked!
	; restore the values from $91 and $92
	PLA ; pull off the $A0 for the RTI guardrails.
TEST_OpenBus_PostTest8:
	PLA
	STA <$92
	PLA
	STA <$91
	TXA ; X = 0 if we ran RTS, X = 1 if we ran RTI.
	CPX #$01
	BEQ TEST_Fail2	
	
	;; END OF TEST ;;	
TEST_Pass2:
	LDA #1
	RTS
;;;;;;;

TEST_OpenBus_IRQRoutine: 
	; This is used in test 4 when we jump to open bus. If the behavior is inaccurate, a BRK is likely to run.
	; We want to run the following code if a BRK occurs, so this gets copied to the IRQ routine in RAM.
	PLA
	PLA
	PLA
	PLA
	PLA
TEST_Fail2:
	JMP TEST_Fail ; This is part of TEST_OpenBus_IRQRoutine, but I'm re-using this JMP to save bytes.
;;;;;;;
	
TEST_ROMnotWritable:
	;;; Test 1 [ROM is not Writable]: Writing to ROM does nothing. ;;;
	; This is an NROM cartridge, so there aren't banks to swap or anything
	LDA #$02 ; 02 = FAIL
	STA CannotWriteToROM_01 ; This address holds a $01
	LDA CannotWriteToROM_01 ; If ROM was updated, you read a 2, which fails the test.
	;; END OF TEST ;;
	RTS						; else, return 1, thus passing.
;;;;;;;

TEST_PPURegMirroring:
	;;; Test 1 [PPU Register Mirroring]: PPU Registers are mirrored through $3FFF ;;;
	; The registers from $2000 to $2007 get repeated every 8 bytes.
	; I'm only testing mirrors of PPUADDR and PPUDATA, but surely if those are implemented, the rest are too.
	LDX #$28     ; Move the PPU v register to $2800
	STX $2006+8  ; A mirror of PPUADDR
	LDY #$00
	STY $2006+16 
	LDA #$01
	STA $2007+32 ; A mirror of PPUDATA
	STX $2006+64 ; Move the PPU v register back to $2800
	STY $2006+128
	LDA $2007+256; Read the buffer
	LDA $3FFF    ; Read the value at VRAM $2800
	PHA	         ; Push the results to the stack
	STX $2006    ; The test has already concluded, so let's not bother with mirrors.
	STY $2006    ; Clear that value back to a $24
	LDA #$24
	STA $2007
	JSR ResetScroll
	PLA          ; Pull the results off the stack
	CMP #$01
	BNE TEST_Fail2
	;; END OF TEST ;;
	RTS
;;;;;;;;;;;;;;;;;;

TEST_DummyReads:
	; Pre-Test preparations.
	LDA #$20
	STA <$51
	LDA #$02
	STA <$50 ; ($50) points to $2002
	LDA #$3F
	STA <$53
	LDA #$F0
	STA <$52 ; ($52) points to $3FF0
	
	;;; Test 1 [Dummy Read Cycles]: A mirror of PPU_STATUS ($2002) will be read twice by LDA $20F2, X (where X = $10). ;;;
	; Since reading $2002 clears bit 7 of PPUSTATUS, we can check if dummy reads are happening by running dummy reads on $2002, then checking bit 7.
	; Let's walk through the LDA $20F2, X instruction cycle by cycle, where X = $10
	; 1: fetch opcode 
	; 2: fetch low byte
	; 3: fetch high byte, add the X offset to the low byte
	; 4: Read $2002, if adding the offset crosses a page boundary (in this case it did), update the high byte.
	; 5: Read $2102.
	;
	; Focus on cycle 4. That's the dummy read.
	
	LDX #$10
	JSR Clockslide_29780 ; Wait a frame so the VBlank flag (bit 7) gets set
	LDA $20F2, X ; If bit 7 of A gets set, then $2002 was only read once.
	BMI TEST_Fail2
	INC <currentSubTest 
	
	;;; Test 2 [Dummy Read Cycles]: The dummy read does NOT occur if a page boundary is not crossed ;;;	
	LDX #0
	JSR Clockslide_29780 ; Wait a frame so the VBlank flag (bit 7) gets set
	LDA $2002, X ; The page boundary is not crossed, so there should only have been 1 read.
	BPL TEST_Fail2
	INC <currentSubTest 
	
	;;; Test 3 [Dummy Read Cycles]: The dummy read is on the correct address ;;;	
	; The dummy read happens after the low byte is updated, but before the high byte.
	LDX #$62
	JSR Clockslide_29780 ; Wait a frame so the VBlank flag gets set
	LDA $3FF0, X ; Dummy read $3F52 (A mirror of $2002), then read $4052 (Open bus emulation is NOT needed to pass this test!)
	LDA $2002	 ; If bit 7 of A gets set, then the dummy read was from the wrong address (bit 7 of $2002 was not cleared by the dummy read).
	BMI TEST_Fail2
	INC <currentSubTest 	
	
	;;; Test 4 [Dummy Read Cycles]: STA $2002, X (where X=0) reads $2002 once. ;;;
	LDX #0
	JSR Clockslide_29780 ; Wait a frame so the VBlank flag gets set
	STA $2002, X ; The dummy read cycle will read from $2002.
	LDA $2002	 ; If bit 7 of A gets set, then $2002 was not read during the STA
	BMI TEST_Fail2
	INC <currentSubTest 	
	
	;;; Test 5 [Dummy Read Cycles]: STA dummy read is on the correct address ;;;
	LDX #$62
	JSR Clockslide_29750 ; Wait (slightly less than) a frame so the VBlank flag gets set
	STA $3FF0, X ; The dummy read cycle will read from $2002.
	LDA $2002	 ; If bit 7 of A gets set, then $2002 was not read during the STA
	BMI TEST_Fail3
	INC <currentSubTest 	

	;;; Test 6 [Dummy Read Cycles]: LDA ($2002),Y (where Y=3) does not have a dummy read. ;;;
	; The page boundary isn't crossed, so no dummy read.
	LDY #1

	JSR Clockslide_29750 ; Wait (slightly less than) a frame so the VBlank flag gets set
	LDA [$0050],Y  ; The dummy read does NOT happen because a page boundary was not crossed.
	LDA $2002 ; The dummy read didn't occur, so bit 7 should be set.
	BPL TEST_Fail3 
	INC <currentSubTest 	
	
	;;; Test 7 [Dummy Read Cycles]: LDA ($3FF0),Y (where Y=62) dummy read occurs, and is on the correct address ;;;
	LDY #$62
	JSR Clockslide_29750 ; Wait (slightly less than) a frame so the VBlank flag gets set
	LDA [$0052],Y
	LDA $2002	 ; If bit 7 of A gets set, then $2002 was not read during the LDA
	BMI TEST_Fail3
	INC <currentSubTest 
	
	;;; Test 8 [Dummy Read Cycles]: STA ($2002),Y (where Y=1) does not have a dummy read. ;;;
	; The page boundary isn't crossed, so no dummy read.
	LDY #1
	JSR Clockslide_29750 ; Wait (slightly less than) a frame so the VBlank flag gets set
	STA [$0050],Y
	LDA $2002	 ; The dummy read didn't occur, so bit 7 should be set.
	BPL TEST_Fail3
	INC <currentSubTest 
	
	;;; Test 9 [Dummy Read Cycles]: STA ($3FF0),Y (where Y=62) dummy read is on the correct address ;;;
	LDY #$62
	JSR Clockslide_29750 ; Wait (slightly less than) a frame so the VBlank flag gets set
	STA [$0052],Y
	LDA $2002	 ; If bit 7 of A gets set, then $2002 was not read during the STA
	BMI TEST_Fail3
	INC <currentSubTest 
	
	;;; Test A [Dummy Read Cycles]: LDA ($2002,X) does not dummy-read $2002 ;;;
	LDX #0
	JSR Clockslide_29750 ; Wait (slightly less than) a frame so the VBlank flag gets set
	LDA [$50,X]
	BPL TEST_Fail3 ; If bit 7 of A is set, then we pass the test. The dummy read was at $0050, which we can't test for.
	INC <currentSubTest 	
	
	;;; Test B [Dummy Read Cycles]: STA ($2002,X) does not dummy-read $2002 ;;;
	LDX #0
	JSR Clockslide_29780 ; Wait a frame so the VBlank flag gets set
	STA [$50,X]
	BPL TEST_Fail3 ; If bit 7 of A is set, then we pass the test. The dummy read was at $0050, which we can't test for.	
	;; END OF TEST ;;
	LDA #1
	RTS
TEST_Fail3:
	JMP TEST_Fail
;;;;;;;

TEST_DummyWrites_Prep:
	; Load VRAM[2400] with #0
	; Load VRAM[2401] with #1
	; Load VRAM[2402] with #2
	; Load VRAM[2403] with #3
	; keep Y unchanged.
	STY <$FE
	LDA $2002
	LDA #$24
	STA $2006
	LDA #0
	STA $2006
	TAX
	LDY #10
TEST_DummyWritesPrepLoop:
	STX $2007
	INX
	DEY
	BNE TEST_DummyWritesPrepLoop
	LDA #$24
	STA $2006
	LDA #0
	STA $2006
	LDY <$FE
	RTS
;;;;;;;

TEST_FailPPUOpenBus:
	JSR ResetScroll
	JMP TEST_Fail
;;;;;;;;;;;;;;;;;

TEST_PPU_Open_Bus:
	;;; Test 1 [PPU Open Bus]: Verify PPU Open Bus exists. ;;;
	; Don't worry, this this is remarkably simple.
	; Here's how PPU Open bus works.
	; The PPU Databus is updated whenever the CPU writes to any PPU Register.
	
	LDX #0
	LDY #1
	LDA #$5A
	STA $2002 ; Address $2002 is read-only. This puts $5A on the ppu bus.
	TXA	  ; clear A for the test.
	LDA $2000 ; Address $2000 is write-only, so the value read is the value of the PPU bus. ($5A)
	CMP #$5A
	BNE TEST_FailPPUOpenBus
	INC <currentSubTest 
	
	;;; Test 2 [PPU Open Bus]: All PPU Registers update PPU Open Bus. ;;;
	; Writing to $2000 updates the PPU Databus
	LDA <PPUCTRL_COPY
	STA $2000 ; this updates the PPU bus and changes nothing with the register... hopefully.
	TXA
	LDA $2001 ; read a different write-only register.
	CMP <PPUCTRL_COPY
	BNE TEST_FailPPUOpenBus
	
	; Writing to $2001 updates the PPU Databus
	LDA <PPUMASK_COPY
	STA $2001
	TXA
	LDA $2000
	CMP <PPUMASK_COPY
	BNE TEST_FailPPUOpenBus

	; we've already tested writing to $2002
	
	; Writing to $2003 updates the PPU Databus
	LDA #04
	STA $2003
	TXA
	LDA $2000
	CMP #04
	BNE TEST_FailPPUOpenBus
	
	; Writing to $2004 updates the PPU Databus
	LDA #$FF
	STA $2004
	TXA
	LDA $2000
	CMP #$FF
	BNE TEST_FailPPUOpenBus
	
	; Writing to $2005 updates the PPU Databus
	LDA $2002
	LDA #$00
	STA $2005
	TYA
	LDA $2000
	CMP #$00
	BNE TEST_FailPPUOpenBus
	
	; Writing to $2006 updates the PPU Databus
	LDA $2002
	LDA #$20
	STA $2006
	TXA
	LDA $2000
	CMP #$20
	BNE TEST_FailPPUOpenBus
	
	; Writing to $2007 updates the PPU Databus
	LDA #$24
	STA $2007
	TYA
	LDA $2000
	CMP #$24
	BNE TEST_FailPPUOpenBus
	INC <currentSubTest 
	
	;;; Test 3 [PPU Open Bus]: Address $2002, bits 0 through 4 are open bus ;;;
	LDA $2002
	LDA #$15
	STA $2006
	LDA $2002
	AND #$1F
	CMP #$15
	BNE TEST_FailPPUOpenBus2
	INC <currentSubTest 
	JSR ResetScroll

	LDA <$50	; This value will be $00 if you are running [PPU Open Bus], but $01 if you are running [Dummy Write Cycles], which re-runs thsi test to verify the ppu bus works as a prerequisite.
	BNE TEST_PPU_Open_Bus_SkipDecayTest
	
	;;; Test 4 [PPU Open Bus]: The PPU Databus decays. ;;;
	LDA #$FF
	STA $2002
	LDX #60
TEST_PPU_Open_Bus_60FrameStall:; wait approximately one second.
	JSR Clockslide_29780	
	DEX
	BNE TEST_PPU_Open_Bus_60FrameStall
	LDA $2000
	BNE TEST_FailPPUOpenBus2

	;; END OF TEST ;;
TEST_PPU_Open_Bus_SkipDecayTest:
	JSR WaitForVBlank
	JSR ResetScroll
	LDA #01
	RTS
;;;;;;;
TEST_FailPPUOpenBus2:
	JSR ResetScroll
	JMP TEST_Fail

TEST_DummyWritePrep_SetUpV:
	LDA #$25
	STA $2006
	LDA #$FA
	STA $2006
	RTS
;;;;;;;

TEST_DummyWritePrep_PPUADDR25FA: ; This exists to save bytes
	JSR SetPPUADDRFromWord
	.byte $25, $FA
	LDA #$25
	STA $2002 ; Set the PPU Open bus value to 25
	RTS
;;;;;;;

TEST_DummyWritePrep_26: ; This exists to save bytes
	JSR TEST_DummyWritePrep_PPUADDR25FA ; just leech off this to save bytes.
	LDA #$26
	STA $2002 ; Set the PPU Open bus value to 26
	RTS
;;;;;;;

TEST_DummyWrites:
	; Special thanks to bisqwit and blargg for creating a test for dummy writes. (I'm pretty much just doing what they did.)
	; Consider the ASL instruction.
	; This is a "Read-Modify-Write" instruction, for it does the following:
	; Read target address, modify the value, and write it back.
	; But that's not the whole story, as this instruction has "Dummy Writes". (Indexed instructions also have dummy reads in addition to dummy writes)
	; Consider ASL $0400. Let's see every cycle of this instruction.
	; 1: fetch opcode 
	; 2: fetch low byte
	; 3: fetch high byte
	; 4: Read $0400.
	; 5: Write the value back to $0400, then do the operation on this value. (arithmetic shift left)
	; 6: Write this new value to $0400.
	;
	; Focus on cycle 5. That's the dummy write.
	
	;;; Test 1 [Dummy Write Cycles]: Verify PPU Open Bus exists. ;;;
	; This Dummy Write test relies on PPU Open Bus, so if it's not emulated we cannot check for dummy writes accurately.
	LDA #1
	STA <$50				; The PPU_Open_Bus test uses address $50 to skip the decay test, since that's not needed here.
	JSR TEST_PPU_Open_Bus	; It feels pretty silly running another test inside this test.
	LDX #1					; But hey, it saves on bytes.
	STX <currentSubTest		; reset the current sub test, as running TEST_PPU_Open_Bus changed it.
	CMP #$01				
	BNE TEST_FailPPUOpenBus2
	INC <currentSubTest 
	
	; Here's how the test works.
	; Prep the PPU databus with a specific value, usually $25 or $26.
	; RMW $2006. Read $2006 (PPU open bus), Dummy Write $2006 and modify value read, write $2006 again.
	; If we know where the writes will take the 'v' register, then we can simply read $2007 twice after this test to verify the dummy writes occured.
	
	; for example: INC $2006
	; 1: fetch opcode 
	; 2: fetch low byte
	; 3: fetch high byte
	; 4: Read $2006. (address $2006 is write-only, so we read the PPU data bus: #$25)
	; 5: Write #$25 to $2006, then do the operation on this value. (INC #$25 = #$26)
	; 6: Write #$26 to $2006. The VRAM address is now $2526	
	
	; Let's make some preparations...
	JSR ResetScrollAndWaitForVBlank
	
	; Let me explain this subroutine real quick.
	; The return address is modified inside this subroutine, so it returns to the byte after the terminator.
	; Basically, WriteToPPUADDRWithByte will read the two bytes after it, and store them to $2006, then the third byte is stored at $2007.
	; Then, if the following byte if $FF (the terminator), exit the subroutine. Othwerwise, grab the next 3 bytes and do it again.
	JSR WriteToPPUADDRWithByte
	.byte $25, $4A, $5A ; VRAM[$254A] = $5A
	.byte $25, $4B, $5C ; VRAM[$254B] = $5C
	.byte $25, $12, $F1 ; VRAM[$2512] = $F1
	.byte $25, $92, $7E ; VRAM[$2592] = $7E
	.byte $25, $24, $11 ; VRAM[$2524] = $11
	.byte $25, $26, $22 ; VRAM[$2526] = $22
	
	.byte $26, $4C, $8D ; VRAM[$264C] = $8D
	.byte $26, $4D, $A5 ; VRAM[$264D] = $A5
	.byte $26, $13, $F0 ; VRAM[$2613] = $F0
	.byte $26, $93, $36 ; VRAM[$2693] = $36
	.byte $26, $25, $98 ; VRAM[$2625] = $98
	.byte $26, $27, $4F ; VRAM[$2627] = $4F
	.byte $FF ; Terminator.
	; WriteToPPUADDRWithByte will return here:
	JSR ResetScrollAndWaitForVBlank

	;;; Test 2 [Dummy Write Cycles]: See if Read-Modify-Write instructions write to $2006 twice. ;;;
	JSR TEST_DummyWritePrep_PPUADDR25FA ; v = 25FA, PpuBus = $25
	ASL $2006							; v = 254A
	JSR DoubleLDA2007 ; Read from VRAM
	CMP #$5A
	BNE TEST_FailDummyWrites
	
	JSR TEST_DummyWritePrep_PPUADDR25FA ; v = 25FA, PpuBus = $25
	SEC
	ROL $2006							; v = 254B
	JSR DoubleLDA2007 ; Read from VRAM
	CMP #$5C
	BNE TEST_FailDummyWrites
	
	JSR TEST_DummyWritePrep_PPUADDR25FA ; v = 25FA, PpuBus = $25
	LSR $2006							; v = 2512
	JSR DoubleLDA2007 ; Read from VRAM
	CMP #$F1
	BNE TEST_FailDummyWrites
	
	JSR TEST_DummyWritePrep_PPUADDR25FA ; v = 25FA, PpuBus = $25
	SEC
	ROR $2006							; v = 2592
	JSR DoubleLDA2007 ; Read from VRAM
	CMP #$7E
	BNE TEST_FailDummyWrites
	
	JSR TEST_DummyWritePrep_PPUADDR25FA ; v = 25FA, PpuBus = $25
	DEC $2006							; v = 2524
	JSR DoubleLDA2007 ; Read from VRAM
	CMP #$11 ;
	BNE TEST_FailDummyWrites
	
	JSR TEST_DummyWritePrep_PPUADDR25FA ; v = 25FA, PpuBus = $25
	INC $2006							; v = 2526
	JSR DoubleLDA2007 ; Read from VRAM
	CMP #$22 ;
	BNE TEST_FailDummyWrites
	INC <currentSubTest 
	JMP TEST_DummyWritesPt2
;;;;;;;
TEST_FailDummyWrites:
	JSR ResetScroll
	JMP TEST_Fail
TEST_DummyWritesPt2:
	JSR ResetScrollAndWaitForVBlank
	;;; Test 3 [Dummy Write Cycles]: See if Read-Modify-Write instructions with X indexing write to $2006 twice. ;;;
	LDX #6
	JSR TEST_DummyWritePrep_26 ; v = 25FA, PpuBus = $26
	ASL $2000,X			       ; v = 264C
	JSR DoubleLDA2007 ; Read from VRAM
	CMP #$8D
	BNE TEST_FailDummyWrites
	
	JSR TEST_DummyWritePrep_26 ; v = 25FA, PpuBus = $26
	SEC
	ROL $2000,X			       ; v = 264D
	JSR DoubleLDA2007 ; Read from VRAM
	CMP #$A5
	BNE TEST_FailDummyWrites
	
	JSR TEST_DummyWritePrep_26 ; v = 25FA, PpuBus = $26
	LSR $2000,X			       ; v = 2613
	JSR DoubleLDA2007 ; Read from VRAM
	CMP #$F0
	BNE TEST_FailDummyWrites
	
	JSR TEST_DummyWritePrep_26 ; v = 25FA, PpuBus = $26
	SEC
	ROR $2000,X			       ; v = 2693
	JSR DoubleLDA2007 ; Read from VRAM
	CMP #$36
	BNE TEST_FailDummyWrites
	
	JSR TEST_DummyWritePrep_26 ; v = 25FA, PpuBus = $26
	DEC $2000,X			       ; v = 2625
	JSR DoubleLDA2007 ; Read from VRAM
	CMP #$98 ;
	BNE TEST_FailDummyWrites
	
	JSR TEST_DummyWritePrep_26 ; v = 25FA, PpuBus = $26
	INC $2000,X			       ; v = 2627
	JSR DoubleLDA2007 ; Read from VRAM
	CMP #$4F ;
	BNE TEST_FailDummyWrites
	
	;; END OF TEST ;;
	JSR ResetScroll
	LDA #01
	RTS
;;;;;;;

RTS_If_Running_All_Tests:	; The following tests should not draw anythign on screen if we're running the automatically-run-all-tests mode.
	LDA <RunningAllTests
	BEQ RTS_If_Running_All_Tests_Continue ; skip printing stuff on screen if we're running all tests right now.
	PLA
	PLA
	LDA #01
	RTS
RTS_If_Running_All_Tests_Continue:
	RTS
;;;;;;;

TEST_PowerOnState_CPU_RAM:
	;;; Test 1 [CPU RAM Power On State]: Print the values recorded at power on ;;;
	JSR RTS_If_Running_All_Tests ; If running all tests automatically, skip drawing stuff on screen. This isn't actually testing anything anyway.
	JSR ClearNametableFrom2240
	JSR ResetScrollAndWaitForVBlank
	JSR Print32Bytes
	.word $2244
	.word PowerOnRAM
	JSR ResetScroll
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;	

TEST_PowerOnState_PPU_RAM:
	;;; Test 1 [PPU RAM Power On State]: Print the values recorded at power on ;;;
	JSR RTS_If_Running_All_Tests ; If running all tests automatically, skip drawing stuff on screen. This isn't actually testing anything anyway.
	JSR ClearNametableFrom2240
	JSR ResetScrollAndWaitForVBlank
	JSR Print32Bytes
	.word $2244
	.word PowerOnVRAM
	JSR ResetScroll
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;	

TEST_PowerOnState_PPU_Palette:
	;;; Test 1 [Palette RAM Power On State]: Print the values recorded at power on ;;;
	JSR RTS_If_Running_All_Tests ; If running all tests automatically, skip drawing stuff on screen. This isn't actually testing anything anyway.
	JSR ClearNametableFrom2240
	JSR ResetScrollAndWaitForVBlank
	JSR Print32Bytes
	.word $2244
	.word PowerOnPalette
	JSR ResetScroll
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;	

TEST_PowerOnState_PPU_ResetFlag:
	;;; Test 1 [PPU Reset Flag]: Print the value recorded at power on ;;;
	LDA PowerOnTest_PPUReset
	RTS
;;;;;;;

TEST_PowerOnState_CPU_Registers:
	;;; Test 1 [CPU Registers Power On State]: Print the values recorded at power on ;;;
	JSR RTS_If_Running_All_Tests ; If running all tests automatically, skip drawing stuff on screen. This isn't actually testing anything anyway.
	JSR ClearNametableFrom2240
	JSR ResetScrollAndWaitForVBlank
	LDA #0
	STA <dontSetPointer
	
	JSR PrintText
	.word $2252
	.byte "A ", $FF
	LDA PowerOn_A
	JSR PrintByte
	
	JSR PrintText
	.word $2272
	.byte "X ", $FF
	LDA PowerOn_X
	JSR PrintByte
	
	JSR PrintText
	.word $2292
	.byte "Y ", $FF
	LDA PowerOn_Y
	JSR PrintByte

	JSR ResetScrollAndWaitForVBlank

	JSR PrintText
	.word $22A6
	.byte "Stack Pointer ", $FF
	LDA PowerOn_SP
	JSR PrintByte
	
	JSR PrintText
	.word $22C4
	.byte "Processor flags ", $FF
	LDA PowerOn_P
	JSR PrintByte
	;; END OF TEST ;;
	JSR ResetScroll
	LDA #1
	STA <dontSetPointer
	RTS
;;;;;;;

TEST_Fail4:
	JMP TEST_Fail
TEST_UnofficialInstructions_Prep:
	LDA #$42
	STA $500
	STA <$50
	LDA #0
	TAX
	TAY
	RTS
TEST_UnofficialInstructionsExist:
	;;; Test 1 [Unofficial Instructions Exist]: What happens when we run an unofficial opcode? ;;;
	; This test does NOT verify accurate emulation of every one of these instructions.
	; It just makes sure they all vaguely perform what's expected of them, instead of NOP.
	; For instructions with many different addressing modes, This only checks the Immediate mode if it exists, or Absolute.
	; let's run a 3-byte NOP, and check if it was actually 3 bytes.
	LDA #0
	LDX #0
	LDY #$0F
	; The following should be: NOP $98A2	
	.byte $0C, $A2, $98
	; But if this was treated as a 1-byte NOP, X=98
	CPX #$98
	BEQ TEST_Fail4
	INC <currentSubTest 
	
	;;; Test 2 [Unofficial Instructions Exist]: Was it a 2-byte nop? ;;;
	; And if this was treated as a 2-byte NOP, A=0F
	CMP #$0F
	BEQ TEST_Fail4
	; Alright! It was treated as a 3-byte NOP, which is what it should be.
	INC <currentSubTest 
	
	;;; Test 3 [Unofficial Instructions Exist]: NOP Absolute updates PPUSTATUS ;;;
	JSR Clockslide_29780 ; wait for next frame.
	.byte $0C, $02, $20 ; NOP $2002
	LDA $2002
	BMI TEST_Fail4 ; if bit 7 was still set after that NOP $2002, that's a fail!
	INC <currentSubTest 
	
	;;; Test 4 [Unofficial Instructions Exist]: Does SLO exist? ;;;
	JSR TEST_UnofficialInstructions_Prep
	LDA #$0F
	.byte $0F ; SLO Absolute
	.word $0500; $SLO $0500
	; A |= ($42 << 1) -> $8F
	CMP #$8F
	BNE TEST_Fail4
	LDA $0500
	CMP #$84
	BNE TEST_Fail4
	; SLO exists!
	INC <currentSubTest 

	;;; Test 5 [Unofficial Instructions Exist]: Does ANC exist? ;;;
	JSR TEST_UnofficialInstructions_Prep
	LDA #$8F
	CLC
	.byte $0B, $8C ; ANC #$8C
	; A &= $8C -> $8C
	BCC TEST_Fail4
	CMP #$8C
	BNE TEST_Fail4
	; ANC exists!
	INC <currentSubTest
	
	;;; Test 6 [Unofficial Instructions Exist]: Does RLA exist? ;;;
	JSR TEST_UnofficialInstructions_Prep
	LDA #$F1
	SEC
	.byte $2F ; RLA Absolute
	.word $0500; $RLA $0500
	; A &= (($42 << 1) | Carry) -> $81
	CMP #$81
	BNE TEST_Fail4
	LDA $0500
	CMP #$85
	BNE TEST_Fail4
	; RLA exists!
	INC <currentSubTest 
	
	;;; Test 7 [Unofficial Instructions Exist]: Does SRE exist? ;;;
	JSR TEST_UnofficialInstructions_Prep
	LDA #$FF
	SEC
	.byte $4F ; SRE Absolute
	.word $0500; $SRE $0500
	; A ^= ($42 >> 1) -> $DE
	CMP #$DE
	BNE TEST_Fail4	
	; SRE exists!
	INC <currentSubTest 
	
	;;; Test 8 [Unofficial Instructions Exist]: Does ASR exist? ;;;
	JSR TEST_UnofficialInstructions_Prep
	LDA #$F0
	.byte $4B, $42 ; ASR #$42
	; A = (A & $42) >> 1 = $20
	CMP #$20
	BNE TEST_Fail5	
	; ASR exists!
	INC <currentSubTest
	
	;;; Test 9 [Unofficial Instructions Exist]: Does RRA exist? ;;;
	JSR TEST_UnofficialInstructions_Prep
	LDA #$20
	SEC
	.byte $6F ; RRA Absolute
	.word $0500; $RRA $0500
	; A += ($42 >> 1) | $80*Carry = $C1
	CMP #$C1
	BNE TEST_Fail5	
	; RRA exists!
	INC <currentSubTest 
	
	;;; Test A [Unofficial Instructions Exist]: Does ARR exist? ;;;
	JSR TEST_UnofficialInstructions_Prep
	LDA #$F0
	SEC
	.byte $6B, $42 ; ARR #$42
	; A = ((A & $42) >> 1) | $80*Carry = $A0
	; NOTE: This instruction also changes the flags in a unique way.
	; I'm not testing for hte flag stuff here.
	CMP #$A0
	BNE TEST_Fail5		
	; ARR exists!
	INC <currentSubTest
	
	;;; Test B [Unofficial Instructions Exist]: Does SAX exist? ;;;
	JSR TEST_UnofficialInstructions_Prep
	LDA #$F0
	LDX #$2F
	.byte $8F ; SAX $0500
	.word $0500
	;$500 = (A&X)
	LDA $0500
	CMP #$20
	BNE TEST_Fail5
	; SAX exists!
	INC <currentSubTest
	
	;;; Test C [Unofficial Instructions Exist]: Does ANE exist? ;;;
	JSR TEST_UnofficialInstructions_Prep
	LDA #$FF
	LDX #$F0
	.byte $8B, $30 ; ANE #$30
	; Due to the way this instruction varies on different CPUs, let's just confirm A is no longer $FF
	CMP #$FF
	BEQ TEST_Fail5	
	; ANE exists!
	INC <currentSubTest
	
	;;; Test D [Unofficial Instructions Exist]: Does SHA exist? ;;;
	JSR TEST_UnofficialInstructions_Prep
	; Test the unstable part too, why not.
	LDA #$1F
	LDX #$FF
	LDY #$80
	.byte $9F ; SHA $0500
	.word $1E80 ; Use a mirror
	; This goes unstable, so the high byte of the target address will be changed.
	; Hi = ($1E+1) & A & X;
	; 	 = $05
	; $500 = A & X & H
	;	   = $0D & $15 & $1F
	;	   = 5
	; H is the high byte of the target address +1.
	; So we should write $05 to $0500
	LDA $0700
	CMP #$1F
	BNE TEST_Fail5
	; SHA exists!
	INC <currentSubTest
	
	;;; Test E [Unofficial Instructions Exist]: Does SHX exist? ;;;
	JSR TEST_UnofficialInstructions_Prep
	LDA #$00
	LDX #$05
	LDY #$80
	.byte $9E ; SHX $0500
	.word $1E80 ; Use a mirror
	; This goes unstable, so the high byte of the target address will be changed.
	; Hi = ($1E+1) & X;
	; 	 = $05
	; $500 = X & H
	; H is the high byte of the target address +1.
	; So we should write $05 to $0500
	LDA $0500
	CMP #$05
	BNE TEST_Fail5
	; SHX exists!
	INC <currentSubTest
	
	JMP TEST_UnofficialInstructions_Continue
TEST_Fail5:	; This is in the middle of the test, since it saves bytes to branch here.
	JMP TEST_Fail
TEST_UnofficialInstructions_Continue:

	;;; Test F [Unofficial Instructions Exist]: Does SHY exist? ;;;
	JSR TEST_UnofficialInstructions_Prep
	LDA #$00
	LDX #$80
	LDY #$05
	.byte $9C ; SHY $0500
	.word $1E80 ; Use a mirror
	; This goes unstable, so the high byte of the target address will be changed.
	; Hi = ($1E+1) & Y;
	; 	 = $05
	; $500 = Y & H
	; H is the high byte of the target address +1.
	; So we should write $05 to $0500
	LDA $0500
	CMP #$05
	BNE TEST_Fail5
	; SHY exists!
	INC <currentSubTest
	
	;;; Test G [Unofficial Instructions Exist]: Does SHS exist? ;;;
	JSR TEST_UnofficialInstructions_Prep
	TSX
	STX $501
	LDA #$1F
	LDX #$FF
	LDY #$80
	.byte $9B ; SHS $0500
	.word $1E80 ; Use a mirror
	; This goes unstable, so the high byte of the target address will be changed.
	; Hi = ($1E+1) & A & X;
	; 	 = $05
	; $500 = X & H
	; H is the high byte of the target address before adding the Y offset.
	; So we should write $05 to $0500
	; Before we check $0500, this instruction just destroyed the stack pointer.
	TSX
	CPX $0501
	BNE TEST_UnofficialInstructions_SHS_Continue
	; The stack pointer was unchanged?!
	JMP TEST_Fail
TEST_UnofficialInstructions_SHS_Continue:
	LDX $501
	TXS ; Fix the stack pointer.
	LDA $0700
	CMP #$1F ; See if this was the right value too.
	BNE TEST_Fail5
	; SHS exists!
	INC <currentSubTest
	
	;;; Test H [Unofficial Instructions Exist]: Does SHA ($zp), Y exist? ;;;
	JSR TEST_UnofficialInstructions_Prep
	; Test the unstable part too, why not.
	LDA #$80
	STA <$50
	LDA #$1E
	STA <$51 ; ($51) = $1E80
	LDA #$1F
	LDX #$FF
	LDY #$80
	.byte $93, $50 ; SHA ($50) -> $1E80
	; This goes unstable, so the high byte of the target address will be changed.
	; Hi = ($1E+1) & A & X;
	; 	 = $05
	; $500 = A & X & H
	;	   = $0D & $15 & $1F
	;	   = 5
	; H is the high byte of the target address +1.
	; So we should write $05 to $0500
	LDA $0700
	CMP #$1F
	BNE TEST_Fail5
	; SHA ($zp), Y exists!
	INC <currentSubTest

	;;; Test I [Unofficial Instructions Exist]: Does LAX exist? ;;;
	JSR TEST_UnofficialInstructions_Prep
	.byte $AF ; LAX $0500
	.word $0500
	;A = $0500; X = $0500
	CMP $0500
	BNE TEST_Fail5
	CPX $0500
	BNE TEST_Fail5
	; LAX exists!
	INC <currentSubTest
	
	;;; Test J [Unofficial Instructions Exist]: Does LXA exist? ;;;
	JSR TEST_UnofficialInstructions_Prep
	LDA #$1F 
	LDX #$F0
	.byte $AB, $30 ; LXA #$30
	; A = (A|MAGIC) & $30; X = A;
	; another one where we'll just check to see if these changed at all.
	CMP #$1F
	BEQ TEST_Fail5
	CPX #$F0
	BEQ TEST_Fail5
	; LXA exists!
	INC <currentSubTest
	
	;;; Test K [Unofficial Instructions Exist]: Does LAE exist? ;;;
	JSR TEST_UnofficialInstructions_Prep
	; This also destroys the stack pointer, so...
	TSX
	STX $501
	LDA #$33
	STA $500
	LDX #$82
	TXS
	; The stack pointer is now $83 for this test.
	.byte $BB ; LAE $500, Y
	.word $0500 
	; A = StackPointer & Immediate
	; And then transfer A to X and StackPointer.
	; So let's fix the stack pointer first.
	STX <$FD
	LDX $501
	TXS	; Fix the stack pointer
	CMP #$02
	BNE TEST_Fail6
	LDX <$FD
	CPX #$02
	BNE TEST_Fail6
	; LAE exists!
	INC <currentSubTest
	
	;;; Test L [Unofficial Instructions Exist]: Does DCP exist? ;;;
	JSR TEST_UnofficialInstructions_Prep
	LDA #$41
	.byte $CF	; DCP $0500
	.word $0500
	BNE TEST_Fail6	
	; DCP exists!
	INC <currentSubTest
	
	;;; Test M [Unofficial Instructions Exist]: Does AXS exist? ;;;
	JSR TEST_UnofficialInstructions_Prep
	LDA #$F0
	LDX #$66
	.byte $CB, $40; AXS #$40
	; X = (A&X)-M
	CPX #$20
	BNE TEST_Fail6	
	; AXS exists!
	INC <currentSubTest
	
	;;; Test N [Unofficial Instructions Exist]: Does ISC exist? ;;;
	JSR TEST_UnofficialInstructions_Prep
	LDA #$22
	.byte $EF	; ISC $0500
	.word $0500
	; Increment $0500, then subtract it from A
	CMP #$DF
	BNE TEST_Fail6	
	; LAE exists!
	INC <currentSubTest
	;; END OF TEST ;;
	LDA #1
	RTS
TEST_Fail6:	; This is in the middle of the test, since it saves bytes to branch here.
	JMP TEST_Fail
;;;;;;;;;;;;;;;;;

; These upcoming subroutines are used in the individual opcode tests for the unofficial isntructions.

TEST_VerifyInstructionIsOneByte:	; Write the following to address $5C0: [opcode] $60, $C8, $60
	LDA <Copy_A ; the opcode
	STA $5C0
	LDA #$60
	STA $5C1
	STA $5C3
	LDA #Reserved_C8	; It's just the value $C8
	STA $5C2
	LDA #$50
	STA <Reserved_C8
	STA <Reserved_C8+1
	LDX #0
	LDY #0
	JSR $5C0
	CPY #0
	BNE FAIL_WrongInstructionSize
	LDA <Copy_A ; the opcode
	RTS
;;;;;;;

TEST_VerifyInstructionIsTwoByte: ; Write the following to address $5C0: [opcode] $C8, $60
	LDA <Copy_A ; the opcode
	STA $5C0
	LDA #Reserved_C8	; It's just the value $C8
	STA $5C1
	LDA #$60
	STA $5C2
	LDA #$50
	STA <Reserved_C8
	STA <Reserved_C8+1
	LDX #0
	LDY #0
	JSR $5C0
	CPY #0
	BNE FAIL_WrongInstructionSize
	LDA <Copy_A ; the opcode
	RTS
;;;;;;;
	
TEST_VerifyInstructionIsThreeByte: ; Write the following to address $5C0: TXS, STX $7FF, LDX #0, [opcode], INY, INY, LDX $7FF, TXS, RTS. If those INY instructions get executed, the instruction was the wrong size. 
	LDX #0
TEST_VerifyInstructionIsThreeLoop:
	LDA TEST_UnOp_ThreeByte_RamFunc, X
	STA $5C0,X
	INX
	CPX #$E
	BNE TEST_VerifyInstructionIsThreeLoop
	LDA <Copy_A ; the opcode
	STA $5C6
	LDA #$50
	STA <Reserved_C8
	STA <Reserved_C8+1
	LDX #0
	LDY #0
	JSR $5C0
	CPY #0
	BNE FAIL_WrongInstructionSize
	LDA <Copy_A ; the opcode
	RTS
;;;;;;;

FAIL_WrongInstructionSize:	; We need to pull 4 different return addresses off the stack.
	PLA
	PLA
	PLA
	PLA
	PLA
	PLA
	PLA
	PLA
	LDA #2	; Error code 0.
	RTS

TEST_UnOp_ThreeByte_RamFunc:
	TSX
	STX $7FF
	LDX #0
	NOP
	INY
	INY
	LDX $7FF
	TXS
	RTS
;;;;;;


TEST_UnOp_RamFunc: ; this gets copy/pasted into RAM at address $0580
	NOP	; These can be replaced with a JSR instruction.
	NOP	; Certain operations have different behavior if a DMA occurs in the 2nd to last cycle.
	NOP	; So those instructions might put a JSR here to set things up and precisely time time a DMA. 
	LDY <Test_UnOp_Y
	TSX			; Some unofficial instructions modify the stack pointer
	STX <Copy_SP; make a copy of the stack pointer
	LDX <Test_UnOp_SP
	TXS	
	LDX <Copy_X ; restore X for the test.
	LDA <Test_UnOp_FlagsInit
	PHA
	LDA <Test_UnOp_A	
	PLP	; Get init flags ready for the test. The T flag isn't a concern.
TEST_UnOp_RamFuncTest: ; Ram Function TEST
	NOP	; Overwrite this with the test.
	NOP	; Overwrite this with the test.
	NOP	; Overwrite this with the test.
	PHA
	PHP	; push the flags from the test
	PLA ; Pull the status flags off into A
	AND #$CF ; mask away the B and T flag, which is set by PHP
	STA <Copy_Flags	; and store the flags here for later
	PLA
	STA <Copy_A  ; Store A
	STX <Copy_X	 ; Store X
	TSX
	STX <Copy_SP2; Store Stack Pointer
	STY <Copy_Y	 ; Store Y
	LDX <Copy_SP; Fix the stack pointer in case it was modified.
	TXS
	LDX <Copy_X ; restore X for the test results.
	RTS
TEST_UnOp_RamFuncEnd:
;;;;;;;;;;;;;;;;;;;;;
; It's a bit cursed to be creating constants here, but labels need to be defined before you can use them to create constants.
UnOpTest_Opcode = $0580+(TEST_UnOp_RamFuncTest-TEST_UnOp_RamFunc)
UnOpTest_Operand = UnOpTest_Opcode+1
UnOpTest_Operand2 = UnOpTest_Opcode+2
;;;;;;;	
TEST_UnOp_Setup:
	; The tests of the Unofficial Instructions will be using this function to set everything up.
	; Copy/Paste the test function into RAM.
	PHA
	LDX #0
TEST_UnOp_SetupLoop:
	LDA TEST_UnOp_RamFunc, X
	STA $580, X
	INX
	CPX #(TEST_UnOp_RamFuncEnd-TEST_UnOp_RamFunc)
	BNE TEST_UnOp_SetupLoop
	PLA
	STA UnOpTest_Opcode
	RTS
;;;;;;;
TEST_UnOp_SetupByAddressingMode:
	; Setting up RAM for the test!
	; The goal: around address $580, we have the code to run the test, but the operands are currently EA EA
	; This function will determine the addressing mode of the test based on the value of the opcode (The A Register)
	; Then a jump table is used to set up the operands of the test around $580.
	; For instance, if you want to test LDA $0500, it will jump to TEST_UnOp_SetupAddressingMode_Absolute
	; ... where the values $00 and $05 will be stored in the operands of the test.
	; Suppose the test is LDA $0500, X. The value stored will be ($0500-X) so the X offset would reach the correct byte. 
	; For zero page instructions, the second operand byte is intentionally left as a NOP.
	;
	; NOTE: These tests assume you have correct implementation of the various addressing modes.
	; In other words, the (indirect), Y tests will always use the exact same operands (always using Test_UnOp_IndirectPointerLo)
	; And the offset for (indirect, X)  test will always land on Test_UnOp_IndirectPointerLo
	
	STA <$FF
	STX <$FD
	; Determine the addressing mode of this instruction by examining the lower 6 bits.	
	; Assume A is the opcode
	STA <$02 ; 2 = opcode
	; get lower 5 bits.
	AND #$1F
	; store this in a temp location
	STA <$03 ; 3 = lower 5 bits of opcode.
	; check if we need to flip from an X offset to a Y offset;
	AND #$17
	CMP #$17
	BNE Test_UnOp_DontFlipXtoY
	LDA <$02 ; A = opcode
	AND #$C0 ; A = upper 2 bits of opcode
	CMP #$80 ; ; if only bit 7 is set, flip X to Y
	BNE Test_UnOp_DontFlipXtoY
	LDA <$03
	AND #$1E
	STA <$03	
Test_UnOp_DontFlipXtoY:
	LDA <$03
	ASL A
	TAX
	LDA Test_UnOp_SetupJumpTable,X
	STA <$0
	LDA Test_UnOp_SetupJumpTable+1,X
	STA <$1
	LDA <$FF
	LDX <$FD
	JMP [$0000]
	
Test_UnOp_SetupJumpTable:
	.word TEST_UnOp_SetupAddrMode_Immediate  ; 0 - Immediate
	.word TEST_Fail							 ; 1 - N/A
	.word TEST_UnOp_SetupAddrMode_Immediate  ; 2 - Immediate
	.word TEST_UnOp_SetupAddrMode_IndX  	 ; 3 - (Indirect, X)
	.word TEST_UnOp_SetupAddrMode_ZP 		 ; 4 - ZeroPage
	.word TEST_Fail							 ; 5 - N/A
	.word TEST_Fail							 ; 6 - N/A
	.word TEST_UnOp_SetupAddrMode_ZP 		 ; 7 - ZeroPage
	.word TEST_Fail							 ; 8 - N/A
	.word TEST_UnOp_SetupAddrMode_Immediate  ; 9 - Immediate
	.word TEST_Fail							 ; A - N/A
	.word TEST_UnOp_SetupAddrMode_Immediate  ; B - Immediate
	.word TEST_UnOp_SetupAddrMode_Abs  		 ; C - Absolute
	.word TEST_Fail							 ; D - N/A
	.word TEST_Fail							 ; E - N/A
	.word TEST_UnOp_SetupAddrMode_Abs  		 ; F - Absolute
	.word TEST_Fail							 ; 10- N/A
	.word TEST_Fail							 ; 11- N/A
	.word TEST_Fail							 ; 12- N/A (HLT is tested elsewhere)
	.word TEST_UnOp_SetupAddrMode_IndY  	 ; 13- (Indirect), Y
	.word TEST_UnOp_SetupAddrMode_ZPX		 ; 14- ZeroPage, X
	.word TEST_Fail							 ; 15- N/A
	.word TEST_UnOp_SetupAddrMode_ZPY		 ; 16- ZeroPage, Y !! Not always the case for the official instructions, but it's convenient for this jump table.
	.word TEST_UnOp_SetupAddrMode_ZPX		 ; 17- ZeroPage, X (or Y if bit 7 is set and bit 6 is not)
	.word TEST_Fail							 ; 18- N/A
	.word TEST_Fail							 ; 19- N/A
	.word TEST_UnOp_SetupAddrMode_Implied    ; 1A- Implied
	.word TEST_UnOp_SetupAddrMode_AbsY 		 ; 1B- Absolute, Y
	.word TEST_UnOp_SetupAddrMode_AbsX 		 ; 1C- Absolute, X
	.word TEST_Fail							 ; 1D- N/A
	.word TEST_UnOp_SetupAddrMode_AbsY 		 ; 1E- Absolute, Y !! Not always the case for the official instructions, but we don't care about that here.
	.word TEST_UnOp_SetupAddrMode_AbsX 		 ; 1F- Absolute, X (or Y if bit 7 is set and bit 6 is not)


TEST_UnOp_SetupAddrMode_Implied:
	; I don't think there are any implied unofficial instructions, so uh... I guess we'll just ignore this label.

TEST_UnOp_SetupAddrMode_Immediate:
	LDA Test_UnOp_ValueAtAddressForTest	; Load the operand of the immediate instruction
	STA UnOpTest_Operand				; and store it in RAM 1 byte after where we stored the opcode.
	JSR TEST_VerifyInstructionIsTwoByte ; Also verify the length of the instruction.
	RTS

TEST_UnOp_SetupAddrMode_IndX:
	STX <Copy_X
	LDA #Test_UnOp_IndirectPointerLo
	SEC
	SBC <Copy_X
	STA UnOpTest_Operand
	LDA <Test_UnOp_OperandTargetAddrHi
	STA <Test_UnOp_IndirectPointerHi
	LDA <Test_UnOp_OperandTargetAddrLo
	STA <Test_UnOp_IndirectPointerLo
	LDA <Test_UnOp_ValueAtAddressForTest
	LDY #0
	STA [Test_UnOp_ExpectedResultAddrLo],Y
	LDY <Copy_Y
	JSR TEST_VerifyInstructionIsTwoByte
	RTS

TEST_UnOp_SetupAddrMode_IndY:
	;;; Set up the test for (Indirect), Y addressed ;;;
	LDA #Test_UnOp_IndirectPointerLo
	STA UnOpTest_Operand	
	STY <Copy_Y
	LDA <Test_UnOp_OperandTargetAddrHi
	STA <Test_UnOp_IndirectPointerHi
	LDA <Test_UnOp_OperandTargetAddrLo
	SEC
	SBC <Copy_Y	
	STA Test_UnOp_IndirectPointerLo
	BCS TEST_UnOp_IndY_DontDecHigh
	DEC <Test_UnOp_IndirectPointerHi
TEST_UnOp_IndY_DontDecHigh	
	LDA <Test_UnOp_ValueAtAddressForTest
	LDY #0
	STA [Test_UnOp_ExpectedResultAddrLo],Y
	LDY <Copy_Y
	JSR TEST_VerifyInstructionIsTwoByte
	RTS

TEST_UnOp_SetupAddrMode_ZP:
	;;; Set up the test for Zero Page addressed ;;;
	LDA <Test_UnOp_OperandTargetAddrLo
	; Only ever test from $50 to $5F
	AND #$0F
	ORA #$50
	STA UnOpTest_Operand
	STA <Test_UnOp_ExpectedResultAddrLo; Modify the pointers
	STA <Test_UnOp_OperandTargetAddrLo ; Modify the pointers
	LDA #0
	STA <Test_UnOp_ExpectedResultAddrHi; Modify the pointers
	STA <Test_UnOp_OperandTargetAddrHi; Modify the pointers
	LDA <Test_UnOp_ValueAtAddressForTest; Load the initial value for the test.
	STY <Copy_Y
	LDY #0
	STA [Test_UnOp_OperandTargetAddrLo],Y
	STA [Test_UnOp_ExpectedResultAddrLo],Y
	LDY <Copy_Y
	JSR TEST_VerifyInstructionIsTwoByte
	RTS

TEST_UnOp_SetupAddrMode_ZPX:
	;;; Set up the test for Zero Page addressed ;;;
	STX <Copy_X
	LDA <Test_UnOp_OperandTargetAddrLo
	; Only ever test from $50 to $5F
	AND #$0F
	ORA #$50
	STA <Test_UnOp_ExpectedResultAddrLo; Modify the pointers
	SEC
	SBC <Copy_X	
	STA UnOpTest_Operand
	STA <Test_UnOp_OperandTargetAddrLo ; Modify the pointers
	LDA #0
	STA <Test_UnOp_ExpectedResultAddrHi; Modify the pointers
	STA <Test_UnOp_OperandTargetAddrHi; Modify the pointers
	LDA <Test_UnOp_ValueAtAddressForTest; Load the initial value for the test.
	STY <Copy_Y
	LDY #0
	STA [Test_UnOp_ExpectedResultAddrLo],Y
	LDY <Copy_Y
	JSR TEST_VerifyInstructionIsTwoByte
	RTS

TEST_UnOp_SetupAddrMode_ZPY:
	;;; Set up the test for Zero Page addressed ;;;
	STY <Copy_Y
	LDA <Test_UnOp_OperandTargetAddrLo
	; Only ever test from $50 to $5F
	AND #$0F
	ORA #$50
	STA <Test_UnOp_ExpectedResultAddrLo; Modify the pointers
	SEC
	SBC <Copy_Y	
	STA UnOpTest_Operand
	STA <Test_UnOp_OperandTargetAddrLo ; Modify the pointers
	LDA #0
	STA <Test_UnOp_ExpectedResultAddrHi; Modify the pointers
	STA <Test_UnOp_OperandTargetAddrHi; Modify the pointers
	LDA <Test_UnOp_ValueAtAddressForTest; Load the initial value for the test.
	LDY #0
	STA [Test_UnOp_ExpectedResultAddrLo],Y
	LDY <Copy_Y
	JSR TEST_VerifyInstructionIsTwoByte
	RTS
;;;;;;;
TEST_UnOp_SetupAddrMode_Abs:
	;;; Set up the test for Absolute addressed ;;;
	LDA <Test_UnOp_OperandTargetAddrLo
	STA UnOpTest_Operand
	LDA <Test_UnOp_OperandTargetAddrHi
	STA UnOpTest_Operand2
	LDA <Test_UnOp_ValueAtAddressForTest
	STY <Copy_Y
	LDY #0
	STA [Test_UnOp_OperandTargetAddrLo],Y
	STA [Test_UnOp_ExpectedResultAddrLo],Y
	LDY <Copy_Y
	JSR TEST_VerifyInstructionIsThreeByte
	RTS
;;;;;;;
TEST_UnOp_SetupAddrMode_AbsX:
;;; Set up the test for Absolute, X addressed ;;;
	STX <Copy_X
	LDA <Test_UnOp_OperandTargetAddrHi
	STA UnOpTest_Operand2
	LDA <Test_UnOp_OperandTargetAddrLo
	SEC
	SBC <Copy_X	
	STA UnOpTest_Operand
	BCS TEST_UnOp_AbsX_DontDecHigh
	DEC UnOpTest_Operand2
TEST_UnOp_AbsX_DontDecHigh	
	LDA <Test_UnOp_ValueAtAddressForTest
	STY <Copy_Y
	LDY #0
	STA [Test_UnOp_OperandTargetAddrLo],Y
	STA [Test_UnOp_ExpectedResultAddrLo],Y
	LDY <Copy_Y
	JSR TEST_VerifyInstructionIsThreeByte
	RTS
TEST_UnOp_SetupAddrMode_AbsY:
	STY <Copy_Y
	LDA <Test_UnOp_OperandTargetAddrHi
	STA UnOpTest_Operand2
	LDA <Test_UnOp_OperandTargetAddrLo
	SEC
	SBC <Copy_Y	
	STA UnOpTest_Operand
	BCS TEST_UnOp_AbsY_DontDecHigh
	DEC UnOpTest_Operand2
TEST_UnOp_AbsY_DontDecHigh	
	LDA <Test_UnOp_ValueAtAddressForTest
	LDY #0
	STA [Test_UnOp_OperandTargetAddrLo],Y
	STA [Test_UnOp_ExpectedResultAddrLo],Y
	LDY <Copy_Y
	JSR TEST_VerifyInstructionIsThreeByte
	RTS
;;;;;;;

TEST_PrepAXYForTest:
	LDX <Test_UnOp_X
	LDY <Test_UnOp_Y
	LDA <Test_UnOp_A
	RTS
;;;;;;;

TEST_UnOpRunTest:
	JSR TEST_PrepAXYForTest	; Set up X and Y for the indexing offsets.
	LDA <$FF ; the opcode
	JSR TEST_UnOp_SetupByAddressingMode ; Set up the operands around $580
	JSR TEST_PrepAXYForTest	; Set up A, X, and Y for the initial values of the test.
	STA <Copy_A
	STX <Copy_X
	JSR $0580	; Run the test!
	RTS
;;;;;;;

Test_UnOpEvaluateResults:
	LDY #0
	LDA [Test_UnOp_ExpectedResultAddrLo],Y
	CMP <Test_UnOp_ValueAtAddressResult
	BNE FAIL_UnOpTest ; Error code 1: The result at the expected address was incorrect
	INC <currentSubTest
Test_UnOpEvaluateResults_StartA:
	LDA <Copy_A
	CMP <Test_UnOp_CMP
	BNE FAIL_UnOpTest ; Error code 2: The result of the A register was incorrect
	INC <currentSubTest
	LDX <Copy_X
	CPX <Test_UnOp_CPX
	BNE FAIL_UnOpTest ; Error code 3: The result of the X register was incorrect
	INC <currentSubTest
	LDY <Copy_Y
	CPY <Test_UnOp_CPY
	BNE FAIL_UnOpTest ; Error code 4: The result of the Y register was incorrect
	INC <currentSubTest
	LDA <Copy_Flags
	CMP <Test_UnOp_CM_Flags
	BNE FAIL_UnOpTest ; Error code 5: The result of the flags were incorrect
	RTS ; Pass!
FAIL_UnOpTest:
	PLA	; Pull of the Return Address
	PLA	;
	PLA
	PLA
	JMP TEST_Fail ; and fail the test.
	
Test_UnOpEvaluateResultsIncludingStackPointer:
	LDY #0
	LDA [Test_UnOp_ExpectedResultAddrLo],Y
	CMP <Test_UnOp_ValueAtAddressResult
	BNE FAIL_UnOpTest ; Error code 1: The result at the expected address was incorrect
	INC <currentSubTest
	LDA <Copy_A
	CMP <Test_UnOp_CMP
	BNE FAIL_UnOpTest ; Error code 2: The result of the A register was incorrect
	INC <currentSubTest
	LDX <Copy_X
	CPX <Test_UnOp_CPX
	BNE FAIL_UnOpTest ; Error code 3: The result of the X register was incorrect
	INC <currentSubTest
	LDY <Copy_Y
	CPY <Test_UnOp_CPY
	BNE FAIL_UnOpTest ; Error code 4: The result of the Y register was incorrect
	INC <currentSubTest
	LDA <Copy_Flags
	CMP <Test_UnOp_CM_Flags
	BNE FAIL_UnOpTest ; Error code 5: The result of the flags were incorrect
	INC <currentSubTest
	LDA <Copy_SP2
	CMP <Test_UnOp_CPS
	BNE FAIL_UnOpTest ; Error code 6: The result of the stack pointer was incorrect
	RTS ; Pass!

TEST_RunTest_AddrInitAXYF:
	;.word TargetAddress
	;.byte Initial, A, X, Y, Flags
	;.word ResultAddress
	;.byte result, r_A, r_X, r_Y, r_Flags
	STA <$FF
	JSR CopyReturnAddressToByte0
	LDY #0
	LDX #0
TEST_AddrInitAXYF_PreLoop:
	LDA [$0000],Y
	STA <Test_UnOp_OperandTargetAddrLo,X
	INY
	INX
	CPX #7 ; Set up $20 through $26
	BNE TEST_AddrInitAXYF_PreLoop
	LDX #0
TEST_AddrInitAXYF_PreLoop2:
	LDA [$0000],Y
	STA <Test_UnOp_ExpectedResultAddrLo,X
	INY
	INX
	CPX #7 ; Set up $28 through $2E
	BNE TEST_AddrInitAXYF_PreLoop2
	; With the varaibles all set up, let's prep the test:
	JSR FixRTS
	JSR TEST_UnOpRunTest
	; Evaluating the test.
	LDA <initialSubTest
	STA <currentSubTest	
	JSR Test_UnOpEvaluateResults
	; If you made it this far, we passed this test!
	; (not necessarily the entire suite, but this specific test, at least)
	LDA UnOpTest_Opcode ; reset this value before the next test, assuming another one follows
	RTS
;;;;;;;

TEST_RunTest_AddrInitAXYFS:
	;.word TargetAddress
	;.byte Initial, A, X, Y, Flags, StackPointer
	;.word ResultAddress
	;.byte result, r_A, r_X, r_Y, r_Flags, r_StackPointer
	STA <$FF
	JSR CopyReturnAddressToByte0
	LDY #0
	LDX #0
TEST_AddrInitAXYFS_PreLoop:
	LDA [$0000],Y
	STA <Test_UnOp_OperandTargetAddrLo,X
	INY
	INX
	CPX #16 ; Set up $28 through $2F
	BNE TEST_AddrInitAXYFS_PreLoop
	; With the varaibles all set up, let's prep the test:
	JSR FixRTS
	JSR TEST_UnOpRunTest
	; Evaluating the test.
	LDA <initialSubTest
	STA <currentSubTest	
	JSR Test_UnOpEvaluateResultsIncludingStackPointer
	; If you made it this far, we passed this test!
	; (not necessarily the entire suite, but this specific test, at least)
	LDA UnOpTest_Opcode ; reset this value before the next test, assuming another one follows
	RTS
;;;;;;;
	
TEST_RunTest_ImmOperandAXYF:
	STA <$FF
	JSR CopyReturnAddressToByte0
	LDY #0
	LDX #0
TEST_ImmOperandAXYF_PreLoop:
	LDA [$0000],Y
	STA <Test_UnOp_ValueAtAddressForTest,X
	INY
	INX
	CPX #5 ; Set up $22 through $26
	BNE TEST_ImmOperandAXYF_PreLoop
	LDX #0
TEST_ImmOperandAXYF_PreLoop2:
	LDA [$0000],Y
	STA <Test_UnOp_CMP,X
	INY
	INX
	CPX #4 ; Set up $22 through $26
	BNE TEST_ImmOperandAXYF_PreLoop2
	JSR FixRTS
	JSR TEST_UnOpRunTest
	LDA #2
	STA <currentSubTest	
	JSR Test_UnOpEvaluateResults_StartA
	; If you made it this far, we passed this test!
	; (not necessarily the entire suite, but this specific test, at least)
	LDA UnOpTest_Opcode ; reset this value before the next test, assuming another one follows
	RTS
;;;;;;;

;Test_UnOp_OperandTargetAddrLo = $20
;Test_UnOp_OperandTargetAddrHi = $21
;Test_UnOp_ValueAtAddressForTest = $22
;Test_UnOp_A = $23
;Test_UnOp_X = $24
;Test_UnOp_Y = $25
;Test_UnOp_FlagsInit = $26
;Test_UnOp_SP = $27
;Test_UnOp_ExpectedResultAddrLo = $28
;Test_UnOp_ExpectedResultAddrHi = $29
;Test_UnOp_ValueAtAddressResult = $2A
;Test_UnOp_CMP = $2B
;Test_UnOp_CPX = $2C
;Test_UnOp_CPY = $2D
;Test_UnOp_CM_Flags = $2E
;Test_UnOp_CPS = $2F

;Test_UnOp_IndirectPointerLo = $30
;Test_UnOp_IndirectPointerHi = $31

TEST_SLO_03:
	LDA #$03
	BNE TEST_SLO
TEST_SLO_07:
	LDA #$07
	BNE TEST_SLO
TEST_SLO_0F:
	LDA #$0F
	BNE TEST_SLO
TEST_SLO_13:
	LDA #$13
	BNE TEST_SLO
TEST_SLO_17:
	LDA #$17
	BNE TEST_SLO
TEST_SLO_1B:
	LDA #$1B
	BNE TEST_SLO
TEST_SLO_1F:
	LDA #$1F
TEST_SLO:
	JSR TEST_UnOp_Setup; Set the opcode
	
	; A lot of these unofficial instruction tests will tell you to "see TEST_SLO" for an explanation. Here it is!
	
	; First of all, the test happens in RAM around address $580.
	; The instruction we are testing for begins at address $593.
	; If your emulator has some debug tools, (Or if it doesn't, your IDE probably does...) consider setting a breakpoint when the program counter is at address $593.
	;	
	; The ASM code in this section might look a little confusing...
	; These JSR instructions lead to subroutines that modify the return address
	; so the .word and .byte parts don't get executed.
	; The format of these tests look like this:	
	;
	; JSR TEST_RunTest_AddrInitAXYF
	; iAddress
	; iValue 
	; iA,   iX,   iY,   iflags
	; rAddress
	; rValue 
	; rA,   rX,   rY,   rflags
	;
	; The address at "iAddress" will be assigned the value of "iValue". 
	; The A register will be assigned the value of iA, the X register will be assigned the value of iX, and so on.
	; Then the test runs, which is pretty much just running the instruction in question. In this case, it's some form of SLO.
	; Then, the value of rAddress is compared with rValue. (If it doesn't match, return error code 1)
	; Then, the value of the A register is compared with rA. (If it doesn't match, return error code 2)
	; Then, the value of the X register is compared with rX. (If it doesn't match, return error code 3)
	; Then, the value of the Y register is compared with rY. (If it doesn't match, return error code 4)
	; Then, the value of the status flags are compared with rflags. (If they don't match, return error code 5)
	
	JSR TEST_RunTest_AddrInitAXYF
	.word $0500                                     ; Initialize address $500 with...
	.byte $40                                       ; a value of $40.
	.byte $01, $64, $45, (flag_i | flag_c | flag_z) ; A=$01, X=$64, Y=$45, Flags = I|C|Z
	.word $0500                                     ; Then, after the test runs, check address $500...
	.byte $80                                       ; for a value of $80.
	.byte $81, $64, $45, (flag_i | flag_n)          ; Check if A=$81, X=$64, Y=$45, and flags = I|N
	; SLO ;
	; Let's walk through this one for the sake of documentation.
	; $0500 = $40, A = $01
	; SLO will shift the value at $0500 to the left.
	; $40 << 1 = $80, so that's the new value at $0500
	; then, bitwise OR the A register with the result of that previous step.
	; $01 | $80 = $81.
	; So the result is, $0500 = $80, and A = $81.
	; The Negative, Carry, and Zero are the only flags modified, and they behave like ORA in this instance.
	; So in this case, the negative flag is set, carry is cleared, and zero is cleared.	
	
	JSR TEST_RunTest_AddrInitAXYF
	.word $057F                                              ; Initialize address $57F with...
	.byte $FF                                                ; a value of $FF.
	.byte $00, $21, $9E, (flag_i | flag_v)                   ; A=$00, X=$21, Y=$9E, Flags = I|V
	.word $057F                                              ; Then, after the test runs, check address $57F...
	.byte $FE                                                ; for a value of $FE.
	.byte $FE, $21, $9E, (flag_i | flag_n | flag_c | flag_v) ; Check if A=$FE, X=$21, Y=$9E, and flags = I|N|C|V
	
	JSR TEST_RunTest_AddrInitAXYF
	.word $05FF                            ; Initialize address $5FF with...
	.byte $00                              ; a value of $00.
	.byte $00, $FF, $FF, (flag_i | flag_c) ; A=$00, X=$FF, Y=$FF, Flags = I|C
	.word $05FF                            ; Then, after the test runs, check address $5FF...
	.byte $00                              ; for a value of $00.
	.byte $00, $FF, $FF, (flag_i | flag_z) ; Check if A=$00, X=$FF, Y=$FF, and flags = I|Z
	; This one really doesn't have any wild edge cases or anything.
	; it's probably a safe bet to assume if your emulator made it this far, then it's good.	
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

TEST_RLA_23:
	LDA #$23
	BNE TEST_RLA
TEST_RLA_27:
	LDA #$27
	BNE TEST_RLA
TEST_RLA_2F:
	LDA #$2F
	BNE TEST_RLA
TEST_RLA_33:
	LDA #$33
	BNE TEST_RLA
TEST_RLA_37:
	LDA #$37
	BNE TEST_RLA
TEST_RLA_3B:
	LDA #$3B
	BNE TEST_RLA
TEST_RLA_3F:
	LDA #$3F
TEST_RLA:
	JSR TEST_UnOp_Setup; Set the opcode
	
	; see TEST_SLO for an explanation of the format here.
	
	JSR TEST_RunTest_AddrInitAXYF
	.word $0500
	.byte $44
	.byte $C1, $64, $45, (flag_i | flag_c | flag_z)
	.word $0500
	.byte $89
	.byte $81, $64, $45, (flag_i | flag_n)
	; RLA ;
	; ROL, then AND ;

	JSR TEST_RunTest_AddrInitAXYF
	.word $0544
	.byte $0F
	.byte $33, $7B, $FE, (flag_i | flag_z | flag_v)
	.word $0544
	.byte $1E
	.byte $12, $7B, $FE, (flag_i | flag_v)

	JSR TEST_RunTest_AddrInitAXYF
	.word $05BF
	.byte $00
	.byte $A5, $E1, $00, (flag_i | flag_z | flag_n)
	.word $05BF
	.byte $00
	.byte $00, $E1, $00, (flag_i | flag_z)

	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

TEST_SRE_43:
	LDA #$43
	BNE TEST_SRE
TEST_SRE_47:
	LDA #$47
	BNE TEST_SRE
TEST_SRE_4F:
	LDA #$4F
	BNE TEST_SRE
TEST_SRE_53:
	LDA #$53
	BNE TEST_SRE
TEST_SRE_57:
	LDA #$57
	BNE TEST_SRE
TEST_SRE_5B:
	LDA #$5B
	BNE TEST_SRE
TEST_SRE_5F:
	LDA #$5F
TEST_SRE:
	JSR TEST_UnOp_Setup; Set the opcode
	
	; see TEST_SLO for an explanation of the format here.
	
	JSR TEST_RunTest_AddrInitAXYF
	.word $0500
	.byte $F0
	.byte $5A, $64, $45, (flag_i | flag_c | flag_z)
	.word $0500
	.byte $78
	.byte $22, $64, $45, (flag_i)
	; SRE ;
	; LSR, then EOR ;

	JSR TEST_RunTest_AddrInitAXYF
	.word $053A
	.byte $48
	.byte $24, $8C, $8D, (flag_i | flag_v)
	.word $053A
	.byte $24
	.byte $00, $8C, $8D, (flag_i | flag_v | flag_z)
	
	JSR TEST_RunTest_AddrInitAXYF
	.word $05B1
	.byte $01
	.byte $00, $00, $00, (flag_i)
	.word $05B1
	.byte $00
	.byte $00, $00, $00, (flag_i | flag_c | flag_z)

	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

TEST_RRA_63:
	LDA #$63
	BNE TEST_RRA
TEST_RRA_67:
	LDA #$67
	BNE TEST_RRA
TEST_RRA_6F:
	LDA #$6F
	BNE TEST_RRA
TEST_RRA_73:
	LDA #$73
	BNE TEST_RRA
TEST_RRA_77:
	LDA #$77
	BNE TEST_RRA
TEST_RRA_7B:
	LDA #$7B
	BNE TEST_RRA
TEST_RRA_7F:
	LDA #$7F
TEST_RRA:
	JSR TEST_UnOp_Setup; Set the opcode
	
	; see TEST_SLO for an explanation of the format here.
	
	JSR TEST_RunTest_AddrInitAXYF
	.word $0500
	.byte $D0
	.byte $07, $64, $45, (flag_i | flag_c | flag_z)
	.word $0500
	.byte $E8
	.byte $EF, $64, $45, (flag_i | flag_n)
	; RRA ;
	; ROR, then ADC ;
	; Notably, the ROR behavior updates the carry flag before the ADC.
	
	JSR TEST_RunTest_AddrInitAXYF
	.word $0566
	.byte $11
	.byte $F7, $12, $34, (flag_i | flag_z | flag_v)
	.word $0566
	.byte $08
	.byte $00, $12, $34, (flag_i | flag_z | flag_c)
	
	JSR TEST_RunTest_AddrInitAXYF
	.word $05E1
	.byte $20
	.byte $90, $7B, $F2, (flag_i | flag_z | flag_c)
	.word $05E1
	.byte $90
	.byte $20, $7B, $F2, (flag_i | flag_v | flag_c)
	
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

TEST_SAX_83:
	LDA #$83
	BNE TEST_SAX
TEST_SAX_87:
	LDA #$87
	BNE TEST_SAX
TEST_SAX_8F:
	LDA #$8F
	BNE TEST_SAX
TEST_SAX_97:
	LDA #$97
TEST_SAX:
	JSR TEST_UnOp_Setup; Set the opcode
	
	; see TEST_SLO for an explanation of the format here.
	
	JSR TEST_RunTest_AddrInitAXYF
	.word $0500
	.byte $5A
	.byte $F3, $3F, $45, (flag_i | flag_c | flag_z | flag_v)
	.word $0500
	.byte $33
	.byte $F3, $3F, $45, (flag_i | flag_c | flag_z | flag_v)
	; SAX ;
	; Store A & X;
	
	JSR TEST_RunTest_AddrInitAXYF
	.word $05D3
	.byte $21
	.byte $5A, $A5, $45, (flag_i)
	.word $05D3
	.byte $00
	.byte $5A, $A5, $45, (flag_i)
	
	JSR TEST_RunTest_AddrInitAXYF
	.word $05EC
	.byte $21
	.byte $90, $E0, $45, (flag_i | flag_c)
	.word $05EC
	.byte $80
	.byte $90, $E0, $45, (flag_i | flag_c)

	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

TEST_LAX_A3:
	LDA #$A3
	BNE TEST_LAX
TEST_LAX_A7:
	LDA #$A7
	BNE TEST_LAX
TEST_LAX_AF:
	LDA #$AF
	BNE TEST_LAX
TEST_LAX_B3:
	LDA #$B3
	BNE TEST_LAX
TEST_LAX_B7:
	LDA #$B7
	BNE TEST_LAX
TEST_LAX_BF:
	LDA #$BF
TEST_LAX:
	JSR TEST_UnOp_Setup; Set the opcode
	
	; see TEST_SLO for an explanation of the format here.
	
	JSR TEST_RunTest_AddrInitAXYF
	.word $0500
	.byte $00
	.byte $07, $64, $45, (flag_i | flag_c | flag_v)
	.word $0500
	.byte $00
	.byte $00, $00, $45, (flag_i | flag_c | flag_z | flag_v)
	; LAX ;
	; Load A and X ;

	JSR TEST_RunTest_AddrInitAXYF
	.word $05B3
	.byte $9F
	.byte $00, $00, $88, (flag_i | flag_z)
	.word $05B3
	.byte $9F
	.byte $9F, $9F, $88, (flag_i | flag_n)

	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

TEST_DCP_C3:
	LDA #$C3
	BNE TEST_DCP
TEST_DCP_C7:
	LDA #$C7
	BNE TEST_DCP
TEST_DCP_CF:
	LDA #$CF
	BNE TEST_DCP
TEST_DCP_D3:
	LDA #$D3
	BNE TEST_DCP
TEST_DCP_D7:
	LDA #$D7
	BNE TEST_DCP
TEST_DCP_DB:
	LDA #$DB
	BNE TEST_DCP
TEST_DCP_DF:
	LDA #$DF
TEST_DCP:
	JSR TEST_UnOp_Setup; Set the opcode
	
	; see TEST_SLO for an explanation of the format here.
	
	JSR TEST_RunTest_AddrInitAXYF
	.word $0500
	.byte $F5
	.byte $F4, $64, $45, (flag_i)
	.word $0500
	.byte $F4
	.byte $F4, $64, $45, (flag_i | flag_c | flag_z)
	; DCP ;
	; DEC, then  CMP ;
	
	JSR TEST_RunTest_AddrInitAXYF
	.word $05F0
	.byte $00
	.byte $F2, $00, $11, (flag_i)
	.word $05F0
	.byte $FF
	.byte $F2, $00, $11, (flag_i | flag_n)
	
	JSR TEST_RunTest_AddrInitAXYF
	.word $0522
	.byte $80
	.byte $80, $8F, $E3, (flag_i)
	.word $0522
	.byte $7F
	.byte $80, $8F, $E3, (flag_i | flag_c)
	

	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

TEST_ISC_E3:
	LDA #$E3
	BNE TEST_ISC
TEST_ISC_E7:
	LDA #$E7
	BNE TEST_ISC
TEST_ISC_EF:
	LDA #$EF
	BNE TEST_ISC
TEST_ISC_F3:
	LDA #$F3
	BNE TEST_ISC
TEST_ISC_F7:
	LDA #$F7
	BNE TEST_ISC
TEST_ISC_FB:
	LDA #$FB
	BNE TEST_ISC
TEST_ISC_FF:
	LDA #$FF
TEST_ISC:
	JSR TEST_UnOp_Setup; Set the opcode
	
	; see TEST_SLO for an explanation of the format here.
	
	JSR TEST_RunTest_AddrInitAXYF
	.word $0500
	.byte $3F
	.byte $75, $64, $45, (flag_i)
	.word $0500
	.byte $40
	.byte $34, $64, $45, (flag_i | flag_c)
	; ISC ;
	; INC, then SBC ;
	
	JSR TEST_RunTest_AddrInitAXYF
	.word $05BB
	.byte $96
	.byte $98, $15, $8F, (flag_i)
	.word $05BB
	.byte $97
	.byte $00, $15, $8F, (flag_i | flag_z | flag_c)
	
	JSR TEST_RunTest_AddrInitAXYF
	.word $05BB
	.byte $7F
	.byte $05, $15, $8F, (flag_i)
	.word $05BB
	.byte $80
	.byte $84, $15, $8F, (flag_i | flag_v | flag_n)

	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;


TEST_SHA_93:
	; Okay, this one needs an explanation.
	; Per my research, it would appear early RP2A03G revision CPU's (and earlier) have slightly different behavior than late RP2A03G revision CPU's (and later)
	; I call the early revision behavior "Behavior 1", and the late revision beahvior "Behavior 2."
	; The big difference here is the "corruption" of the high byte when the Y register indexes beyond a page boundary.
	; With behavior 1, the high byte of the address bus is bitwise ANDed with A AND X.
	; With behavior 2, the high byte of the address bus is bitwise ANDed with X. (The A register doesn't have any affect on this high byte corruption with behavior 2.)
	; It is currently unknown if behavior 1 has a "Magic Number", but it is known that behavior 2 definitely does.
	LDA #PostDMACyclesUntilTestInstruction+3
	STA <Test_UnOp_CycleDelayPostDMA	
	; Since we need to run this instruction to determine the behavior *before* running a series of tests, let's first confirm this instruction's length in bytes.
	; This is SHA (Indirect),Y, which is 2 bytes long.
	LDX #0
	.byte $93, $E8
	CPX #0
	BEQ  TEST_SHA_93_CorrectLength
	LDA #2	; error code 0.
	RTS
;;;;;;;
	
TEST_SHA_93_CorrectLength:
	; Determine if this instruction is using behavior 1 or 2. (or not implemented)
	LDA #$FF
	STA <$00 ; For checking behavior 1
	STA $0A00; For checking behavior 2
	LDA #$F0
	STA <Test_UnOp_IndirectPointerLo
	LDA #$1E
	STA <Test_UnOp_IndirectPointerHi
	LDA #$55
	LDX #$AA
	LDY #$10
	.byte $93, Test_UnOp_IndirectPointerLo ; SHA (Test_UnOp_IndirectPointerLo), Y ; (Test_UnOp_IndirectPointerLo) = $1EF0
	; Behavior 1: Hi = ($1E+1) & $55 & $AA = 0	:: write ($1E+1) & $55 & $AA = 0
	; Behavior 2: Hi = ($1E+1) & $AA = 0A		:: ($1E+1) & $55 & ($AA | MAGIC) = ?? & $1F (we don't know what MAGIC is, but the result must be $1F or less)
	LDA $0A00
	CMP #$FF
	BNE TEST_SHA_Behavior2_93_JMP ; if address $0A00 was updated, this is behavior 2.
	LDA <$00
	CMP #$00
	BEQ TEST_SHA_Behavior1_93_JMP ; if address $0000 was updated, this is behavior 1.
	LDA #$3E ; (Error code F) And if address $1F00 was changed, or of nothing happened at all, this failed.
	RTS		 ; (If address $1F00 ($700) was updated, that value gets fixed before the NMI occurs.)
;;;;;;;
	
TEST_SHA_Behavior2_93_JMP:
	JMP TEST_SHA_Behavior2_93
TEST_SHA_Behavior1_93_JMP:
	JMP TEST_SHA_Behavior1_93
	
TEST_SHA_9F:
	; See TEST_SHA_93 for an explanation.
	LDA #PostDMACyclesUntilTestInstruction+4
	STA <Test_UnOp_CycleDelayPostDMA
	; Since we need to run this instruction to determine the behavior *before* running a series of tests, let's first confirm this instruction's length in bytes.
	; This is SHA Absolute, which is 3 bytes long.
	LDX #0
	.byte $9F, $E8, $E8
	CPX #0
	BEQ  TEST_SHA_9F_CorrectLength
	LDA #2	; error code 0.
	RTS
;;;;;;;
	
TEST_SHA_9F_CorrectLength:
	
	; Determine if this instruction is using behavior 1 or 2. (or not implemented)
	LDA #$FF
	STA <$00 ; For checking behavior 1
	STA $0A00 ; For checking behavior 2
	LDA #$55
	LDX #$AA
	LDY #$10
	.byte $9F, $F0, $1E	; SHA $1EF0, Y
	; Behavior 1: Hi = ($1E+1) & $55 & $AA = 0	:: write ($1E+1) & $55 & $AA = 0
	; Behavior 2: Hi = ($1E+1) & $AA = 0A		:: ($1E+1) & $55 & ($AA | MAGIC) = ?? & $1F (we don't know what MAGIC is, but the result must be $1F or less)
	LDA $0A00
	CMP #$FF
	BNE TEST_SHA_Behavior2_9F_JMP ; if address $0A00 was updated, this is behavior 2.
	LDA <$00
	CMP #$00
	BEQ TEST_SHA_Behavior1_9F_JMP ; if address $0000 was updated, this is behavior 1.
	LDA #$3E ; (Error code F) And if address $1F00 was changed, or of nothing happened at all, this failed.
	RTS 	 ; (If address $1F00 ($700) was updated, that value gets fixed before the NMI occurs.)
;;;;;;;
	
TEST_SHA_Behavior2_9F_JMP:
	JMP TEST_SHA_Behavior2_9F
TEST_SHA_Behavior1_9F_JMP:
	JMP TEST_SHA_Behavior1_9F
	
	; So there are 2 different behaviors you can expect here.
	; H is the high byte of the address bus before indexing, +1
	; 1. Write: A & X & H
	; 2. Write: A & (X | Magic) & H :: *Magic CAN CHANGE!
	;		Magic has been seen to be 00, F5, F9, FA, and FF.
	
	; When the Y register is used as an offset and causes the high byte to change, the high byte becomes "unstable".
	; The behavior here IS correlated to the other set of behaviors.
	; 1. Hi = Hi & A & X
	; 2. Hi = Hi & X
TEST_SHA_Behavior1_93
	LDA #$93
	BNE TEST_SHA_Behavior1
TEST_SHA_Behavior1_9F:
	LDA #$9F
TEST_SHA_Behavior1:
	PHA
	LDA <RunningAllTests
	BNE TEST_SHA_Behavior1_SkipPrints
	
	LDA #0
	STA <dontSetPointer
	JSR PrintTextCentered
	.word $22B0
	.byte " SHA Behavior 1", $FF
	JSR PrintTextCentered
	.word $2330
	.byte "SHA magic = $", $FF
	LDA #$FF
	LDX #$00
	LDY #$60
	.byte $9F, $F0, $FE ; SHA $FEF0, Y
	LDA <$50
	JSR PrintByte
	
	JSR ResetScrollAndWaitForVBlank
TEST_SHA_Behavior1_SkipPrints:
	PLA

	JSR TEST_UnOp_Setup; Set the opcode
	; This test follows the documented behavior of these instructions. Most emulators probably go here.
	; Special thanks to 8BitLord64 for help researching this.
	; Write: A & X & H
	; Hi = Hi & A & X
	JSR TEST_RunTest_AddrInitAXYF
	.word $0525
	.byte $FF
	.byte $FF, $FF, $00, (flag_i)
	.word $0525
	.byte $06
	.byte $FF, $FF, $00, (flag_i)
	; SHA ;
	; This test needs to be VERY carefully made
	; the high byte of the target address can be modified "unexpectedly"
	; let's run some tests where the high byte doesn't change.
	; Store (A & X & H), where "H" is the high byte of the target address + 1.
	JSR TEST_RunTest_AddrInitAXYF
	.word $1D00	; If someone is testing for this instruction, they would surely have RAM mirroring implemented.
	.byte $FF
	.byte $3F, $F5, $00, (flag_i | flag_c | flag_z | flag_v)
	.word $0500
	.byte $14
	.byte $3F, $F5, $00, (flag_i | flag_c | flag_z | flag_v)
	
	; Now to make the high byte go unstable.
	JSR TEST_RunTest_AddrInitAXYF
	.word $1F10 ; $1E90 will be the operand.
	.byte $FF
	.byte $0D, $15, $80, (flag_i | flag_c | flag_z | flag_v)
	.word $0510
	.byte $05
	.byte $0D, $15, $80, (flag_i | flag_c | flag_z | flag_v)
	; Hi = ($1E+1) & A & X;
	; 	 = $05
	; $510 = A & X & H
	;	   = $0D & $15 & $1F
	;	   = 5
	INC <$55 ; make this non-zero for the test.	
	JSR TEST_RunTest_AddrInitAXYF
	.word $0555 ; $0402 will be the operand.
	.byte $FF
	.byte $F0, $09, $FF, (flag_i)
	.word $0055
	.byte $00
	.byte $F0, $09, $FF, (flag_i)
	; Hi = ($1E+1) & A & X;
	; 	 = $00
	; $510 = A & X & H
	;	   = $0D & $15 & $1F
	;	   = 5
	
	; And now to test if the value written is still ANDed with H if the cycle before the write had a DMA.
	PHA
	LDA #$20
	STA $0580
	LDA #Low(DMASync_50MinusACyclesRemaining)
	STA $0581
	LDA #High(DMASync_50MinusACyclesRemaining)
	STA $0582	
	LDA #$6
	STA <initialSubTest	; The following test will give error codes, 6, 7, 8, 9, and A. Error code 6 is probably the only one that will show up.
	PLA
	
	JSR TEST_RunTest_AddrInitAXYF
	.word $0500
	.byte $5A
	.byte $8F, $FF, $00, (flag_i)
	.word $0500
	.byte $8F	; H isn't part of the equation anymore.
	.byte $8F, $FF, $00, (flag_i)
	
;; END OF TEST ;;
	LDA #5	; Pass, "code 1"
	RTS
;;;;;;;
	
TEST_SHA_Behavior2_93
	LDA #$93
	BNE TEST_SHA_Behavior2
TEST_SHA_Behavior2_9F:
	LDA #$9F
TEST_SHA_Behavior2:
	PHA	
	LDA <RunningAllTests
	BNE TEST_SHA_Behavior2_SkipPrints
	
	LDA #0
	STA <dontSetPointer
	JSR PrintTextCentered
	.word $22B0
	.byte " SHA Behavior 2", $FF
	JSR PrintTextCentered
	.word $2330
	.byte "SHA magic = $", $FF
	LDA #$FF
	LDX #$00
	LDY #$60
	.byte $9F, $F0, $FE ; SHA $FEF0, Y
	LDA <$50
	JSR PrintByte
	
	JSR ResetScrollAndWaitForVBlank
TEST_SHA_Behavior2_SkipPrints:
	PLA
	JSR TEST_UnOp_Setup; Set the opcode
	; This test follows the behavior of many consoles I tested, though differs from the documentation.
	; Special thanks to GTAce, Fiskbit, and Lain for helping research this.
	; Write: A & (X | Magic) & H
	; Hi = Hi & X
	
	; We can not make any assumptions on what "magic" is. Therefore, X needs to always be FF.
	JSR TEST_RunTest_AddrInitAXYF
	.word $0525
	.byte $FF
	.byte $FF, $FF, $00, (flag_i)
	.word $0525
	.byte $06
	.byte $FF, $FF, $00, (flag_i)
	
	JSR TEST_RunTest_AddrInitAXYF
	.word $1D00
	.byte $FF
	.byte $03, $FF, $00, (flag_i)
	.word $0500
	.byte $02
	.byte $03, $FF, $00, (flag_i)
	
	; Now to make the high byte go unstable.
	JSR TEST_RunTest_AddrInitAXYF
	.word $1F10 ; $1E90 will be the operand.
	.byte $FF
	.byte $0A, $FF, $80, (flag_i | flag_c | flag_z | flag_v)
	.word $0710
	.byte $0A
	.byte $0A, $FF, $80, (flag_i | flag_c | flag_z | flag_v)
	; the high byte will only be ANDed with X (FF in this case)
	
	; And now to test if the value written is still ANDed with H if the cycle before the write had a DMA.
	PHA
	LDA #$20
	STA $0580
	LDA #Low(DMASync_50MinusACyclesRemaining)
	STA $0581
	LDA #High(DMASync_50MinusACyclesRemaining)
	STA $0582	
	LDA #$6
	STA <initialSubTest	; The following test will give error codes, 6, 7, 8, 9, and A. Error code 6 is probably the only one that will show up.
	PLA
	
	JSR TEST_RunTest_AddrInitAXYF
	.word $0500
	.byte $5A
	.byte $8F, $FF, $00, (flag_i)
	.word $0500
	.byte $8F	; H isn't part of the equation anymore.
	.byte $8F, $FF, $00, (flag_i)
	
	;; END OF TEST ;;
	LDA #9	; Pass, "code 2"
	RTS
;;;;;;;

TEST_SHS_9B:
	; See TEST_SHA_93 for more information.
	LDA #PostDMACyclesUntilTestInstruction+4
	STA <Test_UnOp_CycleDelayPostDMA
	; Determine if this instruction is using behavior 1 or 2. (or not implemented)
	; Since we need to run this instruction to determine the behavior *before* running a series of tests, let's first confirm this instruction's length in bytes.
	; This is SHS Absolute, which is 3 bytes long.
	TSX
	STX <Copy_SP
	LDX #0
	.byte $9B, $E8, $E8
	CPX #0
	BEQ  TEST_SHS_9B_CorrectLength
	LDX <Copy_SP
	TXS
	LDA #2	; error code 0.
	RTS
;;;;;;;
	
TEST_SHS_9B_CorrectLength:
	; Whichever choice of behavior your emulator used for SHA, (behavior 1 vs behavior 2) you should use the same choice of behavior for the SHS instruction. (behavior 1 or behavior 2)
	LDX <Copy_SP
	TXS
	LDA #$FF
	STA <$00 ; For checking behavior 1
	STA $0A00 ; For checking behavior 2
	TSX
	STX <Copy_SP
	LDA #$55
	LDX #$AA
	LDY #$10
	.byte $9B, $F0, $1E	; SHS $1EF0, Y
	; Behavior 1: Hi = ($1E+1) & $55 & $AA = 0	:: write ($1E+1) & $55 & $AA = 0
	; Behavior 2: Hi = ($1E+1) & $AA = 0A		:: ($1E+1) & $55 & ($AA | MAGIC) = ?? & $1F (we don't know what MAGIC is, but the result must be $1F or less)
	LDX <Copy_SP
	TXS
	LDA $A00
	CMP #$FF
	BNE TEST_SHS_Behavior2_9B_JMP ; if address $0A00 was updated, this is behavior 2.
	LDA <$00
	CMP #$00
	BEQ TEST_SHS_Behavior1_9B ; if address $0000 was updated, this is behavior 1.
	LDA #$3E ; (Error code F) And if address $1F00 was changed, or of nothing happened at all, this failed.
	RTS		 ; (If address $1F00 ($700) was updated, that value gets fixed before the NMI occurs.)
;;;;;;;
	
TEST_SHS_Behavior2_9B_JMP:
	JMP TEST_SHS_Behavior2_9B
	
TEST_SHS_Behavior1_9B:
	LDA <RunningAllTests
	BNE TEST_SHS_Behavior1_SkipPrints
	LDA #0
	STA <dontSetPointer
	JSR PrintTextCentered
	.word $22D0
	.byte " SHS Behavior 1", $FF
	JSR PrintTextCentered
	.word $2350
	.byte "SHS magic = $", $FF
	TSX
	STX <Copy_SP
	LDA #$FF
	LDX #$00
	LDY #$60
	.byte $9B, $F0, $FE ; SHS $FEF0, Y
	LDX <Copy_SP
	TXS
	LDA <$50
	JSR PrintByte
	JSR ResetScrollAndWaitForVBlank
TEST_SHS_Behavior1_SkipPrints:
	LDA #$9B
	JSR TEST_UnOp_Setup; Set the opcode
	; This test follows the documented behavior of these instructions. Most emulators probably go here.
	; Special thanks to 8BitLord64 for help researching this.
	; Write: A & X & H
	; Hi = Hi & A & X
	JSR TEST_RunTest_AddrInitAXYFS
	.word $0525
	.byte $FF
	.byte $FF, $FF, $00, (flag_i), $FF
	.word $0525
	.byte $06
	.byte $FF, $FF, $00, (flag_i), $FF
	; SHS ;
	; This test needs to be VERY carefully made
	; This test also modifies the stack pointer.
	; the high byte of the target address can be modified "unexpectedly"
	; let's run some tests where the high byte doesn't change.
	; Store (A & X & H), where "H" is the high byte of the target address + 1.
	JSR TEST_RunTest_AddrInitAXYFS
	.word $1D00	; If someone is testing for this instruction, they would surely have RAM mirroring implemented.
	.byte $FF
	.byte $3F, $F5, $00, (flag_i | flag_c | flag_z | flag_v), $35
	.word $0500
	.byte $14
	.byte $3F, $F5, $00, (flag_i | flag_c | flag_z | flag_v), $35
	
	; Now to make the high byte go unstable.
	JSR TEST_RunTest_AddrInitAXYFS
	.word $1F10 ; $1E90 will be the operand.
	.byte $FF
	.byte $0D, $15, $80, (flag_i | flag_c | flag_z | flag_v), $05
	.word $0510
	.byte $05
	.byte $0D, $15, $80, (flag_i | flag_c | flag_z | flag_v), $05
	; Hi = ($1E+1) & A & X;
	; 	 = $05
	; $510 = A & X & H
	;	   = $0D & $15 & $1F
	;	   = 5
	INC <$55 ; make this non-zero for the test.	
	JSR TEST_RunTest_AddrInitAXYFS
	.word $0555 ; $0402 will be the operand.
	.byte $FF
	.byte $F0, $09, $FF, (flag_i), $00
	.word $0055
	.byte $00
	.byte $F0, $09, $FF, (flag_i), $00
	; Hi = ($1E+1) & A & X;
	; 	 = $00
	; $510 = A & X & H
	;	   = $0D & $15 & $1F
	;	   = 5
	
	PHA
	LDA #$20
	STA $0580
	LDA #Low(DMASync_50MinusACyclesRemaining)
	STA $0581
	LDA #High(DMASync_50MinusACyclesRemaining)
	STA $0582	
	LDA #$7
	STA <initialSubTest	; The following test will give error codes, 7, 8, 9, A, B, and C. Error code 7 is probably the only one that will show up.
	PLA
	
	JSR TEST_RunTest_AddrInitAXYFS
	.word $0500
	.byte $5A
	.byte $8F, $FF, $00, (flag_i), $8F
	.word $0500
	.byte $8F
	.byte $8F, $FF, $00, (flag_i), $8F
	
;; END OF TEST ;;
	LDA #5	; Pass "code 1"
	RTS
;;;;;;;

TEST_SHS_Behavior2_9B:
	LDA <RunningAllTests
	BNE TEST_SHS_Behavior2_SkipPrints
	LDA #0
	STA <dontSetPointer
	JSR PrintTextCentered
	.word $22D0
	.byte " SHS Behavior 2", $FF
	JSR PrintTextCentered
	.word $2350
	.byte "SHS magic = $", $FF
	TSX
	STX <Copy_SP
	LDA #$FF
	LDX #$00
	LDY #$60
	.byte $9B, $F0, $FE ; SHS $FEF0, Y
	LDX <Copy_SP
	TXS
	LDA <$50
	JSR PrintByte
	JSR ResetScrollAndWaitForVBlank
TEST_SHS_Behavior2_SkipPrints:
	LDA #$9B
	JSR TEST_UnOp_Setup; Set the opcode
	JSR TEST_RunTest_AddrInitAXYFS
	.word $0525
	.byte $FF
	.byte $FF, $FF, $00, (flag_i), $FF
	.word $0525
	.byte $06
	.byte $FF, $FF, $00, (flag_i), $FF
	
	JSR TEST_RunTest_AddrInitAXYFS
	.word $1D00
	.byte $FF
	.byte $03, $FF, $00, (flag_i), $03
	.word $0500
	.byte $02
	.byte $03, $FF, $00, (flag_i), $03
	
	JSR TEST_RunTest_AddrInitAXYFS
	.word $1F10 ; $1E90 will be the operand.
	.byte $FF
	.byte $0A, $FF, $80, (flag_i | flag_c | flag_z | flag_v), $0A
	.word $0710
	.byte $0A
	.byte $0A, $FF, $80, (flag_i | flag_c | flag_z | flag_v), $0A

	PHA
	LDA #$20
	STA $0580
	LDA #Low(DMASync_50MinusACyclesRemaining)
	STA $0581
	LDA #High(DMASync_50MinusACyclesRemaining)
	STA $0582	
	LDA #$7
	STA <initialSubTest	; The following test will give error codes, 7, 8, 9, A, B, and C. Error code 7 is probably the only one that will show up.
	PLA
	
	JSR TEST_RunTest_AddrInitAXYFS
	.word $0500
	.byte $5A
	.byte $8F, $FF, $00, (flag_i), $8F
	.word $0500
	.byte $8F
	.byte $8F, $FF, $00, (flag_i), $8F

;; END OF TEST ;;
	LDA #9	; Pass "code 2"
	RTS
;;;;;;;

TEST_SHY_9C:
	LDA #PostDMACyclesUntilTestInstruction+4
	STA <Test_UnOp_CycleDelayPostDMA
	LDA #$9C
	JSR TEST_UnOp_Setup; Set the opcode
	JSR TEST_RunTest_AddrInitAXYF
	.word $15BB
	.byte $7F
	.byte $11, $00, $FF, (flag_i)
	.word $15BB
	.byte $16
	.byte $11, $00, $FF, (flag_i)
	
	JSR TEST_RunTest_AddrInitAXYF
	.word $1D00
	.byte $7F
	.byte $33, $00, $0F, (flag_i)
	.word $1D00
	.byte $0E
	.byte $33, $00, $0F, (flag_i)

	; Goes unstable.
	JSR TEST_RunTest_AddrInitAXYF
	.word $1F10
	.byte $7F
	.byte $77, $80, $05, (flag_i)
	.word $510
	.byte $05
	.byte $77, $80, $05, (flag_i)

	; And now to test if the value written is still ANDed with H if the cycle before the write had a DMA.
	PHA
	LDA #$20
	STA $0580
	LDA #Low(DMASync_50MinusACyclesRemaining)
	STA $0581
	LDA #High(DMASync_50MinusACyclesRemaining)
	STA $0582	
	LDA #$6
	STA <initialSubTest	; The following test will give error codes, 6, 7, 8, 9, and A. Error code 6 is probably the only one that will show up.
	PLA
	
	; SHY just becomes STY if a DMA occurs on the right cpu cycle.
	JSR TEST_RunTest_AddrInitAXYF
	.word $0500
	.byte $5A
	.byte $80, $00, $A5, (flag_i)
	.word $0500
	.byte $A5	; H isn't part of the equation anymore.
	.byte $80, $00, $A5, (flag_i)

	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

TEST_SHX_9E:
	LDA #PostDMACyclesUntilTestInstruction+4
	STA <Test_UnOp_CycleDelayPostDMA
	LDA #$9E
	JSR TEST_UnOp_Setup; Set the opcode
	JSR TEST_RunTest_AddrInitAXYF
	.word $15BB
	.byte $7F
	.byte $11, $FF, $00, (flag_i)
	.word $15BB
	.byte $16
	.byte $11, $FF, $00, (flag_i)
	
	JSR TEST_RunTest_AddrInitAXYF
	.word $1D00
	.byte $7F
	.byte $33, $0F, $00, (flag_i)
	.word $1D00
	.byte $0E
	.byte $33, $0F, $00, (flag_i)

	; Goes unstable.
	JSR TEST_RunTest_AddrInitAXYF
	.word $1F10
	.byte $7F
	.byte $77, $05, $80, (flag_i)
	.word $510
	.byte $05
	.byte $77, $05, $80, (flag_i)

	; And now to test if the value written is still ANDed with H if the cycle before the write had a DMA.
	PHA
	LDA #$20
	STA $0580
	LDA #Low(DMASync_50MinusACyclesRemaining)
	STA $0581
	LDA #High(DMASync_50MinusACyclesRemaining)
	STA $0582	
	LDA #$6
	STA <initialSubTest	; The following test will give error codes, 6, 7, 8, 9, and A. Error code 6 is probably the only one that will show up.
	PLA
	
	; SHX just becomes STX if a DMA occurs on the right cpu cycle.
	JSR TEST_RunTest_AddrInitAXYF
	.word $0500
	.byte $5A
	.byte $80, $A5, $00, (flag_i)
	.word $0500
	.byte $A5	; H isn't part of the equation anymore.
	.byte $80, $A5, $00, (flag_i)
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

TEST_LAE_BB:
	LDA #$BB
	JSR TEST_UnOp_Setup; Set the opcode
	JSR TEST_RunTest_AddrInitAXYFS
	.word $500
	.byte $5A
	.byte $11, $FF, $00, (flag_i | flag_v), $CA
	.word $500
	.byte $5A
	.byte $4A, $4A, $00, (flag_i | flag_v), $4A

	JSR TEST_RunTest_AddrInitAXYFS
	.word $5E3
	.byte $C3
	.byte $7C, $99, $52, (flag_i), $9A
	.word $5E3
	.byte $C3
	.byte $82, $82, $52, (flag_i | flag_n), $82
	
	JSR TEST_RunTest_AddrInitAXYFS
	.word $5E3
	.byte $04
	.byte $AB, $CD, $EF, (flag_i | flag_c | flag_n), $90
	.word $5E3
	.byte $04
	.byte $00, $00, $EF, (flag_i | flag_c | flag_z), $00 ;
	; NOTE: Yes, the stack pointer will be set to 00;
	;       Yes, the test will then PHA and PHP.
	;       No, this will not corrupt the bottom of the stack, for the stack pointer is initialized to $EF during the reset routine I wrote.
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

TEST_ANC_0B:
	LDA #$0B
	BNE TEST_ANC
TEST_ANC_2B:
	LDA #$2B
TEST_ANC:
	; see TEST_SLO for an explanation of how these tests work.
	; Except this one is slightly different, so let me explain.
	; TEST_RunTest_ImmOperandAXYF is similar to TEST_RunTest_AddrInitAXYF,
	; but instead of iAddress, iValue, iA, iX, iY, iFlags, rAddress, rValue, rA, rX, rY, rFlags
	; this function uses operand, iA, iX, iY, iFlags, rA, rX, rY, rFlags.
	; Error code 2 means A didn't match the expected result.
	; Error code 3 means X didn't match the expected result.
	; Error code 4 means Y didn't match the expected result.
	; Error code 5 means the flags didn't match the expected result.
	JSR TEST_UnOp_Setup ; Set the opcode
	JSR TEST_RunTest_ImmOperandAXYF
	.byte $F0
	.byte $5A, $64, $45, (flag_i | flag_z | flag_c)
	.byte $50, $64, $45, (flag_i)
	; ANC ;
	; Bitwise AND with Accumulator then Set Carry if Negative
	; $5A & $F0 = 50	
	
	JSR TEST_RunTest_ImmOperandAXYF
	.byte $F5
	.byte $81, $00, $01, (flag_i | flag_v)
	.byte $81, $00, $01, (flag_i | flag_c | flag_n | flag_v)
	
	JSR TEST_RunTest_ImmOperandAXYF
	.byte $5A
	.byte $A5, $FF, $5A, (flag_i | flag_c)
	.byte $00, $FF, $5A, (flag_i | flag_z)	
	
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;	
	
TEST_ASR_4B:
	LDA #$4B
	JSR TEST_UnOp_Setup ; Set the opcode
	JSR TEST_RunTest_ImmOperandAXYF
	.byte $F0
	.byte $81, $64, $45, (flag_i | flag_z | flag_c)
	.byte $40, $64, $45, (flag_i)
	; ASR ;
	; Bitwise AND with Accumulator then Logical Shift Right Accumulator
	
	JSR TEST_RunTest_ImmOperandAXYF
	.byte $52
	.byte $43, $00, $01, (flag_i | flag_c | flag_v)
	.byte $21, $00, $01, (flag_i | flag_v)
	
	JSR TEST_RunTest_ImmOperandAXYF
	.byte $41
	.byte $BF, $55, $AA, (flag_i | flag_z | flag_c)
	.byte $00, $55, $AA, (flag_i | flag_z | flag_c)	
	
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

TEST_ARR_6B:
	LDA #$6B
	JSR TEST_UnOp_Setup ; Set the opcode
	JSR TEST_RunTest_ImmOperandAXYF
	.byte $F2
	.byte $EE, $64, $45, (flag_i | flag_z | flag_v)
	.byte $71, $64, $45, (flag_i | flag_c)
	; ARR ;
	; Bitwise AND with A then Rotate A and check bits
	; Negative flag = bit 7
	; Carry flag = bit 6
	; Overflow flag = bit 5
	; Zero flag = result is zero
	JSR TEST_RunTest_ImmOperandAXYF
	.byte $01
	.byte $59, $64, $45, (flag_i | flag_z)
	.byte $00, $64, $45, (flag_i | flag_z)
	
	JSR TEST_RunTest_ImmOperandAXYF
	.byte $4F
	.byte $F3, $64, $45, (flag_i | flag_z | flag_c)
	.byte $A1, $64, $45, (flag_i | flag_v | flag_n)
	
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

TEST_ANE_8B:
	LDA #$8B
	JSR TEST_UnOp_Setup ; Set the opcode
	JSR TEST_RunTest_ImmOperandAXYF
	.byte $00
	.byte $5A, $3B, $45, (flag_i | flag_z | flag_c)
	.byte $00, $3B, $45, (flag_i | flag_z | flag_c)
	; ANE ;
	; A = (((A | Magic) & X) & Immediate)
	; The "Magic" value is not consistent, and so this test cannot rely on any specific value.
	; It is possible to test and see what this value is, but it could be different between tests.
	; Because of this, the tests used here need to specifically verify behavior only in cases where the magic value does not alter the outcome.
	; Basically, unless Immediate is $00, or A is $FF, the outcome is not guaranteed.
	
	JSR TEST_RunTest_ImmOperandAXYF
	.byte $CF
	.byte $FF, $9F, $99, (flag_i | flag_z | flag_v)
	.byte $8F, $9F, $99, (flag_i | flag_n | flag_v)
	
	; That's pretty much all we can test with this instruction, so we're good to go!
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

TEST_LXA_AB:
	LDA #$AB
	JSR TEST_UnOp_Setup ; Set the opcode
	JSR TEST_RunTest_ImmOperandAXYF
	.byte $00
	.byte $5A, $3B, $45, (flag_i | flag_z | flag_c)
	.byte $00, $00, $45, (flag_i | flag_z | flag_c)
	; LXA ;
	; A = ((A | Magic) & Immediate), X = A
	; The "Magic" value is not consistent, and so this test cannot rely on any specific value.
	; It is possible to test and see what this value is, but it could be different between tests.
	; Because of this, the tests used here need to specifically verify behavior only in cases where the magic value does not alter the outcome.
	; Basically, unless Immediate is $00, or A is $FF, the outcome is not guaranteed.
	
	JSR TEST_RunTest_ImmOperandAXYF
	.byte $A5
	.byte $FF, $8F, $99, (flag_i | flag_z | flag_v)
	.byte $A5, $A5, $99, (flag_i | flag_n | flag_v)
	
	; That's pretty much all we can test with this instruction, so we're good to go!
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;
	
TEST_AXS_CB:
	LDA #$CB
	JSR TEST_UnOp_Setup ; Set the opcode
	JSR TEST_RunTest_ImmOperandAXYF
	.byte $10
	.byte $F0, $B0, $45, (flag_i | flag_z | flag_c)
	.byte $F0, $A0, $45, (flag_i | flag_c | flag_n)
	; AXS ;
	; X = (A&X) - Immediate
	
	JSR TEST_RunTest_ImmOperandAXYF
	.byte $00
	.byte $5A, $CC, $FF, (flag_i | flag_z | flag_c)
	.byte $5A, $48, $FF, (flag_i | flag_c)
	
	JSR TEST_RunTest_ImmOperandAXYF
	.byte $E5
	.byte $00, $66, $45, (flag_i | flag_z | flag_c | flag_v)
	.byte $00, $1B, $45, (flag_i | flag_v)
	
	JSR TEST_RunTest_ImmOperandAXYF
	.byte $45
	.byte $C5, $5F, $00, (flag_i | flag_n)
	.byte $C5, $00, $00, (flag_i | flag_z | flag_c)
	
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

TEST_SBC_EB:
	LDA #$EB
	JSR TEST_UnOp_Setup ; Set the opcode
	JSR TEST_RunTest_ImmOperandAXYF
	.byte $10
	.byte $F0, $22, $75, (flag_i | flag_z | flag_c | flag_v)
	.byte $E0, $22, $75, (flag_i | flag_c | flag_n)
	; SBC ;
	; It's the same as the official SBC Immediate instruction.
	
	JSR TEST_RunTest_ImmOperandAXYF
	.byte $EE
	.byte $52, $93, $B2, (flag_i)
	.byte $63, $93, $B2, (flag_i)
	
	JSR TEST_RunTest_ImmOperandAXYF
	.byte $80
	.byte $05, $C0, $1F, (flag_i | flag_z | flag_c | flag_v | flag_n)
	.byte $85, $C0, $1F, (flag_i| flag_v | flag_n)
	
	JSR TEST_RunTest_ImmOperandAXYF
	.byte $43
	.byte $44, $C0, $1F, (flag_i)
	.byte $00, $C0, $1F, (flag_i| flag_z | flag_c)
	
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

TEST_MAGIC:
	; The ANE and LXA instructions have "magic values".
	; The value is typically $EE or $FF.
	; This test just prints what the value is for both instructions.	
	; First, let's confirm the instructions are 2 bytes long.
	LDX #0
	.byte $8B, $E8
	CPX #0
	BEQ TEST_MAGIC_Continue
	LDA #2 ; error code 0
	RTS	
TEST_MAGIC_Continue:
	LDA #$FF
	.byte $AB, $E8
	CPX #1
	BNE TEST_MAGIC_Continue2
	LDA #2 ; error code 0
	RTS	
TEST_MAGIC_Continue2:
	LDA <RunningAllTests
	BEQ TEST_MAGIC_Continue3 ; skip printing stuff on screen if we're running all tests right now.
	LDA #01
	RTS
TEST_MAGIC_Continue3:
	LDA #0
	STA <dontSetPointer
	JSR PrintTextCentered
	.word $2330
	.byte "ANE magic = $", $FF
	LDA #0
	LDX #$FF
	.byte $8B, $FF ; ANE #$FF
	JSR PrintByte
	
	JSR PrintTextCentered
	.word $2350
	.byte "LXA magic = $", $FF
	LDA #0
	.byte $AB, $FF ; LXA #$FF
	JSR PrintByte
	
;; END OF TEST ;;
	JSR ResetScroll
	LDA #1
	RTS
;;;;;;;

TEST_DMA_Plus_OpenBus:
	;;; Test 1 [DMA + Open Bus]: Check if reading from $4000 returns $40, and not zero. ;;;
	LDA $4000
	CMP #$40
	BNE FAIL_DMA_Plus_OpenBus
	INC <currentSubTest

	;;; Test 2 [DMA + Open Bus]: If the DMA occurs just before the Open Bus read, it will update the databus to $00 ;;;
	JSR DMASync_50CyclesRemaining	; sync DMA
	JSR Clockslide_47
	LDA $4000 ; <------- [Opcode] [Operand1] [Operand2] [*DMA*] [Read]
	BNE FAIL_DMA_Plus_OpenBus
	
	;; END OF TEST ;;
	LDA #0
	STA $4015
	LDA #1
	RTS
;;;;;;;

FAIL_DMA_Plus_OpenBus:
	JMP TEST_Fail

TEST_DMA_Plus_2007_Prep:
	JSR DisableRendering ; let's disable rendering for this one.
	LDX #$24
	STX $2006
	LDX #0
	STX $2006
	STX $2007 ; write 0 to VRAM $2800
	INX
	STX $2007 ; write 1 to VRAM $2801
	INX
	STX $2007 ; write 2 to VRAM $2802
	INX
	STX $2007 ; write 3 to VRAM $2803
	INX
	STX $2007 ; write 4 to VRAM $2804
	LDX #$24
	STX $2006
	LDX #$01
	STX $2006 ; and set 'v' back to $2400
	LDA $2007 ; read $2007 and prep the buffer.
	RTS
;;;;;;;

TEST_DMA_Plus_2007R:
	; Here's the set up:
	; VRAM will read 0 1 2 3 4
	; The LDA $2007 instruction has 4 read cycles.
	; [Opcode] [Operand1] [Operand2] [Read $2007]
	; if the DMA occurs between [Operand2] and [Read $2007], the ppu 'v' register will be incremented twice due to the DMA's dummy cycles.
	JSR TEST_DMA_Plus_2007_Prep	
	JSR DMASync_50CyclesRemaining	; sync DMA
	; We have 50 CPU cycles until the DMA occurs.
	JSR Clockslide_47
	LDA $2007 ; <------- [Opcode] [Operand1] [Operand2] [*DMA*] [Read]
	NOP 
	NOP	
	
	;;; Test 1 [DMA + $2007 Read]: verify PPU buffer behavior ;;;
	CMP #$00
	BEQ TEST_Fail7 ; if the value of A is $00, then your PPU buffer is probably not implemented correctly.
	INC <currentSubTest
	
	;;; Test 2 [DMA + $2007 Read]: Check DMA timing ;;;
	CMP #$01
	BEQ TEST_Fail7 ; if the value of A is $01, then the timing of the DMA is off.
	INC <currentSubTest
	
	;;; Test 3 [DMA + $2007 Read]: Check the DMA dummy reads occured the correct number of times ;;;	
	CMP #$03
	BMI TEST_Fail7
	INC <currentSubTest
	;; END OF TEST ;;
	
	JSR ResetScrollAndWaitForVBlank
	JSR EnableRendering_BG	
	LDA #1
	RTS
;;;;;;;

TEST_DMA_Plus_2007W:
	; Here's the set up:
	; VRAM will read 0 1 2 3 4
	; The STA $2007 instruction has 3 read cycles, then a write cycle.
	; [Opcode] [Operand1] [Operand2] [Write $2007]
	; However, DMC DMA's cannot interrupt a write cycle! Therefore, the address bus cannot be $2007 during the DMA, so nothing unusual happens!	
	; This test only has relevant results if the DMA + $2007R rest passes.
	;;; Test 1 [DMA + $2007 Write]: The DMA + $2006 Read test passes. ;;;
	JSR TEST_DMA_Plus_2007R
	LDX #1
	STX <currentSubTest
	CMP #1
	BNE TEST_Fail7
	INC <currentSubTest

	JSR TEST_DMA_Plus_2007_Prep	; the v register is now at 2401
	JSR DMASync_50CyclesRemaining	; sync DMA
	; We have 50 CPU cycles until the DMA occurs.
	JSR Clockslide_45 ;+45 cycles
	LDA #$5A		  ;+2 cycles
	STA $2007 ; <------- [Opcode] [Operand1] [Operand2] [DMA attempts, but fails. Write] [Opcode (NOP)] [*DMA*]
	NOP 	  ; The DMA occurs inside this NOP, if your emulator is timing it right.
	NOP		  ; And the v register is now at $2402. It was not incremented extra times in the DMA, so LDA $2007 read the expected value.
	;;; Test 2 [DMA + $2007 Write]: The v register should be at $2402 ;;;
	JSR DoubleLDA2007
	CMP #$03
	BNE TEST_Fail7
	;; END OF TEST ;;
	
	JSR ResetScrollAndWaitForVBlank
	JSR EnableRendering_BG	
	LDA #1
	RTS

TEST_Fail7:
	JSR ResetScrollAndWaitForVBlank
TEST_Fail8:
	JSR EnableRendering_BG	
	JMP TEST_Fail

Test_ProgramCounter_Wraparound:
	;;; Test 1 [Program Counter Wraparound]: Executing from $FFFF should wrap around to address $0000 ;;;
	LDA #$00
	STA <$00
	LDA #$60
	STA <$01
	JSR $FFFF ; .byte $06, $00 = ASL <$00; $01 = 60, RTS
	
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

TEST_VBlank_Beginning:
	;;; Test 1 [VBLank Beginning]: Tests the timing of the $2002 Vblank flag ;;;
	; Special thanks to blargg for figuring this stuff out.
	JSR DisableRendering
	LDX #0
TEST_VBlank_Beginning_Loop:
	TXA
	PHA	
	JSR VblSync_Plus_A
	; This next CPU cycle is synced with PPU cycle 0+A for this frame.
	; Let's "subtract" 5 CPU cycles.
	JSR Clockslide_29776
	LDX $2002
	LDY $2002
	; Here's how this test works.
	; When A=0, the LDX instruction is too early, and the LDY instruction happens after VBlank begins.
	;	- In that case, X=$00, but Y=$80 (The bits get rearranged, and this is stored at $50 as "02")
	; Every iteration of this loop, this test will run 1 PPU cycle closer to VBlank than the previous iteration.
	; When A=4, the LDX instruction will read $2002 on the same cycle that would otherwise set the VBlank flag.
	;	- in that case, the value read is $00, and the VBlank flag is NOT set afterwards.	X=$00, Y=$00
	; When A>=5, the read cycle of the LDX instruction will be after Vblank begins. X=$80, (the vblank flag is cleard, so...) Y=$00.
	;	-(The bits get rearranged, and this is stored at $50 as "01")
	
	; Put the X register into bit 1, and the Y register into bit 2.
	TXA
	ASL A
	LDA #0
	ROL A
	STA <$00
	TYA
	ASL A
	LDA #0
	ROL A
	ASL A
	ORA <$00
	; A should now be 0000 00XY, where X and Y are bit 7 of X and Y.
	STA <$00
	PLA
	TAX
	LDA <$00
	STA <$50,X
	INX
	CPX #$07
	BNE TEST_VBlank_Beginning_Loop
	; Address $50 should now look exactly like TEST_VBlank_Beginning_Expected_Results
	LDX #0
TEST_VBlank_Beginning_Loop2:
	LDA <$50,X
	CMP TEST_VBlank_Beginning_Expected_Results,X
	BNE TEST_Fail9
	INX
	CPX #$03 ; since byte 2 in this list could depend on CPU/PPU clock alignment...
	BNE TEST_VBlank_Beginning_Loop2_SkipByte2	; let's ignore it.
	INX	
TEST_VBlank_Beginning_Loop2_SkipByte2:
	CPX #$07
	BNE TEST_VBlank_Beginning_Loop2
	
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;
	
TEST_Fail9:
	JSR EnableRendering_BG	
	JMP TEST_Fail

TEST_VBlank_Beginning_Expected_Results:
	;				     $00 is also acceptable in the fourth byte (byte 3), depending on CPU/PPU clock alignment.
	.byte $02, $02, $02, $02, $00, $01, $01
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TEST_VBlank_End:
	;;; Test 1 [VBLank Beginning]: Tests the timing of the $2002 Vblank flag ;;;
	; Special thanks to blargg for figuring this stuff out.
	JSR DisableRendering
	LDX #0
TEST_VBlank_End_Loop:
	TXA
	JSR VblSync_Plus_A
	; This next CPU cycle is synced with PPU cycle 0+A for this frame.
	; Vblank ends in about 2273.333 CPU cycles.
	; So let's stall for 2273-4 cycles, as this upcoming LDA takes 4 cycles.
	JSR Clockslide_2269
	LDA $2002
	; Here's how this test works.
	; When A=0, the LDA instruction occurs before VBlank ends.
	; Every iteration of this loop, this test will run 1 PPU cycle closer to the end of VBlank than the previous iteration.
	; Eventually, the vblank flag is no longer set when the LDA instruction reads from $2002. (when A>=4)
	; The bits are rearranged so the VBlank flag gets stored in bit 0, and this value is written to $50,X
	ASL A	; Shift VBlank flag into carry
	LDA #0	; clear A
	ROL A	; Rotate carry into bit 0.
	STA <$50,X	; store in $50,X
	INX	
	CPX #$07
	BNE TEST_VBlank_End_Loop ; loop until X=7
	; Address $50 should now look exactly like TEST_VBlank_Beginning_Expected_Results
	LDX #0
TEST_VBlank_End_Loop2:
	LDA <$50,X
	CMP TEST_VBlank_End_Expected_Results,X
	BNE TEST_Fail9
	INX
	CPX #$07
	BNE TEST_VBlank_End_Loop2
	
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

TEST_VBlank_End_Expected_Results:
	.byte $01, $01, $01, $01, $00, $00, $00, $00
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FAIL_NMI_Control1:
	JSR DisableNMI
	JMP TEST_Fail

TEST_NMI_Control:
	; Special thanks to blargg. I'm pretty much just doing what they did here.
	LDA #$E8	; INX opcode
	STA $700
	LDA #$40	; RTI opcode
	STA $701
	;;; Test 1 [NMI Control]: The NMI should not occur when disabled. ;;;
	; The NMI *should* already be disabled (and it being enabled during the "WaitForVBlank" that happened before the jump here would be problematic...)
	; but let's test this anyway.
	LDX #0
	JSR Clockslide_29780 ; Wait 1 frame.
	CPX #0
	BNE FAIL_NMI_Control1 ; If the NMI occurs, it will run INX, ... RTI. That would increment X to 1, thus failing the test.
	INC <currentSubTest
	
	;;; Test 2 [NMI Control]: The NMI should occur at vblank when enabled. ;;;
	; Again, reaching this test would be impossible without the NMI occuring, so I have a hunch it won't fail this one.
	JSR Clockslide_2269 ; wait long enough that VBlank should be over.
	JSR EnableNMI
	; X is still zero.
	JSR Clockslide_29780 ; Wait 1 frame.
	CPX #1
	BNE FAIL_NMI_Control1 ; If the NMI occurs, it will run INX, ... RTI. That would increment X to 1, thus passing the test.
	INC <currentSubTest

	;;; Test 3 [NMI Control]: The NMI should occur when enabled during vblank, if the Vblank flag is enabled. ;;;
	JSR DisableNMI
	LDX #0
	JSR WaitForVBlank
	JSR Clockslide_29780 ; Wait 1 frame.
	JSR EnableNMI
	CPX #1
	BNE FAIL_NMI_Control1
	INC <currentSubTest
	
	;;; Test 4 [NMI Control]: The NMI should NOT occur when enabled during vblank, if the Vblank flag is disabled. ;;;
	JSR DisableNMI
	LDX #0
	JSR WaitForVBlank ; Wait for Vblank reads $2002, clearing the Vblank flag
	JSR EnableNMI
	JSR Clockslide_2269 ; wait long enough that VBlank should be over.
	CPX #0
	BNE FAIL_NMI_Control1
	INC <currentSubTest

	;;; Test 5 [NMI Control]: The NMI should NOT occur a second time if writing $80 to $2000 when the NMI flag is already enabled. ;;;
	JSR DisableNMI
	LDX #0
	JSR WaitForVBlank
	JSR Clockslide_29780 ; Wait 1 frame.
	JSR EnableNMI
	JSR EnableNMI	
	CPX #1
	BNE FAIL_NMI_Control2	; If X was 2, then the NMI ran twice, thus failing the test.
	INC <currentSubTest
	
	;;; Test 6 [NMI Control]: (previous test) but the NMI was enabled going into VBlank. ;;;
	; The NMI is enabled going into this test.
	LDX #0
	JSR Clockslide_29780 ; Wait 1 frame. (The NMI should happen in here)
	JSR EnableNMI ; (and the NMI should not happen a second time)
	CPX #1
	BNE FAIL_NMI_Control2	; If X was 2, then the NMI ran twice, thus failing the test.
	INC <currentSubTest
	
	;;; Test 7 [NMI Control]: The NMI should occur an additional time if you disable and then re-enable the NMI. ;;;
	JSR DisableNMI
	LDX #0
	JSR WaitForVBlank
	JSR Clockslide_29780 ; Wait 1 frame.
	JSR EnableNMI
	JSR DisableNMI
	JSR EnableNMI ; (and the NMI should happen a second time)
	CPX #2
	BNE FAIL_NMI_Control2
	INC <currentSubTest
	
	;;; Test 8 [NMI Control]: The NMI should occur 2 instructions after the NMI is enabled. ;;;
	; STA $2000
	; LDX #$10
	; [NMI]	
	JSR DisableNMI
	LDX #0
	JSR WaitForVBlank
	JSR Clockslide_29780 ; Wait 1 frame.
	; Instead of using JSR EnableNMI, I need to actually write it all out here.
	LDA <PPUCTRL_COPY
	ORA #$80
	STA <PPUCTRL_COPY
	STA $2000
	LDX #$10
	CPX #$11
	BNE FAIL_NMI_Control2	; If the NMI happened before the LDA #$10 (incorrect), then X will be 1, thus failing the test.
	;; END OF TEST ;;
	JSR DisableNMI
	LDA #1
	RTS
;;;;;;;
FAIL_NMI_Control2:
FAIL_NMI_Timing:
	JSR DisableNMI
	JMP TEST_Fail
;;;;;;;;;;;;;;;;;

TEST_NMI_Timing:
	LDA #$84	; STY <$zp opcode
	STA $700
	LDA #Copy_Y
	STA $701
	LDA #$40	; RTI opcode
	STA $702
	; The NMI routine is now:
	; STY <Copy_Y
	; RTI	
	JSR DisableRendering
	LDX #0
	;;; Test 1 [NMI Timing]: Tests the timing of the NMI ;;;

TEST_NMI_Timing_Loop:
	TXA
	LDY #$80
	STA <Copy_Y
	LDY #1
	JSR VblSync_Plus_A
	; This next CPU cycle is synced with PPU cycle 0+A for this frame.
	JSR Clockslide_29700 ; stall until 80 CPU cycles until Vblank
	; Here's how this test works.
	; The NMI stores the value of Y somewhere.
	; Here's a series of INY isntructions. The NMI will happen in the middle of these.
	JSR EnableNMI ; This takes 31 cycles.
	JSR Clockslide_49; NMI should be in 0 cycles.	
	INY
	INY
	INY
	INY
	LDY <Copy_Y
	STY <$50,X
	JSR DisableNMI
	INX	
	CPX #$0A
	BNE TEST_NMI_Timing_Loop ; loop until X=7
	; Address $50 should now look exactly like TEST_VBlank_Beginning_Expected_Results
	LDX #0
	; Check the first value to determine if the CPU/PPU Clock alignment affected the results.
	LDA <$50
	CMP #$03
	BEQ TEST_NMI_Timing_Loop3 ; Use this loop if the first value read was 3.
	; Assume if it wasn't 3, that it was 2.
TEST_NMI_Timing_Loop2:
	LDA <$50,X
	CMP TEST_NMI_Timing_Expected_Results+1,X ; The expected results shifter over by 1 ppu cycle.
	BNE FAIL_NMI_Timing
	INX
	CPX #$0A
	BNE TEST_NMI_Timing_Loop2
	BEQ TEST_NMI_Timing_End	
TEST_NMI_Timing_Loop3:
	LDA <$50,X
	CMP TEST_NMI_Timing_Expected_Results,X  ; The expected result shifter over by 1 ppu cycle.
	BNE FAIL_NMI_Timing
	INX
	CPX #$0A
	BNE TEST_NMI_Timing_Loop3
TEST_NMI_Timing_End:
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

TEST_NMI_Timing_Expected_Results:
	; With a single CPU/PPU clock alingment, this will be off by 1, starting at the $02 instead of the $03.
	.byte $03,$02,$02,$02,$02,$02,$02,$01,$01,$01,$01
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TEST_NMI_Suppression:
	JSR PrepNMI_TimingTests
TEST_NMI_Suppression_Loop:
	TXA
	LDY #0
	JSR VblSync_Plus_A
	; This next CPU cycle is synced with PPU cycle 0+A for this frame.
	JSR Clockslide_29700 ; stall until 80 CPU cycles until Vblank
	JSR EnableNMI ; This takes 31 cycles.
	JSR Clockslide_45; NMI should be in 0 cycle.	
	LDA $2002
	ASL A ; Put VBlank flag in Carry
	TYA	; transfer Y to A (Y = 1 if the NMI happened)
	ROL A
	; A = (0000 00YV) where Y is set if the NMI occured, and V is set if the VBlank flag is set.) 
	STA <$50,X
	JSR DisableNMI
	INX	
	CPX #$0A
	BNE TEST_NMI_Suppression_Loop ; loop until X=7
	LDX #1
TEST_NMI_Suppression_Loop2:
	LDA <$50,X
	CMP TEST_NMI_Suppression_Expected_Results,X  ; The expected result shifter over by 1 ppu cycle.
	BNE FAIL_NMI_Suppression
	INX
	CPX #3
	BNE TEST_NMI_Suppression_Skip
	INX
TEST_NMI_Suppression_Skip:
	CPX #6
	BNE TEST_NMI_Suppression_Skip2
	INX
TEST_NMI_Suppression_Skip2:
	CPX #$0A
	BNE TEST_NMI_Suppression_Loop2
TEST_NMI_Suppression_End:
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

TEST_NMI_Suppression_Expected_Results:
	; With a single CPU/PPU clock alingment, this will be off by 1, starting at the $02 instead of the $03.
		;skip reading the FF bytes. it could be 00 or 02. The final FF could be 01/03.
	.byte $FF, $02, $02, $FF, $00, $01, $FF, $03, $03, $03, $03
FAIL_NMI_Suppression:
FAIL_NMI_VBL_End:
	JSR DisableNMI
	JMP TEST_Fail
;;;;;;;;;;;;;;;;;
	
TEST_NMI_VBL_End:
	JSR PrepNMI_TimingTests
	;;; Test 1 [NMI at VBlank End]: Tests the timing of the NMI as VBlank ends ;;;
	; Special thanks to blargg for figuring this stuff out.
TEST_NMI_VBL_End_Loop:
	TXA
	LDY #0
	JSR VblSync_Plus_A
	; This next CPU cycle is synced with PPU cycle 0+A for this frame.
	; Vblank ends in about 2273.333 CPU cycles.
	; So let's stall for 2200 cycles.
	JSR Clockslide_2252
	JSR EnableNMI	; NMI enable in 21 cycles.
	TYA
	STA <$50,X	; store in $50,X	
	JSR DisableNMI
	INX	
	CPX #$07
	BNE TEST_NMI_VBL_End_Loop ; loop until X=7
	; Address $50 should now look exactly like TEST_VBlank_Beginning_Expected_Results
	LDX #0
TEST_NMI_VBL_End_Loop2:
	LDA <$50,X
	CMP TEST_NMI_VBL_End_Expected_Results,X
	BNE FAIL_NMI_VBL_End
	INX
	CPX #$07
	BNE TEST_NMI_VBL_End_Loop2
	
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

TEST_NMI_VBL_End_Expected_Results:
	.byte $01, $01, $01, $00, $00, $00, $00
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TEST_NMI_Disabled_VBL_Start:
	JSR PrepNMI_TimingTests
	;;; Test 1 [NMI Disabled at VBLank]: Tests the timing of the NMI if disabled right as VBlank occurs ;;;
TEST_NMI_Disabled_VBL_Start_Loop:
	TXA
	LDY #0
	JSR VblSync_Plus_A
	; This next CPU cycle is synced with PPU cycle 0+A for this frame.
	JSR Clockslide_29700 ; NMI in ~80 cycles
	JSR EnableNMI ; this takes 31 cycles
	JSR Clockslide_29	
	JSR DisableNMI	; NMI disabled in 21 cycles.
	TYA
	STA <$50,X	; store in $50,X	
	INX	
	CPX #$07
	BNE TEST_NMI_Disabled_VBL_Start_Loop ; loop until X=7
	; Address $50 should now look exactly like TEST_NMI_Disabled_VBL_Start_Expected_Results
	LDX #0
TEST_NMI_Disabled_VBL_Start_L2:
	LDA <$50,X
	CMP TEST_NMI_Disabled_VBL_Start_Expected_Results,X
	BNE FAIL_NMI_Disabled_VBL_Start
	INX
	CPX #3
	BNE TEST_NMI_Disabled_VBL_Skip
	INX
TEST_NMI_Disabled_VBL_Skip:
	CPX #$07
	BNE TEST_NMI_Disabled_VBL_Start_L2
	
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

	FAIL_NMI_Disabled_VBL_Start:
	JSR DisableNMI
	JMP TEST_Fail
;;;;;;;;;;;;;;;;;

TEST_NMI_Disabled_VBL_Start_Expected_Results:
						; This $FF could be a 00, or a 01, so skip it in the evaluation.
	.byte $00, $00, $00, $FF, $01, $01, $01
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PREP_SpriteZeroHit:
	LDA #0
	STA <dontSetPointer
	JSR PrintCHR
	.word $2001 ; At address $2001
	.byte $FC, $FF
	JSR ResetScroll
	JSR ClearPage2 ; $200 to $2FF = $FF
	JSR InitializeSpriteZero
	;    Ypos, CHR, Att, XPos
	.byte $00, $FC, $00, $08
	; InitializeSpriteZero updates the return address, returning here:
	JSR WaitForVBlank
	RTS
;;;;;;;

FAIL_Sprite0Hit_Behavior1:
	JMP FAIL_Sprite0Hit_Behavior

TEST_Sprite0Hit_Behavior:
	; Some prep.
	JSR PREP_SpriteZeroHit
	
	;;; Test 1 [Sprite Zero Hit Behavior]: Does a sprite zero hit occur in a situation in which it should? ;;;
	; What is a sprite zero hit?
	; Every slot in Object Attribute Memory (OAM) can be numbered from 0 to 63.
	; The object in slot zero will be referred to as "Sprite Zero".
	; The "CHR" byte in OAM determines which index from the pattern table to use for the graphics.
	; Each pixel drawn will take 2 bits from the pattern data, and if the value is 00, it will be rendered with "the background color".
	; If the 2 bits are 01, 10, or 11, then this pixel will be drawn with color 1, 2, and 3 of the specified color palette respectively. (with color 0 being the background color)
	; Let's refer to any pixel that is using a non-background-color as a "solid pixel".
	; Keep in mind, this "solid pixel" terminology is only referring to the 2 bits from the pattern data, and has nothing to do with the actual colors drawn.
	; A "sprite zero hit" occurs when the following happens:
	; A solid pixel of sprite zero is drawn on the same pixel as a solid pixel of the background.
	; And if a sprite zero hit was detected, bit 6 of address $2002 is set, similar to how the VBlank flag is using bit 7 of the same address.
	
	; So let's work this one out.
	; A solid white square has been placed at VRAM address $2001. (We reset the scroll with the value $2000, so this square is 8 pixels to the right of the upper left of the screen)
	; We have initialized Sprite Zero as a white square, and set it's screen coordinates to ($08, $00) which should overlap the box. (But it will be 1 pixel lower)
	; Therefore, a solid pixel of Sprtie Zero is guaranteed to overlap a solid pixel of this white square in the background.
	
	JSR EnableRendering_S ; start rendering sprites!
	LDX #02
	STX $4014 ; OAM DMA
	JSR Clockslide_3000 ; Wait long enough for VBlank to be over, and the sprite zero hit to occur. (we're not going for precise timing on this test. Just to see if it happens.)
	LDA $2002	; Bit 6 should be set, since the sprite zero hit should have occured.
	AND #$40
	BEQ FAIL_Sprite0Hit_Behavior1
	INC <currentSubTest

	;;; Test 2 [Sprite Zero Hit Behavior]: Sprite zero hits should not happen if Background Rendering is disabled. ;;;
	JSR DisableRendering_BG ; only disable rendering the background.
	JSR WaitForVBlank
	STX $4014 ; OAM DMA (we want to keep OAM refreshed for these tests)
	JSR Clockslide_3000 ; Wait long enough for VBlank to be over, and a few scanlines to render. (Sprite Zero hit should not occur, for the background is not rendering.)
	LDA $2002	; Bit 6 should NOT be set, since the sprite zero hit should not have occured.
	AND #$40
	BNE FAIL_Sprite0Hit_Behavior1
	INC <currentSubTest

	;;; Test 3 [Sprite Zero Hit Behavior]: Sprite zero hits should not happen if Sprite Rendering is disabled. ;;;
	JSR WaitForVBlank
	JSR EnableRendering_BG ; enable the background
	JSR DisableRendering_S ; and disable sprites
	STX $4014 ; OAM DMA (we want to keep OAM refreshed for these tests)
	JSR Clockslide_3000 ; Wait long enough for VBlank to be over, and a few scanlines to render. (Sprite Zero hit should not occur, for sprites are not rendering.)
	LDA $2002	; Bit 6 should NOT be set, since the sprite zero hit should not have occured.
	AND #$40
	BNE FAIL_Sprite0Hit_Behavior1
	INC <currentSubTest

	;;; Test 4 [Sprite Zero Hit Behavior]: Sprite zero hits should not happen if both sprites and background Rendering are disabled. ;;;
	JSR WaitForVBlank
	JSR DisableRendering_BG ; enable the background
	STX $4014 ; OAM DMA (we want to keep OAM refreshed for these tests)
	JSR Clockslide_3000 ; Wait long enough for VBlank to be over, and a few scanlines to render. (Sprite Zero hit should not occur, for rendering is disabled.)
	LDA $2002	; Bit 6 should NOT be set, since the sprite zero hit should not have occured.
	AND #$40
	BNE FAIL_Sprite0Hit_Behavior1
	INC <currentSubTest
	
	;;; Test 5 [Sprite Zero Hit Behavior]: Sprite zero hits should not happen if sprite zero is completely transparent. ;;;
	JSR WaitForVBlank
	JSR EnableRendering  ; enable the background and sprites.
	JSR InitializeSpriteZero ; Init sprite zero with a completely transparent sprite. (All pixels are background-color)
	;    YPos, CHR, Att, XPos
	.byte $00, $FF, $00, $08
	STX $4014 ; OAM DMA (we want to keep OAM refreshed for these tests)
	JSR Clockslide_3000 ; Wait long enough for VBlank to be over, and a few scanlines to render. (Sprite Zero hit should not occur, for sprite zero as no solid pixels.)
	LDA $2002	; Bit 6 should NOT be set, since the sprite zero hit should not have occured.
	AND #$40
	BNE FAIL_Sprite0Hit_Behavior
	INC <currentSubTest	
	
	;;; Test 6 [Sprite Zero Hit Behavior]: Sprite zero hits can happen at X=254. (verify for the next test) ;;;
	JSR WaitForVBlank	
	JSR PrintCHR
	.word $201F ; At address $201F
	.byte $FC, $FF
	JSR ResetScroll
	JSR InitializeSpriteZero
	;    YPos, CHR, Att, XPos
	.byte $00, $FC, $00, $FE
	JSR WaitForVBlank
	STX $4014 ; OAM DMA (we want to keep OAM refreshed for these tests)
	JSR Clockslide_3000 ; Wait long enough for VBlank to be over, and a few scanlines to render. (Sprite Zero hit should occur.)
	LDA $2002	; Bit 6 should be set, since the sprite zero hit should have occured.
	AND #$40
	BEQ FAIL_Sprite0Hit_Behavior
	INC <currentSubTest
	
	;;; Test 7 [Sprite Zero Hit Behavior]: Sprite zero hits cannot happen at X=255. ;;;
	JSR WaitForVBlank	
	JSR InitializeSpriteZero
	;    YPos, CHR, Att, XPos
	.byte $00, $FC, $00, $FF
	JSR WaitForVBlank
	STX $4014 ; OAM DMA (we want to keep OAM refreshed for these tests)
	JSR Clockslide_3000 ; Wait long enough for VBlank to be over, and a few scanlines to render. (Sprite Zero hit should not occur, for sprite zero is at X=255.)
	LDA $2002	; Bit 6 should NOT be set, since the sprite zero hit should not have occured.
	AND #$40
	BNE FAIL_Sprite0Hit_Behavior
	INC <currentSubTest

	;;; Test 8 [Sprite Zero Hit Behavior]: Sprite zero hits should not happen if sprite zero is at X=0, and the PPU's 8 pixel mask is enabled (show BG, no sprite). ;;;
	JSR WaitForVBlank
	JSR PrintCHR
	.word $2000 ; At address $2000
	.byte $FC, $FF
	JSR ResetScroll
	JSR EnableRendering  ; enable the background and sprites.
	LDA #$1A
	STA $2001 ; enable the background in the left 8 pixels, but not sprites
	JSR InitializeSpriteZero
	;    YPos, CHR, Att, XPos
	.byte $00, $FC, $00, $00
	JSR WaitForVBlank
	STX $4014 ; OAM DMA (we want to keep OAM refreshed for these tests)
	JSR Clockslide_3000 ; Wait long enough for VBlank to be over, and a few scanlines to render. (Sprite Zero hit should not occur, for sprite zero is masked away.)
	LDA $2002	; Bit 6 should NOT be set, since the sprite zero hit should not have occured.
	AND #$40
	BNE FAIL_Sprite0Hit_Behavior
	INC <currentSubTest	
	BNE TEST_Sprite0Hit_Behavior_Continued ; branch always around this fail condition.
	
FAIL_Sprite0Hit_Behavior:
	JSR ClearOverscanNametable
	JSR WaitForVBlank
	JSR DisableRendering_S
	JSR EnableRendering_BG
	JMP TEST_Fail
	
TEST_Sprite0Hit_Behavior_Continued:
	;;; Test 9 [Sprite Zero Hit Behavior]: Sprite zero hits should not happen if sprite zero is at X=0, and the PPU's 8 pixel mask is enabled (show sprite, no BG). ;;;
	JSR WaitForVBlank
	LDA #$1C
	STA $2001 ; enable the sprites in the left 8 pixels, but not BG
	STX $4014 ; OAM DMA (we want to keep OAM refreshed for these tests)
	JSR Clockslide_3000 ; Wait long enough for VBlank to be over, and a few scanlines to render. (Sprite Zero hit should not occur, for sprite zero is masked away.)
	LDA $2002	; Bit 6 should NOT be set, since the sprite zero hit should not have occured.
	AND #$40
	BNE FAIL_Sprite0Hit_Behavior
	INC <currentSubTest	

	;;; Test A [Sprite Zero Hit Behavior]: Despite the 8 pixel mask, if the sprite has visible pixels beyond the mask (X>0, X<8) the Sprite Zero Hit occurs. ;;;
	JSR WaitForVBlank
	JSR InitializeSpriteZero
	;    YPos, CHR, Att, XPos
	.byte $00, $FC, $00, $01	; Xpos = 1
	STX $4014 ; OAM DMA (we want to keep OAM refreshed for these tests)
	JSR Clockslide_3000 ; Wait long enough for VBlank to be over, and a few scanlines to render. (Sprite Zero hit should occur, for some sprite zero is visible.)
	LDA $2002	; Bit 6 should be set, since the sprite zero hit should have occured.
	AND #$40
	BEQ FAIL_Sprite0Hit_Behavior
	INC <currentSubTest	

	;;; Test B [Sprite Zero Hit Behavior]: Sprite zero hits can happen at Y=238. (verify for the next test) ;;;
	JSR WaitForVBlank	
	JSR PrintCHR
	.word $23A1 ; At address $23A1
	.byte $FC, $FF	; solid white square.
	JSR ResetScroll
	JSR InitializeSpriteZero
	;    YPos, CHR, Att, XPos
	.byte 238, $FC, $00, $08
	JSR WaitForVBlank
	STX $4014 ; OAM DMA (we want to keep OAM refreshed for these tests)
	JSR Clockslide_29780 ; Wait an entire frame, since this sprite is at the bottom of the screen. (Sprite Zero hit should occur.)
	LDA $2002	; Bit 6 should be set, since the sprite zero hit should have occured.
	AND #$40
	BEQ FAIL_Sprite0Hit_Behavior
	INC <currentSubTest
	
	;;; Test C [Sprite Zero Hit Behavior]: Sprite zero hits cannot happen at Y>=239. ;;;
	JSR WaitForVBlank	
	JSR InitializeSpriteZero
	;    YPos, CHR, Att, XPos
	.byte 239, $FC, $00, $08
	JSR WaitForVBlank
	STX $4014 ; OAM DMA (we want to keep OAM refreshed for these tests)
	JSR Clockslide_29780 ; Wait an entire frame, since this sprite is at the bottom of the screen. (Sprite Zero hit should NOT occur.)
	JSR Clockslide_500 ; wait a few more scanlines just to be sure.
	LDA $2002	; Bit 6 should NOT be set, since the sprite zero hit should not have occured.
	AND #$40
	BNE FAIL_Sprite0Hit_Behavior2
	INC <currentSubTest

	;;; Test D [Sprite Zero Hit Behavior]: Sprite Zero Hit test with a sprite that isn't a solid 8x8 square. ;;;
	; If this test fails, it could be for one of two reasons.
	; Either, A: Your sprites are being rendered one scanline higher than they should be. (Though I assume if it passes test C that's not the case)
	; Or B: Your sprite zero hit detection isn't actually checking for "solid pixels" overlapping.
	JSR WaitForVBlank
	JSR PrintCHR
	.word $2002 ; At address $2001
	.byte $C1, $FF ; $C1 is a full 8x8 square with a single pixel missing around the middle of it.
	JSR ResetScroll
	JSR InitializeSpriteZero
	;    YPos, CHR, Att, XPos
	.byte $02, $C0, $00, $13	; CHR $C0 is a 1x1 pixel dot. Position ($13, $02) should be lined up perfectly so this one dot sprite falls in the 1x1 hole of the tile.
	STX $4014 ; OAM DMA (we want to keep OAM refreshed for these tests)
	JSR Clockslide_3000 ; Wait long enough for VBlank to be over, and a few scanlines to render. (Sprite Zero hit should miss, since the visible pixel of the sprite isn't overlapping the tile's visible pixels)
	LDA $2002	; Bit 6 should NOT be set, since the sprite zero hit should not have occured.
	AND #$40
	BNE FAIL_Sprite0Hit_Behavior2
	INC <currentSubTest	
	
	;;; Test E [Sprite Zero Hit Behavior]: The sprite zero hit flag is not set until the PPU cycle in which the dot is drawn. ;;;
	JSR WaitForVBlank
	JSR InitializeSpriteZero
	;    YPos, CHR, Att, XPos
	.byte $00, $FC, $00, $FE
	JSR DisableRendering
	LDA #0
	JSR VblSync_Plus_A
	; The sprite zero hit will occur at X=254 of scanline 1. (cycle 255 of scanline 1, since the screen isn't rendering until cycle 1)
	; We are now synced with dot 1 of scanline 241. (Scanline 261 is the final one before looping back to scanline 0)
	; Every scanline is 341 PPU cycles.
	; (21 scanlines plus scanline 0) * PPU cycles per line + cycles into line 1 before the sprite zero hit =
	; (21+1)*341 + 253 ppu cycles until the sprite zero hit =
	; 7756 ppu cycles until the sprite zero hit.
	; There are 3 PPU cycles for every CPU cycle
	; 2585.33 CPU cycles until the sprite zero hit.
	STX $4014 ; OAM DMA ; 4 + 514 CPU cycles. 2067.33 CPU cycles left.
	JSR EnableRendering ; +30 CPU cycles. 2037.33 CPU cycles left.
	JSR Clockslide_2032 ; 5.33 CPU cycles left.
	LDA $2002	; This should read 1 CPU cycles *BEFORE* the sprite zero hit flag is set.
	AND #$40
	BNE FAIL_Sprite0Hit_Behavior2
	LDA #0
	JSR VblSync_Plus_A
	STX $4014 ; OAM DMA ; + 514 CPU cycles. 2071.33 CPU cycles left.
	JSR EnableRendering ; +30 CPU cycles. 2041.33 CPU cycles left.
	JSR Clockslide_2032 ; 5.33 CPU cycles left.
	NOP ; 3.33 CPU cycles left.
	NOP ; 1.33 CPU cycles left. (I chose to add an extra NOP here, in case CPU/PPU alignment affects the timing of this flag when reading $2002.)
	LDA $2002	; This should read 2 CPU cycles *AFTER* the sprite zero hit flag is set.
	AND #$40
	BEQ FAIL_Sprite0Hit_Behavior2	
	;; END OF TEST ;;
	JSR ClearOverscanNametable
	LDA #1
	RTS
;;;;;;;
FAIL_Sprite0Hit_Behavior2:
	JMP FAIL_Sprite0Hit_Behavior
;;;;;;;;;;;;;;;;;

FAIL_ArbitrarySpriteZero1:
	JMP FAIL_ArbitrarySpriteZero

TEST_ArbitrarySpriteZero:
	;;; Test 1 [Arbitrary Sprite Zero]: Sprite 0 should trigger a sprite zero hit. No other sprite should. ;;;
	JSR PREP_SpriteZeroHit
	JSR EnableRendering_S ; start rendering sprites!
	LDA #02
	STA $4014 ; OAM DMA
	JSR Clockslide_3000 ; Wait long enough for VBlank to be over, and the sprite zero hit to occur. (we're not going for precise timing on this test. Just to see if it happens.)
	LDA $2002	; Bit 6 should be set, since the sprite zero hit should have occured.
	AND #$40
	BEQ FAIL_ArbitrarySpriteZero1
	LDX #1
TEST_ArbitrarySpriteZeroLoop:
	JSR WaitForVBlank
	JSR ClearPage2
	JSR InitializeSpriteX
	;    YPos, CHR, Att, XPos
	.byte $00, $FC, $00, $08
	LDA #02
	STA $4014 ; OAM DMA
	JSR Clockslide_3000 ; Wait long enough for VBlank to be over, and the sprite zero hit to occur. (we're not going for precise timing on this test. Just to see if it happens.)
	LDA $2002	; Bit 6 should be set, since the sprite zero hit should have occured.
	AND #$40
	BNE FAIL_ArbitrarySpriteZero1
	INX
	CPX #64
	BNE TEST_ArbitrarySpriteZeroLoop
	INC <currentSubTest	
	
	;;; Test 2 [Arbitrary Sprite Zero]: The first processed sprite of a scanline is treated as "sprite zero". ;;;
	; This test is a bit tricky to understand. Let's break down the sprite evaluation process by which ppu cycles in a scanline are doing which task.
	; PPU cycle >= 1 && PPU cycle <= 64: clear Secondary-OAM.
	; PPU cycle >= 65 && PPU cycle <= 256: Sprite evaluation
	; PPU cycle >= 257 && PPU cycle <= 320: Shift register initialization. (Every one of these cycles also clears PPUOAMAddress to 0.)
	;
	; Keep in mind, on scanline n, we're processing the OAM data in preparation for scanline n+1.
	; (So the sprites drawn on, for example, scanline 6 were evaluated during the rendering of scanline 5.)
	;
	; Let's take a deep look into how Sprite Evaluation works on any given scanline. (PPU cycle >= 65 && PPU cycle <= 256)
	; for odd ppu cycles: read index "PPUOAMAddress" of OAM. Let's call the value read "S"
	;	- "PPUOAMAddress" is the value set by writing to $2003.
	;	- for our example here, assume PPUOAMAddress is zero, reset during the shift register init from the previous scanline.
	; for even cycles: Evaluate "S" and determine if this sprite should be drawn on the next scanline.
	;	- Depending on how the evaluation goes, modify PPUOAMAddress. Typically increment by 1 or 4. (actually "it's complicated", but that's for a different test.)
	; Let's focus on the even cycles.
	; First of all, if Secondary-OAM is full, the behavior is different. Let's focus on when Secondary-OAM is not full.
	; STEP 1: Check that the Y position of this object is in range of this scanline.
	;	- The value checked here is "S", which was read in the previous PPU cycle. In this example, "S" should be index 0 of OAM, since PPUOAMAddress was cleared in the previous scanline.
	;	- If the current scanline number-"S" is positive, and less than 8 (or 16 if the sprites are using the 8 by 16 mode) then this object is in range for this scanline.
	;	- That previous sentance was just a verbose way of calculating "yes, this object should be rendered on the next scanline".
	;	- Now, if Secondary-OAM is not full (in this example it is still empty, so yeah- it's not full) we know this object will be in the next scanline, so add it to Secondary-OAM.
	;	- In addition to being added to Secondary-OAM, if this is PPU cycle 66 of a scanline, it is assumed that we are processing sprite zero, so raise a flag indicating sprite zero exists on the next scanline.
	; STEP 2 to 4: Read "S" as the CHR data, attributes, and X position respectively. (each of these steps happen 2 ppu cycles after the previous step, since we need to read "S" from OAM again)
	;	- There's actually some wild stuff going on with the X position, but that's for a different test.
	;
	; So to recap, read the Y position, and on the following cycle, see if it's in range. If it is, and this is PPU cycle 66 of a given scanline, raise a flag indicating sprite zero exists on the next scanline.
	; - this "flag" essentially says, Secondary-OAM index 0 is "Sprite Zero", as in, a Sprite Zero hit will occur if a "solid pixel" of "sprite zero" overlaps a "solid pixel" of the background.
	; - which is, again, a really verbose way of saying "run a check for a sprite zero hit next scanline" if the value of "S" on ppu cycle 66 was in range for this scanline. 
	;
	; Duh. If you've implemented sprite zero hits, you should be following along. 
	; Perhaps that "flag" isn't the exact way your emulator checks if a sprite is "sprite zero", but it will make sense in a moment why I'm phrasing it this way.
	;
	; What happens if you write to $2003 after the "Shift register initialization" and before "Sprite evaluation"?
	; Well, PPUOAMAddress won't be $00 when sprite evaluation begins.
	; So the first sprite processed on cycle 66 won't necessarily be index zero of OAM.
	; But if "S" is in range of the scanline, and it's cycle 66, then the next scanline will consider Secondary-OAM index 0 as "sprite zero", even if it isn't OAM index 0.
	;
	; In other words, it *is* possible for an object that isn't OAM index 0 to trigger a sprite 0 hit!

	; On a completely unrelated topic, writing to $2003 is all sorts of jank, and I need my test here to prevent that "jankiness" from ruining the results.
	; This behavior appears to only happen on CPU/PPU clock alignment 3:
	; writing to $2003 can copy 8 bytes of OAM from $20 to $27, and paste these values at:
	; The old PPUOAMAddress & $F8
	; The new PPUOAMAddress & $F8
	; So we also want to the 8 values starting at $20 to match the 8 values we want at the new PPUOAMAddress

	; Since this test is a doozy, I will comment every line and explain why I'm doing this.
	JSR ClearPage2				; Let's clear page 2. I'm using page 2 for the OAM DMA, so OAM will be a copy of $200 - $2FF
	JSR WaitForVBlank			; Wait for VBlank. I'm going to disable rendering next, and I'd prefer if I waited for VBlank to do that.
	JSR DisableRendering		; Rendering is now disabled. Rendering needs to be disabled for the upcoming VblSync_Plus_A subroutine to work properly.
	LDX #32						; Let's initialize Sprite 32 at screen coordinates ($08, $00)
	JSR InitializeSpriteX		; This subroutine reads the following 4 bytes, and adjusts the return address accordingly, so the following 4 bytes are not executed.
	.byte $00, $FC, $00, $08	; Y Position, Pattern Table Index, Attributes, X position  
	LDX #8						; Let's also initialize Sprite 8 with the same values, so the $2003 corruption doesn't break anything.
	JSR InitializeSpriteX		; This subroutine reads the following 4 bytes, and adjusts the return address accordingly, so the following 4 bytes are not executed.
	.byte $00, $FC, $00, $08	; Y Position, Pattern Table Index, Attributes, X position  
	LDA #0						; A=0, since this next subroutine syncs to PPU cycle A of Vblank, and I want to sync to cycle 0.
	JSR VblSync_Plus_A  		; Sync the next CPU cycle to PPU cycle 0 of VBlank. (cycle 1 of scanline 241)
								; The CPU is now at PPU cycle 0 of vblank.
								; Let's caluclate how many CPU cycles remain until scanline 0 is being rendered.
								; We're on dot 1 of scanline 241. The final dot before scanline 0 is dot 341 of scanline 261
								; There are 341 PPU cycles per scanline
								; (341 * 21)-1 = 7160 PPU cycles until dot 0 of scanline 0.
								; 3 PPU cycles per 1 CPU cycle. 7160/3 = 2386.66 CPU cycles.
								; So let's count CPU cycles. We have 2386 cycles until dot 0, which is when we want to write to $2003 to udpate PPUOAMAddress
	LDA #02						; (+2 CPU cycles)   A = 2, so the OAM DMA will use page 2
	STA $4014					; (+518 CPU cycles) Run the OAM DMA with page 2.
	LDA #32*4					; (+2 CPU cycles) Load A with 32*4 (128, or $80) which is the OAM address for the object we initialized.
	JSR EnableRendering			; (+30 CPU cycles) Enable rendering of both the background and sprites, so the sprite zeto hit can occur.
								; After setting up sprite 8 and running the OAM DMA, we have 1596 CPU cycles remaining before cycle 0 of scanline 0.
	JSR Clockslide_1830			; (+1598 CPU cycles) This function just stalls for 1598 CPU cycles, so we should be slightly after cycle 0 of scanline 0.
	STA $2003					; Store A ($80) at PPUOAMAddress. (and probably copy 8 instances of $FF from OAM[$00] to OAM[$20], which won't break anything)
								; Now, the sprite evaluation will occur with sprite 8 getting processed first.
								; Since this object is the first one processed, PPU cycle 66 will check if it is in range of the current scanline.
								; and if it is (it is), it will be treated as sprite zero for the purposes of triggering a sprite zero hit, despite being sprite 8.
	JSR Clockslide_500			; Wait a few scanline for this entire sprite to be drawn
	LDA $2002					; Read PPUSTATUS
	AND #$40					; mask away every bit except the Sprite Zero Hit flag.
	BEQ FAIL_ArbitrarySpriteZero; If bit 6 was zero, the sprite zero hit did not occur, thus failing the test.
	INC <currentSubTest			; And if we passed this, increment the subtest so the error code is adjusted for this next test.
	
	;;; Test 3 [Arbitrary Sprite Zero]: Misaligned OAM can properly draw a sprite, and yes, it can even trigger a sprite zero hit. ;;;
	; So in that previous test, PPUOAMAddress manually set to a non-zero value just before sprite evaluation. However, this value was a multiple of 4, so it wasn't too complicated.
	; Now things are getting complicated, because we need to talk about what happens in sprite evaluation if PPUOAMAddress is NOT a multiple of 4.
	;	- I am referring to this as "misaligned OAM"
	;	- To be clear, there is also some very specific behavior with misaligned OAM (if the y position is NOT in range) that cannot be checked with sprite zero hits.
	;	- That will be tested in a different test.
	; Let's begin with a misaligned object that passes the "Y Position in range of scanline check"
	; Let's write all of this at $0221.
	; Keep in mind, the OAM attribute byte doesn't have bits 2, 3, or 4, and since we're misaligned, now our CHR Pattern is missing those bits.
	; The CHR Pattern of our choice is essentially bitwise ANDed with $E3.
	; That's why tile $E3 in the pattern data is just a full square.
MisalignedOAM_SpriteZeroTest:   ; I re-use this code in the Misaligned OAM test.
Address2004_SpriteZeroTest:     ; I also re-use this code in the $2004 behavior test.
	JSR ClearPage2				; Same as above. Clear page 2.
	JSR WaitForVBlank			; Same as above. Wait for VBlank.
	JSR DisableRendering		; Same as above. Disable rendering for the VBL Sync subroutine.
	LDX #$81					; We're going to write this at OAM $81
	JSR InitializeOAMAddrX		; Similar to the other subroutine, but this one doesn't multiply X by 4.
	.byte $00, $E3, $00, $08	; Same as above. These bytes don't get executed. Use pattern $E3.
	LDX #$21					; We're going to write this at OAM $21, so the $2003 corruption doesn't break anything.
	JSR InitializeOAMAddrX		; Similar to the other subroutine, but this one doesn't multiply X by 4.
	.byte $00, $E3, $00, $08	; Same as above. These bytes don't get executed. Use pattern $E3.
	LDA #0						; Same as above. Sync to ppu cycle 0 of vblank. 
	JSR VblSync_Plus_A  		; Same as above. Sync to ppu cycle 0 of vblank. 
								; Same as above. We have 2386 cycles until dot 0 of scanline 0.	
	LDA #02						; Same as above. A=2 for the OAM DMA.
	STA $4014					; Same as above. Run the OAM DMA with page 2.
	LDA #$81					; Load A with $81, which we will write to $2003 to offset the OAM address.
	JSR EnableRendering			; Same as above. Enable rendering sprites + background.
	JSR Clockslide_1830			; Same as above, except we're 1 CPU cycles earlier than last time. (3 PPU cycles)
	STA $2003					; Store A ($81) at a mirror of PPUOAMAddress. (and probably copy 8 instances of $FF from OAM[$00] to OAM[$20], which won't break anything)
	JSR Clockslide_500			; Same as above. Wait a few scanline for this entire sprite to be drawn
	LDA $2002					; Read PPUSTATUS
	AND #$40					; Same as above. mask away every bit except the Sprite Zero Hit flag.
	BEQ FAIL_ArbitrarySpriteZero; Same as above. If bit 6 was zero, the sprite zero hit did not occur, thus failing the test.
	
	;; END OF TEST ;;
	JSR ClearOverscanNametable
	LDA #1
	RTS
;;;;;;;
	
FAIL_ArbitrarySpriteZero:
FAIL_SprOverflow:
FAIL_MisalignedOAM:
FAIL_Address2004:
	JSR ClearOverscanNametable
	JSR WaitForVBlank
	JSR DisableRendering_S
	JSR EnableRendering_BG
	JMP TEST_Fail
;;;;;;;;;;;;;;;;;

SpriteOverflowLUT:
	.byte $00, $FC, $00, $80
	; Y position = $00 (top of screen)
	; Pattern = $FC (solid white square)
	; Attributes = 0 (not flipped, palette 0)
	; X Position = $80 (middle of screen)
	
	JMP FAIL_ArbitrarySpriteZero ; Disable rendering sprites *and* fail the test.

TEST_SprOverflow_Behavior:
	;;; Test 1 [Sprite Overflow Behavior]: 9 sprites in a single scanline will set the Sprite Overflow Flag. ;;;
	JSR ClearPage2
	LDA #0
	TAX
	TAY
SprOverflow_PrepLoop:
	LDA SpriteOverflowLUT, Y
	STA $200, X
	INX
	INY
	CPY #4
	BNE SprOverflow_Prep1
	LDY #0
SprOverflow_Prep1:
	CPX #4*9
	BNE SprOverflow_PrepLoop
	JSR WaitForVBlank
	LDA #02
	STA $4014 ; Set up OAM so objects 0 through 8 exist on scanline 1.
	JSR EnableRendering	; Enable both the background and sprites.
	JSR Clockslide_3000 ; wait long enough for these to render.
	LDA $2002
	AND #$20 ; Bit 5 holds the sprite overflow flag
	BEQ FAIL_SprOverflow
	INC <currentSubTest	
	
	;;; Test 2 [Sprite Overflow Behavior]: The Sprite Overflow Flag is NOT the same thing as the CPU's V flag. ;;;
	; The first emulator I ever made was making this mistake, ha! I doubt anybody is making this mistake, but I'll test for it anyway.
	JSR WaitForVBlank
	LDA #02
	STA $4014 ; Set up OAM so objects 0 through 8 exist on scanline 1.
	CLV	; Clear CPU V flag
	JSR Clockslide_3000 ; wait long enough for these to render.
	BVS FAIL_SprOverflow ; The CPU V flag should not have been set by the PPU.
	CLV	; Likewise, clearing this will not clear the Sprite Overflog flag.
	LDA $2002
	AND #$20 ; Bit 5 holds the sprite overflow flag
	BEQ FAIL_SprOverflow
	INC <currentSubTest		
	
	;;; Test 3 [Sprite Overflow Behavior]: 8 sprites in a single scanline will not set the Sprite Overflow Flag. ;;;
	LDA #$FF
	STA $200	; move sprite zero to Y=$FF (does not get rendered ever)
	JSR WaitForVBlank
	LDA #02
	STA $4014 ; Set up OAM so objects 0 through 7 exist on scanline 1.
	JSR Clockslide_3000 ; wait long enough for these to render.
	LDA $2002
	AND #$20 ; Bit 5 holds the sprite overflow flag. (in this case, not set because only 8 sprites existed on the busiest scanline)
	BNE FAIL_SprOverflow
	INC <currentSubTest		

	;; END OF TEST ;;
	JSR ClearOverscanNametable
	LDA #1
	RTS
;;;;;;;
	
MisalignedOAM_Test:
	JSR WaitForVBlank
	LDA #02
	STA $4014
	JSR DisableRendering
	LDA #0
	JSR VblSync_Plus_A
	; Sync to dot 0 of vblank

	LDA #02
	STA $4014
	JSR EnableRendering
	JSR Clockslide_1816
	RTS
;;;;;;;

FAIL_MisalignedOAM_Behavior:
	JMP FAIL_MisalignedOAM
	
TEST_MisalignedOAM_Behavior:
	; Let's talk about what happens when you misalign the PPU OAM Address immediately before sprite evaluation, and how this changes the behavior of sprite evaluation.
	;;; Test 1 [Misaligned OAM Behavior]: Misaligned OAM can properly draw a sprite and trigger a sprite zero hit (Misaligned OAM "+1 behavior"). ;;;
	; This is genuinely the exact same test as [Arbitrary Sprite Zero] test 3.
	; Please see [Arbitrary Sprite Zero] test 3 for an explanation.
	; If this doesn't work, then it is assumed misaligned OAM is not working at all.
	JSR PREP_SpriteZeroHit			
	JSR MisalignedOAM_SpriteZeroTest
	LDX #1
	STX <currentSubTest
	CMP #1
	BNE FAIL_MisalignedOAM_Behavior
	; Thsi test also relies on proper Sprite Overflow Flag emulation, so let's check that one too.
	JSR TEST_SprOverflow_Behavior
	LDX #1
	STX <currentSubTest
	CMP #1
	BNE FAIL_MisalignedOAM_Behavior
	INC <currentSubTest	
	
	;;; Test 2 [Misaligned OAM Behavior]: Misaligned OAM "+4 behavior" Offset by 1" ;;;	
	; Misaligned OAM should stay misaligned until an object's Y position is out of the range of this scanline, at which point the OAM address is incremented by 4 and bitwise ANDed with $FC.
	
	; In the "Arbitrary Sprite Zero" test, I said the following:
	; 	- Depending on how the evaluation goes, modify PPUOAMAddress. Typically increment by 1 or 4. (actually "it's complicated", but that's for a different test.)
	; Well, it's time for that test! 
	; When evaluating if the Y position of an object is in range for the scanline, if it *isn't* in range, the following occurs.
	; PPUOAMAddress += 4
	; PPUOAMAddress &= $FC
	;
	; This bitwise AND masks away the lower 2 bits, and it's not super common to see emulated.
	; If OAM is always aligned, then this bitwise AND seemingly does nothing.
	; In pretty much every case, the OAM address will always be a multiple of 4 when reading the Y position from OAM. 
	; Hence, adding 4 to this address when an object's Y position is not in range would take it to another multiple of 4. The bitwise AND makes no affect.
	;
	; However, if the OAM address is not a multiple of 4 when this bitwise AND occurs, it will re-align the PPUOAMAddress with a multiple of 4.
	; Let's study a series of bytes in OAM and how this works.
	; I'll put square brackets around the first object to be evaluated, and curly braces around the second. 
	; Try visualizing it like a venn diagram: [A {B] C} where "A" are bytes exclisive to the first object, "B" are bytes that are shared, and "C" are bytes exclusive to the following object to get processed.
	; If OAM is aligned, it might look like this:
	; (OAM Address $80): [$80, $FC, $00, $08,] {$00, $FC, $00, $08}
	; Where that first byte ($80) is not in range of the scanline, so PPUOAMAddress is incremented by 4 and bitwise ANDed with $FC. The result takes PPUOAMAddress to $84.
	; This is the expected behavior, but when OAM is misaligned, these objects "overlap", sharing bytes. What would have been the X position of the first object becomes the Y position of the second:
	; If OAM is misaligned +1, it might look like this.
	; (OAM Address $80): $FF, [$80, $FC, $00, {$08,] $00, $FC, $00,} $08
	; Where that first byte ($80) is not in range of the scanline. The result still takes PPUOAMAddress to $84 (where the value is $08), due to the bitwise AND.
	; If OAM is misaligned +2, it might look like this.
	; (OAM Address $80): $FF, $FF, [$80, $FC, {$00, $08,] $00, $FC,} $00, $08
	; Where the same thing applies. PPUOAMAddress is now $84.
	; If OAM is misaligned +3, it might look like this.
	; (OAM Address $80): $FF, $FF, $FF, [$80, {$FC, $00, $08,] $00,} $FC, $00, $08
	; Where the same thing applies. PPUOAMAddress is now $84.
	; And if OAM is misaligned +4, then it's actually aligned again.
	; (OAM Address $80): $FF, $FF, $FF, $FF, [$80, $FC, $00, $08,] {$00, $FC, $00, $08}

	; So to recap, if the Y position *is* in range, then PPUOAMAddress is incremented by 1. Otherwise, add 4 to PPUOAMAddress, and mask away the lower 2 bits of PPUOAMAddress.
	; This results in OAM becoming "re-aligned".
	; And we can test for this behavior by misaligning OAM, having it get re-aligned, and then putting 9 objects on a single scanline to set the Sprite Overflow flag.
	; If the behavior does not match the console, then the data processed will intentionally be set up such that the sprite overflow flag doesn't get set.
	
	; To assist in debugging, the sprite evaluation for all of these tests will occur on scanline 0, and will be the first objects evaluated, starting at dot 65.
	
	; So to recap in simpler terms,
	; If the value read as the Y position *is* in range, just add 1 to the OAM address.
	; If the value read as the Y position is *not* in range, just add 4 to tha OAM address and bitwise AND the OAM address with $FC.
	
	; Before this test, let's clear page 2 (with $FFs).
	JSR ClearPage2
	; Copy data from a look up table to address $280
	LDX #0
TEST_MisalignedOAM_P4_Y_1_Loop:
	LDA MisalignedOAM_Y_LUT_Off1,X
	STA $200, X
	INX
	CPX #41
	BNE TEST_MisalignedOAM_P4_Y_1_Loop
	JSR MisalignedOAM_Test		; Sync with (approximately) dot 0 of scaline 0.
	LDA #1			; The data we want to process in OAM first is at address 1.
	STA $2002		; Write this to $2002 to prime to PPU Data bus.
	LDX #0			; We're going to write to $2003 with an offset, as a means to prevent the $2003 corruption.
	STA $2003, X	; The dummy read prepared the CPU databus with the value read from the PPU databus. Now the early write to $2003 will be #01, the same as the intended write.

	; Okay, so here's how these objects get processed.
	; OAM $01: [$00, $E3, $00, $00]
	; OAM $05: [$00, $E3, $00, $00]
	; OAM $09: [$00, $E3, $00, $00]
	; OAM $0D: [$00, $E3, $00, $00]
	; OAM $11: [$00, $E3, $00, $00]
	; OAM $15: [$00, $E3, $00, $00]
	; OAM $19: [$80]($FF, $FF, $00) This is NOT in range, so the only byte processed here is $80. PPUOAMAddress+=4; PPUOAMAddress&=$FC; (PPUOAMAddress is now $1C)
	; OAM $1C: [$00, $E3, $00, $00]
	; OAM $20: [$00, $E3, $00, $00]
	; OAM $24: [$00, $E3, $00, $00]
	; This puts 9 objects in range of this scanline, so the sprite overflow flag is set!
	; (By the way, the sprites are only processed like this for a single scanline. The rest of the scanlines, PPUOAMAddress will be $00 going into sprite evaluation.)
	JSR Clockslide_500			; Wait long enough for the ppu to draw every scanline in which these objects are relevant.
	LDA $2002					; Read PPUSTATUS, putting the sprite overflow flag in bit 5.
	AND #$20 					; mask away bit 5. The result should be A = $20, since the sprite overflow flag *should* be set.
	BEQ FAIL_MisalignedOAM_Behavior
	INC <currentSubTest	
	
	;;; Test 3 [Misaligned OAM Behavior]: Misaligned OAM "+5 behavior" Offset by 1 ;;;
	; If Secondary OAM is full, instead of incrementing the OAM Address by 4 and bitwise ANDing with $FC, you should instead only increment the OAM address by 5.
	; Before this test, let's clear page 2 (with $FFs).
	JSR ClearPage2
	; Copy data from a look up table to address $220
	LDX #0
TEST_MisalignedOAM_P5_Y_1_Loop:
	LDA MisalignedOAM_Y_LUT_Off1_Full,X
	STA $200, X
	INX
	CPX #43
	BNE TEST_MisalignedOAM_P5_Y_1_Loop
	JSR MisalignedOAM_Test		; Sync with (approximately) dot 0 of scaline 0.
	LDA #1			; The data we want to process in OAM first is at address 1.
	STA $2002		; Write this to $2002 to prime to PPU Data bus.
	LDX #0			; We're going to write to $2003 with an offset, as a means to prevent the $2003 corruption.
	STA $2003, X	; The dummy read prepared the CPU databus with the value read from the PPU databus. Now the early write to $2003 will be #01, the same as the intended write.

	; Okay, so here's how these objects get processed.
	; OAM $01: [$00, $E3, $00, $00]
	; OAM $05: [$00, $E3, $00, $00]
	; OAM $09: [$00, $E3, $00, $00]
	; OAM $0D: [$00, $E3, $00, $00]
	; OAM $11: [$00, $E3, $00, $00]
	; OAM $15: [$00, $E3, $00, $00]
	; OAM $19: [$00, $E3, $00, $00]
	; OAM $1D: [$00, $E3, $00, $00]
	; OAM $21: [$80]($FF, $FF, $FF, $FF) This is NOT in range, so the only byte processed here is $80. Secondary OAM is full, so add 5. PPUOAMAddress+=5; (PPUOAMAddress is now $26)
	; OAM $26: [$00, $E3, $00, $00]
	; This puts 9 objects in range of this scanline, so the sprite overflow flag is set!
	; (By the way, the sprites are only processed like this for a single scanline. The rest of the scanlines, PPUOAMAddress will be $00 going into sprite evaluation.)
	JSR Clockslide_500			; Wait long enough for the ppu to draw every scanline in which these objects are relevant.
	LDA $2002					; Read PPUSTATUS, putting the sprite overflow flag in bit 5.
	AND #$20 					; mask away bit 5. The result should be A = $20, since the sprite overflow flag *should* be set.
	BEQ FAIL_MisalignedOAM_Behavior1
	INC <currentSubTest	
	
	;;; Test 4 [Misaligned OAM Behavior]: Misaligned OAM "+4* behavior" Offset by 1 (* Only +1 with the X Position) ;;;
	; In the "Arbitrary Sprite Zero" test, I said the following:
	;	- There's actually some wild stuff going on with the X position, but that's for a different test.
	; Now it's time to test for this!
	; When evaluating the X position of an object, it also makes the same "in range of scanline" calculation that the Y position makes.
	; It's a bit confusing to explain, so let me recap.
	; In the "Arbitrary Sprite Zero" test, I specifically stated:
	; 	- for odd ppu cycles: read index "PPUOAMAddress" of OAM. Let's call the value read "S"...
	;	- for even cycles: Evaluate "S"...
	;	- STEP 1: Check that the Y position of this object is in range of this scanline.
	;		- If the current scanline number-"S" is positive, and less than 8 (or 16 if the sprites are using the 8 by 16 mode) then this object is in range for this scanline.
	;	- STEP 2 to 4: Read "S" as the CHR data, attributes, and X position respectively. 
	;
	; The exact same calculation used in "STEP 1" to determine if a value is in range of the scanline happens again in STEP 4.
	; Except now "S" holds the value of the X position.
	; So, if the current scanline number-"S" is positive, and less than 8 (or 16 if the sprites are using the 8 by 16 mode) then this object is in range for this scanline.
	; In the case of the Y position not being in range, you would add 4 to PPUOAMAddress and bitwise AND PPUOAMAddress with $FC.
	; However, in the case of the X position not being in range, you only add 1 to PPUOAMAddress, though you still bitwise AND with $FC.
	; In aligned OAM, this bitwise AND is never noticed, as adding 1 will align the PPUOAMAddress.
	; With misaligned OAM, we can detect this, again, by putting 9 objects on a scanline.	
	
	JSR ClearPage2
	LDX #0
TEST_MisalignedOAM_P4_1_Loop:
	LDA MisalignedOAM_LUT_Off1,X
	STA $200, X
	INX
	CPX #41
	BNE TEST_MisalignedOAM_P4_1_Loop
	JSR MisalignedOAM_Test		; Sync with (approximately) dot 0 of scaline 0.
	LDA #1			; The data we want to process in OAM first is at address 1.
	STA $2002		; Write this to $2002 to prime to PPU Data bus.
	LDX #0			; We're going to write to $2003 with an offset, as a means to prevent the $2003 corruption.
	STA $2003, X	; The dummy read prepared the CPU databus with the value read from the PPU databus. Now the early write to $2003 will be #01, the same as the intended write.
	; Okay, so here's how these objects get processed.

	; OAM $01: [$00, $E3, $00, $80]
	; OAM $05: [$00, $E3, $00, $00]
	; OAM $09: [$00, $E3, $00, $00]
	; OAM $0D: [$00, $E3, $00, $00]
	; OAM $11: [$00, $E3, $00, $00]
	; OAM $15: [$00, $E3, $00, $00]
	; OAM $19: [$00, $E3, $00, $80] This X value ($80, at OAM address $20) is NOT in range. PPUOAMAddress+=1; PPUOAMAddress&=$FC; (PPUOAMAddress is now $1C)
	; OAM $1C: [$80]($E3, $FF, $FF) This Y values is also not in range, so add 4 (and bitwise AND with $FC)
	; OAM $20: [$00, $E3, $00, $00]
	; OAM $24: [$00, $E3, $00, $00]

	; This puts 9 objects in range of this scanline, so the sprite overflow flag is set!
	; (By the way, the sprites are only processed like this for a single scanline. The rest of the scanlines, PPUOAMAddress will be $00 going into sprite evaluation.)
	JSR Clockslide_500
	LDA $2002
	AND #$20 ; Bit 5 holds the sprite overflow flag.
	BEQ FAIL_MisalignedOAM_Behavior1
	INC <currentSubTest	

	;;; Test 5 [Misaligned OAM Behavior]: Misaligned OAM "+4* behavior" Offset by 1, Second OAM Full, so OAMAddr +=5 (* Only +1 with the X Position) ;;;
	; If Secondary OAM is full, instead of incrementing the OAM Address by 1 and bitwise ANDing with $FC, you should instead only increment the OAM address by 5.
	; OAM will be offset by 1.
	JSR ClearPage2
	LDX #0
TEST_MisalignedOAM_P4_1F_Loop:
	LDA MisalignedOAM_LUT_Off1_Full,X
	STA $200, X
	INX
	CPX #42
	BNE TEST_MisalignedOAM_P4_1F_Loop
	JSR MisalignedOAM_Test		; Sync with (approximately) dot 0 of scaline 0.
	LDA #1			; The data we want to process in OAM first is at address 1.
	STA $2002		; Write this to $2002 to prime to PPU Data bus.
	LDX #0			; We're going to write to $2003 with an offset, as a means to prevent the $2003 corruption.
	STA $2003, X	; The dummy read prepared the CPU databus with the value read from the PPU databus. Now the early write to $2003 will be #01, the same as the intended write.
	; Okay, so here's how these objects get processed.
	; OAM $01: [$00, $E3, $00, $00]
	; OAM $05: [$00, $E3, $00, $00]
	; OAM $09: [$00, $E3, $00, $00]
	; OAM $0D: [$00, $E3, $00, $00]
	; OAM $11: [$00, $E3, $00, $00]
	; OAM $15: [$00, $E3, $00, $00]
	; OAM $19: [$00, $E3, $00, $00]
	; OAM $1D: [$00, $E3, $00, $80] This X value ($80, at OAM address $20) is NOT in range. PPUOAMAddress+=1; PPUOAMAddress&=$FC; (PPUOAMAddress is now $20)
	; OAM $20: [$80]($E3, $FF, $FF, $FF) This Y values is also not in range and secondary OAM is full, so add 5 (PPUOAMAddress is now $25)
	; OAM $25: [$00, $E3, $00, $80]
	; OAM $2C: [$00, $E3, $00, $80]
	; This puts 9 objects in range of this scanline, so the sprite overflow flag is set!
	; (By the way, the sprites are only processed like this for a single scanline. The rest of the scanlines, PPUOAMAddress will be $00 going into sprite evaluation.)
	JSR Clockslide_500
	LDA $2002
	AND #$20 ; Bit 5 holds the sprite overflow flag.
	BEQ FAIL_MisalignedOAM_Behavior1
	INC <currentSubTest	
	BNE TEST_MisalignedOAM_Continue ; Skip the fail handler. I moved the fail handler here because branches were exceeding $80 bytes.
	
FAIL_MisalignedOAM_Behavior1:
	JMP FAIL_MisalignedOAM

TEST_MisalignedOAM_Continue:
	;;; Test 6 [Misaligned OAM Behavior]: Misaligned OAM "+4* behavior" Offset by 2 (* Only +1 with the X Position) ;;;
	; OAM will be offset by 2.
	JSR ClearPage2
	LDX #0
TEST_MisalignedOAM_P4_2_Loop:
	LDA MisalignedOAM_LUT_Off2,X
	STA $200, X
	INX
	CPX #39
	BNE TEST_MisalignedOAM_P4_2_Loop
	LDX #0
	LDY #$1E
	JSR MisalignedOAM_Test		; Sync with (approximately) dot 0 of scaline 0.
	LDA #2			; The data we want to process in OAM first is at address 2.
	STA $2002		; Write this to $2002 to prime to PPU Data bus.
	LDX #0			; We're going to write to $2003 with an offset, as a means to prevent the $2003 corruption.
	STA $2003, X	; The dummy read prepared the CPU databus with the value read from the PPU databus. Now the early write to $2003 will be #02, the same as the intended write.
	; Okay, so here's how these objects get processed.
	; OAM $02: [$00, $E3, $10, $00]
	; OAM $06: [$00, $E3, $20, $00]
	; OAM $0A: [$00, $E3, $30, $00]
	; OAM $0E: [$00, $E3, $40, $00]
	; OAM $12: [$00, $E3, $50, $00]
	; OAM $16: [$00, $E3, $60, $00]
	; OAM $1A: [$00, $E3, $70, $00]
	; OAM $1E: [$00, $E3, $00, $80] This X value ($80, at OAM address $21) is NOT in range. PPUOAMAddress+=1; PPUOAMAddress&=$FC; (PPUOAMAddress is now $20)
	; OAM $20: [$00, $80, $00, $00] 
	; This puts 9 objects in range of this scanline, so the sprite overflow flag is set!
	; (By the way, the sprites are only processed like this for a single scanline. The rest of the scanlines, PPUOAMAddress will be $00 going into sprite evaluation.)
	JSR Clockslide_500
	LDA $2002
	AND #$20 ; Bit 5 holds the sprite overflow flag.
	BEQ FAIL_MisalignedOAM_Behavior1
	INC <currentSubTest	

	;;; Test 7 [Misaligned OAM Behavior]: Misaligned OAM "+4* behavior" Offset by 3 (* Only +1 with the X Position) ;;;
	JSR ClearPage2
	LDX #0
TEST_MisalignedOAM_P4_3_Loop:
	LDA MisalignedOAM_LUT_Off3,X
	STA $200, X
	INX
	CPX #40
	BNE TEST_MisalignedOAM_P4_3_Loop
	LDX #0
	LDY #$1E
	JSR MisalignedOAM_Test		; Sync with (approximately) dot 0 of scaline 0.
	LDA #3			; The data we want to process in OAM first is at address 3.
	STA $2002		; Write this to $2002 to prime to PPU Data bus.
	LDX #0			; We're going to write to $2003 with an offset, as a means to prevent the $2003 corruption.
	STA $2003, X	; The dummy read prepared the CPU databus with the value read from the PPU databus. Now the early write to $2003 will be #03, the same as the intended write.
	; Okay, so here's how these objects get processed.
	; OAM $03: [$00, $10, $00, $00]
	; OAM $07: [$00, $20, $00, $00]
	; OAM $0B: [$00, $30, $00, $00]
	; OAM $0F: [$00, $40, $00, $00]
	; OAM $13: [$00, $50, $00, $00]
	; OAM $17: [$00, $60, $00, $00]
	; OAM $1B: [$00, $70, $00, $00]
	; OAM $1F: [$00, $80, $00, $80] This X value ($80, at OAM address $21) is NOT in range. PPUOAMAddress+=1; PPUOAMAddress&=$FC; (PPUOAMAddress is now $20)
	; OAM $20: [$80]($00, $80, $FF, $FF) Secondary OAM is full, so instead of the PPUOAMAddress += 4, PPUOAMAddress &= $FC behavior, it's just the PPUOAMAddress +=5 behavior. (PPUOAMAddress is now $25)
	; OAM $25: [$00, $FF, $FF, $FF]
	; This puts 9 objects in range of this scanline, so the sprite overflow flag is set!
	JSR Clockslide_500
	LDA $2002
	AND #$20 ; Bit 5 holds the sprite overflow flag.
	BEQ FAIL_MisalignedOAM_Behavior1
	
	;; END OF TEST ;;
	JSR ClearOverscanNametable
	JSR DisableRendering_S
	LDA #1
	RTS
;;;;;;;

	
MisalignedOAM_Y_LUT_Off1:
	; Misaligned +1, YPos not in range.
	.byte $FF
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $80, $FF, $FF      ; Y position is not in range of this scanline, so OAM will become re-aligned.
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	
	; object 6 is processed as $80 (not in range)
	; object 7 is processed as $00, $E3, $00, $00
	; If this was aligned, it looks like this: (upwards of 8 in a single scanline)
	; $FF, $00, $E3, $00
	; $00, $00, $E3, $00
	; $00, $00, $E3, $00
	; $00, $00, $E3, $00
	; $00, $00, $E3, $00
	; $00, $00, $E3, $00
	; $00, $00, $E3, $00
	; $00, $80, $FF, $FF 
	; $00, $E3, $00, $00 
	; $00, $E3, $00, $00

	
MisalignedOAM_Y_LUT_Off1_Full:
	; Misaligned +1, YPos not in range. (OAM will be full before re-aligning, adding +5 due to a hardware error)
	.byte $FF
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $80, $FF, $FF, $FF, $FF; Y position is not in range of this scanline, so OAM+=5; (no bitwise stuff)
	.byte $00			     ; X position and Y position are both in range of this scanline.

	; object 8 is processed as $80 (not in range)
	; object 9 is processed as $00, $E3, $00, $00
	; If this was aligned, it looks like this: (upwards of 8 in a single scanline)
	; $FF, $00, $E3, $00
	; $00, $00, $E3, $00
	; $00, $00, $E3, $00
	; $00, $00, $E3, $00
	; $00, $00, $E3, $00
	; $00, $00, $E3, $00
	; $00, $00, $E3, $00
	; $00, $00, $E3, $00
	; $00, $80, $FF, $FF
	; $FF, $FF, $00
	
	
MisalignedOAM_LUT_Off1:
	; Misaligned +1
	.byte $FF
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $00, $80 ; Y position is in range of this scanline, X position is not. (OAM++; OAM &= $FC) (That $80 is now the first byte processed for the next object)
	.byte $E3, $FF, $FF		 ; OAM is aligned again.
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	; object 7 is processed as $80, $E3, $00, $00
	; object 8 is processed as $00, $E3, $00, $00
	; If this was aligned, it looks like this: (upwards of 8 in a single scanline)
	; $FF, $00, $E3, $00
	; $00, $E3, $00, $00
	; $00, $E3, $00, $00
	; $00, $E3, $00, $00
	; $00, $E3, $00, $00
	; $00, $E3, $00, $00
	; $00, $E3, $00, $00
	; $00, $E3, $00, $00
	; $80, $E3, $FF, $FF
	; $00, $E3, $00, $00
	
MisalignedOAM_LUT_Off1_Full:
	; Misaligned +1 (OAM will be full before re-aligning, adding +5 due to a hardware error)
	.byte $FF
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $00, $80 ; Y position is in range of this scanline, X position is not. (OAM++; OAM &= $FC) (That $80 is now the first byte processed for the next object)
	.byte $E3, $FF, $FF, $FF ; OAM is aligned, but since this object isn't in range, and 2nd OAM is full, due to a hardware bug OAM += 5.
	.byte $00, $E3, $00, $00 ; X position and Y position are both in range of this scanline.
	; object 7 is processed as $80, $E3, $FF, $FF, $FF (womp womp not in range. add 5 for some reason, ha!)
	; object 8 is processed as $00, $E3, $00, $FF
	; If this was aligned, it looks like this: (upwards of 8 in a single scanline)
	; $FF, $00, $E3, $00
	; $00, $E3, $00, $00
	; $00, $E3, $00, $00
	; $00, $E3, $00, $00
	; $00, $E3, $00, $00
	; $00, $E3, $00, $00
	; $00, $E3, $00, $00
	; $00, $E3, $00, $00
	; $80, $E3, $FF, $FF, $FF
	; $00, $E3, $00, $00
	
MisalignedOAM_LUT_Off2:
	; Misaligned +2
	.byte $FF, $FF
	.byte $00, $E3, $10, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $20, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $30, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $40, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $50, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $60, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $70, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $E3, $00, $80 ; Y position is in range of this scanline, X position is not. (OAM++; OAM &= $FC) (That second $00 is now the first byte processed for the next object)
	.byte $00	  			 ; OAM is aligned again.
	; object 8 is processed as $00, $00, $80, $00
	; If this was aligned, it looks like this: (upwards of 8 in a single scanline)
	; $FF, $FF, $00, $E3
	; $10, $00, $00, $E3
	; $20, $00, $00, $E3
	; $30, $00, $00, $E3
	; $40, $00, $00, $E3
	; $50, $00, $00, $E3
	; $60, $00, $00, $E3
	; $00, $00, $80, $00
	; $FF, $FF, $FF, $FF
	
MisalignedOAM_LUT_Off3:
	; Misaligned +3
	.byte $FF, $FF, $FF
	.byte $00, $10, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $20, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $30, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $40, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $50, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $60, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $70, $00, $00 ; X position and Y position are both in range of this scanline.
	.byte $00, $80, $00, $80 ; X position and Y position are both in range of this scanline.
	.byte $FF, $FF, $00
	; object 8 is processed as $80, $00, $80, $FF, $FF
	; object 9 is processed as $00, $FF, $FF, $FF
	; If this was aligned, it looks like this: (upwards of 8 in a single scanline)
	; $FF, $FF, $00, $E3
	; $00, $00, $00, $E3
	; $00, $00, $00, $E3
	; $00, $00, $00, $E3
	; $00, $00, $00, $E3
	; $00, $00, $00, $E3
	; $00, $00, $00, $E3
	; $00, $00, $00, $E3
	; $00, $80, $FF, $FF

FAIL_Address2004_Behavior:
	JSR ClearPage2
	JSR WaitForVBlank
	LDA #2
	STA $4014
	JMP FAIL_Address2004

TEST_Address2004_Behavior:
	;;; Test 1 [Address $2004 behavior]: Writes to $2004 update OAM, and increment the OAM address by 1 ;;;
	JSR DisableRendering
	LDA #0
	STA <dontSetPointer
	JSR PrintCHR	; Put a white square at $2001 on the nametable.
	.word $2001
	.byte $FC, $FF	
	JSR ClearPage2
	JSR ResetScrollAndWaitForVBlank
	LDA #2
	STA $4014 ; run the OAM DMA, overwriting the whole thing with $FF
	LDA #0
	LDY #$FC
	STA $2004	; write $00 to OAM $00
	STY $2004	; write $FC to OAM $01
	STA $2004	; write $00 to OAM $02
	LDA #8
	STA $2004	; write $08 to OAM $03
	; Due to how writing here increments the OAM address, the sprite zero hit won't occur during scanline 1. It will instead occur during scanline 2, but this test is just checking to see if it happens at all.
	JSR EnableRendering
	JSR Clockslide_3000 ; Wait long enough for the sprite zero hit to occur.
	LDA $2002
	AND #$40
	BEQ FAIL_Address2004_Behavior
	INC <currentSubTest
	
	;;; Test 2 [Address $2004 behavior]: Reads from $2004 give you a value in OAM, but do not increment the OAM address ;;;
	JSR ClearPage2
	LDA #$5A			; OAM address $00 will have the value $5A.
	STA $200			;
	LDA #$A5			; and OAM address $01 will have the value $A5.
	STA $201			;
	JSR WaitForVBlank
	LDA #2
	STA $4014 ; run the OAM DMA with page 2.
	LDA $2004
	CMP #$5A
	BNE FAIL_Address2004_Behavior	; You should read the value $5A. (This doesn't use a buffer like reading $2007)
	LDA $2004
	CMP #$5A
	BNE FAIL_Address2004_Behavior	; The OAM Address didn't increment, so the value will still be $5A.
	INC <currentSubTest
	
	;;; Test 3 [Address $2004 behavior]: Reads from the attribute bytes are missing bits 2 through 5 ;;;
	; If OAM is misaligned, it wouldn't be the attribute bytes in that case.
	; Specifically, address n+2, where "n" is a multiple of 4, is missing bits.
	; So, address $02, $06, $0A, $0E, $12, $16... and so on.
	JSR ClearPage2
	JSR WaitForVBlank
	LDA #2
	STA $4014 ; run the OAM DMA with page 2.
	; OAM should be all $FFs, except the attribute addresses, which should be $E3.
	STA $2004 ; INC OAM address to $01
	STA $2004 ; INC OAM address to $02
	LDA $2004
	CMP #$E3
	BNE FAIL_Address2004_Behavior1	; You should read the value $E8
	INC <currentSubTest
	
	;;; Test 4 [Address $2004 behavior]: Reads from $2004 during PPU cycle 1 to 64 of a visible scanline (with rendering enabled) will always read $FF ;;;
	JSR ClearPage2
	LDA #$5A			; OAM address $00 will have the value $5A.
	STA $200			;
	LDA #$A5			; and OAM address $01 will have the value $A5.
	STA $201			;
	JSR WaitForVBlank
	JSR DisableRendering
	LDX #0
	LDA #0
	JSR VblSync_Plus_A
	; Sync to dot 0 of vblank
	LDA #02
	STA $4014
	JSR EnableRendering
	JSR Clockslide_1830
	; we have about 17 PPU cycles until dot 0 of scanline 0
	NOP	; +6 cycles
	NOP	; +6 cycles
	LDA $2004	; +9 cycles before the read.
	CMP #$FF
	BNE FAIL_Address2004_Behavior1	; Despite OAM Address $00 being $5A, the PPU is busy clearing Secondary-OAM to $FF, so this will read $FF.
	INC <currentSubTest
	
	;;; Test 5 [Address $2004 behavior]: Reads from $2004 during PPU cycle 1 to 64 of a visible scanline (with rendering disabled) does a regular read of $2004 ;;;
	JSR WaitForVBlank
	JSR DisableRendering
	LDA #0
	JSR VblSync_Plus_A
	; Sync to dot 0 of vblank
	LDA #02
	STA $4014
	JSR DisableRendering
	JSR Clockslide_1830
	; we have about 17 PPU cycles until dot 0 of scanline 0
	NOP	; +6 cycles
	NOP	; +6 cycles
	LDA $2004	; +9 cycles before the read.
	CMP #$5A
	BNE FAIL_Address2004_Behavior1	; Despite being between cycle 1 and 64 of a visible scanline, since rendering is disabled, it reads $5A.
	INC <currentSubTest
	BNE TEST_Address2004_Behavior_Continue ; brnach alaways around the fail case.
	
FAIL_Address2004_Behavior1:
	JMP FAIL_Address2004

TEST_Address2004_Behavior_Continue:
	;;; Test 6 [Address $2004 behavior]: Writing to $2004 on a visible scanline increments the OAM address by 4 ;;;
	LDA #$8C
	STA $204
	JSR WaitForVBlank
	JSR DisableRendering
	LDA #0
	JSR VblSync_Plus_A
	; Sync to dot 0 of vblank
	LDA #02
	STA $4014
	JSR EnableRendering
	JSR Clockslide_1816
	NOP			;+6
	NOP			;+6
	NOP			;+6
	LDA <$00	;+9	(This was originally a NOP, +6 cycles, but if your $2004 instruction doesn't have a delay of a few PPU cycles, then you would fail this test here, and that's not what this test is testing for.)
	LDA #0		;+6
	STA $2004	;+9 before write (+3 after). write with 20 ppu cycles until dot 0. (the CPU write occurs on dot 321 of the pre-render line)
	STA $2001   ;+9 before write, disable rendering with 8 ppu cycles before dot 0.
	LDA $2004
	CMP #$8C
	BNE FAIL_Address2004_Behavior1	; Despite being between cycle 1 and 64 of a visible scanline, since rendering is disabled, it reads $5A.
	INC <currentSubTest

	;;; Test 7 [Address $2004 behavior]: Writing to $2004 on a visible scanline doesn't write to OAM ;;;
	; leeching off the results of the previous test...
	; PPUOAMAddress is currently 4
	LDX #4
TEST_Address2004_Behavior_Loop:
	STA $2004	; A = $8C, so we're overwriting all of OAM with $8C right now.
	INX
	BNE TEST_Address2004_Behavior_Loop
	; OAM Address is now 0.
	; If writing during rendering wrote a value, this address would be $00. Instead, it should be $5A.
	LDA $2004
	CMP #$5A
	BNE FAIL_Address2004_Behavior1
	INC <currentSubTest

	;;; Test 8 [Address $2004 behavior]: Reads from $2004 during PPU cycle 65 to 256 of a visible scanline (with rendering enabled) reads from the current OAM address, which is changing every other ppu cycle.;;;
	JSR WaitForVBlank
	JSR DisableRendering
TEST_Address2004_Behavior_loop:			; Set up page 2 so every value is essentially the index into OAM
	TXA									; (As mentioned in test 3, the attribute bytes will be missing a few bits, but that's fine.)
	STA $200, X							; We're going to read from OAM in the middle of evaluation to see where the OAM address is.
	INX									;
	BNE TEST_Address2004_Behavior_loop	;
	LDA #0
	JSR VblSync_Plus_A
	; Sync to dot 0 of vblank
	LDA #02
	STA $4014
	JSR EnableRendering
	JSR Clockslide_1830
	; we have about 17 PPU cycles until dot 0 of scanline 0
	; Let's aim for about dot 130. (130 + 17 = 147. 147/3 = 49 CPU cycles. (-3 more since the read happens after 3 more CPU cycles)
	JSR Clockslide_46
	LDA $2004
	BEQ FAIL_Address2004_Behavior1	; It definitely shouldn't be $00.
	CMP #$FF
	BEQ FAIL_Address2004_Behavior1	; Since it's inconsistent between CPU/PPU clock alignments, (and probably different on different consolre revisions) we'll simply just check that it isn't FF.

	;;; Test 9 [Address $2004 behavior]: Reads from $2004 during PPU cycle 256 to 320 of a visible scanline (with rendering enabled) reads $FF again. ;;;
	JSR WaitForVBlank
	JSR DisableRendering

	LDA #0
	JSR VblSync_Plus_A
	; Sync to dot 0 of vblank
	LDA #02
	STA $4014
	JSR EnableRendering
	JSR Clockslide_1830
	; we have about 17 PPU cycles until dot 0 of scanline 0
	; Let's aim for about dot 310. (310 + 17 = 327. 327/3 = 109 CPU cycles. (-3 more since the read happens after 3 more CPU cycles)
	JSR Clockslide_40
	JSR Clockslide_40
	JSR Clockslide_26	; = 106 cycles of clocksliding.
	LDA $2004
	CMP #$FF
	BNE FAIL_Address2004_Behavior2	; This reads $FF. (I'll need to look into why, but I know this is the case.)

	;; END OF TEST ;;
	JSR ClearOverscanNametable
	JSR ClearPage2
	JSR WaitForVBlank
	LDA #2
	STA $4014
	JSR DisableRendering_S
	LDA #1
	RTS
;;;;;;;

	
FAIL_Address2004_Behavior2:
	JMP FAIL_Address2004

FAIL_APURegActivation_Pre:
	LDA #1
	STA <currentSubTest
	JMP TEST_Fail

FAIL_APURegActivation0:
	JMP FAIL_APURegActivation

TEST_APURegActivation:
	;;; Test 1 [APU Register Activation]: Pre-requisite test suite: Does DMA affect the data bus? Is DMC DMA timing accurate? Is open bus accurate enough for this test? How about PPU Open Bus? What about the PPU Read buffer? ;;;
	LDA <result_DMADMASync_PreTest	; This is written before the main menu loads when resetting the ROM. If you aren't passing this test (and using savestates), you'll need to reboot the ROM to update this value.
	CMP #1
	BNE FAIL_APURegActivation_Pre ; Fail if the DMC DMA doesn't update the data bus.
	
	JSR TEST_DMA_Plus_2007R
	CMP #1
	BNE FAIL_APURegActivation_Pre ; Fail if DMC DMA timing is off.
	
	JSR ResetScrollAndWaitForVBlank
	LDY #$10	 ; A copy of Open Bus test 3. If this fails, then open bus isn't reliable enough for this test.
	LDA $50F8, Y ; This offset changes the high byte of the value read, but not the data bus.
	CMP #$50
	BNE FAIL_APURegActivation_Pre ; Fail if open bus is faked.
	
	LDA #$5A
	STA $2002
	LDA #0
	LDA $3000 ; use a mirror to test for mirrors too.
	CMP #$5A
	BNE FAIL_APURegActivation_Pre ; Fail if PPU open bus doesn't exist.

	JSR WriteToPPUADDRWithByte
	.byte $24, $00
	.byte $A5, $FF
	JSR ReadPPUADDRFromWord
	.byte $24, $00
	CMP #$A5
	BNE FAIL_APURegActivation_Pre ; Fail if the PPU read buffer isn't working.

	JSR ResetScrollAndWaitForVBlank
	LDA #02
	STA <currentSubTest
	; It is assumed we're not going to crash when running this test if those 2 pre-requisites pass.

	;;; Test 2 [APU Register Activation]: Pre-requisite test: Reading from $4015 clears the "frame interrupt flag" ;;;
	SEI ; If the frame interrupt flag is set without this, we can get stuck in an infinite loop of BRK instructions.
	LDA #0
	STA $4017	; enable the frame counter Interrupt flag.
	JSR Clockslide_29780 ; wait for the frame interrupt flag.
	JSR Clockslide_100
	LDA $4015
	AND #$40
	BEQ FAIL_APURegActivation0 ; If this fails, the Frame interrupt flag wasn't set? Likely not implemented.
	LDA $4015
	AND #$40
	BNE FAIL_APURegActivation0 ; If this fails, the Frame interrupt flag wasn't cleared when read last time.
	INC <currentSubTest
	
	;;; Test 3 [APU Register Activation]: Can the DMA read from the APU registers when the CPU is not executing out of page $40? ;;;	
	; What's happening here?
	; The 2A03 chip (the CPU/APU) has an address bus.
	; Inside the 2A03 chip are 3 address busses: The 6502 Address Bus, the DMC Address Bus, and the OAM Address bus. On any given cycle, only one of these busses can be chosen to connect to the 2A03 address bus.
	; Here's the catch. Reading from the APU registers requires the 6502 address bus to be in the range of $4000 through $401F.
	; If the OAM address bus is pointing to $4000 through $401F, and the 6502 address bus isn't, then the OAM DMA will only read open bus from that range.
	; Which can be detected, since reading $4015 clears the interrupt flag.
	;
	; This test will write $40 to $4014, running an OAM DMA that will read from address $4000 to $40FF.
	; However, the APU registers are not active! So every value read by the DMA will be open bus.
	
	JSR Clockslide_29780 ; wait for the frame interrupt flag.
	JSR Clockslide_100
	LDA #$40
	STA $4014	; OAM DMA with page $40.
	; This does *NOT* read from the APU Registers!
	LDA $4015
	AND #$40
	BEQ FAIL_APURegActivation0 ; If this fails, the DMA read from the APU registers.
	INC <currentSubTest

	;;; Test 4 [APU Register Activation]: Can your emulator handle the wacky setup required to determine if the APU registers are active due to the 6502 address bus? (this could cause a crash) ;;;
	; Oh- also don't press anything on controller 2 during this test. thanks. :)
	;
	; Okay, so what is this test all about?
	; The APU registers (from $4000 to $4017) are not always accessible.
	; For instance, in the previous test, the APU registers were not active, so that OAM DMA didn't read any of the value there.
	; So "What activates the APU registers?" I hear you asking.
	; These registers are active when the 6502 Address Bus is in the range $4000 through $401F.
	; So if the 6502 address bus was within that range, and a OAM DMA were to occur, then the OAM DMA would be able to read the APU registers.
	;
	; Here's the plan. (Special thanks to lidnariq and Fiskbit)
	; Execute STA $4014 (A = $40) from address $3FFE. (The 6502 address bus will be $4001 when the OAM DMA occurs. Follow that up with a BRK from address $4001.)
	; In order to make this work, we need the PPU data bus to be $8D, the PPU Buffer to be $14, and Open Bus to be $40
	; So, the order of operations here is: 
	; Prepare PPU buffer with $14. (some writes to $2006, a write to $2007, more writes to $2006, and a read from $2007)
	; Perpare PPU data bus with $8D. Write $8D to $2002.
	; Now, when we execute this:
	; [$3FFE = $8D] [$3FFF = $14] [DMC DMA! Overwrite databus with $40] [$4000 = $40] [OAM DMA!]
	; Which will result in an OAM DMA where the 6502 Databus is in-fact from the range $4000 to $401F, so the OAM DMA *will* read from all the registers.
	; And then the final value of the databus will be $00, so the following instruction will be BRK.
	;
	; We'll also want to set up one of the audio channels to be playing, so the results are slightly more interesting. (so APU STATUS has a value other than $00) How about the triangle channel?
	;
	; Okay, but what's actually happening during the DMA? 
	;
	; The only registers at play here are $4015, $4016, and $4017, since those are the only readable APU registers.
	; However, since the APU registers are active (the 6502 address bus is within $4000 through $401F) the OAM DMA can read from the APU registers.
	; Surprisingly, these registers have mirrors every $20 bytes. They just aren't normally accessible, as the 6502 address bus would typically be out of the $4000 through $401F range when trying to read these mirrors.
	; However, with the APU registers active, the OAM DMA will be able to read from the APU registers and their mirrors.
	; Here's the values that are expected to be put in OAM by this DMA.
	;
	;      00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F
	;    ┌─────────────────────────────────────────────────┐
	; 00 │ 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 │ ; The value of $40 is left over from the data bus.
	; 10 │ 40 40 40 40 40 44 41 40 40 40 40 40 40 40 40 40 │ ; The $40's are the left over data bus. The value of $44 is the frame interrupt flag + the triangle channel from reading address $4015 (APU Status).
	; 20 │ 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 40 │ ; Referring to the above line, the $41 is open bus + reading controller 1, and $40 is open bus + controller 2. (this line is just open bus)
	; 30 │ 40 40 40 40 40 04 01 00 00 00 00 00 00 00 00 00 │ ; This time, the frame interrupt flag is cleared, which clears bit 4 of open bus in future reads. The $01 is just controller 1. Controller 2 is still $00.
	; 40 │ 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 │ ; All zeroes. Just open bus.
	; 50 │ 00 00 00 00 00 04 01 00 00 00 00 00 00 00 00 00 │ ; Just the triangle playing with APU STATUS, and controller 1 being $01, which will never change. Controller 2 is still $00, and will never change.
	; 60 │ 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 │
	; 70 │ 00 00 00 00 00 04 01 00 00 00 00 00 00 00 00 00 │ ; Actually a correction about controller 2. If your DMA somehow reads the controller port extra times, this will eventually be $01, as will every open bus byte following it.
	; 80 │ 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 │ ; If that does occur, you likely won't execute a BRK instruction on address $4001. It would likely be ORA <$01, X, which I could use to manipulate the databus into an RTS!
	; 90 │ 00 00 00 00 00 04 01 00 00 00 00 00 00 00 00 00 │
	; A0 │ 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 │
	; B0 │ 00 00 00 00 00 04 01 00 00 00 00 00 00 00 00 00 │
	; C0 │ 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 │
	; D0 │ 00 00 00 00 00 04 01 00 00 00 00 00 00 00 00 00 │
	; E0 │ 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 │
	; F0 │ 00 00 00 00 00 04 01 00 00 00 00 00 00 00 00 00 │
	;    └─────────────────────────────────────────────────┘

	; Step 1: Set up the IRQ function
	LDA #$68	;PLA
	STA $600	; - PLA (Flags from BRK)
	STA $601	; - PLA (Return address Low)
	STA $602	; - PLA (Return Address High)
	LDA #$A9	; LDA #Immediate
	STA $603	; - LDA
	STA $604	; - #$A9
	LDA #$60	;RTS
	STA $605	; - RTS (to the JSR inside this test.)
	; Step 2: Begin playing the triangle channel. (so APU Status isn't $00)
	LDA #4
	STA $4015	; enable the triangle channel
	LDA #$F0
	STA $400B
	LDA #$FF
	STA $4008
	; Step 3: strobe controllers and read controller 1 eight times.
	JSR ReadController1
	; Controller 2 was also strobed, but never read.
	; Step 4: Put $14 in the PPU read buffer.
	JSR WaitForVBlank
	JSR DisableRendering
	JSR WriteToPPUADDRWithByte
	.byte $24, $00
	.byte $14, $FF
	JSR SetPPUADDRFromWord
	.byte $24, $00
	LDA $2007 ; Prep the buffer with the value of $14 written to PPU $2400
	JSR ResetScroll
	; Step 5: Put $8D in the PPU data bus.
	LDA #$8D
	STA $2002
	; Step 6: Try and prevent a crash with incorrect results of the test.
	LDX #0 	 ; If (instead of BRK) you run: ORA <$01, X...
	LDA #$60 ; This value of $60 will be put on the databus. an RTS instruction!
	STA <$01 ; And since the BRK jumps to a function laoding the value of A with $A9, we can check for this after the test.
	
	; Step 7: Schedule a DMA
	LDA #$40
	JSR DMASyncWith40
	; We have 50 CPU cycles until the DMA occurs.
	; JSR takes 6 cycles, we want the DMA to occur 3 cycles after that. We need to stall for 41 CPU cycles
	JSR Clockslide_41	; This takes 41 CPU cycles
	JSR $3FFE	; Jump to $3FFE, as explained above.
	; Making it back here is honestly an accomplishment. This should not crash, but I can't really prepare for incorrect emulation any more than I did in the above tests.
	; If the wrong value remains on the data bus, then there's not much I can do about that. Hope you execute a BRK?
	; And hey, if you didn't, I sure hope you executed an RTS. Speaking of, let's check for that magic number set by the LDA inside the BRK routine.
	CMP #$A9
	BNE FAIL_APURegActivation
	INC <currentSubTest
	
	;;; Test 5 [APU Register Activation]: The DMA can read from the APU registers when the CPU is executing out of page $40? ;;;
	; Step 1: copy OAM to page 2.
	LDX #0
TEST_APURegActivation_Test5Loop:
	LDA $2004
	STA $2004 ; increment OAM Address.
	STA $500,X
	INX
	BNE TEST_APURegActivation_Test5Loop
	; Instead of making a 256 byte large look up table, I'm going to check each row individually. The result should match that table printed out above in the Test 4 description.
	; X already equals zero.
TEST_APURegActivation_Eval_0:		;
	LDA $500,X						; Read the value copied from OAM
	CMP #$40						; This row should be all $40's
	BNE FAIL_APURegActivation		; If it's not $40, you fail
	INX								; If it IS $40, check the next one.
	CPX #$15						; Loop this through address $214
	BNE TEST_APURegActivation_Eval_0;
	LDA $500,X						; Read the value copied from OAM at $215
	CMP #$44						; This should be 44
	BNE FAIL_APURegActivation		; If it's not $44, you fail
	INX								; Increment X for the next one.
	LDA $500,X						; Read the value copied from OAM at $216
	CMP #$41						; This should be 41
	BNE FAIL_APURegActivation		; If it's not $41, you fail
	INX								; Increment X for the next one.
TEST_APURegActivation_Eval_1:		;
	LDA $500,X						; Read the value copied from OAM
	CMP #$40						; This row should be all $40's
	BNE FAIL_APURegActivation		; If it's not $40, you fail
	INX								; If it IS $40, check the next one.
	CPX #$35						; Loop this through address $234
	BNE TEST_APURegActivation_Eval_1;
	; From here on out, it's a pattern of $04, $01, and $00 repeated $1E times
	LDY #0
TEST_APURegActivation_Eval_2:
	CPY #2
	BPL TEST_APURegActivation_Skip0401
	LDA $500,X						; Read the value copied from OAM at $2_5
	CMP #$04						; This should be 04
	BNE FAIL_APURegActivation		; If it's not $04, you fail
	INX								; Increment X for the next one.
	LDA $500,X						; Read the value copied from OAM at $2_6
	CMP #$01						; This should be 01
	BNE FAIL_APURegActivation		; If it's not $01, you fail
	INX								; Increment X for the next one.	
	LDY #02							; It probably should have been INY's for neat-ness, but this saves 2 CPU cycles.
TEST_APURegActivation_Skip0401:
	LDA $500,X						; Read the value copied from OAM
	CMP #$00						; This should be 00
	BNE FAIL_APURegActivation		; If it's not $00, you fail
	INY								; Increment Y for the next one.
	CPY #$20
	BNE TEST_APURegActivation_SkipResetY	; if Y=20, reset to 0, so we can check for the "$04 $01"
	LDY #0
TEST_APURegActivation_SkipResetY:
	INX								; Increment X for the next one.	
	BNE TEST_APURegActivation_Eval_2
	; Bravo!
	INC <currentSubTest
	BNE TEST_APURegActivation_Continue

FAIL_APURegActivation:
	LDA #$40
	STA $4017
	LDA #0
	STA $4015
	JMP TEST_Fail
;;;;;;;;;;;;;;;;;
		
TEST_APURegActivation_Continue:
	;;; Test 6 [APU Register Activation]: If the APU registers are active, there will be bus conflicts if the OAM DMA is reading from outside of open bus. ;;;
	; The setup here is incredibly similar, exept the OAM DMA will occur on page 2 instead, after clearing page 2 to all FFs.
	; Also we're going to write a value of $00 to $2FF to populate the data bus with $00 before the OAM ends.
	;
	; Here's how OAM should end up after this test:
	;
	;      00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F
	;    ┌─────────────────────────────────────────────────┐
	; 00 │ FF FF E3 FF FF FF E3 FF FF FF E3 FF FF FF E3 FF │ ; The value of $FF is because we cleared page 2 with a bunch of FFs. (and the $E3 is the attribute bytes)
	; 10 │ FF FF E3 FF FF 24 E3 FF FF FF E3 FF FF FF E3 FF │ ; The value of $24 is the triangle channel from reading address $4015, + bit 5 is set from the byte on page 2.
	; 20 │ FF FF E3 FF FF FF E3 FF FF FF E3 FF FF FF E3 FF │ ; Amusingly, it does not appear to have read the controllers, despite the reads from APU_STATUS.
	; 30 │ FF FF E3 FF FF 24 E3 FF FF FF E3 FF FF FF E3 FF │
	; 40 │ FF FF E3 FF FF FF E3 FF FF FF E3 FF FF FF E3 FF │
	; 50 │ FF FF E3 FF FF 24 E3 FF FF FF E3 FF FF FF E3 FF │
	; 60 │ FF FF E3 FF FF FF E3 FF FF FF E3 FF FF FF E3 FF │
	; 70 │ FF FF E3 FF FF 24 E3 FF FF FF E3 FF FF FF E3 FF │
	; 80 │ 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 │ ; I made the second half of page 2 all zeroes.
	; 90 │ 00 00 00 00 00 04 00 00 00 00 00 00 00 00 00 00 │
	; A0 │ 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 │
	; B0 │ 00 00 00 00 00 04 00 00 00 00 00 00 00 00 00 00 │
	; C0 │ 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 │
	; D0 │ 00 00 00 00 00 04 00 00 00 00 00 00 00 00 00 00 │
	; E0 │ 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 │
	; F0 │ 00 00 00 00 00 04 00 00 00 00 00 00 00 00 00 00 │ 
	;    └─────────────────────────────────────────────────┘
	;
	; Most amusingly, it looks like $4015 is read, but $4016 and $4017 aren't visible in this chart. (But don't let that fool you, as the controllers are still getting clocked)
	
	JSR ClearPage2
	LDX #$80
	LDA #0
TEST_APURegActivation_Prep6Loop:
	STA $200, X
	INX 
	BNE TEST_APURegActivation_Prep6Loop
	LDA #$40
	STA $4017
	
	; Run the same setup as the above test.
	LDA #4
	STA $4015	; enable the triangle channel
	LDA #$F0
	STA $400B
	LDA #$FF
	STA $4008
	; strobe controllers.
	LDA #1
	STA $4016
	LSR A
	STA $4016
	; Put $14 in the PPU read buffer.
	JSR WaitForVBlank
	JSR DisableRendering
	JSR WriteToPPUADDRWithByte
	.byte $24, $00
	.byte $14, $FF
	JSR SetPPUADDRFromWord
	.byte $24, $00
	LDA $2007 ; Prep the buffer with the value of $14 written to PPU $2400
	JSR ResetScroll
	; Put $8D in the PPU data bus.
	LDA #$8D
	STA $2002	
	; Schedule a DMA
	LDA #$02
	JSR DMASyncWith40
	; We have 50 CPU cycles until the DMA occurs.
	; JSR takes 6 cycles, we want the DMA to occur 3 cycles after that. We need to stall for 41 CPU cycles
	JSR Clockslide_41	; This takes 41 CPU cycles
	JSR $3FFE	; Jump to $3FFE, as explained above.
	;;;;;; A real big loop to read compare the values in OAM with the desired results.
	LDX #0
TEST_APURegActivation_Test6Loop:
	LDA $2004
	STA $2004 ; increment OAM Address.
	STA $500,X
	INX
	BNE TEST_APURegActivation_Test6Loop	
	
	LDY #$0B	; Y loops back to $00 in $15 bytes
TEST_APURegActivation_Eval_3:
	CPY #2
	BPL TEST_APURegActivation_Skip0601
	LDA $500,X						; Read the value copied from OAM at $2_5
	CMP #$24						; This should be 24
	BNE FAIL_APURegActivation		; If it's not $24, you fail
	INX								; Increment X for the next one.
	LDA $500,X						; Read the value copied from OAM at $2_6
	CMP #$E3						; This should be E3
	BNE FAIL_APURegActivation2		; If it's not $E3, you fail
	INX								; Increment X for the next one.	
	LDA $500,X						; Read the value copied from OAM at $2_7
	CMP #$FF						; This should be FF
	BNE FAIL_APURegActivation2		; If it's not $FF, you fail
	INX								; Increment X for the next one.	
	LDY #03							; It probably should have been INY's for neat-ness, but this saves 2 CPU cycles.
TEST_APURegActivation_Skip0601:
	LDA $500,X						; Read the value copied from OAM
	PHA
	TXA
	AND #3
	CMP #02
	BNE TEST_APURegActivation_CheckForFFInsteadOfE7
	PLA
	CMP #$E3
	BNE FAIL_APURegActivation2
	BEQ TEST_APURegActivation_EvalCont
TEST_APURegActivation_CheckForFFInsteadOfE7:
	PLA
	CMP #$FF
	BNE FAIL_APURegActivation2		; If it's not $FF, you fail
TEST_APURegActivation_EvalCont:
	INY								; Increment Y for the next one.
	CPY #$20
	BNE TEST_APURegActivation_YSkip2	; if Y=20, reset to 0, so we can check for the "$04 $01"
	LDY #0
TEST_APURegActivation_YSkip2:
	INX								; Increment X for the next one.	
	CPX #$80
	BNE TEST_APURegActivation_Eval_3
TEST_APURegActivation_Eval_4:
	CPY #2
	BPL TEST_APURegActivation_Skip0602
	LDA $500,X						; Read the value copied from OAM at $2_5
	CMP #$04						; This should be 04
	BNE FAIL_APURegActivation2		; If it's not $04, you fail
	INX								; Increment X for the next one.
	LDA $500,X						; Read the value copied from OAM at $2_6
	BNE FAIL_APURegActivation2		; If it's not $00, you fail
	INX								; Increment X for the next one.	
	LDA $500,X						; Read the value copied from OAM at $2_7
	BNE FAIL_APURegActivation2		; If it's not $00, you fail
	INX								; Increment X for the next one.	
	LDY #03							; It probably should have been INY's for neat-ness, but this saves 2 CPU cycles.
TEST_APURegActivation_Skip0602:
	LDA $200,X						; Read the value copied from OAM
	BNE FAIL_APURegActivation2		; If it's not $00, you fail
	INY								; Increment Y for the next one.
	CPY #$20
	BNE TEST_APURegActivation_YSkip3	; if Y=20, reset to 0, so we can check for the "$04 $01"
	LDY #0
TEST_APURegActivation_YSkip3:
	INX								; Increment X for the next one.	
	BNE TEST_APURegActivation_Eval_4
	INC <currentSubTest
	
	;;; Test 6 [APU Register Activation]: The controller ports might not have been visible by the OAM DMA, but did the controller ports get clocked? ;;;

	LDA $4016
	LDA $4016	; it is assumed the B button is not pressed during the test.
	LSR A
	BCC FAIL_APURegActivation2	; Bingo! Look at that. The controller ports *were* clocked, but did not appear in OAM!
	; Most amusing.
		
	;; END OF TEST ;;
	LDA #0
	STA $4015
	LDA #1
	RTS
;;;;;;;

FAIL_APURegActivation2:
FAIL_DMA_Timing:
	LDA #$40
	STA $4017
	LDA #0
	STA $4015
	JMP TEST_Fail
;;;;;;;;;;;;;;;;;

TEST_DMA_Plus_4015R:
	;;; Test 1 [DMA + $4015 Read]: Does the frame interrupt flag ever get set? ;;;
	SEI
	LDA #$00
	STA $4017
	JSR Clockslide_29780
	JSR Clockslide_100
	BIT $4015	; If the frame interrupt flag is set, bit 6 will be set. (set the overflow flag)
	BVC FAIL_DMA_Timing
	INC <currentSubTest

	;;; Test 2 [DMA + $4015 Read]: Does the DMA happen at the right time? ;;;
	JSR DMASync_50CyclesRemaining
	LDA #$4F			;2
	STA $4010			;4
	LDA #$00			;2
	STA $4017			;4
	JSR Clockslide_29780;29780
	JSR Clockslide_200	;100

	; so far, we've ran 29892 cycles since leaving our "DMA Sync in 50 CPU cycles." subroutine.
	; Luckily, I set the DMA to loop every 432 CPU cycles.
	JSR Clockslide_16
	BIT $4015	; If the frame interrupt flag is set, bit 6 will be set. (set the overflow flag) However, we time this DMA to also read this address, clearing the bit. (the overflow flag should be cleared after this BIT instruction)
	BVS FAIL_DMA_Timing	
	
	;; END OF TEST ;;
	LDA #$40
	STA $4017
	LDA #1
	RTS
;;;;;;;

	.bank 2	; If I don't do this, the ROM won't compile.
	.org $C000
	
	; and 33 00s in a row for a nice and neat silent DPCM sample.
	.byte $00,  $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

TEST_DMA_Plus_4016R:
	;;; Test 1 [DMA + $4016 Read]: Does the DMA Update the read-sensitive controller port? (also doubles as a test for DMA timing) ;;;
	
	JSR DMASync_50CyclesRemaining
	JSR Clockslide_35
	LDA #1		; -2 = 48
	STA $4016	; -4 = 44
	LDA #0		; -2 = 42
	STA $4016	; -4 = 38
	LDA $4016 	; -3 = 35
	LSR A
	ROL <$50
	LDX #7	; read from the controller port 7 more times.
TEST_DMA_Plus_4016R_Loop:
	LDA $4016
	LSR A
	ROL <$50
	DEX
	BNE TEST_DMA_Plus_4016R_Loop
	; read the controller again for a "control group" (the player might still be holding A, or for some other reason, other buttons.
	JSR ReadController1
	LDA <controller
	ASL A
	STA <$51
	ORA #1
	CMP <$50
	BNE DMA_Plus_4016R_TryFamicomControllerBehavior

	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;
DMA_Plus_4016R_TryFamicomControllerBehavior:
	LDA <$51
	ORA #7
	CMP <$50
	BNE FAIL_DMA_Plus_4016R
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

FAIL_DMA_Plus_4016R:
FAIL_ControllerStrobing:
	JMP TEST_Fail
	
TEST_ControllerStrobing:
	;;; Test 1 [Controller Strobing] The controller is only strobed if the value written to $4016 has a 1 in bit 0.
	; This test only works if controller 1 is pressing either no buttons, or only A.
		
	LDA #2
	STA $4016	; does not strobe the controller.
	LDA #0
	STA $4016
	JSR ReadControllerInto50_and_A
	AND #$7F
	CMP #$7F
	BNE FAIL_ControllerStrobing
	INC <currentSubTest
	
	;;; Test 2 [Controller Strobing] The controller is only strobed if the value written to $4016 has a 1 in bit 0. (continued)
	LDA #3
	STA $4016 ; does strobe the controller.
	LDA #0
	STA $4016
	JSR ReadControllerInto50_and_A
	AND #$7F
	BNE FAIL_ControllerStrobing	; the result should be $00
	INC <currentSubTest

	;;; Test 3 [Controller Strobing]: Do controller strobes only happen when the CPU transitions from a get cycle to a put cycle? ;;;
	; This test will run DEC $4016
	; cycle 1: read the opcode
	; cycle 2: read the operand (low byte)
	; cycle 3: read the operand (high byte)
	; cycle 4: read from address $4016 ($41)
	; cycle 5: write ($41) to $4016, then DEC to ($40)
	; cycle 6: write ($40) to $4016
	;
	; This results in a 1-cycle strobe of the controller ports, and if that 1-cycle strobe happens on a get cycle, the controllers actually aren't strobed at all!
	JSR WaitForVBlank
	LDA #2
	STA $4014 ; sync CPU with even cycle.
	DEC $4016 ; this should strobe the controller.
	JSR ReadControllerInto50_and_A
	AND #$7F
	BNE FAIL_ControllerStrobing	; the result should be $00
	INC <currentSubTest

	;;; Test 4 [Controller Strobing]: Do controller strobes only happen when the CPU transitions from a get cycle to a put cycle? (continued) ;;;
	; This results in a 1-cycle strobe of the controller ports, however they actually aren't strobed at all!
	JSR WaitForVBlank
	LDA #2
	STA $4014 ; sync CPU with even cycle.
	LDA <$00	; 3 CPU cycles.
	DEC $4016 ; this should strobe the controller.
	JSR ReadControllerInto50_and_A
	AND #$7F
	CMP #$7F
	BNE FAIL_ControllerStrobing	; the result should be $00
	
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;



FAIL_InstructionTiming:
	JMP TEST_Fail

TEST_InstructionTiming_EvenOverhead:
	LDA <$64	; Copy the high byte of the results
	STA <$62	; Paste to the high byte of the odd overhead
	LDA <$65	; Copy the low byte of the results
	STA <$63	; Paste to the low byte of the odd overhead.
	RTS
;;;;;;;
TEST_InstructionTiming_OddOverhead:
	LDA <$66	; Copy the high byte of the results
	STA <$62	; Paste to the high byte of the odd overhead
	LDA <$67	; Copy the low byte of the results
	STA <$63	; Paste to the low byte of the odd overhead.
	RTS
;;;;;;;

TEST_InstructionTiming:
	;;; Test 1 [Instruction Timing]: Is the NMI Timing Reliable enough for this test? ;;;
	; How this test works:
	; The test will begin exactly 1000 CPU cycles before the NMI occurs.
	; The results can be found in a 16-bit value (little endian) at address $0060
	; The result there is the total number of CPU cycles the test spent before jumping to JSR $500
	;
	; The actual way this works is:
	; Address $500 through $6FE are filled with NOP instructions.
	; The NMI will occur somewhere while executing all of those NOPs, and it will push the return address to the stack.
	; By waiting one more frame, we can determine if we were on cycle 1 or 2 of a NOP instruction when the NMI occured, giving us precisely the number of CPU cycles that occured in this test.
	; Then some math happens, storing the result in $60
	;
	; Now, we would really like to run this test even if your NMI timing is bad.
	; So let's run a "callibration test"
	JSR SyncTo1000CyclesUntilNMI
	JSR $500	; wait for NMI, which records the return address, then jumps to ConvertReturnAddressIntoCPUCycles
	; The results stored in $60 and $61 *should* be zero, but some emulators might fail this, due to incorrect NMI timing. (Or perhaps, due to CPU/PPU alignment, the timing could be off)
	; Basically, we take this value (which should be zero) and use that as the "overhead" in future tests.
	; So if the value was 04, indicating that the NMI happened 4 cycles later than expected, we subtract 4 from all of the future tests.
	LDA <$60	; Copy the high byte of the results
	STA <$64	; Paste to the high byte of the even overhead
	LDA <$61	; Copy the low byte of the results
	STA <$65	; Paste to the low byte of the even overhead.
	; Let's also calibrate for an odd number of cycles. In this case, 3.
	; Set the overhead to 3.
	LDA #3
	STA <$63
	JSR SyncTo1000CyclesUntilNMI
	LDA <$00	; take 3 cycles
	JSR $500	; wait for NMI, which records the return address, then jumps to ConvertReturnAddressIntoCPUCycles
	; and store the overhead.
	LDA <$60	; Copy the high byte of the results
	STA <$66	; Paste to the high byte of the odd overhead
	LDA <$61	; Copy the low byte of the results
	STA <$67	; Paste to the low byte of the odd overhead.
	; Now that we have calculated the overheads, let's run a real test.
	JSR TEST_InstructionTiming_EvenOverhead
	
	JSR SyncTo1000CyclesUntilNMI
	JSR $500	
	LDA <$60
	BNE FAIL_InstructionTiming ; this should be zero.
	LDA <$61
	BNE FAIL_InstructionTiming ; this should also be zero.
	; Test 1 continued:
	JSR SyncTo1000CyclesUntilNMI
	JSR Clockslide_500	; wait exactly 500 CPU cycles.
	JSR $500	; wait for NMI, which records the return address, then jumps to ConvertReturnAddressIntoCPUCycles
	; Decimal 500 = $1F4
	LDA <$60
	CMP #$01
	BNE FAIL_InstructionTiming ; this should be $01.
	LDA <$61
	CMP #$F4
	BNE FAIL_InstructionTiming ; this should be $F4.
	; Alright, I think this emulator has reliable enough NMI timing for this.
	; Granted, if any of the instructions needed to sync this up perfectly was failing, then this likely wouldn't even get this far.
	; Oh well? Let's check how long some instructions take!
	INC <currentSubTest
	
	;;; Test 2 [Instruction Timing]: Does LDA #Immediate take 2 cycles? ;;;
	JSR TEST_InstructionTiming_EvenOverhead
	JSR SyncTo1000CyclesUntilNMI
	LDA #$5A ; this takes 2 cycles.
	JSR $500 ; run timing test.
	LDA #02 
	CMP <$61
	BNE FAIL_InstructionTiming ; this should be $02.
	INC <currentSubTest

	;;; Test 3 [Instruction Timing]: Does LDA <ZeroPage take 3 cycles? ;;;
	JSR TEST_InstructionTiming_OddOverhead
	JSR SyncTo1000CyclesUntilNMI
	LDA <$00 ; this takes 3 cycles.
	JSR $500 ; run timing test.
	LDA #03 
	CMP <$61
	BNE FAIL_InstructionTiming1 ; this should be $03.
	INC <currentSubTest
	
	;;; Test 4 [Instruction Timing]: Does LDA Absolute take 4 cycles? ;;;
	JSR TEST_InstructionTiming_EvenOverhead
	JSR SyncTo1000CyclesUntilNMI
	LDA $0000 ; this takes 4 cycles.
	JSR $500 ; run timing test.
	LDA #04 
	CMP <$61
	BNE FAIL_InstructionTiming1 ; this should be $04.
	INC <currentSubTest
	
	;;; Test 5 [Instruction Timing]: Does LDA Absolute, X take 4 cycles if a page boundary is NOT crossed? ;;;
	JSR SyncTo1000CyclesUntilNMI
	LDX #02	  ; This take 2 cycles
	LDA $0000, X ; this takes 4 cycles.
	JSR $500 ; run timing test.
	LDA #06 
	CMP <$61
	BNE FAIL_InstructionTiming1 ; this should be $06.(I also had to set X)
	INC <currentSubTest
	
	;;; Test 6 [Instruction Timing]: Does LDA Absolute, X take 5 cycles if a page boundary IS crossed? ;;;
	JSR TEST_InstructionTiming_OddOverhead
	JSR SyncTo1000CyclesUntilNMI
	LDX #02	  ; This take 2 cycles
	LDA $00FF, X ; this takes 5 cycles.
	JSR $500 ; run timing test.
	LDA #07 
	CMP <$61
	BNE FAIL_InstructionTiming1 ; this should be $06.(I also had to set X)
	INC <currentSubTest
	
	;;; Test 7 [Instruction Timing]: Does LDA (indirect),Y take 5 cycles if a page boundary is NOT crossed? ;;;
	LDA #0
	STA <Test_UnOp_IndirectPointerLo
	STA <Test_UnOp_IndirectPointerHi
	JSR SyncTo1000CyclesUntilNMI
	LDY #02	  ; This take 2 cycles
	LDA [Test_UnOp_IndirectPointerLo],Y ; this takes 5 cycles.
	JSR $500 ; run timing test.
	LDA #07 
	CMP <$61
	BNE FAIL_InstructionTiming1 ; this should be $07.(I also had to set Y)
	INC <currentSubTest

	;;; Test 8 [Instruction Timing]: Does LDA (indirect),Y take 6 cycles if a page boundary IS crossed? ;;;
	JSR TEST_InstructionTiming_EvenOverhead
	LDA #$FF
	STA <Test_UnOp_IndirectPointerLo
	STA <Test_UnOp_IndirectPointerHi
	JSR SyncTo1000CyclesUntilNMI
	LDY #02	  ; This take 2 cycles
	LDA [Test_UnOp_IndirectPointerLo],Y ; this takes 6 cycles.
	JSR $500 ; run timing test.
	LDA #08
	CMP <$61
	BNE FAIL_InstructionTiming1 ; this should be $08.(I also had to set Y)
	INC <currentSubTest
	
	;;; Test 9 [Instruction Timing]: Does JMP take 3 cycles? ;;;
	JSR TEST_InstructionTiming_OddOverhead
	JSR SyncTo1000CyclesUntilNMI
	JMP TEST_InstructionTimingContinue
	; I thought it was clever to jump around the fail condition while testing how long a JMP instruction takes.
	
FAIL_InstructionTiming1:
	JMP TEST_Fail

TEST_InstructionTimingContinue:
	JSR $500 ; run timing test.
	LDA #03 
	CMP <$61
	BNE FAIL_InstructionTiming1 ; this should be $03.(I also had to set X)
	INC <currentSubTest

	;;; Test A [Instruction Timing]: Does LDA (indirect,X) take 6 cycles? ;;;
	JSR TEST_InstructionTiming_EvenOverhead
	LDA #$FF
	JSR SyncTo1000CyclesUntilNMI
	LDX #$FF	  ; This take 2 cycles
	LDA [Test_UnOp_IndirectPointerLo,X] ; this takes 6 cycles.
	JSR $500 ; run timing test.
	LDA #08
	CMP <$61
	BNE FAIL_InstructionTiming1 ; this should be $08.(I also had to set X)
	INC <currentSubTest

	;;; Test B [Instruction Timing]: Do these implied/accumulator instructions each take 2 cycles?  ;;;
	; I guess in theory, you could have an emulator that for some reason makes one of these take 3 cycles, and another take 1 and it would all add up, but that would be dumb.
	; In any case, if you are failing this one, apologies for not narrowing down exactly which one is failing.
	; This test takes a long time to run due to all the syncing with vblank, and I'd like to keep the run duration down.
	JSR SyncTo1000CyclesUntilNMI
	ASL A
	ROL A
	LSR A
	ROR A
	TSX
	TXS
	TAX
	TXA
	TAY
	TYA
	DEX
	INX
	DEY
	INY
	NOP
	JSR $500 ; run timing test.
	LDA #30 
	CMP <$61
	BNE FAIL_InstructionTiming1 ; this should be 30.
	INC <currentSubTest
	
	;;; Test C [Instruction Timing]: Does JSR take 6 cycles?  ;;;
	JSR SyncTo1000CyclesUntilNMI
	JSR TEST_InstructionTimingJSR
TEST_InstructionTimingJSR:
	JSR $500 ; run timing test.
	PLA	; fix the stack
	PLA	; fix the stack
	LDA #$06 
	CMP <$61
	BNE FAIL_InstructionTiming1 ; this should be $06.
	INC <currentSubTest
	
	;;; Test D [Instruction Timing]: Does RTS take 6 cycles?  ;;;
	LDA #LOW(TEST_InstructionTimingRTS)
	SEC
	SBC #1
	LDA #HIGH(TEST_InstructionTimingRTS)
	SBC #0
	PHA
	LDA #LOW(TEST_InstructionTimingRTS)
	SEC
	SBC #1
	PHA
	JSR SyncTo1000CyclesUntilNMI
	RTS
TEST_InstructionTimingRTS:
	JSR $500 ; run timing test.
	PLA	; fix the stack
	PLA	; fix the stack
	LDA #$06 
	CMP <$61
	BNE FAIL_InstructionTiming1 ; this should be $06.
	INC <currentSubTest

	;;; Test E [Instruction Timing]: Does PHA take 3 cycles? ;;;
	JSR TEST_InstructionTiming_OddOverhead
	JSR SyncTo1000CyclesUntilNMI
	PHA
	JSR $500 ; run timing test.
	PLA
	LDA #03 
	CMP <$61
	BNE FAIL_InstructionTiming2 ; this should be $03.
	INC <currentSubTest
	
	;;; Test F [Instruction Timing]: Does PLA take 4 cycles? ;;;
	JSR TEST_InstructionTiming_EvenOverhead
	PHA
	JSR SyncTo1000CyclesUntilNMI
	PLA
	JSR $500 ; run timing test.
	LDA #04 
	CMP <$61
	BNE FAIL_InstructionTiming2 ; this should be $04.
	INC <currentSubTest

	;;; Test G [Instruction Timing]: Does PHP take 3 cycles? ;;;
	JSR TEST_InstructionTiming_OddOverhead
	JSR SyncTo1000CyclesUntilNMI
	PHP
	JSR $500 ; run timing test.
	PLA
	LDA #03 
	CMP <$61
	BNE FAIL_InstructionTiming2 ; this should be $03.
	INC <currentSubTest
	
	;;; Test H [Instruction Timing]: Does PLP take 4 cycles? ;;;
	JSR TEST_InstructionTiming_EvenOverhead
	PHP
	JSR SyncTo1000CyclesUntilNMI
	PLP
	JSR $500 ; run timing test.
	LDA #04 
	CMP <$61
	BNE FAIL_InstructionTiming2 ; this should be $04.
	;TODO Add more instructions?

	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

FAIL_InstructionTiming2:
	JMP TEST_Fail
;;;;;;;;;;;;;;;;;

TEST_IFlagLatency_IRQ:
	STX <$50
	LDA #0	
	STA $4010	; disable the DMA IRQ
	RTI
;;;;;;;

TEST_IFlagLatency_IRQ2:
	INY
	STY <$51
	BEQ TEST_IFlagLatency_IRQ2_DontAcknowledgeIRQ
	STX <$50
	LDA #0	
	STX $4010	; disable the DMA IRQ
TEST_IFlagLatency_IRQ2_DontAcknowledgeIRQ:
	RTI
;;;;;;;

TEST_IFlagLatency_StartTest:
	SEI
	LDA #0
	LDY #$FF
	STA <$50
	STA <$51
	JSR DMASync_50CyclesRemaining
	LDX #0		; +2
	LDA #$8F	; +2
	STA $4010	; +4 (enable the DMA IRQ)
	JSR Clockslide_34 ; +34
	RTS			; +6
;;;;;;;

TEST_IFlagLatency_StartTest_10ExtraCycles:
	SEI
	LDA #0
	LDY #$FF
	STA <$50
	STA <$51
	JSR DMASync_50CyclesRemaining
	LDX #0		; +2
	LDA #$8F	; +2
	STA $4010	; +4 (enable the DMA IRQ)
	JSR Clockslide_24 ; +24
	RTS			; +6
;;;;;;;

TEST_IFlagLatency_IRQPrep:
	LDA #$4C
	STA $600
	LDA #LOW(TEST_IFlagLatency_IRQ)
	STA $601
	LDA #HIGH(TEST_IFlagLatency_IRQ)
	STA $602
	RTS
;;;;;;;

FAIL_IFlagLatency1:
	SEI
	JMP TEST_Fail

TEST_IFlagLatency:
	; How this works.
	; The IRQ occurs when the CPU polls for interrupts, the "IRQ Level Detector" is low, and the I flag of the CPU is not set.
	; As an emulator dev, this poses 2 questions. What sets the IRQ Level Detector low, and when does the CPU poll for interrupts?
	; In an NROM cartridge, there are 2 ways the IRQ Level Detector is set low:
	;	- If the DMC DMA's IRQ flag is set and the final byte of a DMC sample finishes playing. (this is the method used for this test)
	;	- If the APU's frame counter IRQ is enabled, and the frame counter reaches the end of its sequence in mode 0.
	; If the level detector is left low, an IRQ will happen again if the I flag is disabled. (The interrupt sets the I flag. Otherwise it would be an infinite slide of interrupts)
	; The only way the IRQ Level Detector is set high again is by "acknowledging the IRQ".
	; With the DMC DMA IRQ method, we acknowledge the IRQ by writing to $4010 to disable the IRQ.
	;
	; To understand the timing of IRQ Level Detector, We need to talk about a CPU cycle in even more depth.
	; The clock line of the 6502 (called φ0) is used to form two seperate clock inputs. "φ1" is raised when φ0 is low. "φ2" is raised when φ0 is high.
	; You can imagine a CPU cycle in 2 halves. φ1 and φ2.
	;    ......:...........:...........:...........:...........:...........:...........:......
	;    ┐     ┌─────┐     ┌─────┐     ┌─────┐     ┌─────┐     ┌─────┐     ┌─────┐     ┌─────┐     
	; φ0 │     │     │     │     │     │     │     │     │     │     │     │     │     │     │  
	;    └─────┘     └─────┘     └─────┘     └─────┘     └─────┘     └─────┘     └─────┘     └
	;    [φ1]  [φ2]  [φ1]  [φ2]  [φ1]  [φ2]  [φ1]  [φ2]  [φ1]  [φ2]  [φ1]  [φ2]  [φ1]  [φ2]  
	; During φ2 of each CPU cycle, (The timing of this is important when it comes to CPU/PPU Clock alignments, since the PPU is clocked 3 times as often as the CPU clock), the IRQ Level Detector is connected to the IRQ line of the 6502.
	; 
	; Finally, let's talk about "interrupt polling"
	; Just because the IRQ line is set (and the I flag is not), that doesn't mean an IRQ will happen on the next CPU cycle.
	; The CPU needs to poll for interrupts, and this happens (typically*) before the final CPU cycle of an instruction. If an interrupt was detected, then the following instruction will be an interrupt. (This also applies to the NMI)
	; *A branch that isn't taken only polls once before the second cycle, while a branch that is taken additionally polls right before the fourth cycle. (in total, 2 polls.)
	;	- This means that a branch that doesn't cross a page boundary will have the "interrupt delay". See the breakdown below.
	;	- BRK seems to poll before cycle 2, 3, 4, and 5, notably not polling before cycles 6 and 7. This might be the cause of "Interrupt Hijacking"?
	;
	; And this process of polling is directly the cause for the latency in clearing the interrupt flag. Here are the order of operations:
	;	- Assume the I flag is set. (Interrupts will not occur until cleared)
	;	- The IRQ Level Detector is pulled low.
	;	- on φ2, this is detected, and the IRQ pin of the 6502 is set.
	;	- a CLI instruction runs:
	;		- Cycle 1: read the opcode, $58. (An interrupt did not occur, so we keep it)
	;		- Interrupt polling: The I flag is set, so the interrupt does not occur.
	;		- Cycle 2, dummy read, and then clear the I flag.
	;	- The next instruction occurs. Let's say it's a NOP.
	;		- Cycle 1: read the opcode, $EA. (An interrupt did not occur, so we keep it)
	;		- Interrupt polling: The I flag is not set, so the interrupt does occur!!!
	;		- Cycle 2: dummy read.
	;	- The next instruction occurs, but now we're running an interrupt!
	;
	; And you can follow this logic to see why the RTI instruction can update the I flag and be followed by another interrupt immediately:
	;	- Assume the I flag is set. (Interrupts will not occur until cleared)
	;	- The IRQ Level Detector is pulled low.
	;	- on φ2, this is detected, and the IRQ pin of the 6502 is set.
	;	- an RTI instruction runs:
	;		- Cycle 1: read the opcode, $40. (An interrupt did not occur, so we keep it)
	;		- Cycle 2: Dummy read
	;		- Cycle 3: Dummy read at the stack pointer
	;		- Cycle 4: Read from the stack, and copy the values to the processor flags. (Updates the I flag) Also increment the address bus low byte.
	;		- Cycle 5: Read from the stack, this value is held in the data latch. Also increment the address bus low byte.
	;		- Interrupt polling: The I flag is not set, so the interrupt does occur!!!
	;		- Cycle 6: Update the low byte of the PC, Read from the stack, update the high byte of the PC, and copy the low byte of the address bus into the stack pointer.
	;	- The next instruction occurs, but now we're running an interrupt, since the I flag was updated before polling!
	;
	; Let's also walk through that example with the branches, since I'll be testing for it.
	;	- Assume the I flag is clear. (Interrupts will occur)
	;	- Assume The IRQ Level Detector is pulled high. (It will be pulled low mid-instruction for this example)
	;	- The Z flag is set.
	;	- A BEQ instruction runs:
	;		- Cycle 1: read the opcode, $F0. (An interrupt did not occur, so we keep it)
	;		- Interrupt polling: The IRQ line is not set, so the interrupt does not occur.
	;		- It's time for φ2, and let's say that this was timed such that the IRQ Level Detector went low just in time for this cycle, so the IRQ line is now set.
	;		- Cycle 2: Read the operand, check the value of the Z Flag. It is set, so the instruction isn't over yet.
	;		- Cycle 3: Dummy read, move the PC occording to the value read in the operand. Let's say the page boundary was not crossed. (End of instruction)
	;	- Welp, the interrupts were not polled after the IRQ line was set, so the interrupt won't occur until after the next instruction.
	;
	; And by extension, you can follow this logic for the following instructions:
	; 	- SEI: Polls happen before the I flag is set.
	;	- PLP: Polls happen before the I flag is pulled off the stack.	
	;
	; And the test works by simply running an instruction that updates the I flag, running an INX, then the IRQ should run, storing X somewhere. We can see how long the delay was by measuing the value we stored.

	JSR TEST_IFlagLatency_IRQPrep
	
	LDA #0	
	STX $4010	; disable the DMA IRQ
	LDA #$40
	STA $4017	; disable the frame counter IRQ's

	;;; Test 1 [Interrupt Flag Latency]: Does the IRQ happen at all? ;;;
	JSR TEST_IFlagLatency_StartTest ; clear address $50, and sync with DMA. X=0
	LDA #$5A
	; DMA should happen here.
	STA <$50
	JSR Clockslide_50 ; The timing of the IRQ Level detector is not what we are testing for here, so we'll stall for a bit. We *will* time for that in a few tests, but not right now.
	CLI			; +2
	NOP
	; IRQ should happen here.
	NOP
	LDA <$50	; the IRQ routine will overwrite this value, so it should be $00 instead of $5A
	CMP #00
	BNE FAIL_IFlagLatency1
	INC <currentSubTest

	;;; Test 2 [Interrupt Flag Latency]: Does the IRQ happen immediately after CLI, or after the following instruction? ;;;
	JSR TEST_IFlagLatency_StartTest ; clear address $50, and sync with DMA. X=0
	NOP
	; DMA should happen here.
	JSR Clockslide_50 ; Wait for IRQ to be ready
	INX ; X=1
	CLI
	; The IRQ isn't detected until the end of the *next* instruction.
	INX	; X=2
	; IRQ should happen here.
	INX
	LDA <$50
	CMP #02
	BNE FAIL_IFlagLatency1
	INC <currentSubTest
	
	;;; Test 3 [Interrupt Flag Latency]: Does SEI immediately prevent the IRQ from happening? (it should not) ;;;
	JSR TEST_IFlagLatency_StartTest ; clear address $50, and sync with DMA. X=0
	NOP
	; DMA should happen here.
	JSR Clockslide_50 ; Wait for IRQ to be ready
	INX
	CLI
	SEI
	; The interrupt has already been detected before the I flag was set, so the IRQ will happen here. (The IRQ is acknowledged so it doesn't happen twice/infinitely in this test)
	INX
	LDA <$50
	CMP #01
	BNE FAIL_IFlagLatency1
	INC <currentSubTest

	;;; Test 4 [Interrupt Flag Latency]: Check if the interrupt flag was pushed to the stack in the previous test (it should be) ;;;
	TSX
	DEX
	DEX
	LDA $100, X
	AND #flag_i ; the I flag is #$04
	BEQ FAIL_IFlagLatency1
	INC <currentSubTest

	;;; Test 5 [Interrupt Flag Latency]: Does the IRQ run again immediately after the RTI in SEI CLI? (it should) ;;;
	LDA #LOW(TEST_IFlagLatency_IRQ2)
	STA $601
	LDA #HIGH(TEST_IFlagLatency_IRQ2)	; change the IRQ pointer. This new one only acknowledges the IRQ the second time it occurs.
	STA $602
	JSR TEST_IFlagLatency_StartTest ; clear address $50, and sync with DMA. X=0
	NOP
	; DMA should happen here.
	JSR Clockslide_50 ; Wait for IRQ to be ready
	CLI
	INX
	; IRQ should happen here.
	; Second IRQ should happen here.
	INX ; If this happens before the IRQ, you fail the test.
	SEI
	LDA <$51 ; Did the IRQ run twice? (This uses the Y register, incremented in every IRQ, initialized to $FF, so $FF + 2 = 1. CMP #1.
	CMP #1
	BNE FAIL_IFlagLatency1
	LDA <$50 ; Did the second IRQ run before the second INX?
	CMP #1
	BNE FAIL_IFlagLatency
	INC <currentSubTest

	;;; Test 6 [Interrupt Flag Latency]: RTI updates the I flag before the check for an interrupt ;;;
	JSR TEST_IFlagLatency_IRQPrep ; Re-set up the original IRQ routine.
	; This next test uses and RTI, so let's set up the return address and flags.
	LDA #HIGH(TEST_IFlagLatency_RTI)
	PHA
	LDA #LOW(TEST_IFlagLatency_RTI)
	PHA
	LDA #flag_i ; the I flag is #$04
	PHA
	JSR TEST_IFlagLatency_StartTest ; clear address $50, and sync with DMA. X=0
	NOP
	; DMA should happen here.
	JSR Clockslide_50 ; Wait for IRQ to be ready
	LDA #$5A
	STA <$50 ; The IRQ routine would overwrite this. The IRQ should not occur in this test.
	CLI
	RTI	
TEST_IFlagLatency_RTI:
	; The IRQ should not occur, as the RTI instruction updates the flags before polling for interrupts. RTI should pull off the flags such that the I flag is set, preventing interrupts.
	INX	; Really not necessary, as the IRQ should not happen, so no matter what the value of X is, if $50 is overwritten, the test fails.
	INX	; Really not necessary, as the IRQ should not happen, so no matter what the value of X is, if $50 is overwritten, the test fails.
	LDA <$50
	CMP #$5A
	BNE FAIL_IFlagLatency
	INC <currentSubTest

	;;; Test 7 [Interrupt Flag Latency]: Does the IRQ happen immediately after PLP, or after the following instruction? ;;;
	JSR TEST_IFlagLatency_StartTest ; clear address $50, and sync with DMA. X=0
	NOP
	; DMA should happen here.
	JSR Clockslide_50 ; Wait for IRQ to be ready
	LDA #0
	PLA
	PLP	; Pull off the flags. I flag is NOT set.
	INX
	; IRQ should happen here.
	INX ; If this happens before the IRQ, you fail the test.
	LDA <$50
	CMP #01
	BNE FAIL_IFlagLatency
	INC <currentSubTest
	
	;;; Test 8 [Interrupt Flag Latency]: Does the IRQ happen at the correct CPU cycle? ;;;
	; In order to test the Interrupt polling behavior of branches, we need the IRQ to happen at the correct CPU cycle.
	; Let's check if it does!
	JSR TEST_IFlagLatency_StartTest ; clear address $50, and sync with DMA. X=0
	CLI			; +2
	; DMA should happen here
	INX
	; IRQ should happen here.
	INX
	LDA <$50	; the IRQ routine will overwrite this value, so it should be $00 instead of $5A
	CMP #01
	BNE FAIL_IFlagLatency
	INC <currentSubTest

	;;; Test 9 [Interrupt Flag Latency]: Do branches poll for interrupts before cycle 2? (They should) ;;;
	JSR TEST_IFlagLatency_StartTest ; clear address $50, and sync with DMA. X=0
	LDA <$50
	; DMA should happen here.
	CMP #$5A
	CLV	; clear overflow flag.
	CLI	
	BVS	TEST_IFlagLatency_Branch1	; This branch will NOT be taken.
TEST_IFlagLatency_Branch1:
	; IRQ should happen here.
	INX 
	LDA <$50
	CMP #$00
	BNE FAIL_IFlagLatency
	INC <currentSubTest
	
	;;; Test A [Interrupt Flag Latency]: Do branches poll for interrupts before cycle 3? (They should not) ;;;
	JSR TEST_IFlagLatency_StartTest_10ExtraCycles ; clear address $50, and sync with DMA. X=0. We have 12 cycles until the DMA instead of the usual 2 these tests have used.
	LDA #$5A ; +2 (10 cycles until DMA)
	STA <$50 ; +3 (7 cycles until DMA)
	LDA <currentSubTest ; +3 cycles (4 cycles until DMA). This is also using a known non-zero-value, so this branch WILL be taken.
	CLI		 ; +2 cycles (2 cycles until DMA)
	BNE TEST_IFlagLatency_Branch2 ; [1: read opcode] (poll for interrupts, no interrupts) [2: read operand] [DMC DMA, set IRQ Level detector low] [3: move the PC] (End of instruction. did not poll again).
TEST_IFlagLatency_Branch2:
	INX
	; IRQ should happen here.
	LDA <$50
	CMP #$01
	BNE FAIL_IFlagLatency
	INC <currentSubTest
	; And hey, if you pass this one, keep in mind that I only test with BNE here, but this applies to every branch, not just BNE.
	
	; This next test needs to occur at a known page boundary, so let's jump to approximately address $FE00.
	; It doesn't return, so the end of the test just happens out there.
	JMP TEST_IFlagLatency_PageBoundaryTest
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FAIL_IFlagLatency:
	SEI
	JMP TEST_Fail
;;;;;;;;;;;;;;;;;

TEST_NmiAndBrk_BRK:
	STX <Copy_X
	TSX
	JSR Clockslide_50
	LDA $101,X ; read the flags without running PLA, since PLA pokes them a bit.
	LDX <Copy_X
	STA $520,X ; Store the results at $520.
	RTI

TEST_NmiAndBrk_NMI:
TEST_NmiAndIrq_NMI:
	STX <Copy_X
	TSX
	JSR Clockslide_50
	LDA $101,X ; read the flags without running PLA, since PLA pokes them a bit.
	LDX <Copy_X
	STA $500,X ; Store the results at $500.
	RTI

TEST_NmiAndBrk_Prep:
	LDA #$4C
	STA $600
	STA $700
	LDA #LOW(TEST_NmiAndBrk_BRK)
	STA $601
	LDA #HIGH(TEST_NmiAndBrk_BRK)	; change the IRQ pointer.
	STA $602
	LDA #LOW(TEST_NmiAndBrk_NMI)
	STA $701
	LDA #HIGH(TEST_NmiAndBrk_NMI)	; change the NMI pointer.
	STA $702
	RTS
;;;;;;;

TEST_NmiAndBrk:
	JSR TEST_NmiAndBrk_Prep
	;;; Test 1 [NMI and BRK]: What happens when the NMI runs during a BRK instruction? (Error 1 means BRK didn't skip the following byte) ;;;
	; Also known as Interrupt Hijacking, this test will simply sync the CPU such that the NMI will occur in 8-A cycles. Then it will run this 16 times, incrementing A by 1 for each test.
	; Here's how it works:
	; After an NMI or BRK, read the value pushed to the stack, and store at <$50,X or <$60,X respectively.
	; Then just read all the values and compare with an answer key.
	JSR DisableRendering
	LDX #0
TEST_NmiAndBrkLoop:
	STX <Copy_X
	LDA #0
	JSR VblSync_Plus_A
	JSR Clockslide_29700
	; 80 CPU cycles until Vblank.
	JSR EnableNMI ; +31 CPU cycles. (49 cycles until vblank)
	LDX <Copy_X	  ; +3
	TXA			  ; +2 (44 cycles)
	JSR Clockslide36_Plus_A ; + 36 + A
	; 8-A CPU cycles until Vblank.
	; stall for an extra 6 cycles.
	LDY #0
	NOP
	NOP
	BRK ; BRK will return *after* this upcoming INY, since it only gets compiled to [$00].
	INY	; This should get skipped!
	TYA
	BNE FAIL_NmiAndBrk
	INX ; X+=1
	CPX #32
	BNE TEST_NmiAndBrkLoop
	INC <currentSubTest
	
	;;; Test 2 [NMI and BRK]: Check the answer key. ;;;
	; And now we check with the answer key.
	JSR DisableNMI
	LDX #0
TEST_NmiAndBrkAnswerLoop:
	LDA $500,X
	CMP TEST_NmiAndBrkAnswerKey, X
	BNE TEST_NmiAndBrk_TryKey2
	INX

	CPX #64
	BNE TEST_NmiAndBrkAnswerLoop
	
	;; END OF TEST ;;
	LDA #1
	RTS

TEST_NmiAndBrk_TryKey2:
	LDX #0
TEST_NmiAndBrkAnswerLoop2:
	LDA $500,X
	CMP TEST_NmiAndBrkAnswerKey_Alignment2, X
	BNE FAIL_NmiAndBrk
	INX

	CPX #64
	BNE TEST_NmiAndBrkAnswerLoop2
	
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;


FAIL_NmiAndBrk:
	JMP TEST_Fail
	

TEST_NmiAndBrkAnswerKey:   
	.byte $27, $37, $37, $36, $37, $26, $27, $26, $27, $26, $27, $24, $25, $24, $25, $24, $25, $24, $25, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24
	.byte $37, $00, $00, $00, $00, $36, $37, $36, $37, $36, $37, $36, $37, $36, $37, $36, $37, $36, $37, $36, $37, $36, $37, $36, $37, $36, $37, $36, $37, $36, $37, $36
TEST_NmiAndBrkAnswerKey_Alignment2: ; CPU/PPU clock alignment 2 has different results:
    .byte $37, $37, $37, $36, $27, $26, $27, $26, $27, $26, $25, $24, $25, $24, $25, $24, $25, $24, $25, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24
    .byte $00, $00, $00, $00, $37, $36, $37, $36, $37, $36, $37, $36, $37, $36, $37, $36, $37, $36, $37, $36, $37, $36, $37, $36, $37, $36, $37, $36, $37, $36, $37, $36

TEST_NmiAndIrq_Prep:
	LDA #$4C
	STA $602
	STA $700
	LDA #LOW(TEST_NmiAndIrq_IRQ)
	STA $603
	LDA #HIGH(TEST_NmiAndIrq_IRQ)	; change the IRQ pointer.
	STA $604
	LDA #LOW(TEST_NmiAndIrq_NMI)
	STA $701
	LDA #HIGH(TEST_NmiAndIrq_NMI)	; change the NMI pointer.
	STA $702
	LDA #$A9
	STA $600
	LDA #$FF
	STA $601
	RTS
;;;;;;;

TEST_NmiAndIrq_IRQ:
	STX <Copy_X
	TSX
	JSR Clockslide_50
	LDA $101,X ; read the flags without running PLA, since PLA pokes them a bit.
	; Okay cool, now set the I flag there.
	ORA #4
	STA $101,X ; I'd prefer if this didn't infinitely loop, and I'd also like to not have to wait for the IRQ line to be set again, so we're not acknowledging it.
	LDX <Copy_X
	STA $510,X ; Store the results at $520.
	RTI
;;;;;;;

TEST_NmiAndIrq_SetIRQ:
	JSR DMASync_50CyclesRemaining
	LDX #0		; +2
	LDA #$8F	; +2
	STA $4010	; +4 (enable the DMA IRQ)
	JSR Clockslide_34 ; +34
	RTS			; +6
;;;;;;;


TEST_NmiAndIrq:
	JSR TEST_NmiAndIrq_Prep
	JSR TEST_NmiAndIrq_SetIRQ
	; Great! now we set the I flag so this IRQ never runs until we need it.
	SEI
	; This is very similar to the NMI and BRK test ,except instead of a BRK, we just have an IRQ to occur.
	JSR DisableRendering
	LDX #0
TEST_NmiAndIrqLoop:
	STX <Copy_X
	LDA #0
	JSR VblSync_Plus_A
	JSR Clockslide_29700
	; 80 CPU cycles until Vblank.
	JSR EnableNMI ; +31 CPU cycles. (49 cycles until vblank)
	LDX <Copy_X	  ; +3
	TXA			  ; +2 (44 cycles)
	JSR Clockslide36_Plus_A ; + 36 + A
	; 8-A CPU cycles until Vblank.
	; stall for an extra 6 cycles.
	CLI
	LDA #0	; set the zero flag.
	; Assuming you passed the Interrupt flag latency test, the IRQ will occur here!
	NOP
	INX ; X+=1
	CPX #16
	BNE TEST_NmiAndIrqLoop
	
	LDA #0
	STA $4010 ; acknowledge the IRQ, now that we're done.
	SEI
	
	;;; Test 1 [NMI and IRQ]: Check the answer key. ;;;
	JSR DisableNMI
	LDX #0
TEST_NmiAndIrqAnswerLoop:
	LDA $500,X
	CMP TEST_NmiAndIqrAnswerKey, X
	BNE TEST_NmiAndIrq_TryAlignment2
	INX
	CPX #32
	BNE TEST_NmiAndIrqAnswerLoop
	
	;; END OF TEST ;;
	LDA #1
	RTS
	
TEST_NmiAndIrq_TryAlignment2:
	LDX #0
TEST_NmiAndIrqAnswerLoop2:
	LDA $500,X
	CMP TEST_NmiAndIqrAnswerKey_Alignment2, X
	BNE FAIL_NmiAndIqr
	INX
	CPX #32
	BNE TEST_NmiAndIrqAnswerLoop2
	
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

TEST_NmiAndIqrAnswerKey:
	.byte $A5, $A5, $23, $22, $23, $22, $23, $22, $23, $20, $21, $24, $25, $24, $25, $24
	.byte $27, $27, $27, $26, $27, $26, $27, $26, $27, $24, $25, $26, $27, $26, $27, $26
	
TEST_NmiAndIqrAnswerKey_Alignment2:
	.byte $A5, $23, $23, $22, $23, $22, $23, $22, $21, $20, $25, $24, $25, $24, $25, $24
	.byte $27, $27, $27, $26, $27, $26, $27, $26, $25, $24, $27, $26, $27, $26, $27, $26

FAIL_NmiAndIqr:
	JMP TEST_Fail
;;;;;;;;;;;;;;;;;

TEST_RMW2007:
	;;; Test 1 [RMW $2007]: Does a Read-Modify-Write instruction to address $2007 perform an extra write? ;;;
	; This behavior only applies to RP2C02G PPU's and later.
	; This behavior only seems to be consistent if the nametable in which the test is occuring is *all zeroes*.
	; To be more specific, there's probably going to be 3 writes:
	;	-1) The write at "v", which is different depending on console/PPU revisions. (I can't in good consience test for this one, considering the different console behavior)
	;	-2) The "unexpected" write. Write the modified buffer value to: (v & $FF00) | (modified buffer value)
	;	-3) The third write, which is different depending on CPU/PPU clock alignments, and console/PPU revisions. (I can't in good consience test for this one, considering the different console behavior)
	;
	; This test is checking the second case, since as far as I can tell, it is consistent across different consoles.
	; So here's how the test will work.
	; Set up the ppu read buffer.
	; Move v to some location for the test.
	; run some read-modify-write instruction to $2007
	; then just read the location of the second write, which should always be (v & $FF00) | (modified buffer value)
	JSR DisableRendering
	JSR SetPPUADDRFromWord
	.byte $24, $00
	LDA #0
	TAY
	LDX #4
TEST_RMW2007_ClearNametableLoop:
	STA $2007
	DEY
	BNE TEST_RMW2007_ClearNametableLoop
	DEX
	BNE TEST_RMW2007_ClearNametableLoop
	; Okay, cool. address $2400 to $27FF are now all zeroes.
	
	LDA #$5A
	JSR SetPPUReadBufferToA
	; the PPU read buffer is 5A.
	JSR SetPPUADDRFromWord
	.byte $25, $00
	; For the first test here, "v" will be set to $2500
	INC $2007
	; And here's what happened.
	; Cycle 1: read opcode ($EE)
	; Cycle 2: read operand ($07)
	; Cycle 3: read operand ($20)
	; Cycle 4: Read the PPU-read-buffer ($5A)
	; Cycle 5: Write ($5A) to $2007. (also INC $5A to $5B) !! Inconsistent behavior depending on console revision: Who knows what VRAM address was just updated, if any.
	; Cycle 6: Write ($5B) to $2007. This will write to VRAM address $255B. (Also some third write, but that's inconsistent depending on console revision too.)
	;
	; Let's read address $255B
	JSR ReadPPUADDRFromWord
	.byte $25, $5B
	CMP #$5B
	BNE FAIL_RMW2007
	INC <currentSubTest
	;;; Test 2 [RMW $2007]: Is palette RAM inaccessible to this extra write? ;;;
	
	JSR WaitForVBlank ; moving v to palette RAM while rendering is disabled will draw a series of pixels of the color at that palette ram index. I'd like to hide this inside vblank.
	; Reading from palette RAM does not use the PPU read buffer.
	JSR SetPPUADDRFromWord
	.byte $3F, $0D	; the color at this address is $2A
	
	INC $2007
	; And here's what happened.
	; Cycle 1: read opcode ($EE)
	; Cycle 2: read operand ($07)
	; Cycle 3: read operand ($20)
	; Cycle 4: Read the palette RAM address $0D ($2A)
	; Cycle 5: Write ($2A) to $2007. (also INC $2A to $2B) !! Inconsistent behavior depending on console revision: Who knows what VRAM address was just updated, if any.
	; Cycle 6: Write ($2B) to $2007. This should just write to Palette RAM $0E. (Also some third write, but that's inconsistent depending on console revision too.)
		
	; Did we write $2B to $3F2B? (We shouldn't have)
	JSR SetPPUADDRFromWord
	.byte $3F, $2B
	LDA $2007 ; Palette RAM doesn't use the PPU Read buffer.
	CMP #$2B
	BEQ FAIL_RMW2007
	INC <currentSubTest

	;;; Test 3 [RMW $2007]: Did we write to the nametable at $3F2B instead? (Well- the mirror at $272B.) ;;;
	; As it turns out, you shouldn't have written there either.
	JSR ReadPPUADDRFromWord
	.byte $27, $2B
	CMP #$2B
	BEQ FAIL_RMW2007
	
	; I'd like to test for where we *did* write to palette RAM, but that seems inconsistent across consoles, so I'm ending the test here.
	;; END OF TEST ;;
	JSR ResetScroll
	JSR WaitForVBlank
	JSR SetUpDefaultPalette
	JSR ResetScroll
	LDA #1
	RTS
;;;;;;;
	
FAIL_RMW2007:
	; we probably want to reset this nametable to be a bunch of $24's right?
	JSR ResetScroll
	JSR WaitForVBlank
	JSR SetUpDefaultPalette
	JSR ResetScroll
	JMP TEST_Fail
;;;;;;;;;;;;;;;;;	

TEST_APU_Prep:
	SEI	; we don't want any interrupts occuring.
	LDA #$40
    STA $4017	; Disable the frame counter IRQ's
    LDA #$01
    STA $4015	; Enable pulse 1 channel.
    LDA #$10
    STA $4000	; Don't infinitely play pulse 1 channel. (and set the volume to be constantly the minimum.)
    LDA #$7f
    STA $4001	; Disable the sweep.
    LDA #$ff
    STA $4002	; Set Pulse 1's Timer Low to the maximum value.
	RTS
;;;;;;;

FAIL_APULengthCounter:
FAIL_AndDisableAudioChannels:
	LDA #$00
    STA $4015	; disable all audio channels.
	JMP TEST_Fail

TEST_APULengthCounter:
	; Special thanks to blargg. I pretty much just copied all of their APU tests, with a few minor changes and additions here and there.
	JSR TEST_APU_Prep
	
	;;; Test 1 [APU Length Counter]: The pulse 1 channel isn't playing yet. ;;;
	LDA $4015
	BNE FAIL_APULengthCounter
	INC <currentSubTest

	;;; Test 2 [APU Length Counter]: Writing to $4003 will start playing audio. ;;;
	LDA #$18
	STA $4003
	LDA $4015
	CMP #1	; The pulse 1 channel should now be playing.
	BNE FAIL_APULengthCounter ; Otherwise, fail the test!
	INC <currentSubTest
	
	;;; Test 3 [APU Length Counter]: The audio will in-fact stop playing if we wait long enough. ;;;
	LDX #15
TEST_APULengthCounter_DelayQuarterSecondLoop:	; Let's wait for 15 frames. About 1/4th of a second.
	JSR Clockslide_29780
	DEX
	BNE TEST_APULengthCounter_DelayQuarterSecondLoop
	LDA $4015
	BNE FAIL_APULengthCounter ; The pulse 1 channel should no longer be playing.
	INC <currentSubTest

	;;; Test 4 [APU Length Counter]: Writing $80 to $4017 will immediately clock the Length Counter. ;;;
	LDA #0
	STA $4017 ; Reset the frame counter.
	LDA #$18
	STA $4003 ; Length = 2. (The upper 5 bits of a value written to $4003 sets the length counter from a value in a look-up-table.)
	; This Look-up-table is the focus of the Length Table test. But for now, let's just assume at least the length of 2 is emulated.
	LDA #$80
	STA $4017 ; Use the 5-step Frame Counter mode. Writing this value clocks the length counters, which now equals 1.
	STA $4017 ; This clocks it again, so it now equals zero. And just like that, the pulse 1 channel is no longer playing audio.
	LDA $4015
	BNE FAIL_APULengthCounter ; The pulse 1 channel should no longer be playing.
	INC <currentSubTest

	;;; Test 5 [APU Length Counter]: Writing $00 to $4017 will not clock the Length Counter. ;;;
	LDA #0
	STA $4017 ; Reset the frame counter.
	LDA #$18
	STA $4003 ; Length = 2.
	LDA #$00
	STA $4017 ; This doesn't clock the length counters.
	STA $4017 ; This doesn't clock the length counters.
	LDA $4015
	CMP #1
	BNE FAIL_APULengthCounter ; The pulse 1 channel should still be playing.
	INC <currentSubTest

	;;; Test 6 [APU Length Counter]: Disabling the audio channel will immediately clear the length counter to zero. ;;;
	LDA #$18
	STA $4003 ; Length = 2.
	LDA #0
	STA $4015 ; stop playing the pulse 1 channel.
	LDA #1
	STA $4015 ; enable the pulse 1 channel agian.
	LDA $4015 ; The length counter was reset, so the pulse 1 channel isn't playing.
	BNE FAIL_APULengthCounter1
	INC <currentSubTest

	;;; Test 7 [APU Length Counter]: The length counter cannot be set when the channel is disabled. ;;;
	LDA #0
	STA $4015 ; stop playing the pulse 1 channel.
	LDA #$18
	STA $4003 ; Length would be 2, but the channel is disabled, so the length is 0.
	LDA #1
	STA $4015 ; enable the pulse 1 channel agian.
	LDA $4015 ; The pulse 1 channel isn't playing.
	BNE FAIL_APULengthCounter1
	INC <currentSubTest
	
	;;; Test 8 [APU Length Counter]: If the channel is set to play infinitely, it won't clock the length counter. ;;;
	LDA #0
	STA $4017 ; Reset the frame counter.
	LDA #$18
	STA $4003 ; Length = 2.
	LDA #$30
	STA $4000 ; loop channel infinitely
	LDA #$80
	STA $4017 ; Attempt to clock the counter.
	STA $4017 ; This doesn't work since it's playing infinitely.
	LDA #$10
	STA $4000 ; stop looping channel infinitely. The counters should still be 2.
	LDA $4015
	CMP #1
	BNE FAIL_APULengthCounter1 ; The pulse 1 channel should still be playing.
	INC <currentSubTest
	
	;;; Test 9 [APU Length Counter]: If the channel is set to play infinitely, the length counter is left unchanged. ;;;
	; For the most part, I just copied what blargg did for this entire test.
	; I added an extra test here at the end, since I can imagine an emulator setting the length counter to be something like, $FF every APU cycle in which it's set to loop forever.
	; That's certainly *a way* to make it last forever, but it's not what actually happens, so let's test for that.
	LDA #0
	STA $4017 ; Reset the frame counter.
	LDA #$18
	STA $4003 ; Length = 2.
	LDA #$30
	STA $4000 ; loop channel infinitely
	LDA #$80
	STA $4017 ; Attempt to clock the counter.
	STA $4017 ; This doesn't work since it's playing infinitely.
	LDA #$10
	STA $4000 ; stop looping channel infinitely. The counters should still be 2.
	LDA #$80
	STA $4017 ; Attempt to clock the counter.
	STA $4017 ; It actually will work this time.
	LDA $4015
	BNE FAIL_APULengthCounter1 ; The pulse 1 channel should no longer be playing.

	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

FAIL_APULengthCounter1:
FAIL_APULengthTable:
	JMP FAIL_AndDisableAudioChannels
;;;;;;;;;;;;;;;;;
	
TEST_APULengthTable:
	JSR TEST_APU_Prep
	;;; Test 1 [APU Length Table]: What value was the length counter when we write 'n' to address $4003? ;;;
	; Just for clarification, this is actually "Test 1" through "Test W". They all use the same routine, but the error code is adjusted accordingly.
	LDX #0
TEST_APULengthTableLoop:
	TXA
	ASL A
	ASL A
	ASL A ; The upper five bits of A are now the iteration into this loop.
	PHA
	LDA #0
	STA $4017 ; Reset the frame counter.
	PLA
	STA $4003 ; Reset the length counter with the next value for the test.
	LDY #0
TEST_APULengthTable_UpdateCounterLoop:
	LDA #$80
	STA $4017 ; Clock the length counter.
	INY
	LDA $4015	; Check if pulse 1 is still playing.
	BNE TEST_APULengthTable_UpdateCounterLoop ; Loop until it stops.
	; And just like that, we know the value of the length Table, which is now stored in Y.
	TYA
	CMP TEST_APULengthTable_AnswerKey, X
	BNE FAIL_APULengthTable
	INC <currentSubTest
	INX
	CPX #32
	BNE TEST_APULengthTableLoop
	
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;
	
TEST_APULengthTable_AnswerKey:
	.byte 10, 254, 20, 2, 40, 4, 80, 6, 160, 8, 60, 10, 14, 12, 26, 14, 12, 16, 24, 18, 48, 20, 96, 22, 192, 24, 72, 26, 16, 28, 32, 30

FAIL_FrameCounterIRQ:
	LDA #$40
	STA $4017	; disable the IRQ flag.
	JMP TEST_Fail

TEST_FrameCounterIRQ:
	SEI
	;;; Test 1 [APU Frame Counter IRQ]: The IRQ flag is set when the APU Frame counter is in the 4-step mode, and the IRQ flag is enabled. ;;;
	LDA #$00	
	STA $4017	; 4-step mode, enable IRQ
	JSR Clockslide_30000 ; wait long enough that the IRQ flag would be set.
	LDA $4015
	BEQ FAIL_FrameCounterIRQ
	INC <currentSubTest

	;;; Test 2 [APU Frame Counter IRQ]: The IRQ flag is not set when the APU Frame counter is in the 4-step mode, and the IRQ flag is disabled. ;;;
	LDA #$40
	STA $4017	; 4-step mode, disable IRQ
	JSR Clockslide_30000 ; wait long enough that the IRQ flag would be set.
	LDA $4015
	BNE FAIL_FrameCounterIRQ
	INC <currentSubTest
	
	;;; Test 3 [APU Frame Counter IRQ]: The IRQ flag is not set when the APU Frame counter is in the 5-step mode, and the IRQ flag is enabled. ;;;
	LDA #$80
	STA $4017	; 5-step mode, enable IRQ (it doesn't happen in 5-step mode)
	JSR Clockslide_30000 ; wait long enough that the IRQ flag would be set.
	LDA $4015
	BNE FAIL_FrameCounterIRQ
	INC <currentSubTest
	
	;;; Test 4 [APU Frame Counter IRQ]: The IRQ flag is not set when the APU Frame counter is in the 5-step mode, and the IRQ flag is disabled. ;;;
	LDA #$C0
	STA $4017	; enable the frame counter IRQ, and use the 5-step mode.
	JSR Clockslide_30000 ; wait long enough that the IRQ flag would be set.
	LDA $4015
	BNE FAIL_FrameCounterIRQ
	INC <currentSubTest
	
	;;; Test 5 [APU Frame Counter IRQ]: Reading the IRQ flag clears the IRQ flag. ;;;
	LDA #$00	
	STA $4017	; 4-step mode, enable IRQ
	JSR Clockslide_30000 ; wait long enough that the IRQ flag would be set.
	LDA $4015 ; read it, clearing it
	LDA $4015 ; read it again, but it's already cleared.
	BNE FAIL_FrameCounterIRQ
	INC <currentSubTest
	
	;;; Test 6 [APU Frame Counter IRQ]: The IRQ flag should be cleared when the APU transitions from a "put" cycle to a "get" cycle.  ;;;
	LDA #$00	
	STA $4017	; 4-step mode, enable IRQ
	JSR Clockslide_30000 ; wait long enough that the IRQ flag would be set.
	LDA #02
	STA $4014 ; align with even cycle.
	LDA #0
	LDX #0
	.byte $1F	; SLO Absolute, X
	.word $4015 ; This reads from $4015 twice!
	BNE FAIL_FrameCounterIRQ ; If SLO is properly emulated, you might see bit 7 set here (failing the test). The flag is actually cleared before the second read, so it bit 7 should be 0.
	INC <currentSubTest
	
	;;; Test 7 [APU Frame Counter IRQ]: The IRQ flag should not be cleared yet the APU transitions from a "get" cycle to a "put" cycle. ;;;
	; If you are reading this, then you probably passed test 6 and failed test 7.
	; This was a brand new discovery as of writing this ROM, so I expect most emulators to fail this.
	;
	; When reading from $4015, bit 6 will be cleared. This is known behavior (and the focus of test 5)
	; However, bit 6 will not be cleared until the next "get" cycle.
	; For instance here's what happened during test 6:
	; (get) [Read Opcode: $1F]
	; (put) [Read Operand: $15]
	; (get) [Read Operand: $40]
	; (put) [Read $4015] (this is a get cycle, so clear bit 6 of 4015)
	; (get) [Read $4015] (bit 6 was already cleared before the read.)
	;
	; And here's what will happen in this test:
	; (put) [Read Opcode: $1F]
	; (get) [Read Operand: $15]
	; (put) [Read Operand: $40]
	; (get) [Read $4015] (this is a put cycle, so bit 6 of 4015 will not be cleared until after the next cycle.)
	; (put) [Read $4015] (bit 6 was still set when this was read. *Now* we clear bit 6 of $4015.)
	;
	; And of course, in the event of a regular non-double-read, $4015 will still only clear bit 6 on the next get cycle,
	; so you probably want to clear bit 6 inside the APU cycle code of your emulator, and not in your "read $4015" code.
	; I suggest making a flag for "we are clearing bit 6 on the next APU get cycle" to be set inside the "read $4015" code.
	
	LDA #$00	
	STA $4017	; 4-step mode, enable IRQ
	JSR Clockslide_30000 ; wait long enough that the IRQ flag would be set.
	LDA #02
	STA $4014 ; align with even cycle.
	LDA <$00  ; align with odd cycle.
	LDA #0
	LDX #0
	.byte $1F	; SLO Absolute, X
	.word $4015 ; This reads from $4015 twice!
	BEQ FAIL_FrameCounterIRQ2 ; If SLO is properly emulated, bit 7 will be set if you passed the test. The frame counter interrupt flag gets cleared after the second read in this case.
	INC <currentSubTest

	;;; Test 8 [APU Frame Counter IRQ]: Changing the Frame Counter to 5-step mode after the flag was set does not clear the flag. ;;;
	LDA #$00	
	STA $4017 ; 4-step mode, enable IRQ
	JSR Clockslide_30000 ; wait long enough that the IRQ flag would be set.
	LDA #$80
	STA $4017 ; 5-step mode, enable IRQ
	LDA $4015 ; read the IRQ flag, which will still be set.
	BEQ FAIL_FrameCounterIRQ2
	INC <currentSubTest
	
	;;; Test 9 [APU Frame Counter IRQ]: Disabling the IRQ flag will clear the IRQ flag. ;;;
	LDA #$00	
	STA $4017	; 4-step mode, enable IRQ
	JSR Clockslide_30000 ; wait long enough that the IRQ flag would be set.
	LDA #$40
	STA $4017 ; clear the IRQ flag.
	LDA $4015 ; read the IRQ flag, which will no longer be set.
	BNE FAIL_FrameCounterIRQ2
	INC <currentSubTest
	
	;;; Test A [APU Frame Counter IRQ]: Test the timing of the IRQ flag. (see if it's set too early) ;;;
	JSR WaitForVBlank
	LDA #02
	STA $4014 ; sync with even CPU cycle
	LDA #$40
	STA $4017 ; 4-step mode, clear IRQ flag
	LDA #$00	
	STA $4017 ; 4-step mode, enable IRQ (The CPU was on an odd cycle when writing that, so the frame counter is reset in 3 CPU cycles.)
	; the flag should be enabled in 29830 CPU cycles.
	; So let's stall for 29826 cycles, and read $4015 to see if the flag was set. That should be 1 cycle too early.
	JSR Clockslide_29700
	JSR Clockslide_100
	JSR Clockslide_26
	LDA $4015 ; If the flag *is* set, it was set too early, so you fail the test.
	BNE FAIL_FrameCounterIRQ2
	INC <currentSubTest
	BNE TEST_FrameCounterIRQ_Continue
	
FAIL_FrameCounterIRQ2:
	LDA #$40
	STA $4017	; disable the IRQ flag.
	JMP TEST_Fail
	
TEST_FrameCounterIRQ_Continue:
	;;; Test B [APU Frame Counter IRQ]: Test the timing of the IRQ flag. (see if it's set on the right CPU cycle) ;;;
	JSR WaitForVBlank
	LDA #02
	STA $4014 ; sync with even CPU cycle
	LDA #$40
	STA $4017 ; 4-step mode, clear IRQ flag
	LDA #$00	
	STA $4017 ; 4-step mode, enable IRQ (The CPU was on an odd cycle when writing that, so the frame counter is reset in 3 CPU cycles.)
	; the flag should be enabled in 29830 CPU cycles.
	; So let's stall for 29827 cycles, and read $4015 to see if the flag was set. That should be 1 cycle too early.
	JSR Clockslide_29700
	JSR Clockslide_100
	JSR Clockslide_27
	LDA $4015 ; If the flag is *not* set, it was set too late, so you fail the test.
	BEQ FAIL_FrameCounterIRQ2
	INC <currentSubTest

	;;; Test C [APU Frame Counter IRQ]: Test the timing of the IRQ flag. (If the write occurs on an even CPU cycle, the IRQ is delayed by 1 CPU cycle) ;;;
	JSR WaitForVBlank
	LDA #02
	STA $4014 ; sync with even CPU cycle
	LDA <$00  ; sync with odd CPU cycle
	LDA #$40
	STA $4017 ; 4-step mode, clear IRQ flag
	LDA #$00	
	STA $4017 ; 4-step mode, enable IRQ (The CPU was on an even cycle when writing that, so the frame counter is reset in 4 CPU cycles.)
	; the flag should be enabled in 29831 CPU cycles.
	; So let's stall for 29827 cycles, and read $4015 to see if the flag was set. That should be 1 cycle too early.
	JSR Clockslide_29700
	JSR Clockslide_100
	JSR Clockslide_27
	LDA $4015 ; If the flag *is* set, it was set too early, so you fail the test.
	BNE FAIL_FrameCounterIRQ2
	INC <currentSubTest

	;;; Test D [APU Frame Counter IRQ]: Test the timing of the IRQ flag. (see if it's set on the correct cycle) ;;;
	JSR WaitForVBlank
	LDA #02
	STA $4014 ; sync with even CPU cycle
	LDA <$00  ; sync with odd CPU cycle
	LDA #$40
	STA $4017 ; 4-step mode, clear IRQ flag
	LDA #$00	
	STA $4017 ; 4-step mode, enable IRQ (The CPU was on an even cycle when writing that, so the frame counter is reset in 4 CPU cycles.)
	; the flag should be enabled in 29831 CPU cycles.
	; So let's stall for 29828 cycles, and read $4015 to see if the flag was set. That should be *the* cycle it gets set.
	JSR Clockslide_29700
	JSR Clockslide_100
	JSR Clockslide_28
	LDA $4015 ; If the flag is *not* set, it was set too late, so you fail the test.
	BEQ FAIL_FrameCounterIRQ2
	INC <currentSubTest

	;;; Test E [APU Frame Counter IRQ]: Reading $4015 on the same cycle the IRQ flag is set, will not clear the IRQ flag (it gets set again on the following 2 CPU cycles) ;;;
	JSR WaitForVBlank
	LDA #02
	STA $4014 ; sync with even CPU cycle
	LDA <$00  ; sync with odd CPU cycle
	LDA #$40
	STA $4017 ; 4-step mode, clear IRQ flag
	LDA #$00	
	STA $4017 ; 4-step mode, enable IRQ (The CPU was on an even cycle when writing that, so the frame counter is reset in 4 CPU cycles.)
	JSR Clockslide_29700
	JSR Clockslide_100
	JSR Clockslide_27
	LDA $4015 ; Read on the same cycle the IRQ flag is set.
	LDA $4015 ; Read again! But it won't be cleared, since the IRQ flag gets set again.
	BEQ FAIL_FrameCounterIRQ3
	INC <currentSubTest
	
	;;; Test F [APU Frame Counter IRQ]: Reading $4015 on the cycle after the IRQ flag is set, will not clear the IRQ flag (it gets set again on the following CPU cycle) ;;;
	JSR WaitForVBlank
	LDA #02
	STA $4014 ; sync with even CPU cycle
	LDA <$00  ; sync with odd CPU cycle
	LDA #$40
	STA $4017 ; 4-step mode, clear IRQ flag
	LDA #$00	
	STA $4017 ; 4-step mode, enable IRQ (The CPU was on an even cycle when writing that, so the frame counter is reset in 4 CPU cycles.)
	JSR Clockslide_29700
	JSR Clockslide_100
	JSR Clockslide_28
	LDA $4015 ; Read on the same cycle the IRQ flag is set.
	LDA $4015 ; Read again! But it won't be cleared, since the IRQ flag gets set again.
	BEQ FAIL_FrameCounterIRQ3
	INC <currentSubTest
	
	;;; Test G [APU Frame Counter IRQ]: Reading $4015 2 cycles after the IRQ flag is set, will not clear the IRQ flag (it gets set again on this CPU cycle) ;;;
	JSR WaitForVBlank
	LDA #02
	STA $4014 ; sync with even CPU cycle
	LDA <$00  ; sync with odd CPU cycle
	LDA #$40
	STA $4017 ; 4-step mode, clear IRQ flag
	LDA #$00	
	STA $4017 ; 4-step mode, enable IRQ (The CPU was on an even cycle when writing that, so the frame counter is reset in 4 CPU cycles.)
	JSR Clockslide_29700
	JSR Clockslide_100
	JSR Clockslide_29
	LDA $4015 ; Read on the same cycle the IRQ flag is set.
	LDA $4015 ; Read again! But it won't be cleared, since the IRQ flag gets set again.
	BEQ FAIL_FrameCounterIRQ3
	INC <currentSubTest
	
	;;; Test H [APU Frame Counter IRQ]: Reading $4015 3 cycles after the IRQ flag is set, will clear the IRQ flag (it does not get set again on this CPU cycle) ;;;
	JSR WaitForVBlank
	LDA #02
	STA $4014 ; sync with even CPU cycle
	LDA <$00  ; sync with odd CPU cycle
	LDA #$40
	STA $4017 ; 4-step mode, clear IRQ flag
	LDA #$00	
	STA $4017 ; 4-step mode, enable IRQ (The CPU was on an even cycle when writing that, so the frame counter is reset in 4 CPU cycles.)
	JSR Clockslide_29700
	JSR Clockslide_100
	JSR Clockslide_30
	LDA $4015 ; Read on the same cycle the IRQ flag is set.
	LDA $4015 ; Read again! But it will be cleared.
	BNE FAIL_FrameCounterIRQ3
	INC <currentSubTest
	BNE TEST_FrameCounterIRQ_Continue2
		
FAIL_FrameCounterIRQ3:
	LDA #$40
	STA $4017	; disable the IRQ flag.
	JMP TEST_Fail
	
TEST_FrameCounterIRQ_Continue2:
	;;; Test I [APU Frame Counter IRQ]: Despite the "Suppress Frame Counter Interrupts flag" being set, the frame counter interrupt flag *will be set* for 2 CPU cycles. (this is timed 1 cycle too early) ;;;
	; This is a farily recent discovery as of writing this test, so I'm expecting some emulators to fail this one.
	; Let me break this down:
	; 29828 Cycles after frame counter reset: $4015.6 is set to 1.
	; 29829 Cycles after frame counter reset: $4015.6 is set to 1. (The IRQ Level detector is only pulled low if the "Suppress Frame Counter Interrupts flag" is false)
	; 29830 Cycles after frame counter reset: $4015.6 is set according to the "Suppress Frame Counter Interrupts flag". (The IRQ Level detector is only pulled low if the "Suppress Frame Counter Interrupts flag" is false)
	;
	; The following 4 tests will check 29827, 29828, 29829, and 29830 cycles after resetting the frame counter, and the test after that will verify that the IRQ level detector is not pulled low. (An IRQ did not happen)
	JSR WaitForVBlank
	LDA #02
	STA $4014 ; sync with even CPU cycle
	LDA <$00  ; sync with odd CPU cycle
	LDA #$40
	STA $4017 ; 4-step mode, clear IRQ flag (The CPU was on an even cycle when writing that, so the frame counter is reset in 4 CPU cycles.)
	; the flag should be enabled in 29831 CPU cycles.
	; So let's stall for 29827 cycles, and read $4015 to see if the flag was set. That should be *the* cycle it gets set.
	JSR Clockslide_29700
	JSR Clockslide_100
	JSR Clockslide_27
	LDA $4015
	AND #$40
	BNE FAIL_FrameCounterIRQ3
	INC <currentSubTest

	;;; Test J [APU Frame Counter IRQ]: Despite the "Suppress Frame Counter Interrupts" flag being set, the frame counter interrupt flag *will be set* for 2 CPU cycles. (It happens on this cycle) ;;;
	JSR WaitForVBlank
	LDA #02
	STA $4014 ; sync with even CPU cycle
	LDA <$00  ; sync with odd CPU cycle
	LDA #$40
	STA $4017 ; 4-step mode, clear IRQ flag (The CPU was on an even cycle when writing that, so the frame counter is reset in 4 CPU cycles.)
	; the flag should be enabled in 29831 CPU cycles.
	; So let's stall for 29828 cycles, and read $4015 to see if the flag was set. That should be *the* cycle it gets set.
	JSR Clockslide_29700
	JSR Clockslide_100
	JSR Clockslide_28
	LDA $4015
	AND #$40
	BEQ FAIL_FrameCounterIRQ3
	INC <currentSubTest

	;;; Test K [APU Frame Counter IRQ]: Despite the "Suppress Frame Counter Interrupts" flag being set, the frame counter interrupt flag *will be set* for 2 CPU cycles. (It happens on this cycle too) ;;;
	JSR WaitForVBlank
	LDA #02
	STA $4014 ; sync with even CPU cycle
	LDA <$00  ; sync with odd CPU cycle
	LDA #$40
	STA $4017 ; 4-step mode, clear IRQ flag (The CPU was on an even cycle when writing that, so the frame counter is reset in 4 CPU cycles.)
	; the flag should be enabled in 29831 CPU cycles.
	; So let's stall for 29828 cycles, and read $4015 to see if the flag was set. That should be *the* cycle it gets set.
	JSR Clockslide_29700
	JSR Clockslide_100
	JSR Clockslide_29
	LDA $4015
	AND #$40
	BEQ FAIL_FrameCounterIRQ4
	INC <currentSubTest

	;;; Test L [APU Frame Counter IRQ]:  Despite the "Suppress Frame Counter Interrupts" flag being set, the frame counter interrupt flag *will be set* for 2 CPU cycles. (It does not happen on this cycle) ;;;
	JSR WaitForVBlank
	LDA #02
	STA $4014 ; sync with even CPU cycle
	LDA <$00  ; sync with odd CPU cycle
	LDA #$40
	STA $4017 ; 4-step mode, clear IRQ flag (The CPU was on an even cycle when writing that, so the frame counter is reset in 4 CPU cycles.)
	; the flag should be enabled in 29831 CPU cycles.
	; So let's stall for 29830 cycles, and read $4015 to see if the flag was set. That should be *the* cycle it gets set.
	JSR Clockslide_29700
	JSR Clockslide_100
	JSR Clockslide_30
	LDA $4015
	AND #$40
	BNE FAIL_FrameCounterIRQ4
	INC <currentSubTest

	;;; Test M [APU Frame Counter IRQ]: Despite the frame counter interrupt flag being set for those two cycles, an IRQ will not occur even if the CPU I flag is clear. ;;;
	JSR TEST_IFlagLatency_IRQPrep
	; This test is only relaible if the Interrupt Flag Latency test passes.
	JSR WaitForVBlank
	LDX #$5A
	LDA #02
	STA $4014 ; sync with even CPU cycle
	LDA <$00  ; sync with odd CPU cycle
	LDA #$40
	STA $4017 ; 4-step mode, clear IRQ flag (The CPU was on an even cycle when writing that, so the frame counter is reset in 4 CPU cycles.)
	; the flag should be enabled in 29831 CPU cycles.
	; So let's stall for 29828 cycles, and read $4015 to see if the flag was set. That should be *the* cycle it gets set.
	JSR Clockslide_29700
	JSR Clockslide_100
	JSR Clockslide_27
	CLI
	SEI	;[Read Opcode] [Poll for interrupts, and Dummy Read cycle]
	LDA <$50
	CMP #$5A
	BEQ FAIL_FrameCounterIRQ4
	INC <currentSubTest

	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

FAIL_FrameCounterIRQ4:
FAIL_FrameCounter4Step:
	JMP FAIL_AndDisableAudioChannels
;;;;;;;;;;;;;;;;;

TEST_FrameCounter4Step:
	JSR TEST_APU_Prep
	;;; Test 1 [APU Frame Counter 4-Step Mode]: Verify the timing of the first clock (read 1 cycle early. It's still going) ;;;
	LDA #2
	STA $4014
	;CPU is synced with even CPU cycle
	LDA #0
	STA $4017 ; Reset the frame counter.
	LDA #$18
	STA $4003 ; Length = 2.
	LDA #$80
	STA $4017 ; Manually clock the pulse 1 length counter.
	LDA #$40
	STA $4017 ; 4-step mode, disable IRQ (The CPU was on an odd cycle when writing that, so the frame counter is reset in 3 CPU cycles.)
	NOP  ; stall for frame counter to be reset.
	; Okay, the first time the length counters get clocked is in 14913 CPU cycles.
	JSR Clockslide_14900 ; 13 cycles to go.
	NOP ; 11 cycles to go
	NOP ; 9 cycles to go
	NOP ; 7 cycles to go
	LDA <$00 ; 4 cycles
	LDA $4015 ; the pulse channel should still be playing for 1 more cycle.
	BEQ FAIL_FrameCounter4Step
	INC <currentSubTest
	
	;;; Test 2 [APU Frame Counter 4-Step Mode]: Verify the timing of the first clock  (Read the cycle it stops);;;
	LDA #2
	STA $4014
	;CPU is synced with even CPU cycle
	LDA #0
	STA $4017 ; Reset the frame counter.
	LDA #$18
	STA $4003 ; Length = 2.
	LDA #$80
	STA $4017 ; Manually clock the pulse 1 length counter.
	LDA #$40
	STA $4017 ; 4-step mode, disable IRQ (The CPU was on an odd cycle when writing that, so the frame counter is reset in 3 CPU cycles.)
	NOP  ; stall for frame counter to be reset.
	; Okay, the first time the length counters get clocked is in 14913 CPU cycles.
	JSR Clockslide_14900 ; 13 cycles to go.
	NOP ; 11 cycles to go
	NOP ; 9 cycles to go
	NOP ; 7 cycles to go
	NOP ; 5 cycles to go
	NOP ; 3 cycles to go
	LDA $4015 ; the pulse channel should have stopped just before you read.
	BNE FAIL_FrameCounter4Step
	INC <currentSubTest
	
	;;; Test 3 [APU Frame Counter 4-Step Mode]: Verify the timing of the second clock while not inhibiting Frame Counter IRQs (read 1 cycle early. It's still going) ;;;
	LDA #2
	STA $4014
	;CPU is synced with even CPU cycle
	LDA #$18
	STA $4003	; Set the length to 2. We don't need to manually clock this one, as we're checking the timing of the 2nd clock.
	LDA #$40
	STA $4017 ; 4-step mode, disable IRQ (The CPU was on an odd cycle when writing that, so the frame counter is reset in 3 CPU cycles.)
	NOP  ; stall for frame counter to be reset.
	; Okay, the second time the length counters get clocked is in 29829 CPU cycles.
	JSR Clockslide_29820 ; 9 cycle to go
	NOP ; 7 cycles to go
	LDA <$00  ; 4 cycles to go
	LDA $4015 ; the pulse channel should still be playing for 1 more cycle.
	AND #$01  ; If you passed the Frame Counter IRQ test, bit 6 of $4015 should be set here, so it's very important we run AND #1
	BEQ FAIL_FrameCounter4Step
	INC <currentSubTest
	
	;;; Test 4 [APU Frame Counter 4-Step Mode]: Verify the timing of the second clock while not inhibiting Frame Counter IRQs (Read the cycle it stops) ;;;
	LDA #2
	STA $4014
	LDA #$18
	STA $4003 ; Set the length to 2. We don't need to manually clock this one, as we're checking the timing of the 2nd clock.
	LDA #$40
	STA $4017 ; 4-step mode, disable IRQ (The CPU was on an odd cycle when writing that, so the frame counter is reset in 3 CPU cycles.)
	NOP  ; stall for frame counter to be reset.
	; Okay, the second time the length counters get clocked is in 29829 CPU cycles.
	JSR Clockslide_29820 ; 9 cycles to go
	NOP ; 7 cycles to go
	NOP ; 5 cycles to go
	NOP ; 3 cycles to go
	LDA $4015; the pulse channel should have stopped just before you read.
	AND #$01 ; If you passed the Frame Counter IRQ test, bit 6 of $4015 should be set here, so it's very important we run AND #1
	BNE FAIL_FrameCounter4Step2
	INC <currentSubTest
	
	;;; Test 5 [APU Frame Counter 4-Step Mode]: Verify the timing of the third clock (read 1 cycle early. It's still going) ;;;
	LDA #2
	STA $4014
	;CPU is synced with even CPU cycle
	LDA #0
	STA $4017 ; Reset the frame counter.
	LDA #$28
	STA $4003 ; Length = 4.
	LDA #$80
	STA $4017 ; Manually clock the pulse 1 length counter.
	LDA #$40
	STA $4017 ; 4-step mode, disable IRQ (The CPU was on an odd cycle when writing that, so the frame counter is reset in 3 CPU cycles.)
	NOP  ; stall for frame counter to be reset.
	; Okay, the third time the length counters get clocked is in 44743 CPU cycles.
	JSR Clockslide_44730 ; 13 cycles to go.
	NOP ; 11 cycles to go
	NOP ; 9 cycles to go
	NOP ; 7  cycles to go
	LDA <$00 ; 4  cycles to go
	LDA $4015 ; the pulse channel should still be playing for 1 more cycle.
	BEQ FAIL_FrameCounter4Step2
	INC <currentSubTest	
	
	;;; Test 6 [APU Frame Counter 4-Step Mode]: Verify the timing of the third clock  (Read the cycle it stops) ;;;
	LDA #2
	STA $4014
	;CPU is synced with even CPU cycle
	LDA #0
	STA $4017 ; Reset the frame counter.
	LDA #$28
	STA $4003 ; Length = 4.
	LDA #$80
	STA $4017 ; Manually clock the pulse 1 length counter.
	LDA #$40
	STA $4017 ; 4-step mode, disable IRQ (The CPU was on an odd cycle when writing that, so the frame counter is reset in 3 CPU cycles.)
	NOP  ; stall for frame counter to be reset.
	; Okay, the third time the length counters get clocked is in 44743 CPU cycles.
	JSR Clockslide_44730 ; 13 cycles to go.
	NOP ; 11 cycles to go
	NOP ; 9 cycles to go
	NOP ; 7 cycles to go
	NOP ; 5 cycles to go
	NOP ; 3 cycles to go
	LDA $4015 ; the pulse channel should have stopped just before you read.
	BNE FAIL_FrameCounter4Step2	
	INC <currentSubTest	
	
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;
	
FAIL_FrameCounter4Step2:
	JMP FAIL_AndDisableAudioChannels
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TEST_FrameCounterSyncDMC:
	SEI
	LDA #$40        ; clear irq flag
	STA $4017
	LDA #$00        ; mode 0, frame irq enabled
	STA $4017
	JSR Clockslide_29820 ; 7
	LDA <$00
	NOP
	NOP
	LDA $4015
	AND #$40
	BNE TEST_FrameCounter4Step_Sync
TEST_FrameCounter4Step_Sync:
	LDA #$40        ; clear irq flag
	STA $4017
	RTS
;;;;;;;

FAIL_FrameCounter4Step_:
	JMP FAIL_AndDisableAudioChannels
;;;;;;;;;;;;;;;;;

FAIL_FrameCounter5Step:
	JMP FAIL_AndDisableAudioChannels
;;;;;;;;;;;;;;;;;

TEST_FrameCounter5Step:
	JSR TEST_APU_Prep
	;;; Test 1 [APU Frame Counter 5-Step Mode]: Verify the timing of the first clock (read 1 cycle early. It's still going) ;;;
	LDA #2
	STA $4014
	;CPU is synced with even CPU cycle
	LDA #0
	STA $4017 ; Reset the frame counter.
	LDA #$18
	STA $4003 ; Length = 2.
	LDA #$80  ; This upcoming write will clock it once, then we just need to wait for the second clock.
	STA $4017 ; 5-step mode, disable IRQ (The CPU was on an odd cycle when writing that, so the frame counter is reset in 3 CPU cycles.)
	LDA <$00  ; stall for 3 CPU cycles.
	; Okay, the first time the length counters get clocked is in 14912 CPU cycles.
	JSR Clockslide_14900 ; 12 cycles to go.
	NOP ; 10 cycles to go
	NOP ; 8 cycles to go
	NOP ; 6 cycles to go
	NOP ; 4 cycles
	LDA $4015 ; the pulse channel should still be playing for 1 more cycle.
	BEQ FAIL_FrameCounter5Step
	INC <currentSubTest
	
	;;; Test 2 [APU Frame Counter 5-Step Mode]: Verify the timing of the first clock  (Read the cycle it stops);;;
	LDA #2
	STA $4014
	;CPU is synced with even CPU cycle
	LDA #0
	STA $4017 ; Reset the frame counter.
	LDA #$18
	STA $4003 ; Length = 2.
	LDA #$80  ; This upcoming write will clock it once, then we just need to wait for the second clock.
	STA $4017 ; 5-step mode, disable IRQ (The CPU was on an odd cycle when writing that, so the frame counter is reset in 3 CPU cycles.)
	LDA <$00  ; stall for 3 CPU cycles.
	; Okay, the first time the length counters get clocked is in 14912 CPU cycles.
	JSR Clockslide_14900 ; 12 cycles to go.
	NOP ; 10 cycles to go
	NOP ; 8 cycles to go
	NOP ; 6 cycles to go
	LDA <$00 ; 3 cycle to go
	LDA $4015 ; the pulse channel should have stopped just before you read.
	BNE FAIL_FrameCounter5Step
	INC <currentSubTest
	
	;;; Test 3 [APU Frame Counter 5-Step Mode]: Verify the timing of the second clock (read 1 cycle early. It's still going) ;;;
	LDA #2
	STA $4014
	;CPU is synced with even CPU cycle
	LDA #0
	STA $4017 ; Reset the frame counter.
	LDA #$28
	STA $4003 ; Length = 4.
	LDA #$80  ; This upcoming write will clock it once, then we just need to wait for the second clock.
	STA $4017 ; clock it an extra time.
	STA $4017 ; 5-step mode, disable IRQ (The CPU was on an odd cycle when writing that, so the frame counter is reset in 3 CPU cycles.)
	LDA <$00  ; stall for 3 CPU cycles.
	; Okay, the second time the length counters get clocked is in 37280 CPU cycles.
	JSR Clockslide_37270 ; 10 cycles to go.
	NOP ; 8 cycles to go
	NOP ; 6 cycles to go
	NOP ; 4 cycles
	LDA $4015 ; the pulse channel should still be playing for 1 more cycle.
	BEQ FAIL_FrameCounter5Step
	INC <currentSubTest
	
	;;; Test 4 [APU Frame Counter 5-Step Mode]: Verify the timing of the second clock  (Read the cycle it stops);;;
	LDA #2
	STA $4014
	;CPU is synced with even CPU cycle
	LDA #0
	STA $4017 ; Reset the frame counter.
	LDA #$28
	STA $4003 ; Length = 4.
	LDA #$80  ; This upcoming write will clock it once, then we just need to wait for the second clock.
	STA $4017 ; clock it an extra time.
	STA $4017 ; 5-step mode, disable IRQ (The CPU was on an odd cycle when writing that, so the frame counter is reset in 3 CPU cycles.)
	LDA <$00  ; stall for 3 CPU cycles.
	; Okay, the second time the length counters get clocked is in 37280 CPU cycles.
	JSR Clockslide_37270 ; 10 cycles to go.
	NOP ; 8 cycles to go
	NOP ; 6 cycles to go
	LDA <$00 ; 3 cycle to go
	LDA $4015 ; the pulse channel should have stopped just before you read.
	BNE FAIL_FrameCounter5Step2
	INC <currentSubTest
	
	;;; Test 5 [APU Frame Counter 5-Step Mode]: Verify the timing of the third clock (read 1 cycle early. It's still going) ;;;
	LDA #2
	STA $4014
	;CPU is synced with even CPU cycle
	LDA #0
	STA $4017 ; Reset the frame counter.
	LDA #$28
	STA $4003 ; Length = 4.
	LDA #$80  ; This upcoming write will clock it once, then we just need to wait for the second clock.
	STA $4017 ; 5-step mode, disable IRQ (The CPU was on an odd cycle when writing that, so the frame counter is reset in 3 CPU cycles.)
	LDA <$00  ; stall for 3 CPU cycles.
	; Okay, the third time the length counters get clocked is in 52194 CPU cycles.
	JSR Clockslide_52180 ; 14 cycles to go.
	NOP ; 12 cycles to go
	NOP ; 10 cycles to go
	NOP ; 8 cycles to go
	NOP ; 6 cycles to go
	LDA $4015 ; the pulse channel should still be playing for 1 more cycle.
	BEQ FAIL_FrameCounter5Step2
	INC <currentSubTest
	
	;;; Test 6 [APU Frame Counter 5-Step Mode]: Verify the timing of the third clock  (Read the cycle it stops);;;
	LDA #2
	STA $4014
	;CPU is synced with even CPU cycle
	LDA #0
	STA $4017 ; Reset the frame counter.
	LDA #$28
	STA $4003 ; Length = 4.
	LDA #$80  ; This upcoming write will clock it once, then we just need to wait for the second clock.
	STA $4017 ; 5-step mode, disable IRQ (The CPU was on an odd cycle when writing that, so the frame counter is reset in 3 CPU cycles.)
	LDA <$00  ; stall for 3 CPU cycles.
	; Okay, the third time the length counters get clocked is in 52194 CPU cycles.
	JSR Clockslide_52180 ; 14 cycles to go.
	NOP ; 12 cycles to go
	NOP ; 10 cycles to go
	NOP ; 8 cycles to go
	NOP ; 6 cycles to go
	LDA <$00 ; 3 cycle to go
	LDA $4015 ; the pulse channel should have stopped just before you read.
	BNE FAIL_FrameCounter5Step2

	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

FAIL_FrameCounter5Step2:
FAIL_DeltaModulationChannel:
	JMP FAIL_AndDisableAudioChannels
;;;;;;;;;;;;;;;;;

TEST_DeltaModulationChannel:
	
	; Special thanks to blargg, as I am pretty much just going to copy the test they wrote in 2005.
	LDA #$00
	STA $4012 ; Sample address $C000.
	LDA #1
	STA $4013 ; length of #1 * 16 + 1 = 17 bytes.
	LDA #$0F
	STA $4010 ; Fastest sample rate.
	JSR Clockslide_4000
	;;; Test 1 [APU Delta Modulation Channel]: Verify the DMC works ;;;
	; In other words, if the DMC is playing audio, bit 4 of address $4015 will be set.
	LDA #$10
	STA $4015
	JSR Clockslide_4320
	LDA $4015	; the DMC should be playing by now.
	AND #$10
	BEQ FAIL_DeltaModulationChannel	; If bit 4 is not set, then fail the test.
	JSR Clockslide_4320
	LDA $4015	; the DMC should have stopped by now.
	AND #$10
	BNE FAIL_DeltaModulationChannel	; If bit 4 is still set, then fail the test.
	INC <currentSubTest
	
	;;; Test 2 [APU Delta Modulation Channel]: Restarting the DMC should re-load the sample length. ;;;
	LDA #$10
	STA $4015
	JSR Clockslide_4320 ; as we have established, the DMC is now playing.
	LDA #$00
	STA $4015
	LDA #$10
	STA $4015	; Restart the DMC! (The sample length should be reset to 17)
	JSR Clockslide_4320
	LDA $4015	; the DMC should still be playing.
	AND #$10
	BEQ FAIL_DeltaModulationChannel	; If bit 4 is not set (the sample ended), then fail the test.
	JSR Clockslide_4320
	LDA $4015	; the DMC should have stopped by now.
	AND #$10
	BNE FAIL_DeltaModulationChannel	; If bit 4 is still set, then fail the test.
	INC <currentSubTest

	;;; Test 3 [APU Delta Modulation Channel]: Writing $10 to $4015 should start palying a new sample if the previous one ended. ;;;
	LDA #$10
	STA $4015
	JSR Clockslide_8640	; wait for sample to end.
	STA $4015	; write $10 to $4015 again.
	JSR Clockslide_4320
	LDA $4015	; the DMC should be playing.
	AND #$10
	BEQ FAIL_DeltaModulationChannel
	INC <currentSubTest
	JSR Clockslide_4320
	
	;;; Test 4 [APU Delta Modulation Channel]: Writing $10 to $4015 while a sample is currently playing shouldn't affect anything. ;;;
	; Keep in mind, in test 2 we disabled the DMC before writing $10, so the sample was no longer playing in that situation. We're not going to disable it in this test.
	LDA #$10
	STA $4015
	JSR Clockslide_4320 ; as we have established, the DMC is now playing.
	STA $4015	; Write $10 to $4015 again, while the sample is still playing. Nothing changes, don't reload the length or anything.
	LDA $4015	; the DMC should still be playing.
	AND #$10
	BEQ FAIL_DeltaModulationChannel2
	JSR Clockslide_4320
	LDA $4015	; the DMC should have stopped by now.
	AND #$10
	BNE FAIL_DeltaModulationChannel2
	INC <currentSubTest
	
	;;; Test 5 [APU Delta Modulation Channel]: Writing $00 to $4015 will immediately stop the sample. ;;;
	LDA #$10
	STA $4015
	JSR Clockslide_4320 ; as we have established, the DMC is now playing.
	LDA #0
	STA $4015	; Write $10 to $4015 again, while the sample is still playing. Nothing changes, don't reload the length or anything.
	LDA $4015	; the DMC should still be playing.
	AND #$10
	BNE FAIL_DeltaModulationChannel2
	INC <currentSubTest

	;;; Test 6 [APU Delta Modulation Channel]: Writing to $4013 doesn't change the sample length of the currently playing sample. ;;;
	LDA #$10
	STA $4015	; start the sample.
	LDA #2
	STA $4013	; 33 byte sample.	
	JSR Clockslide_8640
	LDA $4015	; the DMC should have stopped by now.
	AND #$10
	BNE FAIL_DeltaModulationChannel2
	; but now the length is 33.
	LDA #$10
	STA $4015
	LDA #1
	STA $4013	; set the sample size back to 17.
	JSR Clockslide_12960
	LDA $4015	; the DMC should still be playing.
	AND #$10
	BEQ FAIL_DeltaModulationChannel2
	JSR Clockslide_4320
	LDA $4015	; the DMC should have stopped by now.
	AND #$10
	BNE FAIL_DeltaModulationChannel2
	INC <currentSubTest

	;;; Test 7 [APU Delta Modulation Channel]: The DMC IRQ Flag should not be set when disabled. ;;;
	; Friendly reminder that in the prep before test 1, we run:
	; LDA #$0F
	; STA $4010
	; which, in addition to using the fastest sample rate, disables the DMC IRQ.
	LDA #$10
	STA $4015 ; start sample.
	JSR Clockslide_8640 ; wait for sample to end.
	LDA $4015 ; Bit 7 (which sets the Negative flag) is set if the DMC IRQ flag is set.
	BMI FAIL_DeltaModulationChannel2	; in this case, it should not be set.
	INC <currentSubTest

	;;; Test 8 [APU Delta Modulation Channel]: The DMC IRQ Flag should be set when enabled, and a sample ends. ;;;
	SEI			; prevent IRQs from actually interrupting the CPU.
	LDA #$8F	; enable the IRQ (and continue using the fastest rate)
	STA $4010
	LDA #$10
	STA $4015 ; start sample.
	JSR Clockslide_8640 ; wait for sample to end.
	LDA $4015 ; Bit 7 (which sets the Negative flag) is set if the DMC IRQ flag is set.
	BPL FAIL_DeltaModulationChannel2	; in this case, it should be set.
	INC <currentSubTest
	BNE FAIL_DeltaModulationChannelContinue ; branch around the fail condition.

FAIL_DeltaModulationChannel2:
	JMP FAIL_AndDisableAudioChannels

FAIL_DeltaModulationChannelContinue:
	;;; Test 9 [APU Delta Modulation Channel]: Reading $4015 does not clear the IRQ flag. ;;;
	LDA $4015 ; Bit 7 should still be set.
	BPL FAIL_DeltaModulationChannel2
	INC <currentSubTest

	;;; Test A [APU Delta Modulation Channel]: Writing to $4015 does clear the IRQ flag. ;;;
	LDA #$10  ; Demonstrated by writing $10, but writing a zero will also clear the IRQ flag.
	STA $4015
	LDA $4015
	BMI FAIL_DeltaModulationChannel2
	LDA #$0
	STA $4015
	INC <currentSubTest

	;;; Test B [APU Delta Modulation Channel]: Disabling the IRQ flag clears the IRQ flag. ;;;
	LDA #$10
	STA $4015 ; start sample.
	JSR Clockslide_8640 ; wait for sample to end.
	; As we have established in test 8, the IRQ flag is currently enabled.
	LDA #$0F
	STA $4010	; disable the IRQ flag.
	LDA $4015
	BMI FAIL_DeltaModulationChannel2
	INC <currentSubTest

	;;; Test C [APU Delta Modulation Channel]: Looping samples should loop. ;;;
	; In other words, bit 4 of address $4015 will be set until you force the sample to stop.
	LDA #$4F	; loop! (and the fastest sample rate)
	STA $4010
	LDA #$10
	STA $4015
	JSR Clockslide_50000 ; wait for a fairly long amount of time.
	LDA $4015
	AND #$10
	BEQ FAIL_DeltaModulationChannel2 ; it should still be playing, since it loops.
	LDA #$00
	STA $4015	; stopping the DMC should still stop the looping sample.
	; You might fail this test if you are waiting 3 or 4 CPU cyles to disable the DMC Channel.
	LDA $4015
	AND #$10
	BNE FAIL_DeltaModulationChannel2
	INC <currentSubTest

	;;; Test D [APU Delta Modulation Channel]: Looping samples should not set the IRQ flag when they loop. ;;;
	LDA #$CF	; loop + enable IRQ flag! (and the fastest sample rate)
	STA $4010
	LDA #$10
	STA $4015
	JSR Clockslide_50000 ; wait for a fairly long amount of time.
	LDA $4015
	BMI FAIL_DeltaModulationChannel2 ; The IRQ flag is not set on looping samples.
	STA $4015
	LDA $4015	; Even if the sample is force-stopped, the IRQ flag is not set.
	BMI FAIL_DeltaModulationChannel2
	INC <currentSubTest

	;;; Test E [APU Delta Modulation Channel]: Clearing the looping flag and then setting it again should keep the sample looping. ;;;
	LDA #$10
	STA $4015
	JSR Clockslide_26352
	LDA #$8F	; Disable loop
	STA $4010
	LDA #$CF
	STA $4010	; enable loop again
	JSR Clockslide_50000 ; wait for a fairly long amount of time.
	LDA $4015
	AND #$10
	BEQ FAIL_DeltaModulationChannel3 ; it should still be playing.
	LDA #$00
	STA $4015
	INC <currentSubTest

	;;; Test F [APU Delta Modulation Channel]: Clearing the looping flag will not immediately end the sample. The sample will then play for it's remaining bytes. ;;;
	LDA #$10
	STA $4015
	JSR Clockslide_26352
	LDA #$8F	; Disable loop
	STA $4010
	LDA $4015
	BMI FAIL_DeltaModulationChannel3 ; The IRQ flag should not have been set.
	AND #$10
	BEQ FAIL_DeltaModulationChannel3 ; it should still be playing.
	JSR Clockslide_4320
	LDA $4015	; the DMC should have stopped by now.
	BPL FAIL_DeltaModulationChannel3 ; The IRQ flag should have been set.
	AND #$10
	BNE FAIL_DeltaModulationChannel3
	INC <currentSubTest

	;;; Test G [APU Delta Modulation Channel]: A looping sample will re-load the sample length from $4013 every time the sample loops. ;;;
	LDA #$CF	; loop + enable IRQ flag! (and the fastest sample rate)
	STA $4010
	LDA #$10
	STA $4015
	JSR Clockslide_26352
	LDA #02
	STA $4013	; sample length is now 33.
	JSR Clockslide_4320
	LDA #$8F	; disable the loop
	STA $4010
	JSR Clockslide_10000
	LDA $4015
	BMI FAIL_DeltaModulationChannel3 ; The IRQ flag should not have been set.
	AND #$10
	BEQ FAIL_DeltaModulationChannel3 ; it should still be playing.
	JSR Clockslide_4320
	LDA $4015	; the DMC should have stopped by now.
	BPL FAIL_DeltaModulationChannel3 ; The IRQ flag should have been set.
	AND #$10
	BNE FAIL_DeltaModulationChannel3
	INC <currentSubTest
	BNE FAIL_DeltaModulationChannelC2 ; branch around another fail condition.

FAIL_DeltaModulationChannel3:
	JMP FAIL_AndDisableAudioChannels
;;;;;;;;;;;;;;;;;
	
FAIL_DeltaModulationChannelC2:
	;;; Test H [APU Delta Modulation Channel]: Writing $00 to $4013 should result in the following sample being 1 byte long. ;;;
	LDA #$0F	; disable IRQ and loop.
	STA $4010
	LDA #0
	STA $4013 ; 1-byte sample.
	LDA #$10
	STA $4015
	JSR Clockslide_1728
	LDA $4015	; the DMC should have stopped by now.
	AND #$10
	BNE FAIL_DeltaModulationChannel3
	INC <currentSubTest

	;;; Test I [APU Delta Modulation Channel]: There should be a one-byte buffer that's filled immediately if empty. ;;;
	LDA #$8F
	STA $4010
	LDA #1
	STA $4013	; 17 byte sample.
	LDA #$10
	STA $4015
	LDA #$10
TEST_DeltaModulationChannelTestILoop:
	AND $4015	; Loop until the sample ends.
	BNE TEST_DeltaModulationChannelTestILoop
	JSR Clockslide_1728
	JSR Clockslide_30
	LDA #0
	STA $4013	; 1 byte sample.
	LDA #$10
	STA $4015
	LDA $4015
	AND #$90	; The IRQ flag should be set, and the sample should have ended.
	CMP #$80
	BNE FAIL_DeltaModulationChannel3
	LDA #$10
	STA $4015	; we go again.
	LDA $4015	
	BEQ FAIL_DeltaModulationChannel3
	; at this point we are playing audio.
	JSR Clockslide_1728
	; and now we aren't
	LDA $4015	
	AND #$10
	BNE FAIL_DeltaModulationChannel3
	INC <currentSubTest
	; Thanks again to blargg for those tests!
	; Now to extend this suite for some specific timing tests.
	
	;;; Test J [APU Delta Modulation Channel]: Check that the DMASync_50CyclesRemaining function works in this emulator ;;;	
	JSR DMASync_50CyclesRemaining
	JSR Clockslide_47
	LDA $4000	; [Read Opcode] [Read Operand] [Read Operand] [DMC DMA! Databus = $00] [Read Open Bus]
	BNE FAIL_DeltaModulationChannel3	; and if the read from $4000 wasn't $00, then fail the test.
	INC <currentSubTest

	;;; Test K [APU Delta Modulation Channel]: Check that that Sample Address overflows to $8000 instead of $0000 ;;;
	; This requires the DMC DMA to update the databus, so you need to have open bus emulation correct.	
	;
	; Just so you know, the value at address $8000 is $EA. (A NOP instruction)
	JSR DMASync_50CyclesRemaining
	LDA #4		;+2
	STA $4013	;+4 sample length = #4 * 16 + 1 = 65 (or $41 in hex)
	LDA #$FF	;+2
	STA $4012	;+4 Sample address is $FFC0
	LDA #$4F	;+2
	STA $4010	;+4 fastest rate. (also loop, so it refreshes the address and length)
	LDX #$0	;+2
	; 30 CPU cycles left.
	JSR Clockslide_30
	; DMA that reloads all the stuff.
	; Next DMA in 428 cycles
	JSR Clockslide_400
	JSR Clockslide_25
	; Next DMA in 3 cycles
TEST_DMC_OverflowLoop: ; DMA every 432 CPU cycles.
	LDA $4000 ;+3 [DMA start] +5	Read from the DMC DMA's modification to the data bus.
	JSR Clockslide_400
	JSR Clockslide_17	
	INX	; +2   Increment X for the next loop.
	CPX #$41 ; +2   If X = $41, we exit the loop.
	BNE TEST_DMC_OverflowLoop ; +3 if looping. +2 if not. (total outside the clockslide = 29. 432-29 = 403)
	; now that A = the $40th byte read:
	CMP #$EA
	BNE FAIL_DeltaModulationChannel4
	INC <currentSubTest

	;;; Test L [APU Delta Modulation Channel]: Check that the DMA will be delayed by 1 CPU cycle if the write to $4015 (which enables the DMC) occurs 2 cycles before the DMA timer reaches 0. ;;;
	; Keep in mind, at the moment we're writing $10 to $4015, the DMC sample still has 1 bit remaining before the buffer is cleared.
	; Which poses an interesting question. Do we run a load DMA (because we wrote to $4015), or a relaod DMA (because the last bit in the buffer has been read)? 
	; So the order of operations is: 
	; - Write $10 to the $4015. The Delta Modulation Channel will be enabled in 3 CPU cycles.
	; - Timer reaches zero, and the last bit in the buffer has been read, attempt to run a DMC DMA on the next CPU cycle.
	; - We're ready for the DMA, but the Delta Modulation Channel isn't enabled yet! Wait another cycle.
	; - The DMC is enabled this time, so the DMA occurs.
	;
	; Per my current understanding, if a sample is playing, you disable the DMC, and the final bit is read from the buffer, the DMA will still attempt to run every cycle until the DMC is re-enabled.
	; It just doesn't run until the DMA is enabled, 3 or 4 cycles after a write to $4015.
	JSR DMASync_50CyclesRemaining
	LDA #0		;+2
	STA $4015	;+4 disable DMC.
	LDA #0		;+2
	STA $4013	;+4
	LDA #$4F	;+2
	STA $4010	;+4 loop sample. (and use the fastest sample rate)
	; 32 cycles remaining until the DMC timer hits 0
	JSR Clockslide_25
	; The timer is now 7
	LDA #$10	;+2	(5 cycles left)
	STA $4015	; Enable the DMC with 2 cycles until the DMA timer hits 0)
	; it will be delayed by 1 cycle, causing an alignment cycle. This DMA will be 3 CPU cycles long instead of the typical 4.
	LDA <$00 ; +3 cycles.	[read opcode] [read operand] [attempt DMC DMA, the DMC Channel isn't enabled yet, so read from address $0000]
	; +3 cycles from the DMA. [Get Halt] [Put] [Get] ; 
	; now we wait for the DMA again.
	; it will occur in 432-5 (=427) cycles.
	JSR Clockslide_400	; 27 cycles left.
	JSR Clockslide_24	; 3 cycles left.
	LDA $4000 ; [read opcode] [read operand] [read operand] [DMC DMA] [Read open bus]
	BNE FAIL_DeltaModulationChannel4
	INC <currentSubTest
	
	;;; Test M [APU Delta Modulation Channel]: Check that the DMA will be delayed by 2 CPU cycles if the write to $4015 occurs 1 cycles before the DMA timer reaches 0. ;;;
	; The order of operations is: 
	; - Write $10 to the $4015. The Delta Modulation Channel will be enabled in 3 CPU cycles.
	; - Timer reaches zero, and the last bit in the buffer has been read, attempt to run a DMC DMA on the next CPU cycle.
	; - We're ready for the DMA, but the Delta Modulation Channel isn't enabled yet! Wait another cycle.
	; - We're ready for the DMA, but the Delta Modulation Channel isn't enabled yet! Wait another cycle.
	; - The DMC is enabled this time, so the DMA occurs.
	JSR DMASync_50CyclesRemaining
	LDA #0		;+2
	STA $4015	;+4 disable DMC.
	LDA #0		;+2
	STA $4013	;+4
	LDA #$4F	;+2
	STA $4010	;+4 loop sample. (and use the fastest sample rate)
	; 32 cycles remaining until the DMC timer hits 0
	JSR Clockslide_26
	; The timer is now 6
	LDA #$10	;+2	(4 cycles left)
	STA $4015	; Enable the DMC with 1 cycles until the DMA timer hits 0)
	; it will be delayed by 1 cycle, causing an alignment cycle. This DMA will be 3 CPU cycles long instead of the typical 4.
	LDA <$00 ; +3 cycles.	[read opcode] [attempt DMC DMA, the DMC Channel isn't enabled yet, so read operand] [attempt DMC DMA, the DMC Channel isn't enabled yet, so read from address $0000]
	; +4 cycles from the DMA. [Put] [Get Halt] [Put] [Get] ; 
	; now we wait for the DMA again.
	; it will occur in 432-5 (=427) cycles.
	JSR Clockslide_400	; 27 cycles left.
	JSR Clockslide_23	; 3 cycles left.
	LDA $4000 ; [read opcode] [read operand] [read operand] [DMC DMA] [Read open bus]
	BNE FAIL_DeltaModulationChannel4
	INC <currentSubTest
	BNE FAIL_DeltaModulationChannelC3
FAIL_DeltaModulationChannel4:
	JMP FAIL_AndDisableAudioChannels
FAIL_DeltaModulationChannelC3:

	;;; Test N [APU Delta Modulation Channel]: Check that the DMA will be delayed by 3 CPU cycles if the write to $4015 occurs the same CPU cycle the DMA timer reaches 0. ;;;
	; The order of operations is: 
	; - Write $10 to the $4015. The Delta Modulation Channel will be enabled in 3 CPU cycles.
	; 	- On the same cycle, the timer reaches zero, and the last bit in the buffer has been read, attempt to run a DMC DMA on the next CPU cycle.
	; - We're ready for the DMA, but the Delta Modulation Channel isn't enabled yet! Wait another cycle.
	; - We're ready for the DMA, but the Delta Modulation Channel isn't enabled yet! Wait another cycle.
	; - We're ready for the DMA, but the Delta Modulation Channel isn't enabled yet! Wait another cycle.
	; - The DMC is enabled this time, so the DMA occurs.
	JSR DMASync_50CyclesRemaining
	LDA #0		;+2
	STA $4015	;+4 disable DMC.
	LDA #0		;+2
	STA $4013	;+4
	LDA #$4F	;+2
	STA $4010	;+4 loop sample. (and use the fastest sample rate)
	; 32 cycles remaining until the DMC timer hits 0
	JSR Clockslide_27
	; The timer is now 5
	LDA #$10	;+2	(3 cycles left)
	STA $4015	; Enable the DMC with 0 cycles until the DMA timer hits 0)
	; it will be delayed by 1 cycle, causing an alignment cycle. This DMA will be 3 CPU cycles long instead of the typical 4.
	LDA <$00 ; +3 cycles.	[attempt DMC DMA, the DMC Channel isn't enabled yet, so read opcode] [attempt DMC DMA, the DMC Channel isn't enabled yet, so read operand] [attempt DMC DMA, the DMC Channel isn't enabled yet, so read from address $0000]
	; +3 cycles from the DMA. [Get Halt] [Put] [Get]
	; now we wait for the DMA again.
	; it will occur in 432-5 (=427) cycles.
	JSR Clockslide_400	; 27 cycles left.
	JSR Clockslide_22	; 3 cycles left.
	LDA $4000 ; [read opcode] [read operand] [read operand] [DMC DMA] [Read open bus]
	BNE FAIL_DeltaModulationChannel4
	
	;; END OF TEST ;;
	LDA #$00
    STA $4015	; disable all audio channels.
	LDA #1
	RTS
;;;;;;;

FAIL_DMC_Conflicts1:
	JMP FAIL_AndDisableAudioChannels
;;;;;;;;;;;;;;;;;

TEST_DMABusConflict:
	; A very similar test to [APU Register Activation]. In fact, I highly suggest you pass that test before looking into this one, as it's slightly more complicated.
	; As a recap, when the 6502 address bus is in the range $4000 to $401F, the APU registers are active (including mirrors of them.)
	; Except the registers aren't just active from $4000 to $40FF. They are active everywhere. Every $20 bytes across the entire address space will be mirrors of the APU registers.
	; Luckily, only 3 of the APU registers have readable values, and the rest are just open bus.
	; So when the 6502 address bus is in the range $4000 to $401F, a DMC DMA reading a sample at address, for example, $FF16 will encounter a bus conflict with controller port 1!
	; The bus conflict is works like this:
	;	- Bits 5, 6, and 7 of the controller port are typically open bus, but in this instance, those 3 bits will be bits 5, 6, and 7 of the sample value read by the DMA, while the rest of the bits are a standard controller read.
	; 	- You could easily emulate this as two lines:
	; 		- Read(CurrentSampleAddress); 
	; 		- Read(0x4000 | (CurrentSampleAddress & 0x1F)); 
	;	- But of course, in reality there is only a single read per CPU cycle.
	;	- (friendly reminder that reading from $4015 does not update the data bus)
	;
	; Anyway, if you passed [APU Register Activation], you should have a good idea at what's going on.
	; We're going to be running a series of DMA's, and syncing them all with a read from $4000, such that the databus is changed by the DMA 1 cycle before the Open bus read.
	; Then, if the bus conflict happens, we can see that will well timed DMAs and open bus reads.
	;
	; Please don't press anything on controller 2 during this test. :)

	JSR ReadController1 ; This strobes controllers and read controller 1 8 times. Controller 2 is left unread, so again, holding buttons on controlelr 2 will fail this test.
	
	;;; Test 1 [DMA Bus Conflicts]: Check that the DMASync_50CyclesRemaining function works in this emulator ;;;	
	JSR DMASync_50CyclesRemaining
	JSR Clockslide_47
	LDA $4000	; [Read Opcode] [Read Operand] [Read Operand] [DMC DMA! Databus = $00] [Read Open Bus]
	BNE FAIL_DMC_Conflicts1	; and if the read from $4000 wasn't $00, then fail the test.
	INC <currentSubTest

	;;; Test 2 [DMA Bus Conflicts]: The bus conflicts exist. ;;;
	; I know, we're jumping right into this one.
	; Anyway, here's how the test works.
	; I'm going to read about $40 samples with DMAs, and compare the values read with a look-up-table answer sheet. It's one of those.
	; And hey, for the fun of it, let's also set the frame counter IRQ flag, which gets cleared by reading $4015.
	LDA #$00
	STA $4017
	JSR Clockslide_30000
	; Okay cool, the frame counter IRQ flag should now be set.
	
	JSR DMASync_50CyclesRemaining
	LDA #4		;+2
	STA $4013	;+4 sample length = #4 * 16 + 1 = 65 (or $41 in hex)
	LDA #$BF	;+2
	STA $4012	;+4 Sample address is $FFC0
	LDA #$4F	;+2
	STA $4010	;+4 fastest rate. (also loop, so it refreshes the address and length)
	LDX #$0	;+2
	; 30 CPU cycles left.
	JSR Clockslide_30
	; DMA that reloads all the stuff.
	; Next DMA in 428 cycles
	LDA #$00
	STA $4017	; Keep the interrupt flag set, but refresh the timer.
	JSR Clockslide_400
	JSR Clockslide_19
	; Next DMA in 3 cycles
TEST_DMC_ConflictLoop: ; DMA every 432 CPU cycles.
	LDA $4000 ;+3 [DMA start] +5	Read from the DMC DMA's modification to the data bus.
	STA $500, X
	JSR Clockslide_400
	LDA #$00
	STA $4017	; Keep the interrupt flag set, but refresh the timer.
	NOP
	NOP
	NOP
	INX	; +2   Increment X for the next loop.
	CPX #$40 ; +2   If X = $40, we exit the loop.
	BNE TEST_DMC_ConflictLoop ; +3 if looping. +2 if not. (total outside the clockslide = 29. 432-29 = 403)
	; Cool, now all $40 of those reads are stored at address $500.
	LDX #0
TEST_DMC_Conflict_AnswerLoop:
	LDA $500, X
	CMP TEST_DMC_Conflicts_AnswerKey, X
	BNE TEST_DMC_Conflict_CheckFamicom
	LDA #$00
	STA $4017	; Keep the interrupt flag set, but refresh the timer.
	INX
	CPX #$40
	BNE TEST_DMC_Conflict_AnswerLoop
	LDA #5
	STA <$50	; pass code 1. (nes)
	BNE TEST_DMC_Test3
	
TEST_DMC_Conflict_CheckFamicom:
	LDX #0
TEST_DMC_Conflict_AnswerLoop_Famicom:
	LDA $500, X
	CMP TEST_DMC_Conflicts_AnswerKey_Famicom, X
	BNE FAIL_DMC_Conflicts
	LDA #$00
	STA $4017	; Keep the interrupt flag set, but refresh the timer.
	INX
	CPX #$40
	BNE TEST_DMC_Conflict_AnswerLoop_Famicom
	LDA #9
	STA <$50	; pass code 2. (famicom)
	
TEST_DMC_Test3:
	INC <currentSubTest

	;;; Test 3 [DMA Bus Conflicts]: The bus conflicts clears the APU Frame Counter Interrupt Flag. ;;;
	LDA $4015	; The bus conflict will read from $4015, clearing the frame counter's interrupt flag. 
	AND #$40
	BNE FAIL_DMC_Conflicts	; so if this is non-zero, the flag was still set, failing the test.
	
	;; END OF TEST ;;
	LDA #$00
    STA $4015	; disable all audio channels.
	LDA <$50
	RTS
;;;;;;;
	
FAIL_DMC_Conflicts:
	JMP FAIL_AndDisableAudioChannels
;;;;;;;;;;;;;;;;;
	
TEST_VblankSync_PreTest:
	; This runs almost immediately after power on, in order to check if the VBlank Sync routine won't loop infinitely.
	LDA $2002
	BPL TEST_VblankSync_PreTest
	; We are now in vblank, but there's a large window in which this could have occured.
	; LDA [Read Opcode] [Read Operand] [Read Operand] * [Read $2002]
	; BPL [Read Opcode] [Read Operand] [Dummy Read, move PC]
	; A 7 CPU cycle window is a bit large.
	; At the moment we execute this code, all we know is that the vblank flag was set between 3 and 10 CPU cycles ago.
	; So the vblank flag will be set between 29770.66 and 29777.66 CPU cycles.
	; With rendering disabled, every 29781 CPU cycles will "fall back" 1 PPU cycle.
	; The plan: Read $2002 in exactly 29770 CPU cycles. (0.66 CPU cycles too early.)
	; Then, stall for 29781 CPU cycles, and read $2002 again.
	; This will take a minimum of 3 frames to exit, and a maximum of 24 frames.
	; If it takes longer than 24 frames, it can be assumed the frame timing has the wrong number of CPU/PPU cycles, and could never use my vblank cync routines.
	LDX #0 ; +2 cycles.
	JSR Clockslide_29765
TEST_VblSyncPreTest_Loop:
	LDA $2002	;+3 [vbl?] +1
	BMI TEST_VblSyncPreTest_GoodEnding; +2
	INX; +2
	CPX #25 ; +2
	BEQ TEST_VblSyncPreTest_BadEnding ; +2
	JSR Clockslide_29766
	JMP TEST_VblSyncPreTest_Loop;+3
	
TEST_VblSyncPreTest_GoodEnding:
	LDA #1
	STA <result_VblankSync_PreTest
	RTS
TEST_VblSyncPreTest_BadEnding:
	LDA #$80	; I use $80 so my VBL sync routine can start by running `LDA <result_VblankSync_PreTest` `BMI FAIL`
	STA <result_VblankSync_PreTest
	RTS
;;;;;;;

TEST_ImpliedDummyRead_BRKed:
	; This is where the PC *should* go after reading an opcode from $4015.
	PLA
	PLA
	PLA; pull off 3 bytes from the BRK instruction.
	PLA
	PLA
	PLA; pull off 3 more bytes from the JSR and PHA instructions.
	LDA #1
	STA <$60	; write to $51. $50 currently has the backup of address $A5 in it.
	JMP TEST_ImpliedDummyRead_Post
	
TEST_ImpliedDummyRead_BRKed2:
	; This is where the PC *should* go after reading an opcode from $2021.
	PLA
	PLA
	PLA; pull off 3 bytes from the BRK instruction.
	PLA
	PLA; pull off 2 more bytes from the JSR instruction.
	PLA
	PLA; pull off 2 more bytes from the other JSR instruction.
	LDA #1
	STA <$60	; write to $60. $50 currently has the backup of address $A5 in it.
	JMP TEST_ImpliedDummyRead_Post2
	
TEST_ImpliedDummyRead_BRKed3:
	; This is where the PC *should* go after reading an opcode from $4015 during the third loop of tests.
	PLA
	PLA; pull off 2 bytes from the RTS prep.
	PLA
	PLA; pull off 2 bytes from the JSR
	PLA
	PLA
	PLA; pull off 3 more bytes from the RTI.
	LDA #1
	STA <$60	; write to $51. $50 currently has the backup of address $A5 in it.
	JMP TEST_ImpliedDummyRead_PostPHP
	
TEST_ImpliedDummyRead_BRKed4:
	; This is where the PC *should* go after reading an opcode from $4015 during the third loop of tests.
	PLA
	PLA
	PLA; pull off 3 bytes from the BRK instruction.
	PLA
	PLA
	PLA; pull off 3 more bytes from the JSR and PHA instructions.
	LDA #1
	STA <$60	; write to $51. $50 currently has the backup of address $A5 in it.
	JMP TEST_ImpliedDummyRead_PostPHA
	
TEST_ImpliedDummyRead_BRKed5:
	; This is where the PC *should* go after reading an opcode from $4015 during the third loop of tests.
	PLA
	PLA
	PLA; pull off 3 bytes from the BRK instruction.
	PLA
	PLA; pull off 2 more bytes from the JSR instruction.
	PLA
	PLA; pull off 2 more bytes from the JSR instruction.
	LDA #1
	STA <$60	; write to $51. $50 currently has the backup of address $A5 in it.
	JMP TEST_ImpliedDummyRead_Post5
	
	TEST_ImpliedDummyRead_BRKed6:
	; This is where the PC *should* go after reading an opcode from $4015 during the third loop of tests.
	PLA
	; Check if we ran a BRK or if this was an IRQ.
	AND #$10
	BEQ TEST_ImpliedDummyReadIRQed6
	PLA
	PLA; pull off 3 bytes from the RTI prep.
	PLA
TEST_ImpliedDummyReadIRQed6:
	PLA
	PLA; pull off 3 more bytes from the BRK.
	; no need to write to $60 for this one.
	JMP TEST_ImpliedDummyRead_Post6
	
Test_ImpliedDummyRead_WaitForFrameCounterFlag:
	LDX <Copy_X			; +2 cycles (This makes it easier to follow in a tracelog.)
	LDA #$4F			; +2 cycles.
	STA $4010			; +4 cycles. Make this sample loop.
	LDA #$00			; +2 cycles.
	STA $4017			; +4 cycles. reset the frame counter.
	JSR Clockslide_29780; +29780
	JSR Clockslide_100	; +100. wait long enough for the frame counter to be set.
	; so far, we've ran 29898 cycles since leaving our "DMA Sync in 50 CPU cycles." subroutine.
	; Luckily, I set the DMA to loop every 432 CPU cycles.
	; 113 cycles until the DMA
	LDA #$0F			; +2 cycles.
	STA $4010			; +4 cycles. Make this stop looping.
	NOP	; stall for 2 cycles.
	SEI ; set interrupt flag.
	; 107 cycles until DMA
	JSR Clockslide_38
	RTS
;;;;;;;
	
TEST_ImpliedDummyRead_BackupRAM:
		; Let's copy this value to somewhere that won't get overwritten.
	LDA <$A5
	STA <$50
	LDA <$A6
	STA <$52
	LDA <$81
	STA <$53
	LDA <$89
	STA <$54
	LDA <$91
	STA <$55
	LDA <$99
	STA <$56
	LDA <$A1
	STA <$57
	LDA <$A9
	STA <$58
	LDA <$B1
	STA <$5A
	LDA <$B9
	STA <$5B
	LDA <$F1
	STA <$5C
	LDA <$A4
	STA <$5D
	; and we can restore that at the end of the test/ when failing the test.
	RTS
;;;;;;;
	
FAIL_ImpliedDummyRead:
	JSR TEST_ImpliedDummyRead_RestoreRAM
	JMP TEST_Fail
	
TEST_ImpliedDummyRead:
	JSR TEST_ImpliedDummyRead_BackupRAM
	; Well, before the madness begins, let's make sure some pre-requisites are met.
	;;; Test 1 [Implied Dummy Reads]: SLO Absolute, X is properly emulated. ;;;
	; This is used to verify the timing that the Frame Counter Interrupt flag gets cleared.
	JSR TEST_SLO_1F
	LDX #1
	STX <currentSubTest
	CMP #1
	BNE FAIL_ImpliedDummyRead1
	INC <currentSubTest

	;;; Test 2 [Implied Dummy Reads]: Prerequisite check. Does the frame counter interrupt flag get set if we enable it? ;;;
	LDA #0
	STA $4017
	JSR Clockslide_29780
	JSR Clockslide_100
	LDA #0
	LDA $4015
	CMP #$40
	BNE FAIL_ImpliedDummyRead1
	; As a means of preventing these error codes from stretching beyond the alphabet, I'm going to also check for the even/odd cycle behavior of clearing this flag under error code 2.
	; See [APU Frame Counter IRQ] test 6 and 7.
	LDA #$00	
	STA $4017	; 4-step mode, enable IRQ
	JSR Clockslide_30000 ; wait long enough that the IRQ flag would be set.
	LDA #02
	STA $4014 ; align with even cycle.
	LDA #0
	LDX #0
	.byte $1F	; SLO Absolute, X
	.word $4015 ; This reads from $4015 twice!
	BNE FAIL_ImpliedDummyRead1 ; If SLO is properly emulated, you might see bit 7 set here (failing the test). The flag is actually cleared before the second read, so it bit 7 should be 0.
	; This test *very deliberately* makes sure the double-reads from $4015 will always have bit 6 cleared before the second read, so we don't need to test for the alternate alignment here.

	INC <currentSubTest
	BNE TEST_ImpliedDummyReadPreReqContinue

FAIL_ImpliedDummyRead1:
	JMP FAIL_ImpliedDummyRead
;;;;;;;;;;;;;;;;;
TEST_ImpliedDummyReadPreReqContinue:
	; This test will require Addreass $00A5 to be the opcode we want to test, but address $A5 is currently used to store some information about the page of tests for the main menu.
	;;; Test 3 [Implied Dummy Reads]: Prerequisite check. Does a modified version of DMA + Open Bus pass? ;;;
	LDA <result_DMADMASync_PreTest	; If this emulator fails the pre-test for the DMA sync routine, then don't even bother trying.
	CMP #1
	BNE FAIL_ImpliedDummyRead1
	; I specifically need to know if the DMA + Open bus test would pass if I also stall long enough for the Frame Counter Interrupt Flag. It should still be in sync, and all that.
	JSR DMASyncWith48
	LDX <Copy_X			; +2 cycles (This makes it easier to follow in a tracelog.)
	LDA #$4F			; +2 cycles.
	STA $4010			; +4 cycles. Make this sample loop.
	LDA #$00			; +2 cycles.
	STA $4017			; +4 cycles. reset the frame counter.
	JSR Clockslide_29780; +29780
	JSR Clockslide_100	; +100. wait long enough for the frame counter to be set.
	LDA #$0F			; +2 cycles.
	STA $4010			; +4 cycles. Make this stop looping.
	NOP	; stall for 2 cycles.
	SEI ; set interrupt flag.
	; 107 cycles until DMA
	JSR Clockslide_50
	JSR Clockslide_50;  8 cycles until DMA
	LDA #$A5 ; 6 cycles until DMA
	LDA $4000
	CMP #$48
	BNE FAIL_ImpliedDummyRead1
	INC <currentSubTest
	
	;;; Test 4 [Implied Dummy Reads]: Prerequisite check. Is open bus accurate enough for this test? ;;;
	; This test actually does work on an everdrive (and it would be nice not to fail because of unrelated open bus issues.)
	; ... we pretty much just need to verify that open bus from $4000 to $401F is good, and if address $4015 updates the databus or not.
	LDA #$5A
	STA $2002	; ppu bus is now $5A
	LDX #$10
	LDA $3FF0, X	; Read ppu bus, read open bus. (this works on an everdrive too.)
	CMP #$5A
	BNE FAIL_ImpliedDummyRead1
	; We already confirmed SLO Absolute, X is accurate, so...
	LDX #3
	.byte $1F
	.word $4015 ; SLO $4015, X
	; despite the first read being from $4015, the data bus won't be updated. The second read is from $4018, which will read #$40.
	; Then it gets SLO'd to be $80
	BPL FAIL_ImpliedDummyRead1
	
	; Check the open bus bits of the controller port.
	JSR WaitForVBlank
	LDA #$F0
	STA $2002	; Set the PPU databus to $F0
	LDX #$17
	LDA $3FFF, X ; dummy read $2006. (The data bus is now $F0) The offset moves the address bus to $4016, reading from controller 1 when the databus was $F0.
	AND #$E0
	CMP #$E0 ; The open bus bits are all set.
	BNE FAIL_ImpliedDummyRead1
	LDA #$FF
	JSR SetPPUReadBufferToA
	LDX #$18
	LDA $3FFF, X ; dummy read $2007 (The data bus is now $F0) The offset moves the address bus to $4017, reading from controller 1 when the databus was $F0.
	PHA
	JSR ResetScroll	; And reset the scroll, since we just moved "v" to $2400.
	PLA
	AND #$E0
	CMP #$E0 ; The open bus bits are all set.
	BNE FAIL_ImpliedDummyRead1
	
	; This next pre-requisite doesn't have an error code, because I assume the emulator will crash if it gets this wrong.
	; This is something you would have fixed if you pass the [Open Bus] test.

	; JSR works like this. (simplified)
	;	Read Opcode
	;	Read Operand
	;	Dummy read from the stack.
	;	Push PCH
	;	Push PCL
	;	Read Operand
	;
	; And yes, pushing to the stack updates the databus.
	;
	; This is another test that would have been verified if I just ran the full [Open Bus] test, but you know... I really want the everdrive to be able to run this test.
	;
	; So we're going to JSR to open bus, and then RTS. And if we fail the test, it will probably crash or something. I don't know.
	; It's not really possible to know how an emulator would act if they got the order of operations wrong here. Something other than the 2nd operand would be on the data bus.
	JSR DMASyncWith60
	JSR Clockslide_43
	JSR $4000
	; and if we didn't crash, we passed the pre-requisite test. woo hoo.
	
	; And that should be all the pre-requisites.
	INC <currentSubTest

	;;; Test 5 [Implied Dummy Reads]: Do the implied instructions have dummy reads? (They should). ;;;
	; This test extends to every error code after this.
	
	; What are we testing for here?
	; The Implied Addressing mode instructions (NOP, ASL A, INX...) all have dummy reads on their second CPU cycle, reading from wherever the PC is.
	; So for instance, a NOP at address $8000 will dummy-read from address $8001. (since the PC is incremented before the second cycle)
	; pretty simple stuff, right?
	;
	; I suggest leaving it at that. You know what this test is checking for. Go forth and make those dummy reads. 
	; Trying to understand the following code is not necessary, and will drive you to madness.
	;
	; Do you even dare know how one tests for this?
	;
	; Abandon hope all ye who enter here.
	; This is without exaggeration, the most insane assembly code I have ever written.	
	
	; The idea:
	; Dummy read a read-sensitive register.
	;
	; Issue: The PPU registers have clock-alignment specific behavior changes, making the test too inconsistent. So we need to rely on the APU registers.
	;
	; The Idea take 2:
	; Dummy read $4015 to clear the Frame Counter Interrupt Flag, which will be clear when reading the next opcode.
	;
	; Issues:
	; Preparing an entire function to run inside open bus (setting up the opcode to be the instruction we want on the address we want to test) is not easy.
	; I need to sync a DMA while keeping the Frame Counter Interrupt Flag set. This DMA is used to change the data bus on the cycle after jumping to Open Bus.
	; The Frame Counter Interrupt Flag is only cleared when transitioning from a put cycle to a get cycle. (see [Frame Counter IRQ] test 6 and 7.)
	; When reading from $4015 as the opcode, bit 5 will be set if the opcode we tested had bit 5 set.
	; So making the Pass/Fail translate to a BRK/RTI will only work for half the instructions. The rest will be JSR/RTS.
	; I would *really* like it if this test did not crash in the event of failure, so I actually do need to make sure both cases are managed.
	; This means I need to manage a bunch of BRK, RTI, JSR, and RTS's, while making sure the stack pointer stays sane in the event of passing or failure.
	; If a JSR happens, the controller ports will be the operands. 
	; The controller ports have open bus in the upper 3 bits (controller 1 has 5 bits on famicom), which will leech off the value read from the opcode. (reading $4015 doesn't update the databus)
	
	
	; Let's set up the brk routine.
	LDA #$4C
	STA $600
	LDA #Low(TEST_ImpliedDummyRead_BRKed)
	STA $601
	LDA #High(TEST_ImpliedDummyRead_BRKed)
	STA $602
		
	LDX #0
TEST_ImpliedDummyRead_Loop:	; This loop tests the opcodes that don't have bit 5 set. ($20)
	STX <Copy_X
	LDA TEST_ImpliedDummyRead_OpsToTest_NoBit5, X
	STA <$A5
	LDA #$A5
	STA <$A4
	; Current objective: move the PC to $4011 with the databus set to $48
	; The plan: 
	; JSR $4011, and then a DMC DMA occurs. (DMC DMA will have set the value $48 to the databus.)
	; It's the simplest thing that could possibly work.
	; 
	; Here's how it will play out.
	; JSR $4011
	; DMC DMA (databus = $48)
	; PHA (Databus = $A4)
	; LDY <$A4 (Address $A4 = $A5, so thedatabus will now be $A5)
	; LDA <$A5 (Databus = the contents of address $A5. This is where we store the opcode we want to test)
	; The opcode in question runs. Dummy reads $4015, clearing the frame counter interrupt flag.
	; Fetch opcode from $4015
	; BRK if PASS, RTI if FAIL. (This is why we had to PHA after the JSR)
	LDA #0
	STA <$60	; address $60 will be a 1 if we executed a BRK, and a 0 if we executed an RTI
	JSR DMASyncWith48	; 50 cycles until DMA.
	JSR Test_ImpliedDummyRead_WaitForFrameCounterFlag
	JSR Clockslide_36	;19 cycles until DLA
	LDA #HIGH(TEST_ImpliedDummyRead_Post)
	PHA
	LDA #LOW(TEST_ImpliedDummyRead_Post)
	PHA
	TSX	; For the TXS test.
	DEX	; Also DEX since we're gonna PHA before the TXS runs.
	LDA #$A4 ; 3 cycles until DMA
	JMP $400F; [Read opcode] [Read operand] [Read operand] 
	; [DMC DMA, databus = $48]
	; PHA [databus = A (A = $A4)] [also dummy read.]
	; LDY <$A4 [Read opcode] [Read operand] [read address $A4, a value of $A5]
	; LDA <$A5 [Read opcpde] [Read operand] [Read address $A5, the opcode we want to test.]
	; NOP [Read Opcode] [Dummy Read $4015 (This should clear the Frame Counter interrupt.)]
	; [Read opcode from $4015. Hopefully, a BRK.]
	;
	; and hopefully the BRK takes you to TEST_ImpliedDummyRead_BRKed, which sets $60 and jumps to TEST_ImpliedDummyRead_Post.
TEST_ImpliedDummyRead_Post:

	LDA <$60
	BEQ FAIL_ImpliedDummyRead2
	INC <currentSubTest	

	LDX <Copy_X
	INX
	CPX #11	; this loops tests 11 opcodes.
	BNE TEST_ImpliedDummyRead_Loop
	BEQ TEST_ImpliedDummyRead_Continue

FAIL_ImpliedDummyRead2:
	JMP FAIL_ImpliedDummyRead
;;;;;;;;;;;;;;;;;
TEST_ImpliedDummyRead_Continue:
	
	LDA #Low(TEST_ImpliedDummyRead_BRKed2)
	STA $601
	LDA #High(TEST_ImpliedDummyRead_BRKed2)
	STA $602
	
	; now we test for the instructions that have bit 5 set.
	; instead of BRK for pass, and RTI for fail, we're looking at JSR for pass, and RTS for fail!
	
	; Due to the upper 3 bits of a controller (or 5 bits on famicom) being open bus, (and $4015 doesn't upodate the databus) the low byte operand of the JSR instruction could have anything in those bits.
	
	LDA #$00	; We need a series of bytes to be BRKs
	STA <$01	; This byte isn't being used in this test, so we're good to overwrite it.
	STA <$09	; This byte isn't being used in this test, so we're good to overwrite it.
	STA <$11	; This byte isn't being used in this test, so we're good to overwrite it.
	STA <$19	; This byte isn't being used in this test, so we're good to overwrite it.
	STA <$21	; This byte isn't being used in this test, so we're good to overwrite it.
	STA <$29	; This byte isn't being used in this test, so we're good to overwrite it.
	STA <$31	; This byte isn't being used in this test, so we're good to overwrite it.
	STA <$39	; This byte isn't being used in this test, so we're good to overwrite it.
	STA <$41	; So far, nothing uses this byte. So we're good to overwrite it.
	STA <$49	; So far, nothing uses this byte. So we're good to overwrite it.
	STA <$51	; This byte isn't being used in this test, so we're good to overwrite it.
	STA <$59	; This byte isn't being used in this test, so we're good to overwrite it.
	STA <$61	; This byte isn't being used in this test, so we're good to overwrite it.
	STA <$69	; This byte isn't being used in this test, so we're good to overwrite it.
	STA <$71	; So far, nothing uses this byte. So we're good to overwrite it.
	STA <$79	; So far, nothing uses this byte. So we're good to overwrite it.
	STA <$81	; This byte is being used for the page stuff, so it's a good thing we copied that one too at the start of the test.	
	STA <$89	; This byte is being used for the page stuff, so it's a good thing we copied that one too at the start of the test.
	STA <$91	; This byte is being used for the page stuff, so it's a good thing we copied that one too at the start of the test.
	STA <$99	; This byte is being used for the page stuff, so it's a good thing we copied that one too at the start of the test.
	STA <$A1	; This byte is being used for the page stuff, so it's a good thing we copied that one too at the start of the test.	
	STA <$A9	; This byte is being used for the page stuff, so it's a good thing we copied that one too at the start of the test.
	STA <$B1	; This byte is being used for the page stuff, so it's a good thing we copied that one too at the start of the test.
	STA <$B9	; This byte is being used for the page stuff, so it's a good thing we copied that one too at the start of the test.
	STA <$C1	; So far, nothing uses this byte. So we're good to overwrite it.
	STA <$C9	; So far, nothing uses this byte. So we're good to overwrite it.
	STA <$D1	; So far, nothing uses this byte. So we're good to overwrite it.
	STA <$D9	; So far, nothing uses this byte. So we're good to overwrite it.
	STA <$E1	; So far, nothing uses this byte. So we're good to overwrite it.
	STA <$E9	; So far, nothing uses this byte. So we're good to overwrite it.
	STA <$F1	; This byte is being used for the PPUCTRL_COPY, so it's a good thing we copied that one too at the start of the test.
	STA <$F9	; So far, nothing uses this byte. So we're good to overwrite it.

	; I recognize this is more bytes than opcodes I'm testing, but better safe than sorry.

	LDX #0
TEST_ImpliedDummyRead_Loop2:	; This loop tests the opcodes that do have bit 5 set. ($20)
	STX <Copy_X
	LDA TEST_ImpliedDummyRead_Bit5OpsToTest, X
	STA <$A5
	; Current objective: move the PC to $4012 with the databus set to $A5
	; The plan: 
	; JSR $4012, and then a DMC DMA occurs. (DMC DMA will have set the value $A5 to the databus.)
	; It's the simplest thing that could possibly work.
	; 
	; Here's how it will play out.
	; JSR $4012
	; DMC DMA (databus = $A5)
	; LDA <$A5 (Databus = the contents of address $A5. This is where we store the opcode we want to test)
	; The opcode in question runs. Dummy reads $4015, clearing the frame counter interrupt flag. (Except bit 5 will be set this time)
	; Fetch opcode from $4015
	; JSR $0021 if PASS, RTS if FAIL.
	JSR ReadController1; We need controller 1 to be fully clocked, and controller 2 unclocked.

	LDA #0
	STA <$60	; address $60 will be a 1 if we executed a BRK, and a 0 if we executed an RTI
	JSR DMASyncWithA5	; 50 cycles until DMA.
	JSR Test_ImpliedDummyRead_WaitForFrameCounterFlag
	JSR Clockslide_47; 95 cycles from clockslides. 8 cycles until DMA
	LDA #$A5 ; 6 cycles until DMA
	JSR $4012; [Read opcode] [Read operand] [Dummy Read] [Push PCH] [Push PCL] [Read operand] 
	; [DMC DMA, databus = $A5]
	; LDA <$A5 [Read opcode] [Read operand] [read address $A5, Databus = the opcode of the isntruction we want to test.]
	; NOP [Read Opcode] [Dummy Read $4015 (This should clear the Frame Counter interrupt.)]
	; [Read opcode from $4015. Hopefully, a JSR.]
	; And here's how the JSR instruction will work:
	; [Read $4015: 20] [Read $4016: 21] [dummy read stack] [Push PCH: 40] [Push PHL: 16] [read $4017: 00]
	; Keep in mind, the open bus value when reading controller 2 will be 16, which gets masked away, as only the upper 3 bits of controller 2 matter.
	;
	; and hopefully the JSR takes you to $0021, a BRK to TEST_ImpliedDummyRead_BRKed2, which sets $60 and jumps to TEST_ImpliedDummyRead_Post2.
TEST_ImpliedDummyRead_Post2:
	LDA <$60
	BEQ FAIL_ImpliedDummyRead3
	INC <currentSubTest	

	LDX <Copy_X
	INX
	CPX #11	; this loops tests 11 opcodes.
	BNE TEST_ImpliedDummyRead_Loop2
	BEQ TEST_ImpliedDummyRead_Continue2
FAIL_ImpliedDummyRead3:
	JMP FAIL_ImpliedDummyRead
TEST_ImpliedDummyRead_Continue2:

	; Okay cool, that's 22 opcodes down.
	; All that's left (ignoring the unofficial NOPs) is:
	; BRK, PHP, PLP, PHA, PLA, RTI, And RTS.
	; Due to how these instructions update the stack pointer, I didn't want to run these instructions in the previous loops.
	; Oh- also branches, which don't update the stack, but *do* have dummy reads.
	
	; Let's start with PHP
	LDA #Low(TEST_ImpliedDummyRead_BRKed3)
	STA $601
	LDA #High(TEST_ImpliedDummyRead_BRKed3)
	STA $602

	LDA #08	; PHP
	STA <$A5
	LDA #$A5
	STA <$A6

	LDA #0
	STA <$60	; address $60 will be a 1 if we executed a BRK, and a 0 if we executed an RTI
	JSR DMASyncWith68	; 50 cycles until DMA.
	JSR Test_ImpliedDummyRead_WaitForFrameCounterFlag
	JSR Clockslide_40; 99 cycles from clockslides. 19 cycles until DMA
	LDA #HIGH(TEST_ImpliedDummyRead_PostPHP) ; 17 cycles until DMA
	PHA		 ; 15 cycles until DMA
	LDX #$A5
	LDA #$A6 ; 6 cycles until DMA
	PHA
	; Despite PHA's opcode not having bit 5 set, writing A5 will set that bit.
	JMP $400F; [Read opcode] [Read operand] [Dummy Read] [Push PCH] [Push PCL] [Read operand] 
	; [DMC DMA, databus = $68]
	; PLA [Pull off A6] [also dummy read.] (4 cycles)
	; LDX <$A6 [Read opcode] [Read operand] [read address $A6, Databus = $A5.] (3)
	; LDA <$A5 [Read opcode] [Read operand] [read address $A5, Databus = the opcode of the instruction we want to test.] (3)
	; PHA [Read Opcode] [Dummy Read $4015 (This should clear the Frame Counter interrupt.)] [Push A ($48) to stack]
	; [Read opcode from $4015. Hopefully, a JSR.]
	;
	; and hopefully the BRK takes you to TEST_ImpliedDummyRead_BRKed3, which sets $60 and jumps to TEST_ImpliedDummyRead_PostPHP.
	.org $D23D	; PHP should push $3C to the stack, so the RTS instruction would return here:
TEST_ImpliedDummyRead_PostPHP:
	LDA <$60
	BEQ FAIL_ImpliedDummyRead4
	INC <currentSubTest	
	; Okay cool, that's 22 opcodes down now.
	; Let's test PHA now.

	LDA #Low(TEST_ImpliedDummyRead_BRKed4)
	STA $601
	LDA #High(TEST_ImpliedDummyRead_BRKed4)
	STA $602

	LDA #$48	; PHA
	STA <$A5
	LDA #$A5
	STA <$A6

	LDA #0
	STA <$60	; address $60 will be a 1 if we executed a BRK, and a 0 if we executed an RTI
	JSR DMASyncWith68	; 50 cycles until DMA.
	JSR Test_ImpliedDummyRead_WaitForFrameCounterFlag
	JSR Clockslide_35; 99 cycles from clockslides. 19 cycles until DMA
	LDA #HIGH(TEST_ImpliedDummyRead_PostPHA) ; 17 cycles until DMA
	PHA		 ; 15 cycles until DMA
	LDA #LOW(TEST_ImpliedDummyRead_PostPHA)
	PHA
	LDX #$A5
	LDA #$A6 ; 6 cycles until DMA
	PHA
	; Despite PHA's opcode not having bit 5 set, writing A5 will set that bit.
	JMP $400F; [Read opcode] [Read operand] [Dummy Read] [Push PCH] [Push PCL] [Read operand] 
	; [DMC DMA, databus = $48]
	; PLA [Pull off A6] [also dummy read.] (4 cycles)
	; LDX <$A6 [Read opcode] [Read operand] [read address $A6, Databus = $A5.] (3)
	; LDA <$A5 [Read opcode] [Read operand] [read address $A5, Databus = the opcode of the instruction we want to test.] (3)
	; PHA [Read Opcode] [Dummy Read $4015 (This should clear the Frame Counter interrupt.)] [Push A ($48) to stack]
	; [Read opcode from $4015. Hopefully, a BRK.]
	;
	; and hopefully the BRK takes you to TEST_ImpliedDummyRead_BRKed3, which sets $60 and jumps to TEST_ImpliedDummyRead_PostPHA.
TEST_ImpliedDummyRead_PostPHA:

	LDA <$60
	BEQ FAIL_ImpliedDummyRead4
	INC <currentSubTest	
	BNE TEST_ImpliedDummyRead_Continue3
FAIL_ImpliedDummyRead4:
	JMP FAIL_ImpliedDummyRead
TEST_ImpliedDummyRead_Continue3:
	
	; Okay cool, that's 24 opcodes down now.
	; I still want to test:
	; BRK, PLP, PLA, RTI, RTS, and branches.
	;
	; Let's take care of PLP and PHP next.
	LDA #$4C
	STA $600
	LDA #Low(TEST_ImpliedDummyRead_BRKed5)
	STA $601
	LDA #High(TEST_ImpliedDummyRead_BRKed5)
	STA $602
	LDX #0
TEST_ImpliedDummyRead_Loop5:	; This loop tests PLP and PLA
	STX <Copy_X
	LDA TEST_ImpliedDummyRead_PullOpsToTest, X
	STA <$A5

	LDA #0
	STA <$60	; address $60 will be a 1 if we executed a BRK, and a 0 if we executed an RTI
	JSR DMASyncWith48	; 50 cycles until DMA.
	JSR Test_ImpliedDummyRead_WaitForFrameCounterFlag
	JSR Clockslide_39; 99 cycles from clockslides. 19 cycles until DMA
	LDA #HIGH(TEST_ImpliedDummyRead_Post5) ; 17 cycles until DMA
	PHA		 ; 15 cycles until DMA
	LDA #LOW(TEST_ImpliedDummyRead_Post5)-1 ; 11 cycles until DMA
	PHA		 ; 12 cycles until DMA
	LDA <$A5 ; 6 cycles until DMA
	JMP $4013; [Read opcode] [Read operand] [Dummy Read] [Push PCH] [Push PCL] [Read operand] 
	; [DMC DMA, databus = $48]
	; PHA [databus = A (A = the opcode we want to test)] [also dummy read.]
	; PLA [Read Opcode] [Dummy Read $4015 (This should clear the Frame Counter interrupt.)] [Dummy Read from stack (no way to test for this)] [Pull A from stack]
	; [Read opcode from $4015. Hopefully, a BRK.]
	;
	; and hopefully the BRK takes you to TEST_ImpliedDummyRead_BRKed5, which sets $60 and jumps to TEST_ImpliedDummyRead_Post5.
TEST_ImpliedDummyRead_Post5:
	LDA <$60
	BEQ FAIL_ImpliedDummyRead5
	INC <currentSubTest	

	LDX <Copy_X
	INX
	CPX #2	; this loops tests 2 opcodes. (PLP and PLA)
	BNE TEST_ImpliedDummyRead_Loop5

	; Alright! That's 26 opcodes tested now.
	; I still want to test:
	; BRK, RTI, RTS, and branches.

	; BRK, RTI, and RTS sound pretty easy. I don't even need to worry about the even/odd cycle thing. I just run the dummy read, then after jumping to a stable point, read $4015 for the interrupt flag.

	LDA #$4C
	STA $600
	LDA #Low(TEST_ImpliedDummyRead_BRKed6)
	STA $601
	LDA #High(TEST_ImpliedDummyRead_BRKed6)
	STA $602
	LDX #0
TEST_ImpliedDummyRead_Loop6:	; This loop tests BRK and RTI
	STX <Copy_X
	LDA TEST_ImpliedDummyRead_IntOpsToTest, X
	STA <$A5
	LDA #$A5
	STA <$A6

	LDA #0
	STA <$60	; address $60 will be a 1 if we executed a BRK, and a 0 if we executed an RTI
	JSR DMASyncWith48	; 50 cycles until DMA.
	JSR Test_ImpliedDummyRead_WaitForFrameCounterFlag
	JSR Clockslide_39; 99 cycles from clockslides. 19 cycles until DMA
	LDA #HIGH(TEST_ImpliedDummyRead_Post6) ; 17 cycles until DMA
	PHA		 ; 15 cycles until DMA
	LDA #LOW(TEST_ImpliedDummyRead_Post6) ; 11 cycles until DMA
	PHA		 ; 12 cycles until DMA
	LDA <$A5 ; 6 cycles until DMA
	; This one doesn't need to worry about even/odd cycle polarity, since we're not double-reading $4015. We dummy read it, and the PC is moved *far away*.
	JMP $4013; [Read opcode] [Read operand] [Dummy Read] [Push PCH] [Push PCL] [Read operand] 
	; [DMC DMA, databus = $48]
	; PHA [databus = A (A = the opcode we want to test)] [also dummy read.]
	; BRK [Read Opcode] [Dummy Read $4015 (This should clear the Frame Counter interrupt.)] [The rest of BRK/RTI...]
	; We don't read $4015 for the operand this time, so we're just going to LDA $4015 after returning to stable code to verify the dummy read happened.
	;
	; and hopefully the BRK takes you to TEST_ImpliedDummyRead_BRKed6, which sets $60 and jumps to TEST_ImpliedDummyRead_Post6.
TEST_ImpliedDummyRead_Post6:
	; Fun fact, the RTI instruction will immediately lead into an IRQ, so the "BRK routine" does some checks for that.
	SEI
	LDA $4015
	AND #$40
	BNE FAIL_ImpliedDummyRead5
	INC <currentSubTest	

	LDX <Copy_X
	INX
	CPX #2	; this loops tests 2 opcodes. (BRK and RTI)
	BNE TEST_ImpliedDummyRead_Loop6
	BEQ TEST_ImpliedDummyRead_Continue4

FAIL_ImpliedDummyRead5:
	JMP FAIL_ImpliedDummyRead
TEST_ImpliedDummyRead_Continue4:

	; Great! That's 28 opcodes tested now.
	; I still want to test:
	; RTS and branches.
	

	LDA #$60
	STA <$A5
	JSR DMASyncWith68	; 50 cycles until DMA.
	JSR Test_ImpliedDummyRead_WaitForFrameCounterFlag
	JSR Clockslide_36; 99 cycles from clockslides. 19 cycles until DMA
	LDA #HIGH(TEST_ImpliedDummyRead_PostJSR) ; 17 cycles until DMA
	PHA		 ; 15 cycles until DMA
	LDA #LOW(TEST_ImpliedDummyRead_PostJSR)-1 ; 11 cycles until DMA
	PHA		 ; 12 cycles until DMA
	LDA <$A5 ; 6 cycles until DMA
	PHA
	; This one doesn't need to worry about even/odd cycle polarity, since we're not double-reading $4015. We dummy read it, and the PC is moved *far away*.
	JMP $4013; [Read opcode] [Read operand] [Read operand] 
	; [DMC DMA, databus = $48]
	; PHA [databus = A (A = the opcode we want to test)] [also dummy read.]
	; BRK [Read Opcode] [Dummy Read $4015 (This should clear the Frame Counter interrupt.)] [The rest of BRK/RTI...]
	; We don't read $4015 for the operand this time, so we're just going to LDA $4015 after returning to stable code to verify the dummy read happened.
	;
	; and hopefully the JSR just takes you here.
TEST_ImpliedDummyRead_PostJSR:
	LDA $4015
	AND #$40
	BNE FAIL_ImpliedDummyRead5
	INC <currentSubTest	

	; 29 opcodes tested now.
	; I still want to test branches, though to be honest, I'm not currently sure how to safely do that.
	; I think my DMA sync routines take a variable amount of time, so I can't rely on a dummy read reading $2002, since the Vblank flag could be cleared whjile waiting for the DMA to sync.
	
	;; END OF TEST ;;
	JSR TEST_ImpliedDummyRead_RestoreRAM
	LDA #1
	RTS
;;;;;;;
	
TEST_ImpliedDummyRead_RestoreRAM:
	SEI
	LDA $4015
	LDA <$50
	STA <$A5
	LDA <$52
	STA <$A6
	LDA <$53
	STA <$81
	LDA <$54
	STA <$89
	LDA <$55
	STA <$91
	LDA <$56
	STA <$99
	LDA <$57
	STA <$A1
	LDA <$58
	STA <$A9
	LDA <$5A
	STA <$B1
	LDA <$5B
	STA <$B9
	LDA <$5C
	STA <$F1
	LDA <$5D
	STA <$A4
	RTS
;;;;;;;
	
TEST_ImpliedDummyRead_OpsToTest_NoBit5:
	; BRK does a dummy read. (test seperately)
	; PHP does a dummy read. (test seperately)
	ASL A
	; Branches do a dummy read. (test seperately)
	CLC
	; RTI does a dummy read. (test seperately)
	; PHA does a dummy read. (test seperately)
	LSR A
	CLI	; make sure no interrupts will happen, ha!
	; PLA does a dummy read. (test seperately)
	DEY
	TXA
	TYA
	TXS
	INY
	DEX
	CLD
;;;;;;;
TEST_ImpliedDummyRead_Bit5OpsToTest:
	; JSR does a dummy read. (test seperately)
	; PLP does a dummy read. (test seperately)
	ROL A
	SEC
	; RTS does a dummy read. (test seperately)
	ROR A
	SEI
	TAY
	TAX
	CLV
	TSX
	INX
	SED
	NOP
;;;;;;;
TEST_ImpliedDummyRead_PullOpsToTest:
	PLP
	PLA
;;;;;;;
TEST_ImpliedDummyRead_IntOpsToTest:
	BRK
	RTI
;;;;;;;
	
TEST_AddrMode_AbsIndex:
	;;; Test 1 [Absolute Indexed Wraparound]: Does LDA Absolute, X read from the expected address ;;;
	; Let's just start with crossing a page boundary, as I would be bewildered if an emulator could even make it this far without indexed LDAs working at all.
	LDA #$5A
	STA $680 ; Set up address $680
	LDX #$F0 ; Set up X
	LDA $590, X ; Read from address $680
	CMP #$5A ; Check if it was the correct address.
	BNE FAIL_AddrMode_AbsIndex
	INC <currentSubTest
	
	;;; Test 2 [Absolute Indexed Wraparound]: Wrapping around from address $FFFF to $0000 ;;;
	LDA #$5A
	STA <$50
	LDX #$51
	LDA $FFFF, X	; $FFFF + $51 = $0050
	CMP #$5A ; Check if it was the correct address.
	BNE FAIL_AddrMode_AbsIndex
	; Make sure it wasn't a fluke. (I don't know. You could somehow incorrectly implement a hypothetical address $10050, and it might just happen to hold $5A.)
	LDA #$A5
	STA <$50
	LDA $FFFF, X	; $FFFF + $51 = $0050
	CMP #$A5 ; Check if it was the correct address.
	BNE FAIL_AddrMode_AbsIndex
	INC <currentSubTest
	
	;;; Test 3 [Absolute Indexed Wraparound]: The same applies to indexing with Y ;;;
	LDY #$51
	LDA $FFFF, Y	; $FFFF + $51 = $0050
	CMP #$A5 ; Check if it was the correct address.
	BNE FAIL_AddrMode_AbsIndex
	
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

FAIL_AddrMode_AbsIndex:
	JMP TEST_Fail

TEST_AddrMode_ZPgIndex:
	;;; Test 1 [Zero Page Indexed Wraparound]: Does LDA <ZeroPage, X read from the expected address ;;;
	LDA #$A5
	STA <$58	; We'll read from address $58 just to test if this instruction is working as expected, with no edge cases.
	LDX #8
	LDA #0
	LDA <$50, X ; read from address $58
	CMP #$A5	; compare with $A5
	BNE FAIL_AddrMode_ZPgIndex ; And fail the test if the expected value wasn't read.
	INC <currentSubTest

	;;; Test 2 [Zero Page Indexed Wraparound]: Indexing should always remain on the zero page. ;;;
	; For instance, suppose X = $20. LDA <$F0, X won't read from address $0110, rather, it will read from address $0010.
	STA <$00
	LDA #$5A
	STA $100
	LDX #1
	LDA <$FF, X
	CMP #$A5
	BNE FAIL_AddrMode_ZPgIndex
	INC <currentSubTest

	;;; Test 3 [Zero Page Indexed Wraparound]: This also applies to Zero Page with Y indexing. ;;;
	LDY #1
	LDX <$FF, Y
	CPX #$A5
	BNE FAIL_AddrMode_ZPgIndex
	
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

FAIL_AddrMode_ZPgIndex
	JMP TEST_Fail
;;;;;;;;;;;;;;;;;

TEST_AddrMode_Indirect:
	;;; Test 1 [Indirect Addressing Wraparound]: Does JMP (indirect) move the program counter to the correct location? ;;;
	; I guess if it doesn't then the emulator would likely crash, huh?
	LDA #LOW(TEST_AddrMode_Indirect_Pass1)
	STA $500
	LDA #HIGH(TEST_AddrMode_Indirect_Pass1)
	STA $501
	LDX #0
	JMP [$0500]
	INX	; I don't know... I guess an emulator could just choose not to move the PC anywhere at all?
TEST_AddrMode_Indirect_Pass1:
	CPX #0
	BNE FAIL_AddrMode_Indirect
	INC <currentSubTest
	
	;;; Test 2 [Indirect Addressing Wraparound]: The Address bus wraps around the page when reading the low and high bytes with indirect addressing ;;;
	; Basically, if the indirect jump is at a page boundary, (address $5FF, for instance) the high byte will be read from the same page as the low byte.
	; So instead of reading $5FF and $600, it reads $5FF and $500.	
	LDY #0	; both X and Y are now zero.
	LDA #$60	; the opcode for RTS
	STA $580	; store at $580, where ths upcoming indirect jump should move the PC.
	STA $681	; also store at 681. An incorrect emulation of the behavior tested here will mvoe the PC to $680, where I will run INX, RTS.
	LDA #$E8	; the opcode for INX
	STA $680	; Store at $680, as mentioned above.
	; And now to set up the test.
	LDA #$80
	STA $5FF	; The low byte of the indirect jump is $80.
	LDA #5
	STA $500	; the correct indirect address is $580
	LDA #6
	STA $600	; while the incorrect address is $680
	JSR TEST_AddrMode_Indirect_Here ; RTS will move the PC back here after the test.
TEST_AddrMode_Indirect_Here: ; Yeah, this set up is a little cursed, but I wanted to use RTS at the locations in RAM instead of JMP.
	CPY #1
	BEQ TEST_AddrMode_Indirect_Next ; If this is executing after the RTS, this test won't need ran a second time.
	INY
	JMP [$05FF] ; If this jumps to $580, pass. if this jumps to $680, fail.	
TEST_AddrMode_Indirect_Next:
	CPX #01
	BEQ FAIL_AddrMode_Indirect
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;
	
FAIL_AddrMode_Indirect:
	JMP TEST_Fail
;;;;;;;;;;;;;;;;;

TEST_AddrMode_IndIndeX:
	;;; Test 1 [Indirect Addressing, X Wraparound]: Does LDA (indirect, X) read from the expected address ;;;
	; Indirect addressint, X works like this:
	; The operand is a byte on the zero page. Add X to that address, the value of which will be the low byte of the target address of the instruction.
	; The following byte in memory will be the high byte of the target address.
	; For example, LDA ($50, X) would work like this: (Assume X = $10, address $60 has the value $00, and address $61 has the value $80)
	; Cycle 1: Read the opcode: $A1
	; Cycle 2: Read the operand: $50
	; Cycle 3: Dummy Read address $0050, and add X to this address.
	; Cycle 4: Read address $0060: $00
	; Cycle 5: Read address $0061: $80
	; Cycle 6: Read address $8000
	;
	; For my test, I'm going to start with something just as simple as that.
	; Address $580 will hold the value $5A
	LDA #$5A
	STA $580
	; and address $58 will be set up with a pointer to address $580
	LDA #$80
	STA <$58
	LDA #$05
	STA <$59
	; And now I set X to $08
	LDX #$08
	; And low we run the LDA instruction.
	LDA [$0050, X]
	; The result of which, should be the value at address $580
	CMP #$5A
	BNE FAIL_AddrMode_IndIndeX
	INC <currentSubTest

	;;; Test 2 [Indirect Addressing, X Wraparound]: The X indexing is confined to the zero page. ;;;
	; Set up $158 to point to address $680
	LDA #$80
	STA $158
	LDA #$06
	STA $159
	; Set X to $F0
	LDX #$F0
	; And low we run the LDA instruction.
	LDA [$0068, X]
	CMP #$5A
	BNE FAIL_AddrMode_IndIndeX
	INC <currentSubTest
	
	;;; Test 3 [Indirect Addressing, X Wraparound]: The Address bus wraps around the page when reading the low and high bytes with indirect addressing ;;;
	LDA #$80
	STA <$FF
	LDA #$05
	STA <$00
	LDA #$06
	STA $100
	; Set X to $00
	LDX #$00
	; And low we run the LDA instruction.
	LDA [$00FF, X]
	CMP #$5A
	BNE FAIL_AddrMode_IndIndeX
	
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

FAIL_AddrMode_IndIndeX:
	JMP TEST_Fail
;;;;;;;;;;;;;;;;;

TEST_AddrMode_IndIndeY:
	;;; Test 1 [Indirect Addressing, Y Wraparound]: Does LDA (indirect), Y read from the expected address ;;;
	; Indirect addressing, Y works like this:
	; The operand is a byte on the zero page, the value of which will be the low byte of the target address of the instruction.
	; The following byte in memory will be the high byte of the target address.
	; For example: LDA ($50), Y would work like this: (Assume Y= $20, address $50 has the value $F0, and address $51 has the value $80)
	; Cycle 1: Read the opcode: $B1
	; Cycle 2: Read the operand: $50
	; Cycle 3: Read address $0050: $F0
	; Cycle 4: Read address $0051: $80. Add Y to the low byte. The address bus is now pointing to $8010.
	; Cycle 5: Dummy Read address $8010. Fix the high byte of the address bus, since the Y indexing crossed a page boundary.
	; Cycle 6: Read from address $8110. (This cycle only occurs if the Y indexing crossed a page boundary.)
	;
	; For my test though, I'm just going to start with something simple.
	; Address $580 will hold the value $5A.
	LDA #$5A
	STA $580
	; and address $50 will be set up with a pointer to address $570
	LDA #$70
	STA <$50
	LDA #$05
	STA <$51
	; And now I set Y to $10
	LDY #$10
	; And low we run the LDA instruction.
	LDA [$0050], Y
	; The result of which, should be the value at address $580
	CMP #$5A
	BNE FAIL_AddrMode_IndIndeY
	INC <currentSubTest
	
	;;; Test 2 [Indirect Addressing, Y Wraparound]: The Y indexing is allowed to cross page boundaries. ;;;
	; Address $610 will hold the value $5A.
	LDA #$5A
	STA $610
	; and address $50 will be set up with a pointer to address $5F0
	LDA #$F0
	STA <$50
	LDA #$05
	STA <$51
	; And now I set Y to $20
	LDY #$20
	; And low we run the LDA instruction.
	LDA [$0050], Y
	; The result of which, should be the value at address $610
	CMP #$5A
	BNE FAIL_AddrMode_IndIndeY
	INC <currentSubTest
	
	;;; Test 3 [Indirect Addressing, Y Wraparound]: The Address bus wraps around the page when reading the low and high bytes with indirect addressing ;;;
	; LDA ($FF), Y works like this:
	; Cycle 1: Read the opcode: $B1
	; Cycle 2: Read the operand: $FF
	; Cycle 3: Read address $00FF:
	; Cycle 4: Read address $0000: (NOTE: This is NOT address $100. The high byte remains $00)
	; Cycle 5: etc.
	;
	; Address $610 will hold the value $5A.
	LDA #$5A
	STA $555
	; and address $FF will be set up with a pointer to address $555
	LDA #$55
	STA <$FF
	LDA #$05
	STA <$00
	; I also make sure address $100 is not #05
	LDA #$06
	STA $100 ; Address $655 should be $00, since that page gets cleared before hte test runs.
	; And now I set Y to $0
	LDY #$0
	; And low we run the LDA instruction.
	LDA [$00FF], Y
	; The result of which, should be the value at address $555, NOT the value at $655
	CMP #$5A
	BNE FAIL_AddrMode_IndIndeY	
	
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

FAIL_AddrMode_IndIndeY:
	JMP TEST_Fail
;;;;;;;;;;;;;;;;;

TEST_AddrMode_Relative:
	;;; Test 1 [Relative Addressing]: Branching from page $00 to page $FF ;;;
	LDA TEST_OpenBus_IRQRoutine,X ; Use the same routine as the [Open Bus] test IRQ. PLA 5 times, and JUMP to the fail condition.
	STA $600, X
	INX
	CPX #8
	BNE TEST_AddrMode_Relative	
	; Some emulators might implement this poorly, such that executing beyond address $FFFF crashes or maybe executes all zeroes? So let's set up the IRQ routine in case a BRK runs.
	; Let's first test by branching from the zero page. If the PC is somehow moving to a hypothetical Page -1, we could set up address $00 to be a BRK, in case it executes to it.
	LDA #$00
	STA <$00
	STA <$01
	STA <$02
	; Address $FFF9 has an RTS, so let's aim for there.
	LDA #$D0
	STA <$52
	LDA #$A5
	STA <$53
	JSR $0052	; This will branch to $FFF9, running an RTS. Otherwise, running a BRK.	
	INC <currentSubTest
	
	;;; Test 2 [Relative Addressing]: Branching from page $FF to page $00 ;;;
	LDA #$E6
	STA <$50
	LDA #$55
	STA <$51
	LDA #$80
	STA <$55
	JSR TEST_FFFF_Branch_Wraparound
	LDA <$55
	CMP #$81
	BNE FAIL_AddrMode_Relative
	
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

FAIL_AddrMode_Relative:
	JMP TEST_Fail
;;;;;;;;;;;;;;;;;

TEST_DecimalFlag:
	;;; Test 1 [The Decimal Flag]: The 6502 "Binary Coded Decimal" flag should not affect the ADC or SBC instructions on the NES ;;;
	; Despite the Decimal Flag existing, (BRK or PHP instructions will still set bit 3 of the value pushed depending on the state of this flag), it doesn't affect ADC or SBC.
	; So let's test that!
	SED
	; With the Decimal Flag set, we can run math, such as $55 - $16 = $39, despite the fact that that's not how hexadecimal numbers work.
	LDA #$55
	SEC
	SBC #$16
	; And if the decimal flag works, the result will be $39.
	; But remember, the decimal does NOT work on the NES. So the result should *actually* be the correct result of subtracting the two hexadecimal numbers, which is $3F.
	CMP #$3F
	BNE FAIL_DecimalFlag
	INC <currentSubTest
	
	;;; Test 2 [The Decimal Flag]: Despite this flag not working, it still gets pushed in a PHP/BRK instruction ;;;
	PHP ; the decimal flag is set.
	PLA ; pull the processor stuff into the A register.
	AND #8 ; the Decimal flag is bit 3.
	BEQ FAIL_DecimalFlag
	CLD ; clear the decimal flag and do this again.
	PHP
	PLA
	AND #8
	BNE FAIL_DecimalFlag ; the Decimal flag is no longer set.
	; And that's pretty much it.
	
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;

FAIL_DecimalFlag:
	CLD
FAIL_BFlag:
	LDA #$40
	STA $4017
	JMP TEST_Fail

TEST_BFlag: 
	;;; Test 1 [The B Flag]: The B flag of the 6502 processor flags is set by PHP ;;;
	PHP
	PLA
	STA <$50	; we'll get back to this one.
	AND #$10
	BEQ FAIL_BFlag
	INC <currentSubTest
	
	;;; Test 2 [The B Flag]: The B flag of the 6502 processor flags is set by BRK ;;;
	; Set up the BRK routine
	LDA #$4C
	STA $600
	STA $700	; also set this up now for the NMI test.
	LDA #LOW(TEST_BFlag_BRK)
	STA $601
	LDA #HIGH(TEST_BFlag_BRK)
	STA $602
	BRK
TEST_BFlag_BRK:
	PLA ; pull off processor flags.
	STA <$51	; we'll get back to this one.
	PLA ; pull off the return address
	PLA ; ^
	LDA <$51
	AND #$10
	BEQ FAIL_BFlag ; the B flag should be set.
	INC <currentSubTest
	
	;;; Test 3 [The B Flag]: This emulator should be capable of running an IRQ before I run an IRQ test. ;;;
	LDA #LOW(TEST_BFlag_BRK2)
	STA $601
	LDA #HIGH(TEST_BFlag_BRK2)
	STA $602
	SEI
	LDA #0
	STA $4017
	JSR Clockslide_30000
	CLI
	NOP
	NOP
	NOP
	SEI
	JMP TEST_Fail
	
TEST_BFlag_BRK2:
	LDA #$40
	STA $4017
	; this IRQ should set the interrupt flag, but better safe than sorry?
	SEI
	INC <currentSubTest
	
	;;; Test 4 [The B Flag]: The B Flag should not be set when processor flags get pushed by an IRQ ;;;
	PLA ; pull off processor flags.
	STA <$52	; we'll get back to this one.
	PLA ; pull off the return address
	PLA ; ^
	LDA <$52
	AND #$10
	BNE FAIL_BFlag ; the B flag should NOT be set.
	INC <currentSubTest
	
	;;; Test 5 [The B Flag]: The B Flag should not be set when processor flags get pushed by an NMI ;;;
	; we already set up $700 a while back.
	LDA #LOW(TEST_BFlag_NMI)
	STA $701
	LDA #HIGH(TEST_BFlag_NMI)
	STA $702
	JSR WaitForVBlank
	JSR Clockslide_20000
	JSR EnableNMI
TEST_BFlag_InfiniteLoop: ; just wait here for the NMI.
	JMP TEST_BFlag_InfiniteLoop ; if the NMI isn't implemented, then this test never could have even started, so don't worry about it.
TEST_BFlag_NMI:
	; this NMI should set the interrupt flag, but better safe than sorry?
	SEI
	JSR DisableNMI
	PLA ; pull off processor flags.
	STA <$53	; we'll get back to this one.
	PLA ; pull off the return address
	PLA ; ^
	LDA <$53
	AND #$10
	BNE FAIL_BFlag2 ; the B flag should NOT be set.
	INC <currentSubTest
	
	;;; Test 6, 7, 8, and 9 [The B Flag]: Bit 5 of the processor status is always set. ;;;
	LDX #0
TEST_BFlag_Bit5Loop:
	LDA <$50, X
	AND #$20
	BEQ FAIL_BFlag2
	INC <currentSubTest
	INX
	CPX #4
	BNE TEST_BFlag_Bit5Loop
	
	;; END OF TEST ;;
	LDA #1
	RTS
;;;;;;;
FAIL_BFlag2:
	LDA #$40
	STA $4017
	JMP TEST_Fail
;;;;;;;;;;;;;;;;;

FAIL_PPUReadBuffer:
	JSR ResetScroll
	JMP TEST_Fail
	
TEST_PPUReadBuffer:
	;;; Test 1 [PPU Read Buffer]: Reading from the PPU register at $2007 should work. ;;;
	; it is assumed that writing there works.
	JSR SetPPUADDRFromWord
	.byte $24, $00
	LDA #$5A
	STA $2007
	STA $2007
	STA $2007
	
	JSR SetPPUADDRFromWord
	.byte $24, $00
	LDA #0
	LDA $2007
	LDA $2007
	; this value should be $5A, even if the buffer isn't working.
	CMP #$5A
	BNE FAIL_PPUReadBuffer
	INC <currentSubTest
	
	;;; Test 2 [PPU Read Buffer]: Reading address $2007 should increment the "v" register. ;;;
	JSR ResetScrollAndWaitForVBlank
	JSR SetPPUADDRFromWord
	.byte $24, $00
	LDA #$00	; write 00, 01, 02, and 03 to the nametable.
	STA $2007	; ^
	LDA #$01	; ^
	STA $2007	; ^
	LDA #$02	; ^
	STA $2007	; ^
	LDA #$03	; ^
	STA $2007	; ^
	JSR SetPPUADDRFromWord
	.byte $24, $00
	LDA $2007	; this should put 0 in the buffer
	LDA $2007	; this should read 0 from the buffer, and put 1 in the buffer.
	LDA $2007	; this should read 1 from the buffer, and put 2 in the buffer.
	BEQ FAIL_PPUReadBuffer
	INC <currentSubTest

	;;; Test 3 [PPU Read Buffer]: There should be a 1-bute buffer when reading from $2007 ;;;
	CMP #1
	BNE FAIL_PPUReadBuffer
	INC <currentSubTest

	;;; Test 4 [PPU Read Buffer]: Reading from CHR ROM should use the buffer. ;;;
	JSR ResetScrollAndWaitForVBlank
	JSR SetPPUADDRFromWord
	.byte $00, $00
	LDA $2007 ; prep buffer with 00
	LDA $2007 ; read $00
	LDA $2007 ; read $3C from CHR ROM.
	CMP #$3C
	BNE FAIL_PPUReadBuffer
	INC <currentSubTest
	
	;;; Test 5 [PPU Read Buffer]: Reading from Palette RAM should NOT use the buffer. ;;;
	JSR ResetScrollAndWaitForVBlank
	JSR SetPPUADDRFromWord
	.byte $3F, $00
	LDA $2007 ; read $2D
	LDA $2007 ; read $30
	CMP #$30
	BNE FAIL_PPUReadBuffer2
	INC <currentSubTest
	
	;;; Test 6 [PPU Read Buffer]: Writing to $2006 does not modify the buffer value. ;;;
	JSR ResetScrollAndWaitForVBlank
	JSR SetPPUADDRFromWord
	.byte $24, $00
	LDA $2007 ; Prep buffer with 00
	LDA $2007 ; Prep buffer with 01
	LDA #$00
	STA $2006
	STA $2006 ; Move v to $0000
	LDA $2007 ; read the value of $01 from the buffer.
	CMP #$01
	BNE FAIL_PPUReadBuffer2
	INC <currentSubTest
	
	;;; Test 7 [PPU Read Buffer]: The value on the nametable at $2700 through $27FF should be put in the buffer when reading from palette RAM at $3F00 through $3FFF. ;;;
	JSR ResetScrollAndWaitForVBlank
	JSR SetPPUADDRFromWord
	.byte $27, $00
	LDA #$5A
	STA $2007	; VRAM $2700 = $5A
	JSR SetPPUADDRFromWord
	.byte $24, $00
	LDA $2007 ; Prep buffer with 00
	LDA $2007 ; Prep buffer with 01
	LDA $2007 ; Prep buffer with 02
	LDA #$3F
	STA $2006
	LDA #$00
	STA $2006 ; Move v to $3F00
	LDA $2007 ; read from palette RAM (buffer is now read from VRAM $2700 = $5A)
	LDA #$00
	STA $2006
	STA $2006 ; Move v to $0000
	LDA $2007 ; Read $5A from the buffer.	
	CMP #$5A
	BNE FAIL_PPUReadBuffer2

	;; END OF TEST ;;
	JSR ResetScroll
	LDA #1
	RTS
;;;;;;;
	
FAIL_PPUReadBuffer2:
	JSR ResetScroll
	JMP TEST_Fail

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                ENGINE                   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	.bank 3
	.org $EE40	
DPCM_Sample_68:
	.byte $68, $68, $68, $68, $68, $68, $68, $68, $68, $68, $68, $68, $68, $68, $68, $68
	.byte $68
	
	.org $EE80	
DPCM_Sample_A5:
	.byte $A5, $A5, $A5, $A5, $A5, $A5, $A5, $A5, $A5, $A5, $A5, $A5, $A5, $A5, $A5, $A5
	.byte $A5
	
	.org $EEC0	
DPCM_Sample_60:
	.byte $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60, $60
	.byte $60

	.org $EF00	
DPCM_Sample_48:
	.byte $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48, $48
	.byte $48
	
	.org $EF40
TEST_DMC_Conflicts_AnswerKey:
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	.byte $FF, $FF, $FF, $FF, $FF, $FF, $E1, $E0, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	
TEST_DMC_Conflicts_AnswerKey_Famicom:
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	.byte $FF, $FF, $FF, $FF, $FF, $FF, $F9, $E0, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF

	.org $EFC0
TEST_DMC_ConflictsSample:
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF

; Just a ton of helper functions letting me save some bytes in the tests, and also key functions for loading and navigating the main menu.
	.org $F000

EnableRendering:; Enables rending both sprites and background. Does not affect the other mask flags.
	PHA
	LDA <PPUMASK_COPY
	ORA #$18
	STA <PPUMASK_COPY
	STA $2001
	PLA
	RTS
;;;;;;;

EnableRendering_BG:; Enables rending the background. Does not affect the other mask flags.
	PHA
	LDA <PPUMASK_COPY
	ORA #$08
	STA <PPUMASK_COPY
	STA $2001
	PLA
	RTS
;;;;;;;

EnableRendering_S:; Enables rending sprites. Does not affect the other mask flags.
	PHA
	LDA <PPUMASK_COPY
	ORA #$10
	STA <PPUMASK_COPY
	STA $2001
	PLA
	RTS
;;;;;;;

DisableRendering:; Disables rending both sprites and background. Does not affect the other mask flags.
	PHA
	LDA <PPUMASK_COPY
	AND #$E7
	STA <PPUMASK_COPY
	STA $2001
	PLA
	RTS
;;;;;;;

DisableRendering_BG:; Disables rending the background. Does not affect the other mask flags.
	PHA
	LDA <PPUMASK_COPY
	AND #$F7
	STA <PPUMASK_COPY
	STA $2001
	PLA
	RTS
;;;;;;;

DisableRendering_S:; Disables rending sprites. Does not affect the other mask flags.
	PHA
	LDA <PPUMASK_COPY
	AND #$EF
	STA <PPUMASK_COPY
	STA $2001
	PLA
	RTS
;;;;;;;

EnableNMI:; Enables the NMI. Does not affect the other PPUCRTL flags.
	PHA
	LDA <PPUCTRL_COPY
	ORA #$80
	STA <PPUCTRL_COPY
	STA $2000
	PLA
	RTS
;;;;;;;

DisableNMI:; Disables the NMI. Does not affect the other PPUCRTL flags.
	PHA
	LDA <PPUCTRL_COPY
	AND #$7F
	STA <PPUCTRL_COPY
	STA $2000
	PLA
	RTS
;;;;;;;

ResetScroll:; sets the PPU "v" register to $2000
	LDA #$20
	STA $2006	; Update high byte of v to $20
	LDA #$00
	STA $2006   ; Update low byte of v to $00
	STA $2005	; Update fine X scroll with $00
	STA $2005	; Update fine Y scroll with $00
	RTS
;;;;;;;

ClearNametable:; Overwrites the nametable from $2000 to $27FF with $24. Attribute tables in this area are cleared to $00
	PHA
	LDA #$20
	STA $2006 ; Update high byte of v to $20
	LDA #$00
	STA $2006 ; Update low byte of v to $00
	LDA #$24
	LDX #$08
	LDY #$00
NTLoop1:
	STA $2007
	DEY
	BNE NTLoop1
	DEX
	BNE NTLoop1
	; Now set up the attributes properly
	LDA #$23
	STA $2006
	LDA #$C0
	STA $2006
	LDA #$00
	LDX #$40
NTLoop2:
	STA $2007
	DEX
	BNE NTLoop2
	; And the other attributes
	LDA #$27
	STA $2006
	LDA #$C0
	STA $2006
	LDA #$00
	LDX #$40
NTLoop3:
	STA $2007
	DEX
	BNE NTLoop3
	PLA
	RTS
;;;;;;;

ClearRAMExceptPage3: ; Clears RAM from $0000 to $07FF, except leaving $0300 through $3FF untouched.
	; page 3 is where I'm keeping the uninitialized RAM values, so don't clear that.
	; also don't clear the stack, ha.
	LDA #0
	LDX #0
ClearRamLoop:
	STA <$00,X
	STA $200,X
	STA $400,X
	STA $500,X
	STA $600,X
	STA $700,X
	INX
	BNE ClearRamLoop	
	RTS
;;;;;;;

ClearPage5: ; Page 5 is reserved for RAM used by tests. It's a good idea to clear this before any tests.
	LDA #0
	LDX #0
ClearPage5Loop:
	STA $500,X
	STA $600,X ; it also clears page 6. (The IRQ Vector points to $600, but there are no IRQs by default. Any test needing this space should initialize it during the test)
	STA $700,X ; it also clears page 7. (The NMI vector points to $700, but the NMI routine is set up again at the end of any tests, so don't worry)
	INX
	BNE ClearPage5Loop
	; let's also clear $50 - $6F on the zero page. also $20 to $2F
ClearPage5ZPLoop:
	STA <$20,X
	STA <$50,X
	STA <$60,X
	INX
	CPX #$10
	BNE ClearPage5ZPLoop
	RTS
;;;;;;;

ClearPage2: ; Page 2 is reserved for OAM. Let's clear it with FFs.
	STX <Copy_X	; Keep a copy of X
	LDA #$FF
	LDX #$F
ClearPage2Loop:
	STA $200,X
	STA $210,X
	STA $220,X
	STA $230,X
	STA $240,X
	STA $250,X
	STA $260,X
	STA $270,X
	STA $280,X
	STA $290,X
	STA $2A0,X
	STA $2B0,X
	STA $2C0,X
	STA $2D0,X
	STA $2E0,X
	STA $2F0,X
	DEX
	BPL ClearPage2Loop
	LDX <Copy_X ; restore X
	RTS
;;;;;;;

PrintText:
	; Following a JSR here should be .word $HiLo (the target PPU Address)
	; And following that .word should be a string "Hello World!" and a terminator, $FF
	; This function updates the return address, skipping the word and bytes.
	; Print the string (bytes) at the target PPU Address (word).
	STA <Copy_A	; Keep a copy of the A, X, and Y registers
	STY <Copy_Y	; ^
	STX <Copy_X	; ^
	LDA <dontSetPointer
	BNE PT_dontSetPointer
	JSR CopyReturnAddressToByte0
	LDY #1
	LDA $2002
	LDA [$0000],Y ; Read from the pointer
	STA <$03
	DEY
	LDA [$0000],Y
	STA <$04
	LDA #02
	JSR AddAToByte0
PT_dontSetPointer:
	LDA <$03
	STA $2006
	LDA <$04
	STA $2006
PTloop:
	LDA [$0000],Y
	CMP #$FF
	BEQ PTpostLoop
	TAX
	LDA AsciiToCHR, X ; convert from ascii to my 0123456789ABCDEFGHI... format
	LDX <HighlightTextPrinted
	BEQ PT_SkipHighlight
	ORA #$80
PT_SkipHighlight:
	STA $2007
	INY
	BNE PTloop ; Branch always to the loop
PTpostLoop:	
	INY
	LDA <dontSetPointer
	BNE PTskipFixRTS
	JSR FixRTS
	LDY <Copy_Y	; Restore Y
PTskipFixRTS:
	LDX <Copy_X ; Restore X
	LDA <Copy_A ; Restore A
	RTS
;;;;;;;

PrintTextCentered:
	; Following a JSR here should be .word $HiLo (the target PPU Address)
	; And following that .word should be a string "Hello World!" and a terminator, $FF
	; This function updates the return address, skipping the word and bytes.
	; Print the string (bytes) at the target PPU Address (word), except center the text to the middle of the screen.
	STA <Copy_A
	STY <Copy_Y
	STX <Copy_X
	LDA <dontSetPointer
	BNE PTC_dontSetPointer
	JSR CopyReturnAddressToByte0
	LDY #1
	LDA $2002
	LDA [$0000],Y ; Read from the pointer
	STA <$03
	DEY
	LDA [$0000],Y
	STA <$04
	LDA #02
	JSR AddAToByte0
	; Get length of the string.
PTC_dontSetPointer:
	LDY #0
PTCGetLength:
	INY
	LDA [$0000],Y
	CMP #$FF
	BNE PTCGetLength	
	LDA <$04 ; take pointer low byte
	AND #$E0  ; remove low 5 bits
	ORA #$10  ; add bit 5
	STA <$04
	TYA
	LSR A ; divide length by 2
	EOR #$FF ; make negative
	CLC
	ADC #01
	CLC
	ADC <$04 ; Add the low byte
	STA <$04
	LDA <$03
	STA $2006
	LDA <$04
	STA $2006	
	LDY #0
PTCloop:
	LDA [$0000],Y
	CMP #$FF
	BEQ PTCpostLoop
	TAX
	LDA AsciiToCHR, X ; convert from ascii to my 0123456789ABCDEFGHI... format
	LDX <HighlightTextPrinted
	BEQ PTC_SkipHighlight
	ORA #$80
PTC_SkipHighlight:
	STA $2007
	INY
	BNE PTCloop ; Branch always to the loop
PTCpostLoop:	
	INY
	LDA <dontSetPointer
	BNE PTCskipFixRTS
	JSR FixRTS
	LDY <Copy_Y
PTCskipFixRTS:
	LDX <Copy_X
	LDA <Copy_A
	RTS
;;;;;;;


Print32Bytes:
	; Following a JSR here should be .word $HiLo (the target PPU Address)
	; And following that word should be a second .word, acting as the "target address"
	; print the 32 bytes found at the target address at the target PPU address.
	STA <Copy_A
	STY <Copy_Y
	STX <Copy_X
	JSR CopyReturnAddressToByte0
	LDA $2002
	LDY #$01
	LDA [$0000],Y ; update PPUADDR
	STA $2006
	STA <$02
	DEY
	LDA [$0000],Y
	STA $2006
	STA <$03
	LDA #02
	JSR AddAToByte0	
	LDA [$0000],Y ; copy new pointer to $04 and $05
	STA <$04
	INY
	LDA [$0000],Y ; copy new pointer to $04 and $05
	STA <$05	
	LDY #0	
	LDX #0
P32Loop:
	LDA [$0004],Y	
	PHA ; get left nybble
	AND #$F0
	LSR A
	LSR A
	LSR A
	LSR A
	STA $2007	
	PLA ; get right nybble
	AND #$0F
	STA $2007
	LDA $2007 ; add a space
	INX
	CPX #08
	BNE P32SkipADDR
	LDX #0
	LDA <$03
	CLC
	ADC #$20
	STA <$03
	BCC P32SkipADDRHi
	INC <$02
P32SkipADDRHi:
	LDA <$02
	STA $2006
	LDA <$03
	STA $2006
P32SkipADDR:
	INY
	CPY #32
	BNE P32Loop
	; post loop
	LDY #02
	JSR FixRTS
	LDX <Copy_X
	LDY <Copy_Y
	LDA <Copy_A
	RTS
;;;;;;;

PrintCHR:	; Pretty much the same thing as "PrintText" but don't convert from ascii.
	STA <Copy_A
	STY <Copy_Y
	STX <Copy_X
	LDA <dontSetPointer
	BNE PChr_dontSetPointer
	JSR CopyReturnAddressToByte0
	LDY #1
	LDA $2002
	LDA [$0000],Y ; Read from the pointer
	STA <$03
	DEY
	LDA [$0000],Y
	STA <$04
	LDA #02
	JSR AddAToByte0
PChr_dontSetPointer:
	LDA <$03
	STA $2006
	LDA <$04
	STA $2006
PChrloop:
	LDA [$0000],Y
	CMP #$FF
	BEQ PChrpostLoop
	STA $2007
	INY
	BNE PChrloop ; Branch always to the loop
PChrpostLoop:	
	INY
	LDA <dontSetPointer
	BNE PChrskipFixRTS
	JSR FixRTS
	LDY <Copy_Y
PChrskipFixRTS:
	LDX <Copy_X
	LDA <Copy_A
	RTS
;;;;;;;

InitializeSpriteZero:	; Sets address $200 through $203 to the values found in the 4 bytes following the JSR to this subroutine.
	; This also adjusts the return address.
	JSR CopyReturnAddressToByte0
	LDY #0
InitializeSpriteZeroLoop:
	LDA [$0000],Y
	STA $200,Y
	INY
	CPY #4
	BNE InitializeSpriteZeroLoop
	JSR FixRTS
	RTS
;;;;;;;

InitializeSpriteX:	; Sets address $200+X*4 through $203+X*4 to the values found in the 4 bytes following the JSR to this subroutine.
	; This also adjusts the return address.
	JSR CopyReturnAddressToByte0
	LDA #$02
	STA <$03
	TXA
	ASL A
	ASL A
InitializeSpriteReUseThisForOAMAddrX:
	STA <$02
	LDY #0
InitializeSpriteXLoop:
	LDA [$0000],Y
	STA [$0002],Y
	INY
	CPY #4
	BNE InitializeSpriteXLoop
	JSR FixRTS
	RTS
;;;;;;;

InitializeOAMAddrX:; Sets address $200+X through $203+X to the values found in the 4 bytes following the JSR to this subroutine.
	; This also adjusts the return address.
	JSR CopyReturnAddressToByte0
	LDA #$02
	STA <$03
	TXA
	JMP InitializeSpriteReUseThisForOAMAddrX
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Read32NametableBytes:	; This is ran immediately after power on, and these values are stored for future printing in the "VRAM at power on" test.
	LDA #$20
	STA $2006
	LDA #$00
	STA $2006
	LDA $2007	
	LDX #0
ReadNametableLoop:	
	LDA $2007
	STA PowerOnVRAM, X
	INX
	CPX #$20
	BNE ReadNametableLoop
	RTS
;;;;;;;

ReadPaletteRAM: ; This is ran immediately after power on, and these values are stored for future printing in the "Palette RAM at power on" test.
	LDA #$3F
	STA $2006
	LDA #$00
	STA $2006	
	LDX #0
ReadPalLoop:	
	LDA $2007
	STA PowerOnPalette, X
	INX
	CPX #$20
	BNE ReadPalLoop
	RTS
;;;;;;;

DefaultPalette:	; The default palette for the main menu.
	.byte $2D,$30,$30,$30,$0F,$21,$21,$21,$0F,$26,$26,$26,$0F,$2D,$2D,$2D
	.byte $2D,$30,$30,$30,$0F,$30,$30,$30,$0F,$30,$30,$30,$0F,$30,$30,$30	
SetUpDefaultPalette: ; This function overwrites palette RAM with the values in the above table.
	LDA #$3F
	STA $2006
	LDA #$00
	STA $2006
	LDY #0
SetUpPaletteLoop:
	LDA DefaultPalette,Y
	STA $2007
	INY
	CPY #32
	BNE SetUpPaletteLoop
	RTS
;;;;;;;

AllTestMenuPalette:	; The color palette used in the results screen of the all-test-menu.
	.byte $2D,$30,$30,$30,$0F,$21,$21,$21,$0F,$26,$26,$26,$0F,$26,$06,$21
	.byte $2D,$30,$30,$30,$0F,$31,$31,$31,$0F,$30,$30,$30,$0F,$30,$30,$30	
SetUpAllTestMenuPalette: ; This function overwrites palette RAM with the values in the above table.
	LDA #$3F
	STA $2006
	LDA #$00
	STA $2006
	LDY #0
SetUpAllTestMenuPaletteLoop:
	LDA AllTestMenuPalette,Y
	STA $2007
	INY
	CPY #32
	BNE SetUpAllTestMenuPaletteLoop
	RTS
;;;;;;;
	
CopyReturnAddressToByte0: ; Several helper functions have a series of bytes following them that need to be read to adjust how the function runs.
	; For instance, JSR PrintText has a .word, and a string+terminator following a .byte
	; This function just takes the return address from the previous JSR instruction, adds 1 to it, and stores both bytes in a word at address $0000
	; That way, you can easily run LDA [$0000], Y to read the bytes that followed the JSR instruction.
	; NOTE: This will corrupt the stack. see FixRTS below.
	PLA
	STA <$02
	PLA
	STA <$03
	PLA
	STA <$00
	PLA
	STA <$01
	INC <$00 ; INC the low byte
	BNE CPYRTS0
	INC <$01 ; If needed, INC the high byte
CPYRTS0:	
	LDA <$03
	PHA
	LDA <$02
	PHA
	RTS
;;;;;;;
AddAToByte0: ; This function adds the A register to the word at $0000
	; Since many functions pull the return address off and store values at address $0000, it's very convenient to add a number to the word at $0000 
	CLC
	ADC <$00
	STA <$00
	BCC ADDRTS0
	INC <$01 ; If needed, INC the high byte
ADDRTS0:
	RTS
;;;;;;;
FixRTS:	; Correct the return address so any stack modifications for other functions won't cause issues
	PLA ; pull off the current return address	
	STA <$02
	PLA
	STA <$03 
	DEY ; the RTS address needs to be -1 of the following instruction.
	TYA
	JSR AddAToByte0
	LDA <$01 ; add byte0 to the return stack
	PHA
	LDA <$00
	PHA
	LDA <$03 ; add back the return address from this function
	PHA
	LDA <$02
	PHA
	RTS
;;;;;;;

LoadSuiteMenuNoRendering:	; This only sets up the pointers for tests and results, as well as menuHeight, without any updates to the nametable. Used in the "run every test in the ROM" subroutine.
	STY <Copy_Y
	LDA <suitePointer
	STA <$00
	LDA <suitePointer+1
	STA <$01
	; Address $0000 is now the suite pointer.
	LDY #0
	; The first part of a suite is the name, which we aren't rendering here, so let's keep looking until we find $FF.
LSMNR_Loop1:
	LDA [$0000], Y
	INY
	CMP #$FF
	BNE LSMNR_Loop1
	TYA
	CLC
	ADC <suitePointer
	STA <suitePointer
	BCC LSMNR_SkipInc
	INC <suitePointer+1
LSMNR_SkipInc:
	; Now that we're past the name of the suite, we need to loop over every entry for a page.
	; the format is: Name, $FF, ResultPointer, TestPointer
	; If the first byte of Name is $FF, then we loaded everything in a page.
	LDX #0
	STX <Copy_X
LSMNR_Loop2:
	LDY #0
	LDA <suitePointer
	STA <$00
	LDA <suitePointer+1
	STA <$01
	; Check if we're done with the page.
	LDA [$0000], Y
	CMP #$FF
	BNE LSMNR_SkipExit
	LDA <Copy_X
	LSR A
	STA <menuHeight
	LDY <Copy_Y
	RTS	
LSMNR_SkipExit:
	; Alright, let's skip this string.
	LDY #0
LSMNR_Loop3:
	LDA [$0000], Y
	INY
	CMP #$FF
	BNE LSMNR_Loop3
	TYA
	CLC
	ADC <suitePointer
	STA <suitePointer
	BCC LSMNR_SkipInc2
	INC <suitePointer+1
LSMNR_SkipInc2:
	LDA <suitePointer
	STA <$00
	LDA <suitePointer+1
	STA <$01
	; Now we grab the result pointer.
	LDY #0
	LDX <Copy_X
	LDA [$0000], Y
	STA <suitePointerList, X
	INY
	INX
	LDA [$0000],Y
	STA <suitePointerList, X
	INY
	DEX
	LDA [$0000],Y
	STA <suiteExecPointerList, X
	INY
	INX
	LDA [$0000],Y
	STA <suiteExecPointerList, X
	INY
	INX	
	STX <Copy_X
	; Y = 4.
	TYA
	CLC
	ADC <suitePointer
	STA <suitePointer
	BCC LSMNR_SkipInc3
	INC <suitePointer+1
LSMNR_SkipInc3:
	JMP LSMNR_Loop2
;;;;;;;;;;;;;;;;;;;

LoadSuiteMenu: ; Print a list of tests to run. If these tests have been ran before, print the results too!
	; assume the beginning of the suite is currently stored at suitePointer
	; print the name of the suite.
	; set up the PPU address to $2050	
	LDA #$20
	STA <$03
	LDA #$70
	STA <$04
	LDA #01
	STA <dontSetPointer
	;suitepointer is already set up, so...
	LDA <suitePointer
	STA <$00
	LDA <suitePointer+1
	STA <$01
	JSR PrintTextCentered
	; set up the PPU address to $20A8
	LDA #$20
	STA <$03
	LDA #$A8
	STA <$04
	LDX #0
LSM_Loop:
	; add Y to suitePointer
	TYA
	CLC
	ADC <suitePointer
	STA <suitePointer
	BCC LSM_SkipInc
	INC <suitePointer+1
LSM_SkipInc:
	LDA <$04
	CLC
	ADC #$40
	STA <$04
	BCC LSM_SkipInc2
	INC <$03
LSM_SkipInc2:
	LDA <suitePointer
	STA <$00
	LDA <suitePointer+1
	STA <$01
	LDY #0
	LDA [$0000],Y
	CMP #$FF
	BNE LSM_DontExitLoop
	TXA
	LSR A
	STA menuHeight
	RTS
LSM_DontExitLoop:
	JSR PrintText
	; then store the test results pointer
	LDA [$0000],Y
	STA <suitePointerList, X
	INY
	INX
	LDA [$0000],Y
	STA <suitePointerList, X
	INY
	DEX
	LDA [$0000],Y
	STA <suiteExecPointerList, X
	INY
	INX
	LDA [$0000],Y
	STA <suiteExecPointerList, X
	INY
	DEX	
	; let's also update the attribute tables before prepping X for the next loop.
	TXA
	PHA
	LSR A
	TAX
	JSR DrawTEST	

	JSR UpdateTESTAttributes
	PLA
	TAX
	INX
	INX	
	JMP LSM_Loop
;;;;;;;;;;;;;;;;
	
DrawTEST:	; This will print "TEST", "PASS", "FAIL x" or "...." depending on if the test has yet to be ran, passed, failed, or currently in progress.
	STY <$FE
	STX <$FD
	; relocate the PPU v register
	JSR GetVRegisterByXIndexForMenu
	; read the test results
	TXA
	ASL A
	TAX	
	LDA [suitePointerList,X]
	STA <currentSubTest
	; 0 = "TEST"
	; 1 = "PASS"
	; 2 = "FAIL"
	; 3 = "...." for a test in progress.
	;;;;;;;;;;;;
	AND #$3 ; bits 0 and 1 hold the results. Bits 3+ hold error codes for printing what failed.
	TAX
	TAY
	LDA TestPassFailBlend,Y
	TAY
	LDA AsciiToCHR,Y
	STA $2007
	TXA
	TAY
	LDA TestPassFailBlend+4,Y
	TAY
	LDA AsciiToCHR,Y
	STA $2007
	TXA
	TAY
	LDA TestPassFailBlend+8,Y
	TAY
	LDA AsciiToCHR,Y
	STA $2007
	TXA
	TAY
	LDA TestPassFailBlend+12,Y
	TAY
	LDA AsciiToCHR,Y
	STA $2007
	TXA
	AND #$3
	CMP #2 ; check if we failed.
	BNE DrawTESTEraseErrorCode
	; we failed, so print an error code.
	LDA #$24
	STA $2007
	lda <currentSubTest
	AND #$FC
	LSR A
	LSR A
DrawTESTEnd:
	STA $2007	
	LDY <$FE
	LDX <$FD
	RTS
DrawTESTEraseErrorCode:
	LDA #$24
	STA $2007
	BNE DrawTESTEnd
;;;;;;;



UpdateTESTAttributes: ; This will update the attributes for the test results "PASS", or "FAIL x", so they can be colored differently.
	STY <$FE
	STX <$FD
	; convert the x value to the attribute address, and determine top/bottom.
	LDA #$23
	STA <byte8
	STA $2006
	INX
	TXA
	AND #$FE
	; n = ((x+1)/2)
	ASL A
	ASL A
	; n *= 8
	CLC
	ADC #$C8
	; $23c8 + n
	STA <byte9
	STA $2006	
	LDA $2007
	LDA $2007
	STA <suiteAttributeCopy
	LDA $2007
	STA <suiteAttributeCopy+1
	LDA <byte8
	STA $2006
	LDA <byte9
	STA $2006
	; is this top or bottom?
	DEX
	TXA
	AND #01
	TAY
	LDA AttributeNybblesInverse, Y
	AND <suiteAttributeCopy
	STA <suiteAttributeCopy
	LDA AttributeNybblesInverse, Y
	AND <suiteAttributeCopy+1
	STA <suiteAttributeCopy+1
	
	; read the test results
	LDX <$FD
	TXA
	ASL A
	TAX	
	LDA [suitePointerList,X]
	AND #3
	TAX

	; the palette will be the results.
	LDA AttributePaletteNybbles,X
	AND AttributeNybbles, Y
	ORA <suiteAttributeCopy
	STA <suiteAttributeCopy
	LDA AttributePaletteNybbles,X
	AND AttributeNybbles, Y
	ORA <suiteAttributeCopy+1
	STA <suiteAttributeCopy+1
	
	LDA <suiteAttributeCopy
	STA $2007
	LDA <suiteAttributeCopy+1
	STA $2007
	
	LDY <$FE
	LDX <$FD
	RTS
;;;;;;;

HighlightTest:	; Swaps the characters on the nametable from the unhighlighted varsion to the highlighted version, or vice versa. (flip bit 7)
	JSR GetVRegisterByXIndexForMenu
	LDA $2007
	LDY #$00
CopyTestTextLoop:
	LDA $2007
	STA TESTHighlightTextCopy,Y
	INY
	CPY #$04
	BNE CopyTestTextLoop
	JSR GetVRegisterByXIndexForMenu
	LDY #$00
HighlightLoop:
	LDA TESTHighlightTextCopy,Y
	EOR #$80
	STA $2007
	INY
	CPY #$04
	BNE HighlightLoop
	RTS
;;;;;;;

HighlightPageNumber:	; Swaps the characters on the nametable from the unhighlighted varsion to the highlighted version, or vice versa. (flip bit 7)
	JSR SetPPUADDRFromWord
	.byte $20, $AA
	LDA $2007
	LDY #$00
HighlightPageNumberLoop:
	LDA $2007
	STA $7F0,Y ; this will get cleared before any tests run, so I don't feel bad for using these bytes here,
	INY
	CPY #$0C
	BNE HighlightPageNumberLoop
	JSR SetPPUADDRFromWord
	.byte $20, $AA
	LDY #$00
HighlightPageTextLoop:
	LDA $7F0,Y ; this will get cleared before any tests run, so I don't feel bad for using these bytes here,
	EOR #$80
	STA $2007
	INY
	CPY #$0C
	BNE HighlightPageTextLoop
	RTS
;;;;;;;

GetVRegisterByXIndexForMenu: ; Sets up the PPU's "v" register to print the name of the test at the right position, based on index X into the suite.
	; $20E1 + $40*X
	; High = ((X+3) >> 2) + 20
	TYA
	PHA
	TXA
	CLC
	ADC #$03
	LSR A
	LSR A
	CLC
	ADC #$20
	STA $2006
	; Low = VRegisterByXIndexLowLUT[X&3]
	TXA
	AND #$03
	TAY
	LDA VRegisterByXIndexLowLUT,Y
	STA $2006
	PLA
	TAY
	RTS
;;;;;;;

ReadPPUADDRFromWord: ; Takes the two bytes after the JSR instruction and stores them in $2006. Then reads $2007 twice.
	STY <$FE
	JSR CopyReturnAddressToByte0
	LDA $2002
	LDY #0
	LDA [$0000],Y
	STA $2006
	INY
	LDA [$0000],Y
	STA $2006
	INY
	JSR FixRTS
	LDY <$FE
	LDA $2007
	LDA $2007
	RTS
;;;;;;;
SetPPUADDRFromWord:	; pretty much the same as ReadPPUADDRFromWord, but it doesn't run LDA $2007 twice at the end.
	STA <$FF
	STY <$FE
	JSR CopyReturnAddressToByte0
	LDA $2002
	LDY #0
	LDA [$0000],Y
	STA $2006
	INY
	LDA [$0000],Y
	STA $2006
	INY
	JSR FixRTS
	LDY <$FE
	LDA <$FF
	RTS
;;;;;;;
WriteToPPUADDRWithByte:	; Sets up v then writes n to it, where n is the third bytes after the JSR
	STA <$FF
	STY <$FE
	JSR CopyReturnAddressToByte0
	LDA $2002
	LDY #0
WriteToPPUADDRWithByteLoop:
	LDA [$0000],Y
	CMP #$FF
	BEQ WriteToPPUADDRWithByteExit
	STA $2006
	INY
	LDA [$0000],Y
	STA $2006
	INY
	LDA [$0000],Y
	STA $2007
	INY
	JMP WriteToPPUADDRWithByteLoop
WriteToPPUADDRWithByteExit:
	INY
	JSR FixRTS
	LDY <$FE
	LDA <$FF
	RTS
;;;;;;;

DoubleLDA2007:	; There are a few tests that need to read the contents of a PPU address.
	LDA $2007	; and instead of actually writing out LDA $2007 twice (6 bytes)
	LDA $2007	; you can just jump here instead. (3 bytes)
	RTS
;;;;;;;

SetPPUReadBufferToA: ; Sets the value of the PPU Read buffer to A.
	PHA
	JSR SetPPUADDRFromWord
	.byte $24, $00
	STA $2007
	JSR SetPPUADDRFromWord
	.byte $24, $00
	LDA $2007
	PLA
	RTS
;;;;;;;

PrepNMI_TimingTests: ; This is re-used in a handful of NMI timing tests.
	LDA #$C8	; INY opcode
	STA $700
	LDA #$40	; RTI opcode
	STA $701
	JSR DisableRendering
	LDX #0
	RTS
;;;;;;;


VRegisterByXIndexLowLUT:	; a look up table used in GetVRegisterByXIndexForMenu
	.byte $E1, $21, $61, $A1

AttributeNybbles:			; Attribute nybbles used in UpdateTESTAttributes
	.byte $F0, $0F
AttributeNybblesInverse:	; Attribute nybbles used in UpdateTESTAttributes
	.byte $0F, $F0
	
AttributePaletteNybbles:	; Attribute nybbles used in UpdateTESTAttributes
	.byte $00, $55, $AA, $FF
	
TestPassFailBlend:			; These are used in DrawTEST. index 0 of each of these spells "TEST". index 1 spells "PASS" and so on.
	.byte "TPF."
	.byte "EAA."
	.byte "SSI."
	.byte "TSL."

AsciiToCHR:					; This table converts the ascii values stored in the ROM to the indexes into the pattern table I made.
	.byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24
	.byte $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24, $24
	.byte $24, $26, $24, $24, $35, $24, $24, $24, $24, $24, $32, $30, $29, $31, $25, $33
	.byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $28, $24, $24, $34, $24, $27
	.byte $24, $0A, $0B, $0C, $0D, $0E, $0F, $10, $11, $12, $13, $14, $15, $16, $17, $18
	.byte $19, $1A, $1B, $1C, $1D, $1E, $1F, $20, $21, $22, $23, $24, $24, $24, $24, $24
	.byte $24, $0A, $0B, $0C, $0D, $0E, $0F, $10, $11, $12, $13, $14, $15, $16, $17, $18
	.byte $19, $1A, $1B, $1C, $1D, $1E, $1F, $20, $21, $22, $23;, $24, $24, $24, $24, $24


NMI_Routine:
	; This is the NMI routine for the main menu.
	JSR ReadController1
	JSR MaskDpadConflicts
	LDA <controller_New
	AND #$20
	BNE NMI_DoDebugStuff
	JMP NMI_NotPressingSelect
NMI_DoDebugStuff:
	; Enter or exit debug mode.
	LDA <DebugMode
	BEQ NMI_EnterDebugMode
	; exiting debug mode.
	LDA #0
	STA <DebugMode
	LDA <PPUCTRL_COPY
	AND #$EF
	STA <PPUCTRL_COPY	; the tiles will use pattern table 2.
	STA $2000
	JSR SetPPUADDRFromWord
	.byte $20, $00
	LDA <PPUMASK_COPY
	AND #$FE
	STA <PPUMASK_COPY
	STA $2001
	JMP NMI_NotPressingSelect
NMI_EnterDebugMode:
	LDA #1
	STA <DebugMode
	LDA <PPUCTRL_COPY
	ORA #$10
	STA <PPUCTRL_COPY ; the tiles will use pattern table 1.
	STA $2000
	JSR DisableRendering
	JSR DisableNMI
	JSR ClearNametable2
	JSR SetPPUADDRFromWord
	.byte $25, $00
	LDX #0
NMI_EnterDebugModeLoop:
	LDA $500,X
	STA $2007
	INX
	BNE NMI_EnterDebugModeLoop
	JSR SetPPUADDRFromWord
	.byte $24, $A0
	LDX #0
NMI_EnterDebugModeLoop2:
	LDA <$50,X
	STA $2007
	INX
	CPX #$20
	BNE NMI_EnterDebugModeLoop2
	BNE NMI_EnterDebugModeLoop
	JSR SetPPUADDRFromWord
	.byte $24, $80
	LDX #0
NMI_EnterDebugModeLoop3:
	LDA <$20,X
	STA $2007
	INX
	CPX #$10
	BNE NMI_EnterDebugModeLoop3
	JSR SetPPUADDRFromWord
	.byte $27, $C0
	; set up attribute bytes.
	LDX #0
	LDA #$FF
NMI_EnterDebugModeLoop4:
	STA $2007
	INX
	CPX #$8
	BNE NMI_EnterDebugModeLoop4
	; next 8, write #F0
	LDA #$F0
NMI_EnterDebugModeLoop5:
	STA $2007
	INX
	CPX #$10
	BNE NMI_EnterDebugModeLoop5
	; next 16, write #00
	LDA #0
NMI_EnterDebugModeLoop6:
	STA $2007
	INX
	CPX #$20
	BNE NMI_EnterDebugModeLoop6
	; next 16, write #FF again
	LDA #$FF
NMI_EnterDebugModeLoop7:
	STA $2007
	INX
	CPX #$40
	BNE NMI_EnterDebugModeLoop7
	JSR WaitForVBlank
	LDA <PPUMASK_COPY
	ORA #$0A
	STA <PPUMASK_COPY
	STA $2001
	JSR EnableNMI
	JSR SetPPUADDRFromWord
	.byte $24, $00
	
	
NMI_NotPressingSelect:
	LDA <DebugMode
	BEQ NMI_Continue
	RTI	; skip the JSR ResetScroll when in debug mode.
NMI_Continue:
	LDA <menuCursorYPos
	LDX <menuCursorYPos
	BMI NMI_Menu_CursorAtTop
	; cursor is not at the top.
	LDA <controller_New
	AND #$80 ; A
	BEQ NMI_Menu_NotBeginningTest
	; Run test!
	JSR RunTest	
	JMP ExitNMI
NMI_Menu_NotBeginningTest:
	LDA <controller_New
	AND #$04 ; Down
	BEQ NMI_Menu_NotMovingDown
	INC <menuCursorYPos
	LDA <menuCursorYPos
	CMP <menuHeight
	BNE NMI_Menu_DownNotAtLength
	DEC <menuCursorYPos ; menuCursorYPos = menuHeight-1;
NMI_Menu_DownNotAtLength:
	JSR HighlightTest
	LDX <menuCursorYPos
	JSR HighlightTest
	JMP ExitNMI
	;;;
NMI_Menu_NotMovingDown:
	LDA <controller_New
	AND #$08 ; Up
	BEQ NMI_Menu_NotMovingUp
	; move cursor up
	DEC <menuCursorYPos
	JSR HighlightTest
	LDX <menuCursorYPos
	BMI NMI_Menu_DontPokeTextAgain
	JSR HighlightTest
NMI_Menu_NotMovingUp:
	JMP ExitNMI
NMI_Menu_DontPokeTextAgain:
	JSR HighlightPageNumber	; highlight the "page xx of yy" text.
	JMP ExitNMI
	
	;;;
NMI_Menu_CursorAtTop
	; cursor is at the top. if we press left or right, swap in a different set
	LDA <controller_New
	AND #$01 ; right
	BEQ NMI_Menu_Top_NotPressingRight
	; pressing Right
	LDA <menuTabXPos
	CMP #((EndTableTable - TableTable)/2)-1
	BNE NMI_Menu_SwapSuiteRight_SkipReset
	LDA #$FF
	STA <menuTabXPos
NMI_Menu_SwapSuiteRight_SkipReset:	
	INC <menuTabXPos	
	JSR DrawNewSuiteTable
	JMP ExitNMI
	
NMI_Menu_Top_NotPressingRight:
	LDA <controller_New
	AND #$02 ; left
	BEQ NMI_Menu_Top_NotPressingLeft
	; pressing Left
	LDA <menuTabXPos
	BNE NMI_Menu_SwapSuiteLeft_SkipReset
	LDA #((EndTableTable - TableTable)/2)
	STA <menuTabXPos
NMI_Menu_SwapSuiteLeft_SkipReset:
	DEC <menuTabXPos
	JSR DrawNewSuiteTable
	JMP ExitNMI	
	
NMI_Menu_Top_NotPressingLeft:
	; pressing down moves the cursor to 0.
	LDA <controller_New
	AND #$04 ; down
	BEQ NMI_Menu_Top_NotPressingDown
	LDA #0
	STA <menuCursorYPos
	LDX #0
	JSR HighlightTest
	JSR HighlightPageNumber	; unhighlight it.
NMI_Menu_Top_NotPressingDown:
	; If we press A, let's run every test in the suite automatically!
	LDA <controller_New
	AND #$80 ; A
	BEQ NMI_Menu_Top_NotPressingA
	JSR AutomaticallyRunEveryTestInSuite
NMI_Menu_Top_NotPressingA:
	; If we press Start, let's run every test in the ROM!
	LDA <controller_New
	AND #$10 ; Start
	BEQ NMI_Menu_Top_NotPressingStart
	JSR AutomaticallyRunEveryTestInROM
NMI_Menu_Top_NotPressingStart:
ExitNMI:
	JSR ResetScroll
	RTI
;;;;;;;

AutomaticallyRunEveryTestInSuite: ; This subroutine is used to run every test on a page automatically.
	LDA #1
	STA <AutomateTestSuite        ; The "AutomateTestSuite" varaible is used to prevent awkward highlighting of the test results.
	JSR DisableNMI                ; Disable the NMI, since we're not going to want any extra NMI's running in the middle of this.
	LDX #0
AutomaticallyRunEveryTestLoop:    ; This loop runs once per test on a page.
	STX <menuCursorYPos           ; The "menuCursorYPos" variable is used inside RunTest to determing what code to run.
	JSR RunTest                   ; Run the test at this index into the page.
	INX                           ; increment X until X=MenuHeight.
	CPX <menuHeight               ; The "menuHeight" is just how many tests are on a page.
	BNE AutomaticallyRunEveryTestLoop
	LDA #$FF
	STA <menuCursorYPos           ; A "menuCursorYPos" of $FF is the top of the menu. (Highlighting the page number)
	LDA #0
	STA <AutomateTestSuite        ; Disable the "AutomateTestSuite" varaible.
	JSR ResetScroll               ; Reset the PPU scroll.
	JSR EnableNMI                 ; And enable the MNI.
	RTS
;;;;;;;

SetUpSuitePointer:
	LDA <menuTabXPos
	ASL A
	TAX	
	LDA TableTable,X
	STA <suitePointer
	LDA TableTable+1,X
	STA <suitePointer+1
	RTS
;;;;;;;

DrawNewSuiteTable:	; Draws and prepares the suite, menuTabXPos
	JSR DisableNMI
	JSR DisableRendering
	JSR ClearNametable
	JSR SetUpSuitePointer
	JSR LoadSuiteMenu
	
	JSR DrawPageNumber
	
	; wait for vblank.
	JSR WaitForVBlank	
	JSR EnableRendering_BG
	JSR EnableNMI
	RTS
;;;;;;;

DrawPageNumber: ; Print "page xx / yy" at the top of the suite.	
	LDA #1
	STA <HighlightTextPrinted
	LDA #00
	STA <dontSetPointer
	JSR PrintText
	.word $20AA
	.byte "Page xx / yy", $FF
	JSR SetPPUADDRFromWord
	.byte $20, $AF
	LDA <menuTabXPos
	CLC
	ADC #1
	CMP #$0A
	BPL DNST_DontAdjustV
	LDA #$A4
	STA $2007
	LDA <menuTabXPos
	CLC
	ADC #1
DNST_DontAdjustV:
	JSR PrintByteDecimal_MinDigits
	JSR SetPPUADDRFromWord
	.byte $20, $B4
	LDA #((EndTableTable - TableTable)/2)
	JSR PrintByteDecimal_MinDigits
	LDA #0
	STA <HighlightTextPrinted
	RTS
;;;;;;;
	
ClearNametable2:
	JSR SetPPUADDRFromWord
	.byte $24, $00
	LDA #0
	TAY
	LDX #4
TEST_RMW2007_ClearNametable2Loop:
	STA $2007
	DEY
	BNE TEST_RMW2007_ClearNametable2Loop
	DEX
	BNE TEST_RMW2007_ClearNametable2Loop
	RTS
;;;;;;;
	
WaitForVBlank:	; This loops until VBlank begins. (updates the VBLank flag of $2002 to be cleared before returning)
	LDA $2002
WaitForVblLoop:
	LDA $2002
	BPL WaitForVblLoop
	RTS
;;;;;;;

ResetScrollAndWaitForVBlank:	; Resets the scroll and then waits for vblank.
	JSR ResetScroll
	JSR WaitForVBlank
	RTS
;;;;;;;

ReadController1:	; Some "proper" controller reading routine. Should work properly on Famicom as well as NES.
	LDA <controller
	STA <controller_New
	LDA #$01
	STA $4016
	LSR A
	STA $4016
	LDX #$08
RC_Loop:
	LDA $4016
	LSR A
	ROL <controller
	DEX
	BNE RC_Loop
	LDA <controller
	EOR <controller_New
	AND <controller
	STA <controller_New
	RTS
;;;;;;;

ReadControllerInto50_and_A:	; Reads controller port 1 8 times, storing the result in address 50, and also the A register.
	LDX #8
ReadControllerInto50_Loop:
	LDA $4016
	LSR A
	ROL <$50
	DEX
	BNE ReadControllerInto50_Loop
	LDA <$50
	RTS
;;;;;;;

MaskDpadConflicts:	; If you are holding both left + right, cancel them out. The same applies for up + down,
	LDA <controller
	AND #$F0
	STA <byteF
	LDA <controller
	AND #$0F
	TAY
	LDA DpadConflictMask,Y
	ORA <byteF
	STA <controller
	LDA <controller_New
	AND #$F0
	STA <byteF
	LDA <controller_New
	AND #$0F
	TAY
	LDA DpadConflictMask,Y
	ORA <byteF
	STA <controller_New
	RTS
;;;;;;;
	
DpadConflictMask: ; A LUT for masking the dpad values.
	.byte $00, $01, $02, $00, $04, $05, $06, $00, $08, $09, $0A, $08, $00, $01, $02, $00

RunTest:
	; This function sets things up, then jumps to "JSRFromRAM" where a JSR to the test occurs.
	; Basically, this makes a bunch of preparations for tests, like clearing page 5 of RAM, halting the NMI, etc.
	STA <Copy_A2                  ; Store the A register
	STY <Copy_Y2                  ; Store the Y register
	STX <Copy_X2                  ; Store the X register
	LDA <RunningAllTests
	BNE RunTest_AllTestSkipNMI	  ; If we're currently running all tests the NMI is already disabled, so we don't need to write to $2000 
	JSR DisableNMI	              ; We don't want the NMI occuring during the tests. (and if we do, overwrite the NMI function in RAM before enabling it)
RunTest_AllTestSkipNMI:
	LDX <menuCursorYPos           ; X = which test from the current suite we're running
	TXA
	ASL A				          ; Double X, since we're reading a 2-byte word from a list of 2-byte words.
	TAX
	LDA <suiteExecPointerList,X	  ; read the low byte of where the test occurs.
	STA <JSRFromRAM+1			  ; and store it in RAM next to a JSR opcode.
	LDA <suiteExecPointerList+1,X ; read the high byte of where the test occurs.
	STA <JSRFromRAM+2			  ; and store it in RAM next to the low byte.
								  ; `JSR [Test], RTS` now exists in RAM at "JSRFromRAM"
	LDA <suitePointerList,X	      ; read the low byte of where to store the test results.
	STA <TestResultPointer        ; and store it in RAM
	LDA <suitePointerList+1,X     ; read the high byte of where to store the test results.
	STA <TestResultPointer+1      ; and store it in RAM next to the low byte.
	LDA <RunningAllTests
	BNE RunTest_AllTestSkipDrawing1
	LDY #0
	LDA #3	                      ; a value of 3 here is used to draw "...." as the test status.
	STA [TestResultPointer],Y     ; mark this test as "in progress"
	LDX <menuCursorYPos           ; load X for the upcoming subroutines.
	JSR DrawTEST	              ; replace the word "TEST" with "...."
	JSR HighlightTest             ; and highlight it, since the cursor is still here.
	JSR ResetScroll		          ; Reset the scroll before the test, since we just modified 'v' inside the previous subroutines.
RunTest_AllTestSkipDrawing1:
	LDA #1
	STA <currentSubTest           ; set this to 1 before running any tests.
	STA <initialSubTest			  ; Some tests have multiple sets of tests to run, all using the same code. So writing here changes the test value.
	LDA #$80
	STA <Test_UnOp_SP			  ; Some tests might modify the stack pointer. The test will use a value of $80 just to be sure it's not overwriting other stack data.
	JSR ClearPage5		          ; clear RAM from $500 to $5FF. That RAM is dedicated for running tests, so we want it clean.
	JSR WaitForVBlank             ; this makes debugging your own emulator with this ROM much easier, since the test should always begin at the start of a frame.
	JSR JSRFromRAM                ; !! This is where the test occurs. "JSRFromRAM" is at address $001A. !!
	                              ; The A Register holds the results of the test.
	LDY #0
	STA [TestResultPointer],Y     ; store the test results in RAM.
	STA <Copy_A
	LDA <RunningAllTests
	BNE RunTest_AllTestSkipDrawing2
	LDA <Copy_A
	JSR WaitForVBlank			  ; and wait for VBlank before updating the "...." text with the results.
	LDX <menuCursorYPos		      ; load X for the upcoming subroutines.
	JSR DrawTEST			      ; draw "PASS" or "FAIL x"
	JSR UpdateTESTAttributes      ; and update the colors for that text.
	LDA <AutomateTestSuite
	BNE RunTest_SkipHighlightResult
	JSR HighlightTest		      ; and also highlight it, as the cursor is still there.
RunTest_SkipHighlightResult:
	JSR SetUpNMIRoutineForMainMenu; Recreate the NMI routine JMP, since some tests need their own NMI routine.
	JSR EnableNMI			      ; With the test over, re-enable the NMI
RunTest_AllTestSkipDrawing2:	  ; If we're running all tests, we don't need the NMI to run.
	JSR EnableRendering_BG	      ; and enable rendering too. This should still occur during Vblank.
	LDY <Copy_Y2			      ; Restore the Y register
	LDX <Copy_X2			      ; Restore the X register
	LDA <Copy_A2			      ; Restore the A register
	RTS
;;;;;;;

ClearNametableFrom2240:	; Some "tests" just print a bunch of values on screen around VRAM address $2240.
						; This function simply clears a good amount of VRAM from those tests.
	LDA #$22
	STA $2006
	LDA #$40
	STA $2006
	LDX #$10
	LDA #$24
ClearNTFrom2240Loop:	; I unrolled this loop to save CPU cycles, since I'd like all of this to happen inside VBlank, with time to spare to write mroe stuff.
	STA $2007
	STA $2007
	STA $2007
	STA $2007
	STA $2007
	STA $2007
	STA $2007
	STA $2007
	STA $2007
	STA $2007
	STA $2007
	STA $2007
	STA $2007
	STA $2007
	STA $2007
	STA $2007
	DEX
	BNE ClearNTFrom2240Loop
	RTS
;;;;;;;

ClearOverscanNametable:	; some tests draw tiles in the overscan area of the first nametable. This clears that.
	JSR WaitForVBlank
	JSR SetPPUADDRFromWord
	.byte $20, $00
	LDA #$24
	LDX #$32
ClearOverscanNametableLoop1:
	STA $2007
	DEX
	BNE ClearOverscanNametableLoop1
	JSR SetPPUADDRFromWord
	.byte $23, $A0
	LDA #$24
	LDX #32
ClearOverscanNametableLoop2:
	STA $2007
	DEX
	BNE ClearOverscanNametableLoop2
	JSR ResetScroll
	RTS
;;;;;;;


PrintByte:	; Takes the A register and prints each nybble seperately as two characters on the nametable at the current "v" address.
	; This doesn't make any stack shenanigans.
	PHA
	PHA
	STX <Copy_X
	AND #$F0
	LSR A
	LSR A
	LSR A
	LSR A
	LDX <HighlightTextPrinted
	BEQ PB_SkipHighlight
	ORA #$80
PB_SkipHighlight:
	STA $2007
	PLA
	AND #$0F
	LDX <HighlightTextPrinted
	BEQ PB_SkipHighlight1
	ORA #$80
PB_SkipHighlight1:
	STA $2007
	LDX <Copy_X
	PLA
	RTS
;;;;;;;

PrintByteDecimal:	; Takes the A register and prints a decimal representation of that value on the nametable at the current "v" address.
	; This doesn't make any stack shenanigans.
	PHA
	LDX #$FF
PBD_HundredsLoop:
	; Calculate the hundreds digit in decimal.
	INX
	SEC
	SBC #100
	BCS PBD_HundredsLoop
	; we underflowed. add 100 back.
	ADC #100
	PHA
	TXA
	LDX <HighlightTextPrinted
	BEQ PBD_SkipHighlightHundreds
	ORA #$80
PBD_SkipHighlightHundreds:
	STA $2007
	PLA
	LDX #$FF
PBD_TensLoop:
	; Calculate the hundreds digit in decimal.
	INX
	SEC
	SBC #10
	BCS PBD_TensLoop
	; we underflowed. add 10 back.
	ADC #10
	PHA
	TXA
	LDX <HighlightTextPrinted
	BEQ PBD_SkipHighlightTens
	ORA #$80
PBD_SkipHighlightTens:
	STA $2007
	PLA
	LDX <HighlightTextPrinted
	BEQ PBD_SkipHighlightOnes
	ORA #$80
PBD_SkipHighlightOnes:
	STA $2007
	PLA
	RTS
;;;;;;;

PrintByteDecimal_MinDigits:	; Takes the A register and prints a decimal representation of that value on the nametable at the current "v" address. Removes trailing zeroes.
	; This doesn't make any stack shenanigans.
	PHA
	LDX #1
	STX <PrintDecimalTensCheck
	LDX #$FF
PBDMD_HundredsLoop:
	; Calculate the hundreds digit in decimal.
	INX
	SEC
	SBC #100
	BCS PBDMD_HundredsLoop
	; we underflowed. add 100 back.
	ADC #100
	PHA
	TXA
	BEQ PBDMD_SkipHundredsDigit
	INC <PrintDecimalTensCheck
	LDX <HighlightTextPrinted
	BEQ PBDMD_SkipHighlightHundreds
	ORA #$80
PBDMD_SkipHighlightHundreds:
	STA $2007
PBDMD_SkipHundredsDigit:
	DEC <PrintDecimalTensCheck
	PLA
	LDX #$FF
PBDMD_TensLoop:
	; Calculate the hundreds digit in decimal.
	INX
	SEC
	SBC #10
	BCS PBDMD_TensLoop
	; we underflowed. add 10 back.
	ADC #10
	PHA
	TXA
	; if both this value and PrintDecimalTensCheck are zero, don't print a zero here. Otherwise, the hundreds digit was printed, and we need to print a zero here.
	ORA <PrintDecimalTensCheck
	BEQ PBDMD_SkipTensDigit
	TXA
	LDX <HighlightTextPrinted
	BEQ PBDMD_SkipHighlightTens
	ORA #$80
PBDMD_SkipHighlightTens:
	STA $2007
PBDMD_SkipTensDigit:
	PLA
	LDX <HighlightTextPrinted
	BEQ PBDMD_SkipHighlightOnes
	ORA #$80
PBDMD_SkipHighlightOnes:
	STA $2007
	PLA
	RTS
;;;;;;;

SetUpNMIRoutineForMainMenu:	; This sets up the values at $700 in RAM to be a JMP to the main menu's NMI routine. (The NMI points to address $700)
	LDA #$4C
	STA $700
	LDA #Low(NMI_Routine)
	STA $701
	LDA #High(NMI_Routine)
	STA $702
	RTS
;;;;;;;

DMASync_50CyclesRemaining:	; Sync the CPU and the DMA, such that the DMA runs exactly 50 CPU cycles after the RTS instruction ends.
	JSR DMASync
	; the DMA is in 406 cycles;
	JSR Clockslide_300 ; 406 -> 106
	JSR Clockslide_50  ; 106 -> 56
	RTS ; 56 -> 50 cycles after this RTS, a DMA will occur.
	
DMASync_50MinusACyclesRemaining: ; Sync the CPU and the DMA, such that the DMA runs exactly 50-A CPU cycles after the RTS instruction ends.
	JSR DMASync
	; the DMA is in 400 cycles;
	JSR Clockslide_100 ; 406 -> 306
	JSR Clockslide_100 ; 306 -> 206
	JSR Clockslide_50 ; 206 -> 156
	JSR Clockslide_40 ; 156 -> 116
	JSR Clockslide_21 ; 116 -> 95
	LDA <Test_UnOp_CycleDelayPostDMA ; 95 -> 92
	JSR Clockslide36_Plus_A	; 92 -> (56-A)
	RTS ; (56-A) -> (50-A) cycles after this RTS, a DMA will occur.
;;;;;;;

SyncTo1000CyclesUntilNMI:
	PHA
	LDA #$EA
	LDX #0
SyncTo1000CyclesUntilNMILoop:
	STA $500,X
	STA $600,X
	INX
	BNE SyncTo1000CyclesUntilNMILoop
	LDA #$4C
	STA $700
	LDA #LOW(ConvertReturnAddressIntoCPUCycles)
	STA $701
	LDA #HIGH(ConvertReturnAddressIntoCPUCycles)
	STA $702
	LDA #$60
	STA $6FF	; RTS at the end of page 6.
	JSR DisableRendering
	LDA #0
	JSR VblSync_Plus_A
	; We are now on dot 0 of Vblank
	JSR Clockslide_6000 ; 6000
	JSR EnableNMI		; 6031 (wait for vblank to end first)
	JSR Clockslide_20000; 26031
	JSR Clockslide_2000 ; 28031
	JSR Clockslide_700  ; 28731
	JSR Clockslide_41   ; 28772
	PLA
	RTS	;+6
;;;;;;;

ConvertReturnAddressIntoCPUCycles:
	TSX
	LDA $0103,X ; High byte of the return address
	; The latest the NMI can happen is from address $06F2.
	; Subtract 5 from the high byte.
	SEC
	SBC #$5
	STA <$60	; A very rare use of address $60, which is reserved for non-engine test stuff.
	LDA $0102,X ; Low byte of the return address.
	CLC
	ADC #$2		; add 2 (JSR takes 6 cycles, which would be equivilent to 3 NOPs. Then subtract 1 from 3, ( =2 ) since the NMI happens after the instruction ends.)
	STA <$61	; Keep in mind, these LDA's only work if the stack pointer isn't 00, but that's not really a concern here.
	LDA <$60	;
	ADC #0		; Add the carry.
	; Now, the total number of CPU cycles/2 is stored at $60.
	; Issue: Since we're dividing by 2, we don't know if we're on an even or an odd cycle.
	;
	; start by multiplying by 2.
	ASL A
	STA <$60
	ASL <$61
	LDA <$60
	ADC #0
	STA <$60
	; Okay, now we have the number of CPU cycles, &=$FFFE
	; If this was an even cycle, add 0. If this was an odd cycle, add 1.
	; We're pretty much just going to wait for the next NMI to determine this. LDX #1, and DEX. if the NMI happens before the DEX, then we add 1. Otherwise, add 0. 
	LDA #Low(CRAICPUC_NMI)
	STA $701
	LDA #High(CRAICPUC_NMI)
	STA $702
	JSR Clockslide_29700
	NOP			; +2
	NOP			; +2
	NOP
	NOP
	; Now we clockslide until there's either 2 or 3 cycles until the NMI.
	LDX #0
	; The NMI either happens here...
	INX
	; or here.
	JSR DisableNMI
	; At this point, the 16-bit number stored in $60 (little endian) is exactly 1000-TotalCyclesOfTheTest
	; So all we need to do to calculate TotalCyclesOfTheTest is subtract the 16-bit word at $60 from 1000
	SEC
	LDA #LOW(1000)
	SBC <$61
	STA <$61
	LDA #HIGH(1000)
	SBC <$60
	STA <$60	
	; Subtract the overhead:
	SEC
	LDA <$61
	SBC <$63
	STA <$61
	LDA <$60
	SBC <$62
	STA <$60	
	
	RTI	; returns to the test code.
	
CRAICPUC_NMI: ; Convert Return Address Into CPU Cycles NMI Routine
	TXA
	CLC
	ADC <$61
	STA <$61
	LDA <$60
	ADC <$60
	RTI
;;;;;;;




	; A giant list of ClockSlides!
	; "What's a clockslide?"
	; It's just a subroutine that wastes a precise amount of CPU cycles.
	; If you want to waste exactly n cycles, run JSR Clockslide_n
	; (Clockslide_14 through Clockslide_50 are defined, and most larger clockslides are a combination of JSRs to those clockslides)

Clockslide_100Minus12: ; This is very handy for the following clockslides I want to make. 100, 200, etc.
	JSR Clockslide_26 ;=32
	JSR Clockslide_50 ;=80
	RTS			      ;=100-12. Remember, JSR and RTS add 12 cycles, so to make clockslide 100, I just need to JSR somewhere with JSR Clockslide_100Minus12
;;;;;;;

Clockslide_50000:
	JSR Clockslide_10000
Clockslide_40000:
	JSR Clockslide_10000
Clockslide_30000:
	JSR Clockslide_10000
Clockslide_20000:
	JSR Clockslide_10000
Clockslide_10000:
	JSR Clockslide_1000
Clockslide_9000:
	JSR Clockslide_1000
Clockslide_8000:
	JSR Clockslide_1000
Clockslide_7000:
	JSR Clockslide_1000
Clockslide_6000:
	JSR Clockslide_1000
Clockslide_5000:
	JSR Clockslide_1000
Clockslide_4000:
	JSR Clockslide_1000
Clockslide_3000:
	JSR Clockslide_1000
Clockslide_2000:
	JSR Clockslide_1000
Clockslide_1000:
	JSR Clockslide_100
Clockslide_900:
	JSR Clockslide_100
Clockslide_800:
	JSR Clockslide_100
Clockslide_700:
	JSR Clockslide_100
Clockslide_600:
	JSR Clockslide_100
Clockslide_500:
	JSR Clockslide_100
Clockslide_400:
	JSR Clockslide_100
Clockslide_300:
	JSR Clockslide_100
Clockslide_200:
	JSR Clockslide_100
Clockslide_100:      
	JSR Clockslide_100Minus12 ; Since JSR and RTS take 12 cycles, let's stall for exactly 100-12 cycles.
	RTS
;;;;;;;

;A frame has about 29780 cycles, so let's make a few around that number.
Clockslide_29700:
	JSR Clockslide_100Minus12
	JSR Clockslide_600	;700
	JSR Clockslide_9000 ;9700
	JSR Clockslide_20000;29700
	RTS
;;;;;;;
Clockslide_29750:
	JSR Clockslide_100Minus12
	JSR Clockslide_50	;150
	JSR Clockslide_600	;750
	JSR Clockslide_9000 ;9750
	JSR Clockslide_20000;29750
	RTS
;;;;;;;
Clockslide_29780:
	JSR Clockslide_100Minus12
	JSR Clockslide_50	;150
	JSR Clockslide_30	;180
	JSR Clockslide_600	;780
	JSR Clockslide_9000 ;9780
	JSR Clockslide_20000;29780
	RTS
;;;;;;;
Clockslide_29776:
	JSR Clockslide_100Minus12
	JSR Clockslide_50	;150
	JSR Clockslide_26	;176
	JSR Clockslide_600	;776
	JSR Clockslide_9000 ;9776
	JSR Clockslide_20000;29776
	RTS
;;;;;;;
Clockslide_2269:
	JSR Clockslide_100Minus12
	JSR Clockslide_50	;150
	JSR Clockslide_19	;169
	JSR Clockslide_100	;269
	JSR Clockslide_2000 ;2269
	RTS
;;;;;;;

Clockslide_2252:
	JSR Clockslide_100Minus12
	JSR Clockslide_50	;150
	NOP					;152
	JSR Clockslide_100	;252
	JSR Clockslide_2000 ;2252
	RTS
;;;;;;;

Clockslide_2032:
	JSR Clockslide_100Minus12
	JSR Clockslide_32	;132
	JSR Clockslide_900	;1032
	JSR Clockslide_1000 ;2032
	RTS
;;;;;;;

Clockslide_1830:
	JSR Clockslide_100Minus12
	JSR Clockslide_30	;130
	JSR Clockslide_700	;830
	JSR Clockslide_1000	;1830
	RTS
;;;;;;;

Clockslide_1816:	   ;=6
	JSR Clockslide_100Minus12
	JSR Clockslide_16	;116
	JSR Clockslide_700	;816
	JSR Clockslide_1000	;1816
	RTS
;;;;;;;

Clockslide_14900:
	JSR Clockslide_100Minus12
	JSR Clockslide_800	;900
	JSR Clockslide_4000 ;4900
	JSR Clockslide_10000;14900
	RTS
;;;;;;;

Clockslide_29820:
	JSR Clockslide_100Minus12
	JSR Clockslide_20	;120
	JSR Clockslide_700	;820
	JSR Clockslide_9000 ;9820
	JSR Clockslide_20000;29820
	RTS
;;;;;;;

Clockslide_44730:
	JSR Clockslide_100Minus12
	JSR Clockslide_30	;130
	JSR Clockslide_600	;730
	JSR Clockslide_4000 ;4730
	JSR Clockslide_40000;44730
	RTS
;;;;;;;

Clockslide_37270:
	JSR Clockslide_100Minus12
	JSR Clockslide_50	;150
	JSR Clockslide_20	;170
	JSR Clockslide_100	;270
	JSR Clockslide_7000 ;7270
	JSR Clockslide_30000;37270
	RTS
;;;;;;;

Clockslide_52180:
	JSR Clockslide_100Minus12
	JSR Clockslide_50	;150
	JSR Clockslide_30	;180
	JSR Clockslide_2000 ;2180
	JSR Clockslide_50000;52180
	RTS
;;;;;;;

Clockslide_4320:
	JSR Clockslide_100Minus12
	JSR Clockslide_20	;120
	JSR Clockslide_200  ;320
	JSR Clockslide_4000 ;4320
	RTS
;;;;;;;

Clockslide_432:
	JSR Clockslide_100Minus12
	JSR Clockslide_32	;132
	JSR Clockslide_300  ;420
	RTS
;;;;;;;

Clockslide_8640:
	JSR Clockslide_100Minus12
	JSR Clockslide_40	;140
	JSR Clockslide_500  ;640
	JSR Clockslide_8000 ;8640
	RTS
;;;;;;;

Clockslide_12960:
	JSR Clockslide_100Minus12
	JSR Clockslide_40	;140
	JSR Clockslide_20	;160
	JSR Clockslide_800  ;960
	JSR Clockslide_2000 ;2960
	JSR Clockslide_10000 ;2960
	RTS
;;;;;;;

Clockslide_26352:
	JSR Clockslide_100Minus12
	JSR Clockslide_40	;140
	JSR Clockslide_12	;152
	JSR Clockslide_200  ;352
	JSR Clockslide_6000 ;6352
	JSR Clockslide_20000;26352
	RTS
;;;;;;;

Clockslide_1728:
	JSR Clockslide_100Minus12
	JSR Clockslide_28	;128
	JSR Clockslide_600  ;728
	JSR Clockslide_1000 ;1728
	RTS
;;;;;;;

Clockslide_29766:
	JSR Clockslide_100Minus12
	JSR Clockslide_50	;150
	JSR Clockslide_16	;166
	JSR Clockslide_600	;766
	JSR Clockslide_9000	;9766
	JSR Clockslide_20000;29766
	RTS
;;;;;;;

Clockslide_29765:
	JSR Clockslide_100Minus12
	JSR Clockslide_50	;150
	JSR Clockslide_15	;165
	JSR Clockslide_600	;765
	JSR Clockslide_9000	;9765
	JSR Clockslide_20000;29765
	RTS
;;;;;;;

Clockslide_3395:
	JSR Clockslide_100Minus12
	JSR Clockslide_50	;150
	JSR Clockslide_45	;194
	JSR Clockslide_200	;394
	JSR Clockslide_3000	;3394
	RTS
;;;;;;;

Clockslide_3380:
	JSR Clockslide_100Minus12
	JSR Clockslide_50   ;150
	JSR Clockslide_30   ;180
	JSR Clockslide_200	;380
	JSR Clockslide_3000	;3380
	RTS
;;;;;;;

Clockslide36_Plus_A:;+6
	STA <$00	; +3
	LDA #$FF	; +2
	STA <$01	; +3
	LDA #37		; +2
	SEC			; +2
	SBC <$00	; +3
	STA <$00	; +3
	JMP [$0000]	; 5 + A + 6
;;;;;;;;;;;;;;;;;

VblSync_Plus_A_End: ; Moved here for space. This is the end of the VblSync_Plus_A subroutine.
	JSR Clockslide_29780
	JSR Clockslide_29750
	NOP
	NOP
	NOP
	BIT $2002
	RTS
;;;;;;;

	.org $FDF3
TEST_IFlagLatency_PageBoundaryTest:
	;;; Test B [Interrupt Flag Latency]: Do branches poll for interrupts before cycle 4? (They should) ;;;
	JSR TEST_IFlagLatency_StartTest_10ExtraCycles ; clear address $50, and sync with DMA. X=0. We have 12 cycles until the DMA instead of the usual 2 these tests have used.
	LDA #$5A ; +2 (10 cycles until DMA)
	STA <$50 ; +3 (7 cycles until DMA)
	LDA <currentSubTest ; +3 cycles (4 cycles until DMA). This is also using a known non-zero-value, so this branch WILL be taken.
	CLI		 ; +2 cycles (2 cycles until DMA)
	BNE TEST_IFlagLatency_Branch3 ; [1: read opcode] (poll for interrupts, no interrupts) [2: read operand] [DMC DMA, set IRQ Level detector low] [3: move the PC] (Poll for interrupts, we got one!) [4: update PC high]
	NOP	; The PC will be here at address $FEFF while taking the branch.
	; Address $FE00:
	.byte $40 ; This is the DPCM sample used for the APU Register Activation test.

	; Address $FE01:
TEST_IFlagLatency_Branch3:
	; IRQ should happen here.
	INX
	LDA <$50
	CMP #$00
	BNE FAIL_IFlagLatency2

	;; END OF TEST ;;
	SEI
	LDA #1
	RTS
;;;;;;;
FAIL_IFlagLatency2:
	SEI
	JMP TEST_Fail
;;;;;;;;;;;;;;;;;
	; Address $FE0F:

	.org $FE49	
DMASyncWith40:
	; This fuction very relaibly exits with exactly 50 CPU cycles until the DMA occurs.
	; However, it relies on open bus behavior, with the consequence of an infinite loop if not correctly emulated.
	STA <Copy_A
	LDA #$4F ; loop, max speed.
	STA $4010
	LDA #0
	STA $4011 ; minimum value of DMC
	LDA #$F8
	STA $4012 ; Sample address $FE00.
	LDA #0
	STA $4013 ; #1 * 16 + 1 = 17 byte length.
	LDA #$14
	STA $4015 ; Start the DMC DMA loop (with triangle playing)
	NOP
	NOP
DMASync40_Loop:
	LDA $5000 ; Open bus! Either we will read $40 from the high byte, or $00 from the DMA.
	;	[Read AD] [Read 00] [Read 40] [DMA PUT (1)] [DMA GET (2)] [DMA PUT (3)] [DMA GET (4)] [Read open bus (5)]
	CMP #$40
	BNE DMASync40_Loop ; If the DMA occurs, BIT $5000 will read $40 (Setting overflow flag) ; +2 (7)
	LDA #$0F ; don't loop, continue at max speed. +2 (9)
	STA $4010 
	LDA <$00  
	LDA Copy_A
	JSR Clockslide_100
	JSR Clockslide_100
	JSR Clockslide_100
	JSR Clockslide_50
	; Let's also set the triangle channel to play something, so the APU STATUS isn't #$00
	NOP
	CMP <$C9
	RTS 
	; so we have 50 cycles to go.
		
DMASyncWithoutOpenBus:
	; This function *should* exit with exactly 406 CPU cycles until the DMA occurs.
	; It's a very slightly modified version of the DMA sync routine made by blargg in 2005. (This version has an exit condition in case the DMA timing is so off that it would loop forever.)
	; It doesn't rely on reading open bus, rather is just simply relies on perfectly timed DMAs, and the 3 or 4 cpu cycle delay after writing to $4015.
	; It's worth noting that function *is* consistent on hardware, and it does work. However, despite this, a lot of emulators have incorrect timing for reads from $4015, and won't actually be in sync after this runs.
	; Hence the existence of the open bus DMA Sync routine, but wouldn't you know it- even fewer emulators implement the DMC DMA updating the data bus, so... not much I can do about that.
	LDX #0
    LDA #$80	; Sloest Speed
    STA $4010	; Also enable the DMC IRQ
    LDA #0
    STA $4013	; Length = 0 (+1)
    LDA $4015	; Disable DMC
      
    LDA #$10
    STA $4015 ; Enable DMC (clear the DMC buffer)
	NOP
	STA $4015 ; Enable DMC a second time.
      
    ; Coarse synchronize
dma_sync_loop1:
    BIT $4015	; This only exits once bit 4 is cleared.
    BNE dma_sync_loop1
    NOP      
    ; Fine synchronize. 3421+4 clocks per iter
    NOP               ; 2
    NOP               ; 2
    LDA #226          ; 3391 delay
    BNE dma_sync_first; 3
dma_sync_wait:
    LDA #226          ; 3406 delay
	; 15 extra CPU cycles.
	INX
	BEQ sync_dmc_fail
	CMP <$00
	NOP
	NOP
	NOP
	NOP
dma_sync_first:
    NOP
    NOP
    NOP
    NOP
    SEC
    SBC #1
    BNE dma_sync_first
                     ; 4 DMC wait-states
    LDA #$10         ; 2
    STA $4015        ; 4
    NOP              ; 2
    BIT $4015        ; 4
    BNE dma_sync_wait; 3
    ; The DMA is now synced!

	LDA #$0F
	STA $4010
    JSR Clockslide_3380
	NOP
	LDA #$10
    STA $4015
	LDA #$10
    STA $4015
	NOP
	NOP
	NOP
	NOP
	
	RTS				  ; 412 -> 406
	; the next DMA is at (432) cycles, so we have 406 cycles to go.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
sync_dmc_fail:
	RTS	; The DMA timing will be way off on this test, but it was unable to sync anyway, so... Better than infinite looping?

	.org $FF00
Clockslide:
	; JSR takes 6 cycles.
	; The following bytes are labeled with the total cycles until the RTS instruction ends.
	; Clockslide has a minimum of 12 cycles.
	; EXAMPLE USE: Let's count CPU cycles!
	; LDA #00            ; +2 cycles
	; STA $0100          ; +4 cycles
	; JSR Clockslide_45  ; +45 cycles
	; LDA $2002			 ; +3 cycles
	
Clockslide_50:
	.byte $C9
Clockslide_49:
	.byte $C9
Clockslide_48:
	.byte $C9
Clockslide_47:
	.byte $C9
Clockslide_46:
	.byte $C9
Clockslide_45:
	.byte $C9
Clockslide_44:
	.byte $C9
Clockslide_43:
	.byte $C9
Clockslide_42:
	.byte $C9
Clockslide_41:
	.byte $C9
Clockslide_40:
	.byte $C9
Clockslide_39:
	.byte $C9
Clockslide_38:
	.byte $C9
Clockslide_37:
	.byte $C9
Clockslide_36:
	.byte $C9
Clockslide_35:
	.byte $C9
Clockslide_34:
	.byte $C9
Clockslide_33:
	.byte $C9
Clockslide_32:
	.byte $C9
Clockslide_31:
	.byte $C9
Clockslide_30:
	.byte $C9
Clockslide_29:
	.byte $C9
Clockslide_28:
	.byte $C9
Clockslide_27:
	.byte $C9
Clockslide_26:
	.byte $C9
Clockslide_25:
	.byte $C9
Clockslide_24:
	.byte $C9
Clockslide_23:
	.byte $C9
Clockslide_22:
	.byte $C9
Clockslide_21:
	.byte $C9
Clockslide_20:
	.byte $C9
Clockslide_19:
	.byte $C9
Clockslide_18:
	.byte $C9
Clockslide_17:
	.byte $C9
Clockslide_16:
	.byte $C9
Clockslide_15:
	.byte $C5
Clockslide_14:
	.byte $EA
Clockslide_12:
	.byte $60
;;;;;;;;;;;;;

DMASync: ; Line up the CPU and the DMA. The DMA occurs 406 CPU cycles after the RTS. (typically, this leads into a few clockslides, and another RTS)
	LDA <result_DMADMASync_PreTest ; Check if we need to run the "does the DMA update the data bus" test.
	BEQ TEST_DoesTheDMAUpdateOpenBus ; if we haven't ran this yet, run this test, then return back here.
	CMP #01
	BEQ DMASync_TheGoodOne
	JMP DMASyncWithoutOpenBus
DMASync_TheGoodOne:
	; This fuction very relaibly exits with exactly 406 CPU cycles until the DMA occurs.
	; However, it relies on open bus behavior, with the consequence of an infinite loop if not correctly emulated.
	STA <Copy_A
	LDA #$4F ; loop, max speed.
	STA $4010
	LDA #0
	STA $4011 ; minimum value of DMC
	LDA #$FF
	STA $4012 ; Sample address $FFC0.
	LDA #0
	STA $4013 ; #1 * 16 + 1 = 17 byte length.
	LDA #$10
	STA $4015 ; Start the DMC DMA loop
	NOP
	NOP
DMASync_Loop:
	LDA $4000 ; Open bus! Either we will read $40 from the high byte, or $00 from the DMA.
	;	[Read AD] [Read 00] [Read 40] [DMA PUT (1)] [DMA GET (2)] [DMA PUT (3)] [DMA GET (4)] [Read open bus (5)]
	BNE DMASync_Loop ; If the DMA occurs, LDA $4000 will read $00 ; +2 (7)
	LDA #$0F ; don't loop, continue at max speed. ; +2 (9)
	STA $4010 ; +4 (13)
	LDA <$00  ; +3 (16)
	LDA Copy_A; +4 (20)
	RTS 	  ; +6 (26)
	; the next DMA is at (432) cycles, so we have 406 cycles to go.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
TEST_DoesTheDMAUpdateOpenBus:
	; let's find out!
	STA <Copy_A
	LDA #$4F ; loop, max speed.
	STA $4010
	LDA #0
	STA $4011 ; minimum value of DMC
	LDA #$FF
	STA $4012 ; Sample address $FFC0.
	LDA #0
	STA $4013 ; #1 byte length. (I still have 17 00s in a row since other tests do use a length of 17)
	LDA #$10
	STA $4015 ; Start the DMC DMA loop
	LDX #0
	LDY #0
TEST_DoesTheDMA_Loop:
	DEX
	BNE TEST_DoesTheDMA_LoopPostDec
	DEY
	BEQ TEST_DoesTheDMA_Fail
TEST_DoesTheDMA_LoopPostDec:
	LDA $4000
	BNE TEST_DoesTheDMA_Loop
	LDA #01
	STA <result_DMADMASync_PreTest
	JMP DMASync
TEST_DoesTheDMA_Fail:
	LDA #02
	STA <result_DMADMASync_PreTest
	JMP DMASync
;;;;;;;;;;;;;;;	
	
VblSync: ; sync the CPU to vblank.
	PHA
	SEI
	LDA #0
	STA $2000	

	LDA $2002
VblSync_Loop1:    
	LDA $2002
	BPL VblSync_Loop1
	
	JSR Clockslide_29750
	JSR Clockslide_21	

	LDA $2002
	BMI VblSync_skip4
	LDA $0000	;+4 cycles
VblSync_skip4:
    JSR Clockslide_21
	JMP VblSync_Loop2 ;+3 cycles
;;;;;;;;;;;;;;;;;;;;;

	.org $FFBE
VblSync_ABORT:	; This emulator failed to pre-test, implying that this will loop infinitely, so instead of doing that, just don't bother.
	PLA
	RTS
;;;;;;;

	.org $FFC0
	; 17 00s. This will be the DPCM "audio sample" played during the CMD DMA Sync loop. It should just be silence.
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

VblSync_Loop2:
	JSR Clockslide_16
	LDA $2002
	LDA $2002
	BPL VblSync_Loop2
	
	PLA
	RTS
;;;;;;;

VblSync_Plus_A: ; In this context, A is a PPU cycle.
	PHA
	LDA <result_VblankSync_PreTest		; Check if this sync routine will loop infinitely.
	BMI VblSync_ABORT	; If it will, just RTS without syncing. It was going to fail the test anyway with frame timing that incorrect.
	PLA
	JSR VblSync	; Sync to VBlank
VblSync_Plus_A_Loop:   
	JSR Clockslide_29750 ; wait 29774 cycles
	JSR Clockslide_24
	CLC						; + 2
	ADC #$FF 				; + 2
	BCS VblSync_Plus_A_Loop ; + 3 if looping, 2 otherwise. (29781 CPU cycles if looping. Each frame is 29780.67 CPU cycles long, so this advances 1 PPU cycle)
	JMP VblSync_Plus_A_End	; I ran out of space, so I moved it up there.
	
	;.org $FFF5
TEST_FFFF_Branch_Wraparound:
	; This is part of test 3 of Test_FFFF_Plus_X_Wraparound
	; A = 0, so this branch to $0050 is always taken.
	LDA #0
	.byte $F0, $57; BNE $0050
	; Address $0050 is a branch to this RTS.
	RTS
;;;;;;;
	.org $FFFA	; Interrupt vectors go here:
	.word $0700 ; NMI
	.word RESET ; Reset
	.word $0600 ; IRQ

	;;;; MORE COMPILER STUFF, ADDING THE PATTERN DATA ;;;;

	.incchr "Sprites.pcx"
	.incchr "Tiles.pcx"