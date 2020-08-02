The WonderProject: WonderMadeleine
==================================
(c) 2014  986-Studio / Godzil

Website: http://www.986-studio.com
e-mail: <godzil_nospambot at 986 dash studio dot com> (remove the underscore nospambot of course)


What this project is about:
---------------------------

This is a VHDL implementation of the Bandai 2001 / 2003 chip found in all official WonderSwan Cartridge. It will ultimately provide a fully functional clone of the Bandai chip.


License
-------
This project is currently licensed under the something close to the CC BY-NC-ND:

What does that mean:
 * The BY is the same as the CC:
   + You have to give credits if you are using this code in a chip on your board,
 * The NC differ from the CC:
   + You can use this code to program your own CPLD/FPGA
   + You cannot sell directly this code or a chip using this code, but work using it is fine:
     - You can build your own cartridge that use this CPLD/FPGA (and you can even sell them!)
     - But you can't program CPLD and sell them directly
 * The ND also differ:
   + You are welcome to propose patch for supporting another CPLD/FPGA or correct bugs, add functionality (you can create fork on GitHub for this is not a problème)
   + But changes in the code to integrate into a more complex COLD/FPGA project is not authorised.

*If you have any doubt, please contact me I will be happy to help you*

What is currently working: _(as of 13 november 2014)_
--------------------------
- [x] - ROM Banking
- [x] - SRAM Banking
- [x] - WonderSwan boot unlock
- [ ] - EEPROM
- [ ] - RTC
- [ ] - GPIO
- [ ] - All other unknown parts
