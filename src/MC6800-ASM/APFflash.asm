*  APF2SD v2.0 FOR THE APF MP-1000
*  -----------------------------
*
*  Tom Williams / July 2011 (vers 1.03) / June-2013 (vers 2.0)
*  Simple reader for CH376 interface
*  and 8K of RAM, mapped to the cart.
*
*  We will bank-switch the BOOT-ROM out
*  and that action will map the RAM (which was
*  just loaded with the Cartridge code) into $8000-$9FFF
*  Before we bank-switch, all of the RAM is available
*  at $A000-$BFFF.
*
*  Original code just had one option,
*  It also assumed that a 1-Gig, FAT-32
*  was always available, with one 8k file in root...
*  Usually, this was APFBOOT.BIN, but could named anything.
*  Revision-1 had very little error handling:
*    1: missing/unseated USB or SD.
*    2: cannot find file in root.
*  If either of these happend, it printed the error and
*  went into an infinite loop so the message stayed on-screen.
*  There were no calls to the joystick or user interaction.
*
*  I am using VAPF to format the screens
*  with decent color choices and menu layouts.
*
*  I also want to add a simple text-file reader.
*
* ------------
*   /// Tom.Williams  May-29-2013  ///
*   moving to version 2, we want this to be a different
*   hardware architecture than vers 1.03 due to LRS IPR.
*   ----------
*   /// Tom.Williams  June-01-2013 ///
*   1) do away with the "auto start" of the code.
*   2) simplify the bank-switching to just switch out the ROM.
*      bank-switch by write to $3800-$38FF. (0011,1000,xxxx,xxxx)
*   3) use "write behind" to load programs to the 8K RAM.
*   4) import the file-list and stop booting to APFBOOT.BIN
*   5) fix chicken and the egg problem by copying RTS block to RAM
*   6) need to figure out problem with WAIT4JOY
* ------------
*   // Tom.Williams  June-03 to June-06, 2013 //
*   Hardware is a bit of a mess, the 22v10 was eventually replaced
*   with an ATF20v8B .. this is in prep for moving to 16v8 in future...
*   Re-programmed 20v8 several times, got Space Destroyers to work using
*   the 8K EEPROM and 8K RAM  ( lower 6K ROM mapped, upper 2K RAM mapped )
*   Used a new EEPROM (ATF28C64A) and a new ATF20v8B, mapped 8K RAM to $A000-$BFFF
*   22v8B output for $C000-$CFFF not used (re-purposed)
*   Map CH376 RD#,WR#,CS# to remaining 20v8B pins.  Try init routine.... ... ..
* ------------
*   /// Tom.Williams  June-08-2013 ///
*   1) clean up the comments and remove references to ver 1.03 bank-switching.
*   2) remove bank-switching code chunks for old version. NIX (3) above.
*   3) switch to BLACK Background for text display.  (want to)
*   4) remove WAIT4JOY and use NEWJOY  ; why isn't joystick routine working?
*   5) read through Rocket-Patrol ROM Disassembly, remove NEWJOY
* ------------
*   // Tom.Williams  June-12-2013 //   **GOTCHA**
*    1) change all labels to 8 chars or less.
*    2) fix the Byte-to-Hex-Char routine.
*    3) add LED output using 74LS197... maybe we can get the CH376 init to "go"
*    4) add RAM-TEST routine... prove out more 20v8B PLD WinCUPL equations.
* ------------
*  // Tom.Williams  June-15-2013 //
*    1) posted to the Yahoo group, asking about the MENUSTR and one-byte offset problem.
*    2) Found several non-8-Character Rule Code and Variable Labels - Fix them.
*    3) Get some labeling consistency ---
*         - Remove ":" from Labels
*         - Try not to use EQU *
* ------------
*  // Tom.Williams  June-16-2013 //
*     1)  Moved MENUSTR to higher page boundry (inside $8800-$89FF)
*          result - This did not fix it, however it did show ORG $8800
*          caused a jump in the S19 output ...
*          fixed this in the Perl s19-to-bin.pl
*     3)  Moved MENUSTR to lower page boundry (inside $8000-$1FFF)
*          result - This did not fix it, however it did point out where
*          the text strings, printed later appear to be null... since
*          they are pointing to the *preceeding* byte.
*         FIX: preceed each String Pointer by a Space character.
*     4)  Fix byte-offset problem using one-byte code (not NOOP)
*          I picked CLC because it is fast-execute and does not affect ZERO Flag.
*     "MOVE ALONG, MOVE ALONG"  (Blade Runner)
* ------------
*   // Tom.Williams  July-03-2013 //
*     1) discovered where S19 converter is working for disassembled binaries, but
*        fails when used on the SD2E.asm and SD2F.asm -- solution: use another S19 converter.
*     2) now have 2nd EEPROM board, but r/w is disabled, no RAM, and no bank-switch.
*
*   switched to jEdit for the syntax highlighter.
*
*     It is time-consuming, labor intensive work.  The spiders have to be
*     individually milked - and they DO NOT like it. (Get Smart, 2008 movie)
* ------------
*   // Tom.Williams  July-06-2013 //
*     1) old board is working with 74ls197 latch mapped to CH375 I/O space.
*     2) added HardWare: "Schmart" header and using jumpers with old board.
*     3) added HardWare: wire r/w line to EEPROM r/w on new board (AT28v8b.PDF says it will act as RAM).
*     Tests with ATF28c64a using space destroyers as trying to use the upper 2K as RAM = FAILED.
*     4) need to do something with strings on LED Test, scrolling on HELP screen.
*     Wondering about using 6522 and/or the Arduino SD with Schmart jumpers...
*     5) need to add "press clr to restart" to CH375 failure code.
*     6) added ROW# to be able to add to TOPLEFT when loading X register.
* ------------
*   // Tom.Williams   July-08-2013 //
*     1) add some of the CH375 commands
*     2) built a sub-menu for the CH375 commands
*     3) change Start Menu to say these are CH375 commands....
*     4) LEDPORT should be a variable, like the CH375 ports ... start debug
*     5) is the a problem with CLRSCR? the CH375 calls it, but does not clear screen.
*     6) rewrite CLRSCR and save off A&B registers, only X will be destroyed. do not touch $06.
*     7) use emulator to fix screen placement of "stuff".
*     8) add DISK_INIT command (just mounts the disk).
* ------------
*   // Tom.Williams  July-24-2013 //
*     1)  Purchased Arduino and the SD adapter, got it to read the directory.
*         price check: Arduino CPU = AT Mega 328 = $3.00 (rough) with nothing programmed.
*         I need to verify the G540 will program these, or that there is a manual way.
*     2)  Need some X-Modem or Kermit style way of retreiving DIR versus File and
*         also want to be able to display a text file/ pseudo graphics file...
*         ** will also need to be able to scroll DIR and text/graphics **
*     3) Needed input bits, used 74LS541 from Coleco-Vision board.
* ------------
*   // Tom.Williams  Aug-28-2013 //
*     1)  Had parked it for a while.
*     2)  Have a quick little "output seconds to latch, read from input" loop
*         that works and displays both 4-bit nybles.
*     3)  Started work on bank-switch test routine.  May need to put in
*         another 74LS197... thinking on this since the 20v8 R/S flipflop
*         does not appear to be behaving as an R/S FF should.
* ------------
*   // Tom Williams  Aug-29-2013 //
*     1) remove the older CH375 routines (legal concerns).
*     2) remove some of the "clutter" comments.
*     -- This commits the project to the totally freeware Arduino/UNO.
* ------------
*   // Tom.Williams  Sept-2013 //
*     found a PCB layout guy on eBay, ordered 50 boards made.
*     switched to cheaper MC14066 (4-bit) from SN74LS541 (8-bit).
* ------------
*   // Tom.Williams  Oct-2013 //
*    Oct-18-2013 = send 1st board to Lance for fitting into case.
*    -- I am having to re-write the I/O routine to work
*       with D0,D1,D3,D4 as inputs and
*        D1,D2,D3,D4 as outputs... looks like the pin-mapping
*        on AtMega was also changed.
*    Oct-21-2013, late night=got the "Hello-World" talking back and forth
*        from the APF to the ATMega328 and vice-versa.
*    Oct-22-2013, found in the Arduino forum where someone used the SD-read
*        in order to field-upgrade the ATMega328... want to get examples.
*        emailed that link to Lance,  I need to get the SD to populate the
*        RAM and the bank-switch tested/working, then send him a card with
*        the tested routines in it.
* --------------
*   // Tom.Williams  Nov-2013 //
*     Nov-02-2013,  ack to Lance that he has the assembled board
*        I did not send pre-programmed ATF20v8 or pre-programmed AT28C64B
*     Nov-15-2013,  the "send a string to the atmel" is working, but receive
*        of *any* data is ok one second and messed up the next... (interrupts?)
*     Nov-17-2013,  bank-switch moved from "string" to bit-state.
*        move from hard-coded constants for 4-bit-data-transfer to EQU=constants
*     parked it when they came to inspect the apartment fireplace.
* --------------
*   // Tom.Williams  December-2013 //
*     Dec-02-2013  have it reading Space-Destroyers from SD and playing.
*                  do not have it reading a directory.
* --------------
*   // Tom.Williams  January-2013 //
*     Jan-04-2013  just could not leave it alone.. add Menu-1, Menu-2, bring back
*                  ability to "Flash the APF-Boot EEPROM".
* --------------
*   // Tom.Williams  March-2014 //
*      sent working production-level boards to Lance and Adam
*      issues:  internal Brickdown is horked from the attempt at Flash.
*         switch to CATENA for testing the EEPROM burn routine... (also 2K game)
* *********************************************************
*
* use Adam's Brickdown disassemble 
*  as a base for starting...
*
*  System ROM Routines
WRITESTR  EQU   $4144       ; Write String Routine
BEEP      EQU   $426E
ISJOYUSD  EQU   $40AA
REBOOT    EQU   $4000

*  Equates (RAM Locations - Variables)
JOYDATA   EQU   $01F2       ; Joystick Data, "NSEW,0-9,!=Fire,?=clear"
TIME      EQU   $01FB       ; 1/60 Seconds Counter
SECOND    EQU   $01F9       ; Seconds Counter
MINUTE    EQU   $01FA       ; Minutes Counter

* Equates (our 8k RAM)
SAVROUT   EQU   $BFFF ; save-register for 4-bit writes.  (this is HM6264 RAM while bank-switch is zero)
PEGCTR    EQU   $BFFE ; peg-counter... for bit-load/bit-write routines.
*; LASTJOY   EQU   $BFFD ; Save Last Joystick keypress, next one must be different.
LOCALX    EQU   $BFFB ; MSB->[$BFFB] ; LSB->[$BFFC]
LOCALA    EQU   $BFFA ;
LOCALB    EQU   $BFF9 ;
XSAVE     EQU   $BFF7 ;  MSB->[$BFF7] ; LSB->[$BFF8]
MYCOUNT   EQU   $BFF6 ;
SHSAVX    EQU   $BFF4 ;  MSB->[$BFF4] ; LSB->[$BFF5]
;* EVBAREG   EQU   $BFF3 ;  for use by the Read4Bit, Set4Bit routines
REGX2     EQU   $BFF2 ;  MSB->[$BFF2] ; LSB->[$BFF3]
REGX1     EQU   $BFF0 ;  MSB->[$BFF0] ; LSB->[$BFF1]

