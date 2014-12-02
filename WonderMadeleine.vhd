-------------------------------------------------------------------------------
--                    The WonderProject: WonderMadeleine                     --
--                      (c) 2014  986-Studio / Godzil                        --
--  http://www.986-studio.com  <godzil_nospambot at 986 dash studio dot com> --
--                                                                           --
-- WonderMadeleine.vhd : TOP implementation                                  --
--                                                                           --
-- What this project is about:                                               --
--                                                                           --
-- This is a VHDL implementation of the Bandai 2001 / 2003 chip found in all --
-- official WonderSwan Cartridge. It will ultimately provide a fully         --
-- functional clone of the Bandai chip.                                      --
--                                                                           --
-- Licensed under the the Creative Common BY-NC-ND :                         --
-- You are free to:                                                          --
--   Share, copy and redistribute the material in any medium or format       --
--                                                                           --
--   The licensor cannot revoke these freedoms as long as you follow the     --
--   license terms.                                                          --
--                                                                           --
-- Under the following terms:                                                --
--                                                                           --
--   Attribution   - You must give appropriate credit, provide a link to     --
--                   the license, and indicate if changes were made. You     --
--                   may do so in any reasonable manner, but not in any way  --
--                   that suggests the licensor endorses you or your use.    --
--   NonCommercial - You may not use the material for commercial purposes.   --
--   NoDerivatives - If you remix, transform, or build upon the material,    --
--                   you may not distribute the modified material.           --
--                                                                           --
--   No additional restrictions - You may not apply legal terms or           --
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

entity WonderMadeleine is
    port(
        D_BUS:   inout std_logic_vector( 7 downto  0);      -- 16 bit Data bus
        A_BUS_H: in    std_logic_vector(19 downto 16);      -- High part of 20 bit Address bus
        A_BUS_L: in    std_logic_vector( 3 downto  0);      -- Low part of 20 bit Address bus

        nRD:     in    std_logic;                          -- /RD Signal
        nWR:     in    std_logic;                          -- /WR Signal

        nRESET:  in    std_logic;                          -- /Reset signal

        SYS_CLK: in    std_logic;                          -- 384Khz system clock
        nINT:    out   std_logic;                          -- /INT, used mainly by cart RTC

        nIO:     in    std_logic;                          -- /IO. CPU tell when accessing IOs
        nMBC:    out   std_logic;                          -- /MBC serial link with MBC. Use for handshake
        nSEL:    in    std_logic;                          -- /SEL cart sel.

        EXT_A:   out   std_logic_vector( 7 downto 0);      -- 8 bit A bus extension from IO page
        nSRAM_CS:out   std_logic;                          -- SRAM ChipSelect
        nROM_CS: out   std_logic;                          -- ROM ChipSelect

        EEP_CS:  out   std_logic;
        EEP_DI:  in    std_logic;
        EEP_DO:  out   std_logic;
        EEP_CK:  out   std_logic;

        RTC_CLK: out   std_logic;
        RTC_CS:  out   std_logic;
        RTC_DATA:inout std_logic;

        GPIO:    inout std_logic_vector(1 downto 0)
    );
end WonderMadeleine;

architecture Behavioral of WonderMadeleine is
    component GpioRegs is
        port(
            sel:     in    std_logic;
            nRD:     in    std_logic;
            nWR:     in    std_logic;
            regNum:  in    std_logic;
            data:    inout std_logic_vector(7 downto 0);
            clock:   in    std_logic;
            -- GPIO PINs
            GPIO:    inout   std_logic_vector(1 downto 0)
        );
    end component;

    component EepromRegs
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
    end component;

    component RtcRegs
        port(
            sel:     in    std_logic;
            nRD:     in    std_logic;
            nWR:     in    std_logic;
            regNum:  in    std_logic;
            data:    inout std_logic_vector(7 downto 0);
            clock:   in    std_logic;
            -- RTC PINs
            SDA:     inout std_logic;
            CLK:     out   std_logic;
            CS:      out   std_logic;
            nINT:    out   std_logic
        );
    end component;

    signal rMBC:        std_logic;
    signal readD:       std_logic_vector(7 downto 0);
    signal writeD:      std_logic_vector(7 downto 0);

    signal nRWTop:      std_logic;

    signal regC0:       std_logic_vector(7 downto 0);
    signal regC1:       std_logic_vector(7 downto 0);
    signal regC2:       std_logic_vector(7 downto 0);
    signal regC3:       std_logic_vector(7 downto 0);

    signal eepromRegSel:   std_logic;
    signal rtcRegSel:      std_logic;
    signal gpioRegSel:     std_logic;
    signal ioRegNum:       std_logic_vector(7 downto 0);
