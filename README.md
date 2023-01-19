# APF2SD
SD adapter/reader for the APF M1000/MP1000.<br />
<br />
Useage:<br />
   The adapter fits in the cartridge slot like a regular APF game cartridge.<br />
   The SD is read on boot-up, so needs to be in the slot before applying power.<br />
   Reboot (button) will reboot the currently loaded ROM image.<br />
   To read a new SD card, power off the M1000/MP1000 and power it back on.
<br />
Revision 1 of the reader is set up to emulate all cartridges, including the Space Destroyers which contains extra RAM.<br />
<br />
Revision 1B reprograms the PLD to mask the first 4K of the cartridge space as read-only, this affects the UFO catridge.<br />
<br />
Revision 1 can load the BASIC 8k section but will have no RAM left to load the program.<br />
The hardware allows for a larger RAM to be used, but development was stopped at the "play all the game cartridges" milestone.<br />
<br />
---.<br />
<br />
All chips are DIP, this allowed for prototyping on a solderless breadboard.<br />
<br />
There are 3 programmable chips.<br />
<br />
   ATF20V8B-15PU  -- SPLD, 0.3-inch, PDIP-24: This was originally a 22v10 and the "spare lines" were mapped to breakout points for experimentation/expansion on the PCB.<br />
<br />
   AT28C64B-15PU --EEPROM  -- 0.6-inch, 28-pin DIP: Using the PLD, we can remap banks of the ROM, worked with the PCB artist to allow for 27c256 and 27c512...<br />
<br />
   Atmel: This was an UNO (ATmega328P) and was connected to with a bluetooth serial, it was later programmed with a raw boot image that only read SD and transferred the data to the RAM.  Two bank-switch commands were added : Bank-0 will PLD write-protect the cartridge space and remap the boot ROM and RAM on the memory-map.  The routine from the boot-rom then calls the boot-vector in order to boot to the cartridge image that was loaded and write-protected (treat it as ROM).<br />
<br />
The EEPROM is re-programmable.  A routine was created to load the RAM with an updated image of the boot-rom, then the routine re-programs the EEPROM and rebooots.  - It is possible to "brick" the device, but it makes upgrades to the boot-rom easier.<br />
<br />
   --end of edit, Jan-07-2023.--<br />
<br />
Initial-Upload of files.<br />
<br />
URL Link to My Google-Sites Page : https://sites.google.com/site/apf2sd/home <br />
<br />
URL Link to This Page :  https://github.com/tom63005/APF2SD/ <br />
<br />
Note that when I uploaded the files, the comment says 2022 when it should say 2023. <br />
<br />
   --end of edit, Jan-11-2023.--<br />
<br />
   Link to UNO Rev-3 board https://store-usa.arduino.cc/products/arduino-uno-rev3?selectedStore=us <br />
   (used in the prototype, the finished product uses the ATmega, programmed with a GHEO programmer) <br />
<br />
   License used earlier was GPLv2, with the provision that anyone can use the code for personal use: learning, experimenting, etc.<br />
      I do not beleive there is a profitable application for my code or the circuitry of the experimenter tool created.<br />
      I am one person and have no intention of supporting changes to the revision-1 on a corporate development level.<br />
<br />
   --end of edit, Jan-12-2023.--<br />
<br />
  Jan-16-2023 :: I located the original PC-Boards (about 30 PCBs in this stack) <br />
  ...  If you are interested in a board, send me a PM ... <br />
  I paind to have these manufactured and paid an artist to create the EagleCAD Gerbers.
<br />
- = - = - = --<br />
<br />
  Jan-19-2023 :: I found a snapshot of the source-code archived in 2013, before and after the cards were sent to Lance and Adam for "candidate for release" evaluation. - The cards worked for all catridges but needed a re-work of the PLD to block UFO from overwriting the stack on the 2nd time it was played.  I uploaded the "re-work" with the original git-hub create. The Arduino code is from the snapshot taken: Dec-2013.
<br />
- = - = - = --