* Ports in/out.
EVBDIN    EQU   $D000 ; Atmel AT-Mega-328 Evaluation Board (this is a MC14066BCP)
EVBDOUT   EQU   $D800 ; output port... (this is a 74LS197 from a Commodore 1541)

* You have 1K of RAM, this contains variable-space, screen-memory, and stack.
*  screen memory starts at $0200,  (from the PDF) "32 characters per line, by 16 lines."
*  so, screen end is at $03FF.... (for a text-screen)
*  and the "bottom left" is $0200+(32*15)=512+480=992(dec)=$03E0(hex)
*  from the Rocket-Patrol Disassembly: LDS #$01E4 ; Load Stack Pointer with $01E4
TOPLEFT   EQU   $0200
BOTLEFT   EQU   $03E0
ROW1      EQU   #$20
ROW2      EQU   #$40
ROW3      EQU   #$60
ROW4      EQU   #$80
ROW5      EQU   #$A0
ROW6      EQU   #$C0
ROW7      EQU   #$E0
ROW8      EQU   #$100
ROW9      EQU   #$120
ROW10     EQU   #$140
ROW11     EQU   #$160
ROW12     EQU   #$180
ROW13     EQU   #$1A0
ROW14     EQU   #$1C0  ;  ( 32 * 14 = 448 )
BOTROW    EQU   #$1E0  ; 16 lines, 32*16 is off-screen because top row=0.
*;    also note built-in RAM ends at $0400.

* 4-bit State-Machine Transfer Constants
*; IDLE4BIT  EQU $00 ;* This side is idle, waiting for the other guy to TX
*; TXDATA    EQU $08 ;* I have data to TX
*; TXBYTE    EQU $0C ;* I am starting to send one-byte.
*; TXBIT0    EQU $0E ;* I am sending a bit=0.
*; TXBIT1    EQU $0F ;* I am sending a bit=1.
*; TXBITDNE  EQU $0D ;* I am done sending a bit.
*; TXBYTEDN  EQU $09 ;* I am done sending one-byte.
*; TXDATDNE  EQU $0A ;* I am done sending data (you can interpret-string or reboot or whatever)
* --
*; RXDATACK  EQU $07 ;* Acknowledge we are ready to receive data.
*; RXBYTACK  EQU $04 ;* Acknowledge for "ready to send one-byte"
*; RXBITACK  EQU $05 ;* I am done reading the bit. ( other side follows with state-change to "done sending bit" )
*; RXBITIDL  EQU $03 ;* I am waiting for next bit (or am reading one, this gives 2 states while reading bits ).
*; RXBYTDNE  EQU $06 ;* Acknowledge for "done sending one-byte"
*; RXDATDNE  EQU $01 ;* Acknowledge "done sending data" (the other guy can send checksums or go idle).
* --
*; TXBNKON   EQU $0B ;* tell the co-processor to flip the bank-switch line.
*; RXBNKACK  EQU $02 ;* the other side is Acknowledge for bank-switch (should go idle after this).
* 4-bit State-Machine (end-constants-definition-block)

*  Misc Equates  ( Constants )
EOS       EQU   $FF         ; End of String

* *************************************************************
          ; ----
          ORG   $8000       ; Start of APF Cartridge Area
          
*;  The BIOS uses the first five bytes of the cartridge  

          FCB   $BB         ; Tell BIOS a cart is present
MENUPTR   FDB   MENUSTR     ; Points to Menu string on cartridge ($8000-$87FF)
*                           ; -- must contain valid strings during startup.
          FCB   '6'         ; "N" choices for Start-Up Menu
          FCB   $00         ; Must be $00
          ; -----------------
STRTHERE  LDAA  $0000
          ; -----------------
          CMPA  #1        ; Is Menu Choice = 1?
          BNE   ISNOT1
          CLRA
          STAA  EVBDOUT   ; - the Atmel/Arduino knows the APF is "idle"
          JSR   SAFETCHK
          JMP   GETMNU1   ; load "MENU1.TXT" from root
ISNOT1    CMPA  #2
          BNE   ISNOT2
          JSR   SAFETCHK
          JMP   GETMNU2    ; load "MENU2.TXT" from root
ISNOT2    CMPA  #3
          BNE   ISNOT3
          JSR   SAFETCHK
          JMP   GETSPACE   ; space-destroyers
ISNOT3    CMPA  #4
          BNE   ISNOT4
          JSR   SAFETCHK
          JMP   GETGAME    ; apfgame.bin
ISNOT4    CMPA  #5
          BNE   ISNOT5
          JSR   SAFETCHK
          JMP   GOBRICKS    ; BRICKDOWN (from EEPROM, no SD needed)
ISNOT5    CMPA  #6
          BNE   ISNOT6
          JMP   UTILMNU    ; "Utilities Menu" (FLASH EEPROM, ETC)
ISNOT6    JSR   BEEP
          JSR   DELAY100
          JSR   ISJOYUSD
          LDAA  JOYDATA
          SUBA  #'0'
          STAA  $0000
          BRA   STRTHERE

* ****************************************************
*
*  Cartridge Menu String
*  ---------------------
*  
*  The data required by the BIOS for the main menu is here.
          FCB   0       ; intersting when this byte is changed to EOS.
          ;  the emulator seems to be okay, but the eeprom and hardware...
          ;*
MENUSTR   FCB   $C7     ; Control Byte - Fill 7 spaces with next byte 
          FCB   $CF     ; Fill-Byte - ASCII $EF, (Purple)
*;        --     1 2         3
*;        --     890123456789012345
          FCC   " APF-TO-SD READER "  ; UPPERCASE ONLY!!!! 32-18=14
          FCB   $C7         ; Control Byte - Fill 7 spaces with next byte
          FCB   $CF         ; Fill-Byte - ASCII $EF, (Purple)
          ; -------------------
          FCB   $C7
          FCB   $CF
          ;-     123456789012345678
          FCC   "------------------"  7+18+7=32 CHARS.
          FCB   $C7
          FCB   $CF
          ; -------------------
          FCB   $C7
          FCB   $DF
          ;-     123456789012345678
          FCC   "1. READ MENU1.TXT "
          FCB   $C7         ; Control Byte - Fill 7 spaces with next byte
          FCB   $DF         ; Fill-Byte - $60, (Light Green)  - $DF = CYAN 
          ; -------------------
          FCB   $C7
          FCB   $AF         ; DARK BLUE  (looks Purple on my screen)
          ;-     123456789012345678
          FCC   "2. READ MENU2.TXT "
          FCB   $C7
          FCB   $AF
          ; -------------------
          FCB   $C5
          FCB   $BF         ; RED
          ;-     1234567890123456789012
          FCC   "3. LOAD SPACEDST.BIN  "
          FCB   $C5
          FCB   $BF
          ; -------------------
          FCB   $C5
          FCB   $9F          ; 9F = Yellow
          ;-     123456789012345678
          FCC   "4. LOAD APFGAME.BIN   "
          FCB   $C5
          FCB   $9F
          ; -------------------
          FCB   $C7
          FCB   $DF          ; WHITE
          ;-     123456789012345678
*;        FCC   "5. PLAY BRICKDOWN "
*;        FCC   "5. PLAY CATENA    "
          FCC   "5. PLAY BLOCK 02  "
          FCB   $C7
          FCB   $DF
          ; -------------------
          FCB   $C7
          FCB   $FF          ; GOLD  (Dark Yellow)
          ;-     123456789012345678
          FCC   "6. UTILITIES MENU "
          FCB   $C7
          FCB   $FF
          ; -------------------
*;          FCB   $C7
*;          FCB   $DF          ; CYAN
*;          ;-     123456789012345678
*;          FCC   "------------------"
*;          FCB   $C7
*;          FCB   $DF
          ; -------------------
          FCB   $C8         ; Fill the next ROW
          FCB   $83       ; black over green = 83
          FCB   $C8
          FCB   $93       ; black over yellow = 93
          FCB   $C8
          FCB   $A3       ; black over blue = A3
          FCB   $C8
          FCB   $B3       ; black over red = B3
          ; -------------------
          FCB   $C8         ; Fill the next ROW
          FCB   $C3       ; black over white = C3
          FCB   $C8       ; 
          FCB   $D3       ; black over cyan = D3
          FCB   $C8
          FCB   $E3       ; black over purple = E3
          FCB   $C8
          FCB   $F3       ; black over orange. = F3
          ; -------------------
          FCB   EOS

* ***********************************

* ------------------
*  Start "Program Code"
*  -----------------

*  *******************
*  Use Either Controller...
*  Left = Up a directory (or stay in root "beep")
*  Right = Down a directory (or "boop" - not "beep")
*  Fire/Enter = Load (*.bin) and jump to reset. (*.txt) = TXTREAD else, BOOP
*  Up = Up one Entry, if at top, scroll.
*  Down = Down one Entry, if at bottom, scroll.
*  numbers and clear key... mean nothing at the moment.
*  *******************

* **********************
*;     Scroll up, leaving bottom line original text to be overwritten...
*;     Input: nothing
*;     Output: Destroys X, A, B.
*;    Sept-14-2013, add to save&restore registers, disable interrupt.
SCROLLUP  STX  SHSAVX
          PSHA
          PSHB
          CLRA  ; counter
          LDX  #TOPLEFT
SCRUPLP1  LDAB 32,X     ; top line
          STAB 0,X      ; next line.
          INX          ; next char.
          INCA          ; counter
          BNE  SCRUPLP1 ; drop out of this loop at 256 chars...
SCRUPLP2  LDAB 32,X     ; X from above
          STAB 0,X      ; same steps again...
          INX
          INCA
          CMPA  #224    ; 32*15=480, 480-256=224.
          BNE  SCRUPLP2
          PULB
          PULA
          LDX  SHSAVX
          RTS
* **********************
*;     Scroll down, leaving top line original text to be overwritten...
*;     Input: nothing
*;     Output: Destroys X, A, B.
SCROLLDN  CLRA
          LDX   #TOPLEFT+512-32
SCRDNLP1  LDAB  0,X      ; top line
          STAB  32,X     ; next line.
          DEX           ; next char.
          INCA           ; counter
          BNE   SCRDNLP1 ; drop out of this loop at 256 chars...
SCRDNLP2  LDAB  0,X      ; X from above
          STAB  32,X     ; same steps again...
          DEX
          INCA
          CMPA  #224     ; 32*15=480, 480-256=224.
          BNE   SCRDNLP2
          RTS
* *********************
*; Blank-The-Bottom-Line (of the screen).
*;    input: None
*;    output: destroys the X register.
*; -
BLNKBOTM PSHA
         PSHB
         LDX   #BOTLEFT
    ;     LDAA  #' '
         LDAA  #$80
         LDAB  #32
BLNKBLP  STAA  0,X
         INX
         DECB
         BNE   BLNKBLP
         PULB
         PULA
         RTS
* *********************
*; Clear-Screen,
*;    input: None
*;    output: destroys X register.
CLRSCR   PSHA
         PSHB
         LDX  #1023
         LDAB #$FF
         LDAA #$80