begin

    -- Instantiates all needed components
    gpioInst:   GpioRegs   port map(gpioRegSel,   nRd, nWR, ioRegNum(0), D_BUS, SYS_CLK, GPIO);
    eepromInst: EepromRegs port map(eepromRegSel, nRd, nWR, ioRegNum(2 downto 0), D_BUS, SYS_CLK, EEP_CS, EEP_CK, EEP_DI, EEP_DO);
    rtcInst:    RtcRegs    port map(rtcRegSel,    nRd, nWR, ioRegNum(0), D_BUS, SYS_CLK, RTC_DATA, RTC_CLK, RTC_CS, nINT);

    nINT <= 'Z';
    nMBC <= rMBC;
    nRWTop <= nRD and nWR;
    d_latches: process (nSEL, nIO, nRD, nWR, D_BUS, writeD, readD)
    begin
        if (nSEL='0' and nIO = '0' and nRD = '0' and nWR = '1') then
            D_BUS <= writeD;
            readD <= D_BUS;
        elsif (nSEL='0' and nIO = '0' and nRD = '1' and nWR = '0') then
            D_BUS <= "ZZZZZZZZ";
            readD <= D_BUS;
        else
            D_BUS <= "ZZZZZZZZ";
            readD <= D_BUS;
        end if;
    end process;

    main: process(nSEL, nIO, nRD, nWR, nRWTop, A_BUS_H, A_BUS_L, nRESET, readD, regC0, regC1, regC2, regC3)
    variable validRange: std_logic;
    begin
        ioRegNum(7 downto 4) <= A_BUS_H(19 downto 16);
        ioRegNum(3 downto 0) <= A_BUS_L( 3 downto  0);

        if (nRESET = '0') then
            nSRAM_CS     <= '1';
            nROM_CS      <= '1';
            regC0        <= X"FF";
            regC1        <= X"FF";
            regC2        <= X"FF";
            regC3        <= X"FF";
            eepromRegSel <= '0';
            rtcRegSel    <= '0';
            gpioRegSel   <= '0';
            elsif (nSEL = '0' and validRange = '1') then
            if(nIO = '0') then
                nSRAM_CS <= '1'; nROM_CS <= '1';
                if (falling_edge(nRWTop) and nRD = '0' and nWR = '1') then
                    case ioRegNum is
                        when X"C0"  => writeD <= regC0; eepromRegSel <= '0'; rtcRegSel <= '0'; gpioRegSel <= '0';
                        when X"C1"  => writeD <= regC1; eepromRegSel <= '0'; rtcRegSel <= '0'; gpioRegSel <= '0';
                        when X"C2"  => writeD <= regC2; eepromRegSel <= '0'; rtcRegSel <= '0'; gpioRegSel <= '0';
                        when X"C3"  => writeD <= regC3; eepromRegSel <= '0'; rtcRegSel <= '0'; gpioRegSel <= '0';
                        when X"C4"  => eepromRegSel <= '1'; rtcRegSel <= '0'; gpioRegSel <= '0';
                        when X"C5"  => eepromRegSel <= '1'; rtcRegSel <= '0'; gpioRegSel <= '0';
                        when X"C6"  => eepromRegSel <= '1'; rtcRegSel <= '0'; gpioRegSel <= '0';
                        when X"C7"  => eepromRegSel <= '1'; rtcRegSel <= '0'; gpioRegSel <= '0';
                        when X"C8"  => eepromRegSel <= '1'; rtcRegSel <= '0'; gpioRegSel <= '0';
                        when X"CA"  => eepromRegSel <= '0'; rtcRegSel <= '1'; gpioRegSel <= '0';
                        when X"CB"  => eepromRegSel <= '0'; rtcRegSel <= '1'; gpioRegSel <= '0';
                        when X"CC"  => eepromRegSel <= '0'; rtcRegSel <= '0'; gpioRegSel <= '1';
                        when X"CD"  => eepromRegSel <= '0'; rtcRegSel <= '0'; gpioRegSel <= '1';
                        when others => writeD <= X"FF"; eepromRegSel <= '0'; rtcRegSel <= '0'; gpioRegSel <= '0';
                    end case;
                elsif (falling_edge(nRWTop) and nRD = '1' and nWR = '0') then
                    case ioRegNum is
                        when X"C0"  => regC0 <= readD; eepromRegSel <= '0'; rtcRegSel <= '0'; gpioRegSel <= '0';
                        when X"C1"  => regC1 <= readD; eepromRegSel <= '0'; rtcRegSel <= '0'; gpioRegSel <= '0';
                        when X"C2"  => regC2 <= readD; eepromRegSel <= '0'; rtcRegSel <= '0'; gpioRegSel <= '0';
                        when X"C3"  => regC3 <= readD; eepromRegSel <= '0'; rtcRegSel <= '0'; gpioRegSel <= '0';
                        when X"C4"  => eepromRegSel <= '1'; rtcRegSel <= '0'; gpioRegSel <= '0';
                        when X"C5"  => eepromRegSel <= '1'; rtcRegSel <= '0'; gpioRegSel <= '0';
                        when X"C6"  => eepromRegSel <= '1'; rtcRegSel <= '0'; gpioRegSel <= '0';
                        when X"C7"  => eepromRegSel <= '1'; rtcRegSel <= '0'; gpioRegSel <= '0';
                        when X"C8"  => eepromRegSel <= '1'; rtcRegSel <= '0'; gpioRegSel <= '0';
                        when X"CA"  => eepromRegSel <= '0'; rtcRegSel <= '1'; gpioRegSel <= '0';
                        when X"CB"  => eepromRegSel <= '0'; rtcRegSel <= '1'; gpioRegSel <= '0';
                        when X"CC"  => eepromRegSel <= '0'; rtcRegSel <= '0'; gpioRegSel <= '1';
                        when X"CD"  => eepromRegSel <= '0'; rtcRegSel <= '0'; gpioRegSel <= '1';
                        when others => null;
                    end case;
                end if;
            elsif (nRD = '0' or nWR = '0') then
                -- Not IO
                case A_BUS_H is
                    when X"0"   => nSRAM_CS <= '1'; nROM_CS <= '1';
                    when X"1"   => nSRAM_CS <= '0'; nROM_CS <= '1';
                    when others => nSRAM_CS <= '1'; nROM_CS <= '0';
                end case;
                -- Be sure the reg are not sel during non IO
                eepromRegSel <= '0';
                rtcRegSel    <= '0';
                gpioRegSel   <= '0';
            else
                -- Be sure the reg are not sel during non IO
                eepromRegSel <= '0';
                rtcRegSel    <= '0';
                gpioRegSel   <= '0';
                -- Not accessing SRAM or ROM mapping
                nSRAM_CS <= '1'; nROM_CS <= '1';
            end if;
        else -- Cart is not sel
            nSRAM_CS <= '1'; nROM_CS <= '1';

            -- Be sure the reg are not sel during non IO
            eepromRegSel <= '0';
            rtcRegSel    <= '0';
            gpioRegSel   <= '0';
        end if;

        case A_BUS_H(19 downto 16) is
            when X"0"   => validRange := '0'; EXT_A <= X"00";
            when X"1"   => validRange := '1'; EXT_A <= regC1;
            when X"2"   => validRange := '1'; EXT_A <= regC2;
            when X"3"   => validRange := '1'; EXT_A <= regC3;
            when others => validRange := '1'; EXT_A(7 downto 4) <= regC0(3 downto 0);
                                              EXT_A(3 downto 0) <= A_BUS_H;
        end case;
    end process;

    mbc_lock: process (SYS_CLK, nRESET, A_BUS_H, A_BUS_L)
        type STATE_TYPE is (sWait, sWaitForA5, sA1, SA2, SA3, sA4,
                            sB1, sB2, sB3, sB4, sB5, sB6, sC, sD,
                            sE, sF1, sF2, sF3, sG, sH, sI, sJ1, sJ2,
                            sJ3, sDead);
        variable state: STATE_TYPE := sWait;
    begin
        if (nRESET = '0') then
            state := sWaitForA5;
        elsif (rising_edge(SYS_CLK) and state = sWaitForA5
                                    and A_BUS_H = X"A"
                                    and A_BUS_L = X"5" ) then
            state := sA1;
        elsif (rising_edge(SYS_CLK)) then
            case state is
                when sWait => rMBC <= '1';
                when sWaitForA5 => rMBC <= '1';
                when sA1 => state := sA2;   rMBC <= '1';
                when sA2 => state := sA3;   rMBC <= '1';
                when sA3 => state := sA4;   rMBC <= '1';
                when sA4 => state := sB1;   rMBC <= '1';
                when sB1 => state := sB2;   rMBC <= '0';
                when sB2 => state := sB3;   rMBC <= '0';
                when sB3 => state := sB4;   rMBC <= '0';
                when sB4 => state := sB5;   rMBC <= '0';
                when sB5 => state := sB6;   rMBC <= '0';
                when sB6 => state := sC;    rMBC <= '0';
                when sC  => state := sD;    rMBC <= '1';
                when sD  => state := sE;    rMBC <= '0';
                when sE  => state := sF1;   rMBC <= '1';
                when sF1 => state := sF2;   rMBC <= '0';
                when sF2 => state := sF3;   rMBC <= '0';
                when sF3 => state := sG;    rMBC <= '0';
                when sG  => state := sH;    rMBC <= '1';
                when sH  => state := sI;    rMBC <= '0';
                when sI  => state := sJ1;   rMBC <= '1';
                when sJ1 => state := sJ2;   rMBC <= '0';
                when sJ2 => state := sJ3;   rMBC <= '0';
                when sJ3 => state := sDead; rMBC <= '0';
                when sDead => state := sDead; rMBC <= '1';
            end case;
        end if;
    end process;
