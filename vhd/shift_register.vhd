-------------------------------------------------------------------------------
-- Title      : TKT-1212, shift_left_register Question
-- Project    : 
-------------------------------------------------------------------------------
-- File       : shift_left_register.vhd
-- Author     : Nouman Zia
-- Group number : 6
-- Company    : TUNI
-- Created    : 2023-01-16
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: synthesis of an shift_left_register question
-------------------------------------------------------------------------------

-- Include  libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Declare entity
ENTITY shift_left_register IS
generic (
    width_g : integer range 0 to 6:= 6);

port (
        clk : in std_logic;
        rst_n : in std_logic;
        reg_out : out std_logic_vector(width_g-1 downto 0)
        );   
END shift_left_register ;
-------------------------------------------------------------------------------

-- Architecture called 'rtl' is  defined

architecture rtl of shift_left_register is
    signal shift_left_r: std_logic_vector(width_g-1 downto 0); -- internal signal (reg)
begin -- rtl

    reg_out <= shift_left_r;

    process (clk, rst_n) 

    begin -- process
    
        if rst_n = '0' then -- asynchronous reset (active low)
            shift_left_r <= "000001";

        elsif clk'event and clk = '1' then -- rising clock edge
            shift_left_r <= shift_left_r(width_g-2 downto 0) & '0'; 
        end if;

    end process;

end rtl;