CLSLP1   STAA 0,X
         DEX
         DECB
         BNE  CLSLP1
         LDAB #$FF  ; 256 chars of (32*16=512) written, just run the loop again.
         LDAA #$80
CLSLP2   STAA 0,X
         DEX
         DECB
         BNE  CLSLP2         
         PULB
         PULA
         RTS
* *********************
*;  Delay Subroutines
*; 1 milliscond = 0.001 seconds
*; 3.58MHz clock / 4 = 0.000000279 seconds per clock "cycle".
*; input: nothing  (2 entry points, 100ms delay and 1ms delay)
*; output:  destroys Accumulator A and Index register X
DELAY100  LDAA #99    ;  100 milliseconds. (entry point)
          JMP  MSDLYAA  ; that tiny time-delay.
MSDELAY   LDAA #1     ;  1 millisecond. (entry point)
MSDLYAA   LDX #448    ;  (0.001/0.000000279)/8
MSDLP1    DEX         ;  4 clock cycles.
          BNE MSDLP1  ;  4 clock cycles.
          DECA        ;  2 clock cycles.
          BNE MSDLYAA ;  4 clock cycles.
          RTS
* *********************
*; SAYAHEX  Subroutine, display Accumulator-A as Hexadecimal.
*; input:  Accumulator A  (byte value to display)
*; input:  Index pointer X (where on screen to poke the characters)
*; output: returns nothing.  X=unaffected A=unchanged B=unchanged
SAYAHEX   PSHA
          PSHB
          JSR  BYTE2CH
          STAA 0,X
          STAB 1,X
          PULB
          PULA
          RTS
* *********************
*; BYTE2CH   Subroutine.
*; input:  Accumulator A  (byte value to be translated to two ASCII "HEX" for diplay)
*; output:  Accumulator A (left char), Accumulator B (right char)
BYTE2CH   PSHA
          LSRA   ; shift A right 4 bits
          LSRA   ; **** upper bits become zero  (LSR)
          LSRA   ;      upper bits become carry (ROR)
          LSRA   ;      upper bits become LOWEST bit (ASR)
          CMPA #9   ; if A>9
          BGT  BYHI   ; then Branch
          ADDA #$30   ; else Add ASCII "0"  -- is 6847 table same as ASCII - Appendix D of APF Tech Ref Manual)
          BNE  BYLOW  ; end if
BYHI      ADDA #$37   ; Add ASCII "A"
          SUBA #$40   ;   (see CharMap)
BYLOW     PULB   ; B=arg(1) <-- Acc-A
          ANDB #%00001111 ; mask lower 4 bits
          CMPB #9   ; if B>9
          BGT  BYLAA  ; then Branch
          ADDB #$30   ; else Add ASCII "0"
          BNE  BYEND  ; end if
BYLAA     ADDB #$37   ; Add ASCII "A"
          SUBB #$40
BYEND     RTS         ; done
* ---
* *********************
*; Wait for the FIRE or ENTER button.
WAIT4FIRE  JSR   ISJOYUSD
           LDAA  JOYDATA
           CMPA #$21
           BNE  WAIT4FIRE
           RTS
* ---
* *********************
*;  UCASE subroutine = Upper-Case the Accumulator-A
*;     Input  Accumulator-A
*;     Output Accumulator-A   X=untouched, B=untouched.
UCASE     CMPA  #$61
          BLE   UCSRTN   ; return home, not a lower-case char.
          CMPA  #$7B
          BGT   UCSRTN   ; return home, is "higher than "z" in lower-case."
          SUBA  #$20   ; convert-to-upper
UCSRTN    RTS
* ---
* **********************************************
RAMMSG    FCC " 8K RAM TEST. "
          FCB EOS
RAMWHAT   FCC " EACH DOT/CHAR = 256 BYTES."
          FCB EOS
RAMNFO    FCC " (1=X00,2=X0F,3=XF0,4=XFF). "
          FCB EOS
RAMXIT    FCC " PRESS CLR TO EXIT. "
          FCB EOS
SUCCESS   FCC "ALL TESTS SUCCESSFUL."
          FCB EOS
FIREMSG   FCC " PRESS ENTER OR FIRE BUTTON. "
          FCB EOS
JOYMSSG   FCC " USE JOYSTICK OR PRESS ANYKEY."
          FCB EOS
* ***************************************************
*;  Menu-Select (MAIN)
*;     RAM Test:  Output 4 rows, 32 columns of tests.
*;           Row 1 = write&read back 0xFF, print "1" if success, "." if not.
*;           Row 2 = write&read back 0x0F, print "1" if success, "." if not.
*;           Row 3 = write&read back 0xF0, print "1" if success, "." if not.
*;           Row 4 = write&read back 0x00, print "1" if success, "." if not.
*; - - - - -
RAMTST    LDX   #RAMMSG
          STX   $06
          LDX   #TOPLEFT+ROW4+1  ; row 4.
          JSR   WRITESTR
          
          LDX   #RAMWHAT
          STX   $06
          LDX   #TOPLEFT+ROW8  ; row 8, left side
          JSR   WRITESTR

          LDX   #RAMNFO
          STX   $06
          LDX   #TOPLEFT+ROW9  ; row 9, left side
          JSR   WRITESTR
          
          LDX   #TOPLEFT+ROW10  ; row 10, left side...
          STX   $06    ; Xh->M,Xl->(M+1)
          LDX   #$A000   ; RAM at $A000-$CFFF when bank-switch = 0.
          STX   $04
          
          ; Store Zero in blocks of 256 bytes, put dots as they read-zeros.
          ;  8192/256 = 32 ... enough to fill a row.
RAMLPA    LDAA  #$00
          STAA  0,X
          LDAA  #$FF
          LDAA  0,X
          LDAB  #'1'
          CMPA  #$00
          BEQ   RAMDTA
          LDAB  #'.'
          JSR   SAYFAIL
RAMDTA    LDX   $06
          STAB  0,X  ; row 10.
          LDAA  $05  ; low byte of Memory Counter
          CMPA  #0
          BNE   RAMRA
          INX        ; if low-byte is zero, then bump to next column
          STX   $06
RAMRA     LDX   $04  ; end-if is here (no "else")
          INX
          STX   $04
          LDAA  $04  ; high byte of Memory Counter
          CMPA  #$C0
          BLT   RAMLPA
          
          LDX   #$A000
          STX   $04
RAMLPB    LDAA  #$0F
          STAA  0,X
          LDAA  #$F0
          LDAA  0,X
          LDAB  #'2'
          CMPA  #$0F
          BEQ   RAMDTB
          LDAB  #'.'
          JSR   SAYFAIL
RAMDTB    LDX   $06
          STAB  0,X  ; row 11.
          LDAA  $05  ; low byte of Memory Counter
          CMPA  #0
          BNE   RAMRB
          INX        ; if low-byte is zero, then bump to next column
          STX   $06
RAMRB     LDX   $04  ; end-if is here (no "else")
          INX
          STX   $04
          LDAA  $04  ; high byte of Memory Counter
          CMPA  #$C0
          BLT   RAMLPB

          LDX   #$A000
          STX   $04
RAMLPC    LDAA  #$F0
          STAA  0,X
          LDAA  #$0F
          LDAA  0,X
          LDAB  #'3'
          CMPA  #$F0
          BEQ   RAMDTC
          LDAB  #'.'
          JSR   SAYFAIL
RAMDTC    LDX   $06
          STAB  0,X  ; row 12.
          LDAA  $05  ; low byte of Memory Counter
          CMPA  #0
          BNE   RAMRC
          INX        ; if low-byte is zero, then bump to next column
          STX   $06
RAMRC     LDX   $04  ; end-if is here (no "else")
          INX
          STX   $04
          LDAA  $04  ; high byte of Memory Counter
          CMPA  #$C0
          BLT   RAMLPC

          LDX   #$A000
          STX   $04
RAMLPD    LDAA  #$FF
          STAA  0,X
          LDAA  #$00
          LDAA  0,X
          LDAB  #'4'
          CMPA  #$FF
          BEQ   RAMDTD
          LDAB  #'.'
          JSR   SAYFAIL
RAMDTD    LDX   $06
          STAB  0,X  ; row 13.
          LDAA  $05  ; low byte of Memory Counter
          CMPA  #0
          BNE   RAMRD
          INX        ; if low-byte is zero, then bump to next column
          STX   $06
RAMRD     LDX   $04  ; end-if is here (no "else")
          INX
          STX   $04
          LDAA  $04  ; high byte of Memory Counter
          SUBA  #$C0
          BLT   RAMLPD
          
          LDX   #TOPLEFT+ROW5+2
          LDAA  0,X
          CMPA  #'F'
          BEQ   RAMNOGO
          
          LDX   #SUCCESS   ; if did not find "FAIL", then display "SUCCESS"
          STX   $06
          LDX   #TOPLEFT+ROW5
          JSR   WRITESTR
          
RAMNOGO   LDX   #FIREMSG
          STX   $06    ; what to write goes in $06
          LDX   #TOPLEFT+ROW14    ; where to write it goes in X ; row 14,col 0
          JSR   WRITESTR
          
          JSR   WAIT4FIRE
          
          LDAB  #2
RAMLPX    JSR   DELAY100  ; destroy A,X
          DECB
          BNE   RAMLPX
          
          JMP   REBOOT
* ----------------------
*;  SayFail:  input = nothing, output = destroy X register
SAYFAIL   PSHA
          LDX   #TOPLEFT+ROW5+2  ; row 5, 2 chars in.
          LDAA  #'F'
          STAA  0,X
          LDAA  #'A'
          STAA  1,X
          LDAA  #'I'
          STAA  2,X
          LDAA  #'L'
          STAA  3,X
          PULA
          RTS

* ***************************************************
*;  Select From (MAIN)
*;  CHARACTER DUMP
*;             01234567890123
*; - - - - -
CHDMPMSG  FCC "CHARACTER DUMP"    ; fill-code=characters
          FCB EOS
EXTMSSG   FCC  " PRESS CLR TO EXIT/REBOOT. "
          FCB  EOS
; ---
CHARDMP   LDX   #CHDMPMSG
          STX   $06
          LDX   #TOPLEFT+ROW9+1
          JSR  WRITESTR
          LDX   #EXTMSSG
          STX   $06
          LDX   #BOTLEFT
          JSR   WRITESTR
          ; ------------
          CLRA
          LDX   #TOPLEFT
CHARLP1   STAA  0,X
          INX
          INCA
          CMPA  #$FF
          BNE   CHARLP1
          STAA  0,X   ;-- last character.
*;        ok, so we have dumped every character onto the screen
*;        Next: interactive "this character is 0xNN" and instructions.
*;        -----------------
          LDAA #'N'
          LDX  #TOPLEFT+ROW10+18
          STAA 0,X
          LDAA #'8'
          STAA 4,X
          LDAA #'W'
          LDX  #TOPLEFT+ROW11+17
          STAA 0,X
          LDAA #'4'
          STAA 4,X
          LDAA #'E'
          STAA 2,X
          LDAA #'6'
          STAA 6,X
          LDAA #'S'
          LDX  #TOPLEFT+ROW12+18
          STAA 0,X
          LDAA #'2'
          STAA 4,X
          LDAA #'C'
          LDX  #TOPLEFT+ROW11
          STAA 0,X
          LDAA #'H'
          STAA 1,X
          LDX  #TOPLEFT+ROW13
          LDAA #'J'
          STAA 0,X
          LDAA #'O'
          STAA 1,X
          LDAA #'Y'
          STAA 2,X
          PSHA    ; store it on the stack.
          ; -----
          CLI   ; ?? used by IsJoyUsed
          ; -----
