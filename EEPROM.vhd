-------------------------------------------------------------------------------
--                    The WonderProject: WonderMadeleine                     --
--                      (c) 2014  986-Studio / Godzil                        --
--  http://www.986-studio.com  <godzil_nospambot at 986 dash studio dot com> --
--                                                                           --
-- EEPROM.vhd : EPROM module implementation                                  --
--                                                                           --
-- What this project is about:                                               --
--                                                                           --
-- This is a VHDL implementation of the Bandai 2001 / 2003 chip found in all --
-- official WonderSwan Cartridge. It will ultimately provide a fully         --
-- functional clone of the Bandai chip.                                      --
--                                                                           --
-- Licensed under the the Creative Common BY-NC-ND :                         --
-- You are free to:                                                          --
--   Share — copy and redistribute the material in any medium or format      --
--                                                                           --
--   The licensor cannot revoke these freedoms as long as you follow the     --
--   license terms.                                                          --
--                                                                           --
-- Under the following terms:                                                --
--                                                                           --
--   Attribution   — You must give appropriate credit, provide a link to     --
--                   the license, and indicate if changes were made. You     --
--                   may do so in any reasonable manner, but not in any way  --
--                   that suggests the licensor endorses you or your use.    --
--   NonCommercial — You may not use the material for commercial purposes.   --
--   NoDerivatives — If you remix, transform, or build upon the material,    --
--                   you may not distribute the modified material.           --
--                                                                           --
--   No additional restrictions — You may not apply legal terms or           --
--                                technological measures that legally        --
--                                restrict others from doing anything the    --
--                                license permits.                           --
--                                                                           --
-- Notices:                                                                  --
--                                                                           --
--   You do not have to comply with the license for elements of the material --
--   in the public domain or where your use is permitted by an applicable    --
--   exception or limitation.                                                --
--                                                                           --
--   No warranties are given. The license may not give you all of the        --
--   permissions necessary for your intended use. For example, other rights  --
--   such as publicity, privacy, or moral rights may limit how you use the   --
--   material.                                                               --
--                                                                           --
--                                                                           --
-- What does that mean:                                                      --
--   You can use this code to program your own CPLD                          --
--   You can build your own cartridge that use this CPLD (and you can even   --
--      sell them!)                                                          --
--   But you can't program CPLD and sell them directly                       --
--   You are welcome to propose patch for supporting another CPLD or correct --
--      bugs                                                                 --
--   You can't integrate this code with another CPLD of FPGA project         --
--                                                                           --
-- If you have any doubt, please contact me I will be happy to help you      --
--                                                                           --
-- What is currently working: (as of 13 november 2014)                       --
-- [X] - ROM Banking                                                         --
-- [X] - SRAM Banking                                                        --
-- [X] - WonderSwan boot unlock                                              --
-- [ ] - EEPROM                                                              --
-- [ ] - RTC                                                                 --
-- [ ] - GPIO                                                                --
-- [ ] - All other unknown parts                                             --
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity EepromRegs is
    port(
		sel:     in    std_logic;
		nRD:     in    std_logic;
		nWR:     in    std_logic;
		regNum:  in    std_logic_vector(2 downto 0);
		data:    inout std_logic_vector(7 downto 0);
		clock:   in    std_logic;
		-- EEPROM PINs
		CS:      out   std_logic;
		CLK:     out   std_logic;
		DI:      in    std_logic;
		DO:      out   std_logic
	 );
end EepromRegs;

architecture Behavioral of EepromRegs is
begin

end architecture;