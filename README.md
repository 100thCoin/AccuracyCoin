# AccuracyCoin
A large collection of NES accuracy tests on a single NROM cartridge.

This ROM was designed for the RP2A03G CPU, and the RP2C02G PPU. Some tests might fail on hardware with a different revision.

This ROM currently has 107 tests, each composed of several smaller tests in order to print error codes narrowing down the specific issues your NES emulator might have.

Here's an example of the menu in this ROM, shown on an emulator failing a few tests, passing others, and a few tests on screen haven't been ran yet. (The cursor is currently next to the "RAM Mirroring" test.)

![AccuracyCoin_Page1](https://github.com/user-attachments/assets/ad0cb426-cd84-4784-8b7c-f7dcfecc882a)

# Navigating the menus
Use the DPad to move the cursor up or down.  
If the cursor is at the top of the page (highlighting the current page index), pressing left and right will scroll to a new page of tests.  
If the cursor is at the top of the page (highlighting the current page index), pressing A will run all tests on the page.  
If the cursor is at the top of the page (highlighting the current page index), pressing Start will run all tests on the ROM, and then draw a table showing the results of every test.

Examples:

![Result_Table](https://github.com/user-attachments/assets/523aca93-0f43-4253-addc-9d23ae776b63)

The top 3 tests on page 9 have two different acceptable results depending on the CPU revision, so the light blue number will indicate which behavior was detected.

# Error Codes
For more information, I recommend reading the fully commented assembly code for the test.

### ROM is not Writable
  1: Writing to ROM should not overwrite the byte in ROM.  

### RAM Mirroring
  1: Reading from a 13-bit mirror of an address in RAM should have the same value as the 11-bit address.  
  2: Writing to a 13-bit mirror of an address in RAM should write to the 11-bit address.  

### $FFFF + X Wraparound
  1: Reading from address $FFFF + X, (Where X = 1) should loop around to address $0000.  
  2: Reading from address $FFFF + Y, (Where Y = 1) should loop around to address $0000.  
  3: Writing to address $FFFF + X (Where X = 1) should loop around to address $0000.  
  4: You should be able to branch from page $FF to the zero page, and then back.  
  5. Executing address $FFFF should read address $0000 and $0001 as the operands.  

### PPU Register Mirroring
  1: PPU Registers should be mirrored through $3FFF.  

### PPU Register Open Bus
  1: Reading from a write-only register PPU should return the most recently written value to the PPU Data Bus.  
  2: All PPU Registers should update the PPU Data Bus when written.  
  3: Bits 0 through 4 when reading from address $2002 should read read the PPU Data Bus.  
  4: The PPU Data Bus value should decay before 1 second passes.  

### Dummy read cycles
  1: A mirror of PPU_STATUS ($2002) should be read twice by LDA $20F2, X (where X = $10).  
  2: The dummy read should not occur if a page boundary is not crossed.  
  3: The dummy read was on an incorrect address.  
  4: The STA, X instruction should have a dummy read.  
  5: The STA, X dummy read was on an incorrect address.  
  6: LDA (Indirect), Y should not have a dummy read if a page boundary is not crossed by the Y indexing.  
  7: LDA (Indirect), Y should have a dummy read if a page boundary is crossed by the Y indexing.  
  8: STA (Indirect), Y should not have a dummy read if a page boundary is not crossed by the Y indexing.  
  9: STA (Indirect), Y should have a dummy read if a page boundary is crossed by the Y indexing.  
  A: LDA (Indirect, X) should not have a dummy read.  
  B: STA (Indirect, X) should not have a dummy read.  

### Dummy write cycles
  1: PPU Open Bus should exist.  
  2: Read-Modify-Write instructions should write to $2006 twice.  
  3: Read-Modify-Write instructions with X indexing should write to $2006 twice.  

### Open Bus
  1: Reading from open bus is not all zeroes.  
  2: Reading from open bus with LDA Absolute should simply return the high byte of the operand.  
  3: Indexed addressing crossing a page boundary should not update the data bus to the new high byte value.  
  4: The upper 3 bits when reading from the controller should be open bus.  
  5: Moving the program counter to open bus should read instructions from the floating data bus values.  
  6: Dummy Reads should update the data bus.  
  7: Reading from $4015 should not update the databus.  
  8: Writing should always update the databus, even writing to $4015.  

### Unofficial Instructions
  1: NOP Absolute should not be a 1-byte NOP.  
  2: NOP Absolute should not be a 2-byte NOP.  
  3: NOP Absolute reading address $2002 should clear the VBlank flag.  
  4: Does SLO Absolute do vaguely what's expected of it?  
  5: Does ANC Immediate do vaguely what's expected of it?  
  6: Does RLA Absolute do vaguely what's expected of it?  
  7: Does SRE Absolute do vaguely what's expected of it?  
  8: Does ASR Immediate do vaguely what's expected of it?  
  9: Does RRA Absolute do vaguely what's expected of it?  
  A: Does ARR Immediate do vaguely what's expected of it?  
  B: Does SAX Absolute do vaguely what's expected of it?  
  C: Does ANE Immediate do vaguely what's expected of it?  
  D: Does SHA Absolute, Y do vaguely what's expected of it?  
  E: Does SHX Absolute, Y do vaguely what's expected of it?  
  F: Does SHY Absolute, X do vaguely what's expected of it?  
  G: Does SHS Absolute, Y do vaguely what's expected of it?  
  H: Does SHA (Indirect) Y do vaguely what's expected of it?  
  I: Does LAX Absolute do vaguely what's expected of it?  
  J: Does LXA Immediate do vaguely what's expected of it?  
  K: Does LAE Absolute, Y do vaguely what's expected of it?  
  L: Does DCP Absolute do vaguely what's expected of it?  
  M: Does AXS Immediate do vaguely what's expected of it?  
  L: Does ISC Absolute do vaguely what's expected of it?  

### Unofficial Instructions: SLO, RLA, SRE, RRA, SAX, LAX, DCP, ISC, ANC, ASR, ARR, ANE, LXA, AXS, SBC, LAE
  0: This instruction had the wrong number of operand bytes.  
  1: The target address of the instruction was not the correct value after the test. (Not applicable to the "Immediate" addressing mode.)  
  2: The A register was not the correct value after the test.  
  3: The X register was not the correct value after the test.  
  4: The Y register was not the correct value after the test.  
  5: The CPU Status flags were not correct after the test.  
  6: The Stack pointer was not the correct value after the test. (Only applicable to LAE)  

### Unofficial Instructions: SHA, SHX, SHY
  F: The high byte corruption did not match either known behavior. (Only applicable to SHA. Corruption with SHX and SHY is consistent across revisions.)  
  0: This instruction had the wrong number of operand bytes.  
  1: The target address of the instruction was not the correct value after the test.  
  2: The A register was not the correct value after the test.  
  3: The X register was not the correct value after the test.  
  4: The Y register was not the correct Value after the test.  
  5: The CPU Status flags were not correct after the test.  
  6: If the RDY line goes low 2 cycles before the write cycle, The target address of the instruction was not the correct value after the test.  
  7: If the RDY line goes low 2 cycles before the write cycle, The A register was not the correct value after the test.  
  8: If the RDY line goes low 2 cycles before the write cycle, The X register was not the correct value after the test.  
  9: If the RDY line goes low 2 cycles before the write cycle, The Y register was not the correct Value after the test.  
  A: If the RDY line goes low 2 cycles before the write cycle, The CPU Status flags were not correct after the test.  

 ### Unofficial Instructions: SHS
  F: The high byte corruption did not match either known behavior.  
  0: This instruction had the wrong number of operand bytes.  
  1: The target address of the instruction was not the correct value after the test.  
  2: The A register was not the correct value after the test.  
  3: The X register was not the correct value after the test.  
  4: The Y register was not the correct Value after the test.  
  5: The CPU Status flags were not correct after the test.  
  6: The Stack pointer was not the correct value after the test.  
  7: If the RDY line goes low 2 cycles before the write cycle, The target address of the instruction was not the correct value after the test.  
  8: If the RDY line goes low 2 cycles before the write cycle, The A register was not the correct value after the test.  
  9: If the RDY line goes low 2 cycles before the write cycle, The X register was not the correct value after the test.  
  A: If the RDY line goes low 2 cycles before the write cycle, The Y register was not the correct Value after the test.  
  B: If the RDY line goes low 2 cycles before the write cycle, The CPU Status flags were not correct after the test.  
  C: If the RDY line goes low 2 cycles before the write cycle, The Stack pointer was not the correct value after the test.  

### Interrupt flag latency
  1: An IRQ should occur when a DMC sample ends, the DMC IRQ is enabled, and the CPU's I Flag is clear.  
  2: The IRQ should occur 2 instructions after the CLI instruction. (The CLI instruction polls for interrupts before cycle 2.)  
  3: An IRQ should be able to occur 1 cycle after the final cycle of an SEI instruction. (The SEI instruction polls for interrupts before cycle 2.)  
  4: If an IRQ occurs 1 cycle after the final cycle of an SEI instruction, the I flag should be set in the values pushed to the stack.  
  5: An IRQ should run again after an RTI, if the Interrupt was not acknowledged and the I flag was not set when pushed to the stack.  
  6: The IRQ should occur 1 cycle after the final cycle of an RTI instruction.  (The I flag is pulled off the stack before RTI polls for interrupts.)  
  7: The IRQ should occur 2 instructions after the PLP instruction. (The PLP instruction polls for interrupts before cycle 2.)  
  8: The DMA triggered an IRQ on the wrong CPU cycle.  
  9: Branch instructions should poll for interrupts before cycle 2.  
  A: Branch instructions should not poll for interrupts before cycle 3.  
  B: Branch instructions should poll for interrupts before cycle 4.  

### NMI Overlap BRK
  1: BRK Returned to the wrong address.  
  2: Either NMI timing is off, or interrupt hijacking is incorrectly handled.  

### NMI Overlap IRQ
  1: Either NMI timing is off, IRQ Timing is off, or interrupt hijacking is incorrectly handled.  

### APU Length Counter
  1: Reading from $4015 should not state that the pulse 1 channel is playing before you write to $4003.  
  2: Reading from $4015 should state that the pusle 1 channel is playing after you write to $4003  
  3: Writing $80 to $4017 should immediately clock the Length Counter.  
  4: Writing $00 to $4017 should not clock the Length Counter.  
  5: Disabling the audio channel should immediately clear the length counter to zero.  
  6: The length counter shouldn't be set when the channel is disabled.  
  7: If the channel is set to play infinitely, it shouldn't clock the length counter.  
  8: If the channel is set to play infinitely, the length counter should be left unchanged.  

### APU Length Table
  1: When writing %00000--- to address $4003, the pulse 1 length counter should be set to 10  
  2: When writing %00001--- to address $4003, the pulse 1 length counter should be set to 254  
  3: When writing %00010--- to address $4003, the pulse 1 length counter should be set to 20  
  4: When writing %00011--- to address $4003, the pulse 1 length counter should be set to 2  
  5: When writing %00100--- to address $4003, the pulse 1 length counter should be set to 40  
  6: When writing %00101--- to address $4003, the pulse 1 length counter should be set to 4  
  7: When writing %00110--- to address $4003, the pulse 1 length counter should be set to 80  
  8: When writing %00111--- to address $4003, the pulse 1 length counter should be set to 6  
  9: When writing %01000--- to address $4003, the pulse 1 length counter should be set to 160  
  A: When writing %01001--- to address $4003, the pulse 1 length counter should be set to 8  
  B: When writing %01010--- to address $4003, the pulse 1 length counter should be set to 60  
  C: When writing %01011--- to address $4003, the pulse 1 length counter should be set to 10  
  D: When writing %01100--- to address $4003, the pulse 1 length counter should be set to 14  
  E: When writing %01101--- to address $4003, the pulse 1 length counter should be set to 12  
  F: When writing %01110--- to address $4003, the pulse 1 length counter should be set to 26  
  G: When writing %01111--- to address $4003, the pulse 1 length counter should be set to 14  
  H: When writing %10000--- to address $4003, the pulse 1 length counter should be set to 12  
  I: When writing %10001--- to address $4003, the pulse 1 length counter should be set to 16  
  J: When writing %10010--- to address $4003, the pulse 1 length counter should be set to 24  
  K: When writing %10011--- to address $4003, the pulse 1 length counter should be set to 18  
  L: When writing %10100--- to address $4003, the pulse 1 length counter should be set to 48  
  M: When writing %10101--- to address $4003, the pulse 1 length counter should be set to 20  
  N: When writing %10110--- to address $4003, the pulse 1 length counter should be set to 96  
  O: When writing %10111--- to address $4003, the pulse 1 length counter should be set to 22  
  P: When writing %11000--- to address $4003, the pulse 1 length counter should be set to 192  
  Q: When writing %11001--- to address $4003, the pulse 1 length counter should be set to 24  
  R: When writing %11010--- to address $4003, the pulse 1 length counter should be set to 72  
  S: When writing %11011--- to address $4003, the pulse 1 length counter should be set to 26  
  T: When writing %11100--- to address $4003, the pulse 1 length counter should be set to 16  
  U: When writing %11101--- to address $4003, the pulse 1 length counter should be set to 28  
  V: When writing %11110--- to address $4003, the pulse 1 length counter should be set to 32  
  W: When writing %11111--- to address $4003, the pulse 1 length counter should be set to 30  

### Frame Counter IRQ
  1: The IRQ flag should be set when the APU Frame counter is in the 4-step mode, and the IRQ flag is enabled.  
  2: The IRQ flag should not be set when the APU Frame counter is in the 4-step mode, and the IRQ flag is disabled.  
  3: The IRQ flag should not be set when the APU Frame counter is in the 5-step mode, and the IRQ flag is enabled.  
  4: The IRQ flag should not be set when the APU Frame counter is in the 5-step mode, and the IRQ flag is disabled.  
  5: Reading the IRQ flag should clear the IRQ flag.  
  6: Changing the Frame Counter to 5-step mode after the flag was set should not clear the flag.  
  7: Disabling the IRQ flag should clear the IRQ flag.  
  8: The IRQ flag was enabled too early. (writing to $4017 on an odd CPU cycle.)  
  9: The IRQ flag was enabled too late. (writing to $4017 on an odd CPU cycle.)  
  A: The IRQ flag was enabled too early. (writing to $4017 on an even CPU cycle.)  
  B: The IRQ flag was enabled too late. (writing to $4017 on an even CPU cycle.)  
  C: Reading $4015 on the same cycle the IRQ flag is set, should not clear the IRQ flag. (it gets set again on the following 2 CPU cycles)  
  D: Reading $4015 1 cycle later than the previous test should not clear the IRQ flag. (it gets set again on the following CPU cycle)  
  E: Reading $4015 1 cycle later than the previous test should not clear the IRQ flag. (it gets set again on this CPU cycle)  
  F: Reading $4015 1 cycle later than the previous test should clear the IRQ flag.  
  G: The Frame Counter Interrupt flag should not have been set 29827 cycles after resetting the frame counter.  
  H: The Frame Counter Interrupt flag should have been set 29828 cycles after resetting the frame counter, even if suprressing Frame Counter Interrupts.  
  I: The Frame Counter Interrupt flag should have been set 29829 cycles after resetting the frame counter, even if suprressing Frame Counter Interrupts.  
  J: The Frame Counter Interrupt flag should not have been set 29830 cycles after resetting the frame counter if suprressing Frame Counter Interrupts.  
  K: Despite the Frame Counter Interrupt flag being set for those 2 CPU cycles, if suppressing Frame Counter Interrupts, an IRQ should not occur.  

### Frame Counter 4-step
  1: The first clock of the length counters was early.  
  2: The first clock of the length counters was late.  
  3: The second clock of the length counters was early.  
  4: The second clock of the length counters was late.  
  5: The third clock of the length counters was early.  
  6: The third clock of the length counters was late.  

### Frame Counter 5-step
  1: The first clock of the length counters was early.  
  2: The first clock of the length counters was late.  
  3: The second clock of the length counters was early.  
  4: The second clock of the length counters was late.  
  5: The third clock of the length counters was early.  
  6: The third clock of the length counters was late.  

### Delta Modulation Channel
  1: Reading address $4015 should set bit 4 when the DMC is playing, and clear bit 4 when the sample ends.  
  2: Restarting the DMC should re-load the sample length.  
  3: Writing $10 to $4015 should start palying a new sample if the previous one ended.  
  4: Writing $10 to $4015 while a sample is currently playing shouldn't affect anything.  
  5: Writing $00 to $4015 should immediately stop the sample.  
  6: Writing to $4013 shouldn't change the sample length of the currently playing sample.  
  7: The DMC IRQ Flag should not be set when disabled.  
  8: The DMC IRQ Flag should be set when enabled, and a sample ends.  
  9: Reading $4015 should not clear the IRQ flag.  
  A: Writing to $4015 should clear the IRQ flag.  
  B: Disabling the IRQ flag should clear the IRQ flag.  
  C: Looping samples should loop.  
  D: Looping samples should not set the IRQ flag when they loop.  
  E: Clearing the looping flag and then setting it again should keep the sample looping.  
  F: Clearing the looping flag should not immediately end the sample. The sample should then play for it's remaining bytes.  
  G: A looping sample should re-load the sample length from $4013 every time the sample loops.  
  H: Writing $00 to $4013 should result in the following sample being 1 byte long.  
  I: There should be a one-byte buffer that's filled immediately if empty.  
  J: The DMA occured on the wrong CPU cycle.  
  K: The Sample Address should overflow to $8000 instead of $0000  
  L: Writing to $4015 when the DMC timer has 2 cycles until clocked should not trigger a DMC DMA until after the 3 or 4 CPU cycle delay of writing to $4015.  
  M: Writing to $4015 when the DMC timer has 1 cycle until clocked should not trigger a DMC DMA until after the 3 or 4 CPU cycle delay of writing to $4015.  
  N: Writing to $4015 when the DMC timer has 0 cycles until clocked should not trigger a DMC DMA until after the 3 or 4 CPU cycle delay of writing to $4015.  

### DMA + Open Bus
  1: LDA $4000 should not read back $00 if a DMA did not occur.  
  2: The DMC DMA was either on the wrong cycle, or it did not update the data bus.  

### DMA + $2007 Read
  1: The PPU Read Buffer is not working.
  2: The DMC DMA was either on the wrong cycle, or the halt/alignment cycles did not read from $2007.  
  3: The halt/alignment cycles did not increment the "v" register of the PPU enough times.  

### DMA + $2007 Write
  1: DMA + $2007 Read did not pass.  
  2: The DMA was not delayed by the write cycle.  

### DMA + $4015 Read
  1: The APU Frame Timer Interrupt Flag was never set.  
  2: The DMC DMA was either on the wrong cycle, or the halt/alignment cycles did not read from $4015, which should have cleared the APU Frame Timer Interrupt Flag.  

### DMA + $4016 Read
  1: The DMC DMA was either on the wrong cycle, or the halt/alignment cycles did not read from $4016, which otherwise should have clocked the controller port.  

### Controller Strobing
  1: A value of $02 written to $4016 should not strobe the controllers.  
  2: Any value with bit 0 set written to $4016 should strobe the controllers.  
  3: Controllers should be strobed when the CPU transitions from a "get" cycle to a "put" cycle.  
  4: Controllers should not be strobed when the CPU transitions from a "put" cycle to a "get" cycle.  

### APU Register Activation
  1: A series of prerequisite tests failed. CPU and PPU open bus, the PPU Read Buffer, DMA + Open Bus, and DMA + $2007 Read.  
  2: Reading from $4015 should clear the APU Frame Counter Interrupt flag.  
  3: The OAM DMA should not be able to read from the APU registers if $40 is written to $4016, and the CPU Address Bus is not in the range of $4000 to $401F.  
  4: Something went wrong during the open bus execution. Controller port 2 was possibly clocked too many times.  
  5: The OAM DMA should be able to read from the APU registers (and mirrors of them) if $40 is written to $4016, and the CPU Address Bus is in the range of $4000 to $401F.  
  6: Bus conflicts with the APU registers were not properly emulated.  
  7: Despite the controller registers not being visible in OAM, the controllers should still be clocked.  

### DMC DMA Bus Conflicts
  1: The DMA did not occur on the correct CPU cycle.  
  2: The DMC DMA did not correctly emulate the bus conflict with the APU registers.  
  3: The DMC DMA bus conflict should clear the APU Frame Counter Interrupt Flag.  

### PPU Reset Flag
  1: The PPU registers shouldn't be usable before the end of the first VBlank.  

### VBlank beginning
  1: The PPU Register $2002 VBlank flag was not set at the correct PPU cycle.  

### VBlank end
  1: The PPU Register $2002 VBlank flag was not cleared at the correct PPU cycle.  

### NMI Control
  1: The NMI should not occur when disabled.  
  2: The NMI should occur at vblank when enabled.  
  3: The NMI should occur when enabled during vblank, if the Vblank flag is enabled.  
  4: The NMI should not occur when enabled during vblank, if the Vblank flag is disabled.  
  5: The NMI should not occur a second time if writing $80 to $2000 when the NMI flag is already enabled.  
  6: The NMI should not occur a second time if writing $80 to $2000 when the NMI flag is already enabled, and the NMI flag was enabled going into VBlank.  
  7: The NMI should occur an additional time if you disable and then re-enable the NMI.  
  8: The NMI should occur 2 instructions after the NMI is enabled. (see Interrupt flag latency)  

### NMI Timing
  1: The NMI did not occur on the correct PPU cycle.  

### NMI Suppression
  1: The NMI did not occur on the correct PPU cycle, or the NMI was not suppressed by a precicely timed read of address $2002.  

### NMI at VBlank end
  1: The NMI could occur too late, or was disabled too early.  

### NMI disabled at VBlank
  1: The NMI could occur too late, or was disabled too early.  

### Instruction Timing
  1: The NMI timing was not relaible enough.  
  2: LDA Immediate should take 2 cycles.  
  3: LDA Zero Page should take 3 cycles.  
  4: LDA Absolute should take 4 cycles.  
  5: LDA Absolute, X should take 4 cycles if a page boundary is not crossed.  
  6: LDA Absolute, X should take 5 cycles if a page boundary is crossed.  
  7: LDA (Indirect, Y) should take 5 cycles in a page boundary is not crossed.  
  8: LDA (Indirect, Y) should take 6 cycles in a page boundary is crossed.  
  9: JMP Absolute should take 3 cycles  
  A: LDA (Indirect, X) should take 6 cycles  
  B: ASL A, ROL A, LSR A, ROR A, TSX, TXS, TAX, TXA, TAY, TYA, DEX, INX, DEY, INY, and NOP all should take 2 cycles.  
  C: JSR should take 6 cycles  
  D: RTS should take 6 cycles  
  E: PHA should take 3 cycles  
  F: PLA should take 4 cycles  
  G: PHP should take 3 cycles  
  H: PLP should take 4 cycles  

### Sprite 0 Hit behavior
  1: A Sprite Zero Hit did not occur.  
  2: Sprite zero hits should not happen if Background Rendering is disabled.  
  3: Sprite zero hits should not happen if Sprite Rendering is disabled.  
  4: Sprite zero hits should not happen if both sprites and background Rendering are disabled.  
  5: Sprite zero hits should not happen if sprite zero is completely transparent.  
  6: Sprite zero hits should be able to happen at X=254.  
  7: Sprite zero hits should not be able to happen at X=255.  
  8: Sprite zero hits should not happen if sprite zero is at X=0, and the PPU's 8 pixel mask is enabled (show BG, no sprite).  
  9: Sprite zero hits should not happen if sprite zero is at X=0, and the PPU's 8 pixel mask is enabled (show sprite, no BG).  
  A: Despite the 8 pixel mask, if the sprite has visible pixels beyond the mask the Sprite Zero Hit should occur.  
  B: Sprite zero hits should be able to happen at Y=238.  
  C: Sprite zero hits should nopt be able to happen at Y>=239  
  D: Your sprites are being rendered one scanline higher than they should be, or your sprite zero hit detection isn't actually checking for "solid pixels" overlapping.  
  E: The sprite zero hit flag was set too early.  

### Arbitrary Sprite zero
  1: Sprite 0 should trigger a sprite zero hit. No other sprite should.  
  2: The first processed sprite of a scanline should be treated as "sprite zero".  
  3: Misaligned OAM should be able to trigger a sprite zero hit.  

### Sprite overflow behavior
  1: Evaluating 9 sprites in a single scanline should set the Sprite Overflow Flag.  
  2: The Sprite Overflow Flag should not be the same thing as the CPU's Overflow flag.  
  3: Evaluating only 8 sprites in a single scanline should not set the Sprite Overflow Flag.  

### Misaligned OAM behavior
  1: Misaligned OAM should be able to trigger a sprite zero hit.  
  2: Misaligned OAM should stay misaligned until an object's Y position is out of the range of this scanline, at which point the OAM address is incremented by 4 and bitwise ANDed with $FC.  
  3: If Secondary OAM is full when the Y position is out of range, instead of incrementing the OAM Address by 4 and bitwise ANDing with $FC, you should instead only increment the OAM address by 5.  
  4: Misaligned OAM should re-align in an object's X position is out of the range of this scanline, at which point the OAM address is incremented by 1 and bitwise ANDed with $FC.  
  5: If Secondary OAM is full when the X position is out of range, instead of incrementing the OAM Address by 1 and bitwise ANDing with $FC, you should instead only increment the OAM address by 5.  
  6: The same as test 4, but the initial OAM address was $02 instead of $01. If you see this error code, you might have a false positive on test 4.  
  7: The same as test 5, but the initial OAM address was $03 instead of $01. If you see this error code, you might have a false positive on test 5.  

### Address $2004 behavior
  1: Writes to $2004 should update OAM and increment the OAM address by 1.  
  2: Reads from $2004 should give you a value in OAM, but do not increment the OAM address.  
  3: Reads from the attribute bytes should be missing bits 2 through 5.  
  4: Reads from $2004 during PPU cycle 1 to 64 of a visible scanline (with rendering enabled) should always read $FF.  
  5: Reads from $2004 during PPU cycle 1 to 64 of a visible scanline (with rendering disabled) should do a regular read of $2004.  
  6: Writing to $2004 on a visible scanline should increment the OAM address by 4.  
  7: Writing to $2004 on a visible scanline shouldn't write to OAM.  
  8: Reads from $2004 during PPU cycle 65 to 256 of a visible scanline (with rendering enabled) should read from the current OAM address.  
  9: Reads from $2004 during PPU cycle 256 to 320 of a visible scanline (with rendering enabled) should always read $FF.  

### RMW $2007 Extra Write
  1: A Read-Modify-Write instruction to address $2007 should perform an extra write where the low byte of the PPU address written is the result of the Read-Modify-Write instruction.  
  2: This extra write should not occur when "v" is pointing to Palette RAM.  
  3: If "v" is pointing to Palette RAM, this extra write should not get written to the nametable.  
  4: If "v" is pointing to Palette RAM, this extra write should simply occur at "v" after it was incremented from the read cycle.  