CHARLP2   PULA
          PSHA
          LDX  #TOPLEFT+ROW11+4
          STAA 0,X
          INX
          LDAB #'='
          STAB 0,X
          INX
          JSR  SAYAHEX
          ; -----------
          JSR  DELAY100  ; destroys A,X
          JSR  ISJOYUSD  ; destroys ???
          LDAA JOYDATA
          PSHA
          LDX  #TOPLEFT+ROW13+4
          STAA 0,X
          INX
          LDAB #'='
          STAB 0,X
          INX
          JSR  SAYAHEX  ; destroys A,B,X
          PULA
          ; ----------
          CMPA #$38  ; '8'
          BEQ  CHREQUN  ; not "North"
          CMPA #$4E  ; 'N'
          BNE  CHRNOTN
CHREQUN   PULA
          SUBA #$20
          PSHA
          BRA  CHARLP2
CHRNOTN   CMPA #$36  ; '6'
          BEQ  CHREQUE  ; not "East"
          CMPA #$45  ; 'E'
          BNE  CHRNOTE
CHREQUE   PULA
          INCA
          PSHA
          BRA  CHARLP2
CHRNOTE   CMPA #$34  ; '4'
          BEQ  CHREQUW  ; not 'West'
          CMPA #$57  ; 'W'
          BNE  CHRNOTW
CHREQUW   PULA
          DECA
          PSHA
          BRA  CHARLP2
CHRNOTW   CMPA #$32  ; '2'
          BEQ  CHREQUS  ; not 'South'
          CMPA #$53  ; 'S'
          BNE  CHRNOTS
CHREQUS  PULA
          ADDA #$20
          PSHA
          BRA  CHARLP2
CHRNOTS   CMPA #$3F   ; '?' = CLEAR (#)  button
          BEQ  CHREXIT
          JSR  BEEP
          BRA  CHARLP2
          ; -- If we were not rebooting, use PULA to clear A off the stack.
CHREXIT   JMP  REBOOT
          
* *****************************************************
* ***********12345678901234567890123456789012**********
M3R1    FCC " 1)  TEST 8K RAM CHIP "
        FCB EOS
M3R2    FCC " 2)  GENERIC CHAR-DUMP "
        FCB EOS
M3R3    FCC " 3)  LOAD APFFLASH.BIN "
        FCB EOS
M3R4    FCC " 4)  FLASH RAM TO EEPROM "
        FCB EOS
* *****************************************************
*;  Select From (MAIN)
*;  Sub-Menu for Atmel-Routines
*; - - - - -
UTILMNU   EQU *
          CLRA
          STAA EVBDOUT   ; - the Atmel/Arduino knows the APF is "idle"
          ; ========
          JSR CLRSCR
          JSR DELAY100
          LDX  #M3R1
          STX  $06
          LDX  #TOPLEFT+ROW3
          JSR  WRITESTR
          LDX  #M3R2
          STX  $06
          LDX  #TOPLEFT+ROW4
          JSR  WRITESTR
          LDX  #M3R3
          STX  $06
          LDX  #TOPLEFT+ROW5
          JSR  WRITESTR
          LDX  #M3R4
          STX  $06
          LDX  #TOPLEFT+ROW6
          JSR  WRITESTR
          ; ---          
M3GETJOY  JSR  ISJOYUSD
          LDAA JOYDATA
          CMPA #'1'
          BNE  M3ARND1
          JSR  SAFETCHK
          JSR  CLRSCR
          JMP  RAMTST
M3ARND1   CMPA #'2'
          BNE  M3ARND2
          JSR  SAFETCHK
          JSR  CLRSCR
          JMP  CHARDMP
M3ARND2   CMPA #'3'
          BNE  M3ARND3
          JSR  SAFETCHK
          JSR  CLRSCR
          JMP  GETFLASH
M3ARND3   CMPA #'4'
          BNE  M3ARND4
          JSR  CLRSCR
          JMP  DOFLASH
M3ARND4   JSR  BEEP   
          JSR  DELAY100
M3ARND9   CLC                  ; write to F000 BOOT-ROM
          JMP  M3GETJOY

* *****************************************************
STDEXIT   JSR  SCROLLUP
          JSR  BLNKBOTM
STDEXIT1  LDX  #EXTMSSG
          STX  $06
          LDX  #BOTLEFT
          JSR  WRITESTR
STDEXLP   JSR   ISJOYUSD
          CMPA  #$3F    ; "CLR" button ?
          BNE   STDEXLP
          JSR  DELAY100
          JMP   REBOOT
* *****************************************************
*; ----------
*;  start of 4-bit state-machine style of data transfer routines.
*; ----------
*;  SET4BIT (subroutine)
*;      Input:  Accumulator-A
*;      Output:  hardware bits.
SET4BIT   PSHA             ; save A on stack.
          STAA  SAVROUT
          ASLA   ;*  <--  PCBoard typo
          STAA  EVBDOUT
          LDAA #8   ;*  <-- speed limit.  (55 works, 15 works most of the time)
SET4BITA  DECA ; DEX
          BNE   SET4BITA
          PULA             ; restore A
          RTS
* ******************************************
*; ----------
*;  READ4BIT (subroutine)
*;      Input: hardware bits
*;      Output: Accumulator-A
READ4BIT  PSHB
          LDAA  EVBDIN   ; A = input from MC14066   ???xx?xx
          TAB     ; Transfer A into B.
          ANDB  #%00011000
          LSRB    ;*  -->  PCBoard typo
          ANDA  #%00000011   ; handle bit-shift in hardware.
          ABA    ;*  A=A+B  
          LDAB #07    ;* tiny delay-loop
RD4BITA   DECB
          BNE   RD4BITA ;* end tiny delay-loop
          PULB           ; restore B
          RTS
* ******************************************
*; ----------
*; FILL-MEMORY (subroutine)
*;       Input:  Nothing
*;       Output:  Fills $A000-$A020 with Zero.
*;         saves off X,A,B and restores before returning.
FILLMEM1  STX  XSAVE
          PSHA
          PSHB
          LDX  #$A000
          LDAA #$80
          LDAB #$20
FILLMLP1  INX
          STAA 0,X
          DECB
          BNE  FILLMLP1
          PULB
          PULA
          LDX  XSAVE
          RTS
* ******************************************
*; ----------
*;  BIT4SEND = test "send the any key."
*;  BIT4STRS = send "string" to ATMEL (usually a command,
*;             but could be data to write-to-file)
*;     Input: X = Buffer-to-send  (end with EOS)
*;     Output: destroys A, X, memory $BDFF (counter)
*; ---
*; BIT4SEND  LDX   #ANYKEY     ; X = string to send
BIT4STRS  STX   LOCALX
          LDAA  #%00001000   ; I have data to send
          JSR   SET4BIT
          CLR   $BDFF
BIT4LP1   JSR   READ4BIT
          CMPA  #%00000111   ; wait for hardware to acknowledge
          BEQ   BIT4MAIN   ; handshake satisfied
          DEC   $BDFF
          BNE   BIT4LP1  ; $BDFF == 0 ??
BIT4MAIN  LDX   LOCALX
          LDAA  0,X
          INX
          STX   LOCALX
          STAA  LOCALA
          CMPA  #EOS    ; end-of-string found?   <<<<--- **IMPORTANT INFO**
          BNE   BIT4CHX
          LDAA  #$0A        ; tell other guy we are done sending this byte.
          JSR   SET4BIT
BIT4D01   JSR   READ4BIT
          CMPA  #$01     ; wait for acknowedge.
          BNE   BIT4D01
          LDAA  #$00
          JSR   SET4BIT  ; go into "IDLE"
BIT4D02   JSR   READ4BIT
          CMPA  #$00     ; wait for other guy to be idle.
          BNE   BIT4D02
          RTS   ; return to caller...
          ; ------------
BIT4CHX   LDAA  #%00001100  ; send character X
          JSR   SET4BIT    ; I have a byte to send
BIT4LP2   JSR   READ4BIT
          CMPA  #%00000100   ; wait for acknowledge
          BNE   BIT4LP2
          LDAB  #$08    ; 8 bits.
          STAB  MYCOUNT
          LDAB  LOCALA
          ; ----------- *********************
BIT4BT0   EQU *
          ASRB          ; SHIFT RIGHT Accumulator-B (low bit into Carry-Flag)
  ;        ASLB
          BCC   BIT4BT1
          LDAA  #%00001111  ; bit is a one.
          JSR   SET4BIT
          BRA   BIT4LP3
BIT4BT1   LDAA  #%00001110  ; bit is a zero.
          JSR   SET4BIT
BIT4LP3   JSR   READ4BIT
          CMPA  #%00000101
          BNE   BIT4LP3
          LDAA  #$0D    ;->  "done with bit"
          JSR   SET4BIT
BIT4LP4   JSR   READ4BIT
          CMPA  #%00000011   ;-> ack: "i (Atmel) am waiting for next bit"
          BNE   BIT4LP4
          ; ----------  Bit one complete.
          DEC   MYCOUNT
          BNE   BIT4BT0   ;-> next bit.
          LDAA  #$09         ;-> "done with byte"
          JSR   SET4BIT
          ; ---------- Bit zero complete.
BIT4LP5   JSR   READ4BIT
          CMPA  #$06       ;-> ack: "i see you are done sendinging byte"
          BNE   BIT4LP5
          JMP   BIT4MAIN  ; get next character and output.
*; -------------------------------------
* ******************************************
*;  BIT4RECV = Receive Bytes (from ATMEL) into Buffer at $A000
*;      Input = Nothing.
*;      Output:  X=end of Buffer.
*; ---
BIT4RECV  EQU *
BIT4LPZ   LDAA #$00     ; Idle state.
          JSR  SET4BIT
          LDX  #$A000    ; start of RAM  (start of data-receive buffer).
          STX  LOCALX    ; "Buffer Pointer"
          CLR  LOCALA    ; byte being reconstructed.
          JSR  FILLMEM1
          ; ----
BIT4LP8   JSR  READ4BIT
          CMPA #$0E      ; Atmel is sending bit=0.
          BEQ  BIT4EQUZ
          CMPA #$0F      ; Atmel is sending bit=1.
          BEQ  BIT4EQU1
          CMPA #$0D     ; Atmel ack's you have finished reading bit.
          BNE  BIT4K4
          LDAA #$03   ; Tell Atmel we are ready for next bit.
          JSR  SET4BIT   ; we would bump the bit-counter in 'C' or BASIC...
          JMP  BIT4LP8
BIT4K4    CMPA #$09      ; Atmel is done sending Byte.
          BEQ  BIT4BYTD
          CMPA #$08      ; Sept-13-2013 23:51pm. ; Start-of-data.
          BNE  BIT4K3
          LDAA #$07      ; Acknowledge the Atmel.
          JSR  SET4BIT
          LDX  #$A000    ; set Buffer-Pointer to start of Data-Buffer (start of RAM)
          STX  LOCALX    ; "Buffer Pointer"
          JMP  BIT4LP8
