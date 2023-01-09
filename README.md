# APF2SD
SD adapter/reader for the APF M1000/MP1000.

Useage:
   The adapter fits in the cartridge slot like a regular APF game cartridge.
   The SD is read on boot-up, so needs to be in the slot before applying power.
   Reboot (button) will reboot the currently loaded ROM image.
   To read a new SD card, power off the M1000/MP1000 and power it back on.
   
Revision 1 of the reader is set up to emulate all cartridges, including the Space Destroyers which contains extra RAM.
Revision 1B reprograms the PLD to mask the first 4K of the cartridge space as read-only, this affects the UFO catridge.

All chips are DIP, this allowed for prototyping on a solderless breadboard.
There are 3 programmable chips.
   ATF20V8B-15PU  -- SPLD, 0.3-inch, PDIP-24: This was originally a 22v10 and the "spare lines" were mapped to breakout points for experimentation/expansion on the PCB.
   AT28C64B-15PU --EEPROM  -- 0.6-inch, 28-pin DIP: Using the PLD, we can remap banks of the ROM, worked with the PCB artist to allow for 27c256 and 27c512...
   Atmel: This was an UNO and was connected to with a bluetooth serial, it was later programmed with a raw boot image that only read SD and transferred the data to the RAM.  The PLD write-protects the cartridge space, remaps the boot ROM and RAM on the memory-map, then calls the boot-vector.
   
The EEPROM is re-programmable.  A routine was created to load the RAM with an updated image of the boot-rom, then the routine re-programs the EEPROM and rebooots.  - It is possible to "brick" the device, but it makes upgrades to the boot-rom easier.
   
   --end of edit, Jan-07-2023.--

Okay, so I used "git add ." from the directory to upload...
Then used "git commit" to actually upload...
I saw the TCP log where the github address was accessed, did not capture data packets...
The pictures and source are not here ...
Currently looking at videos where people drag & drop to the web-browser ??
Is there an example of using a Raspberry and command-line ??

   --end of edit, Jan-09-2023, 09:30-am CST--
   .