end architecture;

-- Test script...
-- restart
-- force -freeze sim:/wondermadeleine/SYS_CLK 1 0, 0 {50 ps} -r 100
-- force -freeze sim:/wondermadeleine/A_BUS_H 1100 0
-- force -freeze sim:/wondermadeleine/A_BUS_L 0011 0
-- force -freeze sim:/wondermadeleine/D_BUS 10101010 0 -cancel 200
-- force -freeze sim:/wondermadeleine/regC0 01011011 0
-- force -freeze sim:/wondermadeleine/regC1 10111101 0
-- force -freeze sim:/wondermadeleine/regC2 00101110 0
-- force -freeze sim:/wondermadeleine/nRD 1 0
-- force -freeze sim:/wondermadeleine/nWR 1 0
-- force -freeze sim:/wondermadeleine/nSEL 1 0
-- force -freeze sim:/wondermadeleine/nIO 1 0
-- force -freeze sim:/wondermadeleine/nRD 1 0
-- force -freeze sim:/wondermadeleine/nRESET 1 0

-- force -freeze sim:/wondermadeleine/nSEL 0 50
-- force -freeze sim:/wondermadeleine/nWR 0 70
-- force -freeze sim:/wondermadeleine/nIO 0 90
-- force -freeze sim:/wondermadeleine/nWR 1 110
-- force -freeze sim:/wondermadeleine/nIO 1 130
-- force -freeze sim:/wondermadeleine/nSEL 1 150