BIT4K3    CMPA #$00     ; Atmel went idle...
          BNE  BIT4K2
          JMP  BIT4DN4   ; dang branch-out-of-range anyhow.
BIT4K2    CMPA #$0A    ; Atmel is "Done Sending"
          BNE  BIT4K1
          JMP  BIT4DN4
BIT4K1    CMPA #$0C      ; starting a new byte.
          BNE  BIT4K0
          LDAA #$04      ; I see you are sending a byte.
          JSR  SET4BIT
          CLR  LOCALA    ; the (next) byte we are reconstructing.
BIT4K0    JMP  BIT4LP8
          ; ----
BIT4EQU1  LDAA LOCALA
   ;*       LSRA           ; 0->01101101->C ; logical-shift-right,accumulator-A
          LSLA           ; C<-01101101<-0 ; logical-shift-left,accumulator-A
   ;*       ORAA #$80      ; high-bit = 1   ;  shifted, then OR'ed.
          ORAA #$01      ; INCA is one-byte, but we're showing setting the bit.
          STAA LOCALA
          BRA  BIT4NXT1
BIT4EQUZ  LDAA LOCALA
   ;*       LSRA           ; 0->01101101->C
          LSLA           ; C<-01101101<-0
          STAA LOCALA
BIT4NXT1  LDAA #$05     ; I am done reading Bit
          JSR  SET4BIT
BIT4LP9   EQU *
          JSR  READ4BIT
          CMPA #$0D     ; Atmel ack's you have finished reading bit.
          BNE  BIT4LP9
          LDAA #$03   ; Tell Atmel we are ready for next bit.
          JSR  SET4BIT
          JMP  BIT4LP8
          ; ----------
BIT4BYTD  EQU *
          LDAA #$06     ; I see we are done with that Byte.
          JSR  SET4BIT
BIT4LK1   JSR  READ4BIT
          CMPA #$09    ; "while (in=9), loop"
          BEQ  BIT4LK1
          ; ----------
          LDAA LOCALA  ; the byte we just finished re-constructing.
BIT4OKO   LDX  LOCALX   ; buffer-zone $A000-$BFFF (RAM)
          STAA 0,X
          INX
          STX  LOCALX
          ; ----------
          JSR  READ4BIT
          CMPA #$0C    ; start of next Byte.
          BNE  BIT4OK1
          JMP  BIT4LP8   ; branch-out-of-range.
BIT4OK1   CMPA #$09
          BNE  BIT4OK2
          JMP  BIT4LP8
BIT4OK2   CMPA #$0A    ; Atmel is "Done Sending"
          BEQ  BIT4DN4
          JMP  BIT4LP8
          ; --- if it is done sending, 
          ; --- Handle the message before going "idle"
BIT4DN4   EQU *
          LDX  LOCALX
          LDAA #EOS
          STAA 0,X    ; make sure there is a EOS that can be found.
          CPX  #$A000
          BEQ  BIT4INI1
          LDX  #$A000
          STAA 81,X   ; the string cannot be any more than 80 characters.
          STX  $06
          LDX  #TOPLEFT+ROW13
          JSR  WRITESTR
          JSR  SCROLLUP
          JSR  SCROLLUP
          JSR  FILLMEM1 ; "CLEAR" THE BUFFER TO (Black Background).
BIT4INI1  LDX  #$A000
          STX  LOCALX
          CLR  LOCALA
          ; --------
BIT4DN5   LDAA #$01    ; tell it we see it is done sending "Message"
          JSR  SET4BIT
          LDAB #$FF
          ; --- Wait for Atmel to go "Idle"
BIT4LPA   DECB
          BEQ  BIT4LPB   ; branch on B=Zero
          JSR  READ4BIT
          CMPA #$00
          BNE  BIT4LPA
BIT4LPB   LDAA #$00
          JSR  SET4BIT  ; tell the Atmel we are "Idle"
          JMP  STDEXIT1
          ; -- done.
*;---------
* *************************************************************
* =============================================================
* *************************************************************
* -------------
          ;*  Nov-18-2013 ... moving to constants...
*;T4RXBYTE  (subroutine)
*;       purpose:  receive one byte from Atmel/Arduino
*;       inputs:  nothing
*;       outputs:  Accumulator-A
*;       destroys: nothing
*;       stack-use: 1 byte.
T4RXBYTE  EQU *
          ; --- ---
          JSR  READ4BIT
          CMPA #$0C    ;* Atmel is ready to send a byte.
          BNE  T4RXBYTE
          ; --- ---
          LDAA #$04    ;* Ack for "ready-to-send one-byte"
          JSR  SET4BIT
          CLRA
          PSHA     ; stack = byte we are receiving bits for.
          LDAB #$08   ;* B=8  (we want to receive 8 bits)
T4RXBIT   EQU *
          JSR  READ4BIT
          CMPA #$0E    ;* Atmel has sent a zero-bit.
          BEQ  T4RXZBT
          CMPA #$0F    ;* Atmel has sent a one bit.
          BNE  T4RXBIT
          ;* ================
          ;* - bit is a one.
T4RX1BT   EQU *
          ; --- ---
          PULA
          ASLA           ; C <- xxxx,xxxx <- 0
          ORAA #$01      ; set lowest bit to one.
          PSHA
          BRA  T4RXBTNX  ; branch-always, ACK the bit, wait for Atmel to be not bit=0 or bit=1,
          ;* ================
          ;* - bit is a zero.
T4RXZBT   EQU *
          ; --- ---
          PULA
          ASLA
          PSHA
          ;* ================
T4RXBTNX  LDAA #$05  ; ACK the bit.
          JSR  SET4BIT
          ; --- ---
          STX  LOCALX
          ; --- ---
T4RXLP1   EQU *
          JSR  READ4BIT
          CMPA #$0D
          BEQ  T4RXBTDN

          BRA  T4RXLP1
          ;* ==========
          ;* -- receive bit done.
T4RXBTDN  LDAA #$03  ; we are "bit-idle" waiting for next bit... (or "byte-done")
          JSR  SET4BIT
          DECB   ; B=B-1 (which bit are we receiving?)
          BNE  T4RXBIT  ; if (B != 0) go get next bit.
          ;* ==========
          LDAA #$05  ; ACK the LAST bit.
          JSR  SET4BIT
          ; --- ---
T4RXLP2   JSR  READ4BIT
          CMPA #$09
          BNE  T4RXLP2
          ;* ---
          LDAA #$06
          JSR  SET4BIT
          PULA
          RTS

* *****************************
*; ---------------------------
*;  TW-Receive-String.  (subroutine)
*;       rewrite after wiring error found.
*;     Input: nothing
*;     Output, String in Buffer at $A000, X= end of buffer.
TWRXSTR   EQU *
          JSR  READ4BIT
          CMPA #08
          BNE  TWRXSTR   ; wait till Atmel is ready to send data
          ; --- ---
          LDAA  #07
          JSR  SET4BIT      ;  AKA:  "I am ready to receive data."
          ; === ===
TWRXNBYT  JSR  T4RXBYTE  ; destroys B, keeps X, A=(Byte received).
          STAA 0,X     ; store accumulator-A at memory location = [X+0]
          INX         ; X = X+1.
         ; -----
          STX  REGX1               ;  **************************
          LDX  #TOPLEFT+ROW5+6     ; ** BYTEs Received Counter **
          LDAA REGX1    ; get MSB  ;  **************************
          SUBA #$A0
          JSR  SAYAHEX  ; print MSB to screen.
          LDX  #TOPLEFT+ROW5+8
          LDAA REGX1+1
          ;--  Debug info:  0000 shows black on green at start,
          ;---     the first byte loaded turns to green on (dark-green)
          JSR  SAYAHEX  ; print LSB to screen.
          LDX  REGX1
         ; -----
TWRXSL1   JSR  READ4BIT
          CMPA #$0C
          BEQ  TWRXNBYT
          CMPA #$09
          BEQ  TWRXSL1
          CMPA #$0A
          BNE  TWRXSL1    ; -- ??? are we still receiving bytes ???
TWRXFIN   RTS
*; ---------------------------
* *********************
* TWPRSTR  Input:  X = end of Buffer (start of buffer = 0xA000) 
* *********************
TWPRSTR   EQU *     ;-- just another memcpy( ..., ..., ... )
          STX  XSAVE  ;-- X (input) = end-of-buffer
          LDX  #$A000   ;--  start-of-buffer
          STX  LOCALX
          JSR  SCROLLUP   ; blank out the bottom-line.
          JSR  BLNKBOTM
          ;---
TWPRLP0   LDX  #BOTLEFT
          STX  SHSAVX
          LDAA MYCOUNT  ;  equal to zero?
          BEQ  TWPRARN  ;  yes, do not print number.
          STAA 0,X      ; put it on the screen.
          CMPA #'9'     ; was it already '9' ?
          BNE  TWPRAR0
          LDAA #'0'     ; if it was '9', reset to '0'
TWPRAR0   INCA          ;  increment            
          STAA MYCOUNT  ;  store it.
          INX           ; x=x+1
          LDAA #')'
          STAA 0,X
          INX
          LDAA #' '
          STAA 0,X
          INX
          ;---
TWPRARN   EQU *
          STX  SHSAVX
          ;---
          LDAB #32     ; a line is 32 characters.
TWPRLP1   LDX  LOCALX
          INX
          STX  LOCALX     ;-   0x0A = \n = New-Line
          DEX             ;-   0x0D = \r = Carriage-Return
          CPX  XSAVE
          BNE  TWPRLP2
          JSR  SCROLLUP   ; we are at end of buffer.
          JSR  BLNKBOTM  ; blank the bottom-line...
          RTS           ;   - return.
          ;---
TWPRLP2   LDAA 0,X
          LDX  SHSAVX
          CMPA #$0D
          BEQ  TWPRAR1
          CMPA #$0A
          BEQ  TWPRAR1
          JSR  UCASE     ; allow lower-case in MENU1.TXT
          STAA 0,X     ; screen location
TWPRAR1   INX          ; bump screen location
          STX  SHSAVX
          ; --- ---
          DECB
          BEQ  TWPRAR2  ;*  Bottom line is full.
          CMPA #$0A   ; New-Line character
          BEQ  TWPRAR2
          BRA  TWPRLP1   ; bottom-line is not full.
TWPRAR2   JSR  SCROLLUP
          JSR  BLNKBOTM  ; blank the bottom-line...
          BRA  TWPRLP0
* ************************************************************
;*  GETSPCD   FCC  "GETSPCD"  ; get Space-Destroyers
GETSPCD   FCC "BINDUMP SPACDEST.BIN"
          FCB  EOS
GETSPD01  FCC  "SEARCHING FOR 'SPACDEST.BIN'"
          FCB  EOS
GETSPACE  EQU *
          ; ---- ----
          LDAA  #$00
          JSR   SET4BIT  ; go into "IDLE" for the Atmel/Arduino.
          SEI
          ; ---- ----
          LDX  #GETSPD01
          STX  $06
          LDX  #TOPLEFT+ROW3
          JSR  WRITESTR
          ; ---- ----
          LDX  #BYTESLDD
          STX  $06
          LDX  #TOPLEFT+ROW5+6
          JSR  WRITESTR
          ; ---- ----
          LDX  #GETSPCD
          JSR  BIT4STRS  ; 4-bit string-send...
          ; ---- ----
          LDX  #OPENSTR
          STX  $06
          LDX  #TOPLEFT+ROW4+2
          JSR  WRITESTR
          ; ---- ----
          LDX  #$A000    ; start of RAM (buffer).
          JSR  TWRXSTR   ; after prod-board build, re-invent string receive.
          ; ---- ----
          JMP  LOADDONE
* *************************************************************
GETFLSHS  FCC  "GETFLASH"  ; get EEPROM FLASH  "APF-FLASH.BIN"
          FCB  EOS
GETFL001  FCC  "SEARCHING FOR 'APFFLASH.BIN'"
          FCB  EOS
OPENSTR   FCC  "OPENING..."
          FCB  EOS
BYTESLDD  FCC  "0000 BYTES LOADED."
          FCB  EOS
GETFLASH  EQU *
          ; ---- ----
          LDAA  #$00
          JSR   SET4BIT  ; go into "IDLE" for the Atmel/Arduino.
          SEI
          ; ---- ----
          LDX  #GETFL001
          STX  $06
          LDX  #TOPLEFT+ROW3
          JSR  WRITESTR
          ; ---- ----
          LDX  #BYTESLDD
          STX  $06
          LDX  #TOPLEFT+ROW5+6
          JSR  WRITESTR
          ; ---- ----
          LDX  #GETFLSHS  ; flash string.
          JSR  BIT4STRS  ; 4-bit string-send...
          ; ---- ----
          LDX  #OPENSTR
          STX  $06
          LDX  #TOPLEFT+ROW4+2
          JSR  WRITESTR
          ; ---- ----
          LDX  #$A000    ; start of RAM (buffer).
          JSR  TWRXSTR   ; after prod-board build, re-invent string receive.
          ; ---- ----
          JMP  LOADDONE
* *************************************************************
GETGAMES  FCC "GETGAME"   ; "APFGAME.BIN"
          FCB EOS
GETGAMET  FCC  "SEARCHING FOR 'APFGAME.BIN'"
          FCB  EOS
GETGAME   EQU *
          ; ---- ----
          LDAA  #$00
          JSR   SET4BIT  ; go into "IDLE" for the Atmel/Arduino.
          SEI
          ; ---- ----
          LDX  #GETGAMET
          STX  $06
          LDX  #TOPLEFT+ROW3
          JSR  WRITESTR
          ; ---- ----
          LDX  #BYTESLDD
          STX  $06
          LDX  #TOPLEFT+ROW5+6
          JSR  WRITESTR
          ; ---- ----
          LDX  #GETGAMES  ; "game" string.
          JSR  BIT4STRS  ; 4-bit string-send...
          ; ---- ----
          LDX  #OPENSTR
          STX  $06
          LDX  #TOPLEFT+ROW4+2
          JSR  WRITESTR
          ; ---- ----
          LDX  #$A000    ; start of RAM (buffer).
          JSR  TWRXSTR   ; after prod-board build, re-invent string receive.
          ; ---- ----
          JMP  LOADDONE
* *************************************************************          
LOADDONE  EQU  *
          STX  XSAVE
          LDX  #$A000
          LDAA 0,X
          CMPA #'E'       ; if we start with "ERR", then it is an ERROR
          BNE  LOADOKAY   ; that we loaded, just print it as a string
          LDAA 1,X        ; and then reboot.
          CMPA #'R'
          BNE  LOADOKAY
          LDAA 2,X
          CMPA #'R'
          BNE  LOADOKAY
          JSR  SCROLLUP
          JSR  SCROLLUP
          LDX  XSAVE
          CLR  MYCOUNT
          JSR  TWPRSTR    ; print string (to screen), scroll at 32 chars, etc.
          JMP  STDEXIT
LOADOKAY  CLR  $BF06     ; loop - flag
          JMP  BSSCRLP   ; call bank-switch and reboot.
* *************************************************************
*; ===============================================
*;
ISITRAM   FCC  "ABCD"  ;-- If this is RAM, we can Flash the EEPROM at A000
          ;==  If the EEPROM is at $8000-$9FFF, the write-line is disabled.
SRCPTR    FCC  "00"
DSTPTR    FCC  "00"
FLASHT0   FCB  0
FLASHT1   FCB  1
FLASHT2   FCB  2
FLMSG1    FCC  "  YOU CANNOT FLASH WITHOUT     "
          FCB  EOS
FLMSG2    FCC  "  LOADING THE APFFLASH FIRST   "
          FCB  EOS
FLMSG3    FCC  "  THEN BOOTING TO THAT IMAGE   "
          FCB  EOS
FLMSG4    FCC  "  AND FLASH-ING FROM THERE.    "
          FCB  EOS
FLMSG5    FCC  "  FLASH ROUTINE HAS COMPLETED. "
          FCB  EOS
          ;---- 12345678901234567890123456789012
FLMSG6    FCC  " PLEASE POWER THE MACHINE OFF  "
          FCB  EOS
FLMSG7    FCC  " AND BACK ON AGAIN. "
          FCB  EOS
FLMSG8    FCC  " PLEASE WAIT UNTIL THE COUNTER "
          FCB  EOS
FLMSG9    FCC  " GETS TO $BFFF BEFORE REBOOT.  "
          FCB  EOS
FLMSG10   FCC  " FLASHING EEPROM, "
          FCB  EOS
FLMSG11   FCC  " COUNTER =        "
          FCB  EOS
*; ---------------------------------
DOFLASH   JSR  CLRSCR
          LDX  #ISITRAM  ; -- ?? Is it RAM ??
          LDAA #202     ; don't care what, as long as it is not capital 'A'
          STAA 0,X      ;  A -> memory
          LDAB 0,X      ;  B <- memory
          SBA           ;  A - B -> A
          BEQ  FLSHOK
          LDX  #FLMSG1   ;-- not OK to Flash... Tell the User and Exit.
          STX  $06
          LDX  #TOPLEFT+ROW5
          JSR  WRITESTR
          LDX  #FLMSG2
          STX  $06
          LDX  #TOPLEFT+ROW6
          JSR  WRITESTR
          LDX  #FLMSG3
          STX  $06
          LDX  #TOPLEFT+ROW7
          JSR  WRITESTR
          LDX  #FLMSG4
          STX  $06
          LDX  #TOPLEFT+ROW8
          JSR  WRITESTR
          JMP  STDEXIT     ; remember this scrolls the screen up by one line.
          ; --
FLSHOK    LDX  #FLMSG8
          STX  $06
          LDX  #TOPLEFT+ROW5
          JSR  WRITESTR
          LDX  #FLMSG9
          STX  $06
          LDX  #TOPLEFT+ROW6
          JSR  WRITESTR
          LDX  #FLMSG10
          STX  $06
          LDX  #TOPLEFT+ROW8
          JSR  WRITESTR
          LDX  #FLMSG11
          STX  $06
          LDX  #TOPLEFT+ROW9
          JSR  WRITESTR
          ; ---   START OF THE ROUTINE...
          LDX  #ISITRAM
          LDAA #'A'
          STAA 0,X   ;-- restore this before "flashing" the EEPROM.
          LDAB #30
          STAB FLASHT2   ; set "try this many times" counter
          LDX  #$8000
          STX  SRCPTR    ;-- Source pointer
          LDX  #$A000
          STX  DSTPTR    ;-- .. will let you work out the rest of the controls
          ; -- initialize varibles is done, start programming loop.
FLSHLOOP  LDX  #TOPLEFT+ROW9+12
          LDAA DSTPTR    ;-- High-Byte of pointer
          JSR  SAYAHEX 
          LDX  #TOPLEFT+ROW9+14
          LDAA DSTPTR+1  ;-- Low=Byte of pointer
          JSR  SAYAHEX
          ; ---
          LDX  SRCPTR
          LDAA 0,X
          LDX  DSTPTR
          JSR  FLSHBYTE  ;-- call the "Burn a byte" routine.
          SBA      ;--  A=A-B.
          BEQ  FLSHNXTB  ; go to Next Byte
          DEC  FLASHT2    ; bump "try again" counter.
          BEQ  FLSHNXTB  ; give up on this byte.
          BRA  FLSHLOOP  ;  try burning this byte again.
          ; --
FLSHNXTB  LDX  SRCPTR    ; Bump the counters.
          INX
          STX  SRCPTR
          LDX  DSTPTR
          INX
          STX  DSTPTR
          LDAB #10
          STAB FLASHT2    ; reset "try this many times" counter
          ; --
          CPX  #$C000     ; Have we run out of EEPROM to write to?
          BLT  FLSHLOOP
          ; ---   END OF ROUTINE ... NEXT:  TELL THE USER...
          JSR  CLRSCR
          LDX  #FLMSG5    ;-- "We are done here"
          STX  $06
          LDX  #TOPLEFT+ROW5
          JSR  WRITESTR
          LDX  #FLMSG6
          STX  $06
          LDX  #TOPLEFT+ROW6
          JSR  WRITESTR
          LDX  #FLMSG7
          STX  $06
          LDX  #TOPLEFT+ROW7
          JSR  WRITESTR
FLSHNOXT  JMP  FLSHNOXT    ;-- Do not let the user exit without power-cycle.
*;
*; -----------------------------------------------
*; FLSHBYTE   Input  A=byte to burn to EEPROM,  X=location to burn it to.
*;            Uses:  DSTPTR (Read-Only).
*;            Output: B-register,  if A=B, then success... else... FLASHT0=0...
*;            Destroys:  FLASHT0, FLASHT1, B-register
*; ---
FLSHBYTE  STAA  0,X   ;-- write once, then poll till write-cycle is complete.
          LDAB  #0A  ;-- see MSDELAY for calculation
          STAB  FLASHT0
          CLR   FLASHT1
FLSHPOLL  DEC   FLASHT1   ; inner loop (low byte of counter)
          BNE   FLSHARND
          DEC   FLASHT0   ; outer loop (hi-byte of counter)
          BEQ   FLSHBYDN  ; TimeOut reached.
FLSHARND  LDAB  0,X       ;-- Atmel max write-time is 2-ms
          CBA             ;--   per datasheet for 28C64B.PDF
          BEQ   FLSHBYDN  ;-- if we can read what we wrote, we are done.
          BRA   FLSHPOLL  ;--   else, run until the TimeOut is reached.
FLSHBYDN  RTS   ;-- either polling time has run out, or the bytes are equal.
*; -----------------------------------------------
*;
*;             12345678901234567890123456789012
SAFEM1    FCC " THE BANK-SWITCH IS TURNED ON "
          FCB  EOS
SAFEM2    FCC " IF WE LOAD CARTRIDGES IN THIS "
          FCB  EOS
SAFEM3    FCC " MODE, IT WILL DAMAGE THE"
          FCB  EOS
SAFEM4    FCC " BOOT-ROM.  PLEASE POWER "
          FCB  EOS
SAFEM5    FCC " THE MACHINE OFF AND BACK ON "
          FCB  EOS
SAFEM6    FCC " BEFORE PROCEEDING. "
          FCB  EOS