-- force -freeze sim:/wondermadeleine/nSEL 0 250
-- force -freeze sim:/wondermadeleine/nRD 0 270
-- force -freeze sim:/wondermadeleine/nIO 0 290
-- force -freeze sim:/wondermadeleine/nRD 1 310
-- force -freeze sim:/wondermadeleine/nIO 1 330
-- force -freeze sim:/wondermadeleine/nSEL 1 350

-- force -freeze sim:/wondermadeleine/A_BUS_H 0011 400
-- force -freeze sim:/wondermadeleine/A_BUS_L 0000 400
-- force -freeze sim:/wondermadeleine/nRD 0 410
-- force -freeze sim:/wondermadeleine/nRD 1 420
-- force -freeze sim:/wondermadeleine/nSEL 0 430
-- force -freeze sim:/wondermadeleine/nRD 0 440
-- force -freeze sim:/wondermadeleine/nRD 1 450
-- force -freeze sim:/wondermadeleine/nSEL 1 460

-- force -freeze sim:/wondermadeleine/A_BUS_H 1010 500
-- force -freeze sim:/wondermadeleine/nWR 0 510
-- force -freeze sim:/wondermadeleine/nWR 1 520
-- force -freeze sim:/wondermadeleine/nSEL 0 530
-- force -freeze sim:/wondermadeleine/nWR 0 540
-- force -freeze sim:/wondermadeleine/nWR 1 550
-- force -freeze sim:/wondermadeleine/nSEL 1 560

-- force -freeze sim:/wondermadeleine/A_BUS_H 0000 600
-- force -freeze sim:/wondermadeleine/nWR 0 610
-- force -freeze sim:/wondermadeleine/nWR 1 620
-- force -freeze sim:/wondermadeleine/nSEL 0 630
-- force -freeze sim:/wondermadeleine/nWR 0 640
-- force -freeze sim:/wondermadeleine/nWR 1 650
-- force -freeze sim:/wondermadeleine/nSEL 1 660

-- force -freeze sim:/wondermadeleine/A_BUS_H 0001 700
-- force -freeze sim:/wondermadeleine/nRD 0 710
-- force -freeze sim:/wondermadeleine/nRD 1 720
-- force -freeze sim:/wondermadeleine/nSEL 0 730
-- force -freeze sim:/wondermadeleine/nRD 0 740
-- force -freeze sim:/wondermadeleine/nRD 1 750
-- force -freeze sim:/wondermadeleine/nSEL 1 760

-- run