; ---
SAFETCHK  LDX  #ISITRAM  ; -- ?? Is it RAM ??
          LDAA 0,X     ; don't care what, as long as it is not capital 'A'
          NEGA         ; just manipulate the number so that it isn't
          INCA         ; what used-to-be there.
          INCA
          STAA 0,X      ;  A -> memory
          LDAB 0,X      ;  B <- memory
          SBA           ;  A - B -> A
          BEQ  NOTSAFE
          RTS     
NOTSAFE   JSR  CLRSCR
          LDX  #SAFEM1   ;-- not OK to Flash... Tell the User and Exit.
          STX  $06
          LDX  #TOPLEFT+ROW5
          JSR  WRITESTR
          LDX  #SAFEM2
          STX  $06
          LDX  #TOPLEFT+ROW6
          JSR  WRITESTR
          LDX  #SAFEM3
          STX  $06
          LDX  #TOPLEFT+ROW7
          JSR  WRITESTR
          LDX  #SAFEM4
          STX  $06
          LDX  #TOPLEFT+ROW8
          JSR  WRITESTR
          LDX  #SAFEM5
          STX  $06
          LDX  #TOPLEFT+ROW9
          JSR  WRITESTR
          LDX  #SAFEM6
          STX  $06
          LDX  #TOPLEFT+ROW10
          JSR  WRITESTR
STOPHERE  CLC
          INX
          CLC
          JMP  STOPHERE
          ; --
*; ===============================================
MNU1STR   FCC "BINDUMP MENU1.TXT"  ; <-- 17 chars...
          FCB EOS                  ; <-- EOS is needed by the BIT4STRS routine.
MNU2STR   FCC "BINDUMP MENU2.TXT"  ; <-- 17 chars...
          FCB EOS                  ; <-- EOS is needed by the BIT4STRS routine.
MNU1SRCH  FCC  "SEARCHING FOR 'MENU1.TXT'"
          FCB  EOS
MNU2SRCH  FCC  "SEARCHING FOR 'MENU2.TXT'"
          FCB  EOS
*; ---------------------------------
GETMNU1   EQU *
          ; ---- ----
          LDAA  #$00
          JSR   SET4BIT  ; go into "IDLE" for the Atmel/Arduino.
          SEI
          ; ---- ----
          LDX  #MNU1SRCH
          STX  $06
          LDX  #TOPLEFT+ROW3
          JSR  WRITESTR
          ; ---- ----
          LDX  #BYTESLDD
          STX  $06
          LDX  #TOPLEFT+ROW5+6
          JSR  WRITESTR
          ; ---- ----
          LDX  #MNU1STR  ; Send the File: "MENUx.TXT" string.
          JSR  BIT4STRS  ; 4-bit string-send... (request file from Arduino)
          BRA   TWRDMNU
          ;* ---
GETMNU2   EQU *
          ; ---- ----
          LDAA  #$00
          JSR   SET4BIT  ; go into "IDLE" for the Atmel/Arduino.
          SEI
          ; ---- ----
          LDX  #MNU2SRCH
          STX  $06
          LDX  #TOPLEFT+ROW3
          JSR  WRITESTR
          ; ---- ----
          LDX  #BYTESLDD
          STX  $06
          LDX  #TOPLEFT+ROW5+6
          JSR  WRITESTR
          ; ---- ----
          LDX  #MNU2STR  ; Send the File: "MENUx.TXT" string.
          JSR  BIT4STRS  ; 4-bit string-send... (request file from Arduino)
   ;       BRA   TWRDMNU
          ;* ---
TWRDMNU   EQU *
          ; ---- ----
          LDX  #OPENSTR
          STX  $06
          LDX  #TOPLEFT+ROW4+2
          JSR  WRITESTR
          ; ---- ----
          LDX  #$A000    ; start of receive-buffer.
          JSR  TWRXSTR   ; after prod-board build, re-invent receive routine.
          ; ------
          STX  XSAVE     ; <--- end of buffer (end of data from MENU1.TXT)
          LDX  #$A000
          LDAA 0,X
          CMPA #'E'       ; if we start with "ERR", then it is an ERROR
          BNE  TWMNUOK    ; that we loaded, just print it as a string
          LDAA 1,X        ; and then reboot.
          CMPA #'R'
          BNE  TWMNUOK
          LDAA 2,X
          CMPA #'R'
          BNE  TWMNUOK
          JSR  SCROLLUP
          JSR  SCROLLUP
          LDX  XSAVE      ; <-- end of buffer. (beginning known to be $A000)
          CLR  MYCOUNT
          JSR  TWPRSTR    ; print string (to screen), scroll at 32 chars, etc.
          JMP  STDEXIT
          ; ------
TWMNUOK   LDX  XSAVE
          LDAA #'1'       ; first line start with '1'
          STAA MYCOUNT    ; save to the line-counter.
          JSR  TWPRSTR
          ; ----
          LDX  XSAVE     ; handle if the file did not end with new-line.
          LDAA #$0A
          INX
          STAA 0,X
          ; ----
TWMNUDN   EQU *    ; <-- Menu is on-screen, call the "get joystick/keypad"
          JSR  ISJOYUSD
          ; -- XSAVE = end of buffer,  A000 = start of buffer, MYCOUNT = number of lines.
          LDAA JOYDATA
          CMPA #'?'  ; <-- user clicked clear
          BNE  TWMNUDX
          JSR  BEEP
          BRA  TWMNUDN  
TWMNUDX   CMPA #'!'  ; <-- user clicked enter
          BNE  TWMNUDY
          LDAA #'1'  ; <-- choose 1st entry.
          BRA  TWMNUDZ
TWMNUDY   CMPA MYCOUNT  ; <-- MYCOUNT is (one higher) than number of selections.
          BLT  TWMNUDZ ; <-- bacon, lettuce...
          JSR  BEEP
          BRA  TWMNUDN  
          
TWMNUDZ   STAA LOCALA  ; <-- selection in Local 'A'  (JOYDATA might be "enter")
          LDX  #$A000
          STX  LOCALX  ; <-- start of "buffer" to send as File-Name.
          LDAA #'0'
          CLR  LOCALB   ; string-size.
          INC  LOCALB   ; start counting at 1, not zero.
          ;-------
TWMNLP1   LDAB 0,X
          CMPB #$0A   ; <-- is it the new-line character?
          BNE  TWMNNTNL
          INCA         ; <--  "1", "2", "3", "4", ...
          CMPA LOCALA
          BEQ  TWMNISDN  ; <--  they match "we are done" with the loop.
          INX
          STX  LOCALX  ; <-- point to the character after the new-line.
          CLR  LOCALB   ; string-size.
          DEX
TWMNNTNL  INX
          INC  LOCALB   ; string-size.
          CPX  XSAVE    ; <-- end of data-buffer?
          BEQ  TWMNISDQ  ; <-- yes, we use the last entry (file did not end in new-line)
          BRA  TWMNLP1
          ;-------
TWMNISDN  DEC  LOCALB ; <-- we have LOCALA = Selection number,  LOCALB=length of "filename"
          ;  --  -- LOCALX = start of "filename", X= new-line at end of "filename"
TWMNISDQ  EQU  *  ; <-- if we ended at "not a new-line"
          ;  --  --
          LDAA #08   ; want to copy 8 characters...
          LDX  #$A600  ; "buffer"
          STX  REGX1   ; pointer "copy-to"
          LDX  #MNU2STR
          STX  REGX2   ; pointer "copy-from"
          ;  --  --
TWMNDL1   LDX  REGX2  ; next location to fetch from
          LDAB 0,X    ; fetch "from"
          INX        ; bump location
          STX  REGX2  ; "from" pointer
          LDX  REGX1  ; "to" pointer
          STAB 0,X    ; store at "to"
          INX        ; bump location
          STX  REGX1  ; "to" pointer
          DECA       ; counter
          BNE  TWMNDL1
          ;  --  --
          
*;  STOPGAP0  BRA  STOPGAP0   ;  seemed to be okay here before....
         ; -- works up to here...
          
          LDX  LOCALX   ;  "FILENAME"
          STX  REGX2
          LDAA LOCALB   ; length of "filename"
          DECA
          ;  --  --
TWMNDL2   LDX  REGX2  ; next location to fetch from
          LDAB 0,X    ; fetch "from"
          INX        ; bump location
          STX  REGX2  ; "from" pointer
          LDX  REGX1  ; "to" pointer
          STAB 0,X    ; store at "to"
          INX        ; bump location
          STX  REGX1  ; "to" pointer
          DECA       ; counter
          BNE  TWMNDL2
          ;  --  --
          LDAA  #EOS  ; "End-of-String"
          STAA  0,X

          
*; STOPGAP1   BRA  STOPGAP1    ; writes all over screen and stack before it gets here.

          ;  --  --
          LDAA #15   ; want to copy 15 characters...
          LDX  #$A800  ; "buffer"
          STX  REGX1   ; pointer "copy-to"
          LDX  #MNU1SRCH
          STX  REGX2   ; pointer "copy-from"
          ;  --  --
TWMNDL3   LDX  REGX2  ; next location to fetch from
          LDAB 0,X    ; fetch "from"
          INX        ; bump location
          STX  REGX2  ; "from" pointer
          LDX  REGX1  ; "to" pointer
          STAB 0,X    ; store at "to"
          INX        ; bump location
          STX  REGX1  ; "to" pointer
          DECA       ; counter
          BNE  TWMNDL3
          ;  --  --

          
*; STOPGAP2   BRA  STOPGAP2


          LDX  LOCALX   ;  "FILENAME"
          STX  REGX2
          LDAA LOCALB   ; length of "filename"
          DECA
          ;  --  --
TWMNDL4   LDX  REGX2  ; next location to fetch from
          LDAB 0,X    ; fetch "from"
          INX        ; bump location
          STX  REGX2  ; "from" pointer
          LDX  REGX1  ; "to" pointer
          STAB 0,X    ; store at "to"
          INX        ; bump location
          STX  REGX1  ; "to" pointer
          DECA       ; counter
          BNE  TWMNDL4
          ;  --  --
          LDAA  #$67   ; single-tick character.
          STAA  0,X
          INX
          LDAA  #EOS  ; "End-of-String"
          STAA  0,X
          ;  --  --
          JSR  CLRSCR
     ;->     JMP  GETGAME

  ;          LDAA JOYDATA
  ;          CMPA #'1'
  ;          BNE  MTARND1
  ;          JSR  CLRSCR
  ;            (FETCH FIRST ENTRY FILENAME)
  ;            BRANCH-ALWAYS TO END OF SELECTIONS
  ;MTARND1   CMPA #'2'
  ;          BNE  MTARND2
  ;          JSR  CLRSCR
  ;            (FETCH FIRST ENTRY FILENAME)
  ;            BRANCH-ALWAYS TO END OF SELECTIONS
  ;MTARND2   CMPA #'3'
  ;          BEQ  (TO END OF SELECTIONS)
  ;          ; ---  else, beep and loop.
  ;          JSR  BEEP
  ;          BRA  TWMNUDN
          ; ------
          ; ------
          ; ------
   ;       LDX  #STRBFFR  ; "game" string.
   ;->       LDX  GETGAMES
          ; ------
          ; ------
          ; ------
          LDAA  #$00
          JSR   SET4BIT  ; go into "IDLE" for the Atmel/Arduino.
          SEI
          ; ---- ----
          LDX  #$A800     ; "looking for FILENAME"
          STX  $06
          LDX  #TOPLEFT+ROW3
          JSR  WRITESTR
          ; ---- ----
          LDX  #BYTESLDD    ; "0000 bytes loaded"
          STX  $06
          LDX  #TOPLEFT+ROW5+6
          JSR  WRITESTR
          ; ---- ----
          LDX  #$A600
          JSR  BIT4STRS  ; 4-bit string-send...
          ; ---- ----
          LDX  #OPENSTR  ;  " opening "
          STX  $06
          LDX  #TOPLEFT+ROW4+2
          JSR  WRITESTR
          ; ---- ----
          LDX  #$A000    ; start of "game"-buffer.
          JSR  TWRXSTR   ; after prod-board build, re-invent string receive.
          ; ---- ----
          JMP  LOADDONE
; ===================================================
*
*       
* *************************************************************
*     BANK-SWITCH  Tests Below here.
* *************************************************************
STRBNKON  FCC  "BANKON"
          FCB  EOS
STRBKOFF  FCC  "BANKOFF"
          FCB  EOS
SMSSG01   FCC  "START COPYING BYTES TO RAM."
          FCB  EOS
SMSSG01A  FCC  "COUNTER:"
          FCB  EOS
SMSSG02   FCC  "DONE WITH COPY ROUTINE."
          FCB  EOS
SMSSG03   FCC  " -SENDING (BANKON)- "
          FCB  EOS
*; ==================
BNKOFF    LDX  STRBKOFF
          JSR  BIT4STRS  
          LDAA DELAY100
*; ==================
GOBRICKS  EQU *
BNKSWTST  CLC
          ; ---- ----
          LDAA  #$00
          JSR   SET4BIT  ; go into "IDLE" for the Atmel/Arduino.
          ; ---- ----
          LDX  #SMSSG01
          STX  $06
          LDX  #TOPLEFT+ROW4+0
          JSR  WRITESTR
          LDX  #SMSSG01A
          STX  $06
          LDX  #TOPLEFT+ROW5+0
          JSR  WRITESTR
          ; ---
          ; -  BF00 = Destination MSB    (Dest)
          ; -  BF01 = Destination LSB
          ; -  BF02 = Pull-From-Here-Counter MSB   (SrcPtr)
          ; -  BF03 = Pull-From-Here-Counter LSB
          ; -  BF04 = Pull-From-Here-Upper-Limit MSB   (SrcEnd)
          ; -  BF05 = Pull-From-Here-Upper-Limit LSB
          ; -  BF06 = Flag (copy-to-screen-mem)
          LDX  #$A000   ; destination
          STX  $BF00    ; MSB->$BF00 LSB->$BF01  
          LDX  #$9800   ; our local copy... this will become SD-file-read
          STX  $BF02    ; current-counter (Source)
          LDX  #$9FFF+1 ; upper-limit
          STX  $BF04    ; upper-limit to compare.
          CLR  $BF06    ; Flag
          ;--
BSLP01    CLC   ; TOP of "MAIN-LOOP"
          ;--  Display the counter
          LDAA $BF02  ; - MSB of Counter  (SrcPtr)
          LDX  #TOPLEFT+ROW5+9
          JSR  SAYAHEX
          LDAA $BF03  ; - LSB of Counter  (SrcPtr)
          LDX  #TOPLEFT+ROW5+11
          JSR  SAYAHEX
          ;--
          LDX  $BF02   ; source
          LDAA 0,X     ; PEEK(source)
          LDX  $BF00   ; destination
          STAA 0,X     ; POKE(destination)
          ;--
          ;--  Dest=Dest+1
          INC  $BF01  ; bump the (dest) low byte.
          BNE  BSJ01  ; if low-byte is non-zero, don't bump the high-byte.
          INC  $BF00  ; bump the (dest) high-byte.
BSJ01     CLC
          ;--
          ;--  SrcPtr=SrcPtr+1
          INC  $BF03   ; bump the (src) low-byte.
          BNE  BSJ02   ; if low-byte is non-zero, do not bump high-byte.
          INC  $BF02   ; bump (src) high-byte.
BSJ02     CLC
          ;--  If (SrcPtr != SrcEnd) then Next
          LDX  $BF04   ; upper limit
          CPX  $BF02   ; is upper limit reached?
          BNE  BSLP01  ; Branch if upper-limit is greater than current counter.
          ;--  EndIf
          ;--
          LDX  #SMSSG02  ; "Done with copy routine."
          STX  $06
          LDX  #TOPLEFT+ROW6+0
          JSR  WRITESTR
          ;---
BSSCRLP   LDAA $BF06   ; check Flag
          BEQ  BSARND  ; Branch around this next code chunk
          JMP  TOPLEFT+ROW10+0 ; If flag is nonZero, jump-to-code-chunk in screen-memory.
          ;---------
          ; next chunk does not get executed -now, but is copied to screen-memory
          ; it is then executed from screen memory.
BS2CPY    LDAA #$0B
          LSLA
          STAA  EVBDOUT 
   ;       JSR  SET4BIT    ;- can call this *before* the bank-switch happens.
          LDAB #200
BSSCLPDA  DECB
          BEQ  BSSCLPDB
   ;       JSR  READ4BIT   ;- this could be a problem...
          LDAA EVBDIN     ;-  except D0,D1 are OK -- and D2->D3, D3->D4
          ANDA #%00011011 ; mask lower 4 bits
          CMPA #$02       ;-  we want xxx00x10
          BNE  BSSCLPDA
BSSCLPDB  CLI    ; <-- clear the interrupt flag.
     ;==     CLRA
     ;==     STAA  EVBDOUT  ; tell the Atmel to go "idle".
    ;      LDAA #30     ; A=30 ==> the MATH says (with no interrupts) A=30 is 2 seconds...
          LDAA #5
BSSCLPD0  LDX #50000    ; 2 = ( 1 / 3,579,545 ) * 4 * X * A
BSSCLPD1  DEX           ; (let A=30) :: 2/(X*A) = 4/3579545
          BNE BSSCLPD1  ; 30x = 3579545*2/4 = 1789772.5 :: X=59659 (round down)
          ; ===>  X = 0 here...
          LDX  #TOPLEFT+ROW14+3
          ADDA #'0'
          STAA 0,X   ;-  5,4,3,2,1.
          SUBA #'0'
          DECA
          BNE BSSCLPD0
          JMP  REBOOT
BS2CPZ    EQU  *       ; x = 3579545*2/4 = 1789772.5
          ;---------
          ; END of chunk that is copied to screen-memory.
          ;---------
BNKON     EQU  *   ; entry point from other routines.  :-)
BSARND    LDX  #TOPLEFT+ROW10+0 ; destination
          STX  $BF00
          LDX  #BS2CPY  ; block to copy from
          STX  $BF02
          LDX  #BS2CPZ  ; end of copy-from block.
          STX  $BF04
          INC  $BF06   ; set the flag
          ; ---
          LDX  #SMSSG03  ;  " -- Sending BankON -- "
          STX  $06
          LDX  #TOPLEFT+ROW7+0
          JSR  WRITESTR
          ; ---
          JMP  BSLP01  ; back to copy-loop.

* ********************************************************
*;********************************************************
* ********************************************************

*; ==================
*;* this is the ROM from "BRICKDOWN" - moved to here for BNKSWTST... delete when ready.
*; ==================
          ORG $9800    ; BRICKDOWN.BIN       ;  it is only 2K in size...
*;        ---------------------------------------------------
*;        -- gets moved to 0xA000-0xA7FF by Bank-Switch-Test
*;        --     routine, then calls reboot sequence.
*;        -- setting BANKSW "on" swaps:  8k RAM with 8k EEPROM
*;        --     0x8000-0x9FFF <---> 0xA000-0xBFFF
*;        ---------------------------------------------------
          FCB $BB,$80,$D8,$31,$00,$BD,$42,$96,$BD,$80,$11,$BD
          FCB $80,$45,$7E,$80,$0B,$86,$DF,$CE,$02,$00,$BD,$80
          FCB $BD,$CE,$03,$E0,$BD,$80,$BD,$CE,$03,$E0,$FF,$01
          FCB $86,$CE,$02,$00,$BD,$80,$C6,$CE,$03,$FF,$FF,$01
          FCB $86,$CE,$02,$1F,$BD,$80,$C6,$CE,$02,$EF,$FF,$01
          FCB $82,$FF,$01,$84,$86,$CF,$A7,$00,$39,$BD,$41,$D9
          FCB $25,$01,$39,$B6,$01,$F2,$81,$4E,$26,$03,$7E,$80
          FCB $7F,$81,$53,$26,$03,$7E,$80,$8E,$81,$45,$26,$03
          FCB $7E,$80,$6B,$81,$57,$26,$03,$7E,$80,$75,$39,$FE
          FCB $01,$82,$FF,$01,$84,$08,$7E,$80,$9A,$FE,$01,$82
          FCB $FF,$01,$84,$09,$7E,$80,$9A,$FE,$01,$82,$FF,$01
          FCB $84,$86,$20,$09,$4A,$26,$FC,$7E,$80,$9A,$FE,$01
          FCB $82,$FF,$01,$84,$86,$20,$08,$4A,$26,$FC,$FF,$01
          FCB $80,$A6,$00,$81,$DF,$27,$0F,$FE,$01,$84,$A7,$00
          FCB $FE,$01,$80,$86,$CF,$A7,$00,$FF,$01,$82,$C6,$32
          FCB $86,$FF,$4A,$26,$FD,$5A,$26,$F8,$39,$C6,$20,$A7
          FCB $00,$08,$5A,$26,$FA,$39,$A7,$00,$C6,$20,$08,$5A
          FCB $26,$FC,$A7,$00,$BC,$01,$86,$26,$F3,$A7,$00,$39
          FCB $E9,$4D,$4F,$56,$45,$20,$42,$4C,$4F,$43,$4B,$20
          FCB $20,$2E,$30,$32,$E8,$E1,$42,$59,$20,$41,$44,$41
          FCB $4D,$20,$54,$52,$49,$4F,$4E,$46,$4F,$2C,$20,$4A
          FCB $55,$4C,$59,$20,$32,$30,$2C,$20,$32,$30,$31,$30
          FCB $E3,$E3,$42,$41,$53,$45,$44,$20,$4F,$4E,$20,$45
          FCB $52,$49,$43,$20,$42,$45,$43,$4B,$45,$54,$54,$27
          FCB $53,$E7,$42,$41,$53,$49,$43,$2F,$4D,$4C,$20,$45
          FCB $58,$41,$4D,$50,$4C,$45,$20,$46,$52,$4F,$4D,$20
          FCB $31,$39,$38,$34,$FE,$E5,$31,$2E,$20,$52,$55,$4E
          FCB $20,$50,$52,$4F,$47,$52,$41,$4D,$20,$20,$20,$20
          FCB $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
          FCB $20,$20,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
          FCB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
          FCB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
          FILL  $FF,$A000-*
*;   End of BRICKDOWN.BIN
*; ----------------------------------------------------------
          END
* ********************************
* ********************************
* ********************************
 