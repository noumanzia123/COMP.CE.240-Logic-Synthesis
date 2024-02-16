-------------------------------------------------------------------------------
-- Title      : TKT-1212, Exercise 03
-- Project    : 
-------------------------------------------------------------------------------
-- File       : adder.vhd
-- Author     : David Rama Jimeno, Nouman Zia
-- Group number : 6
-- Company    : TUNI
-- Created    : 2023-01-16
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: An RTL based synchronous adder which has n-bit inputs and the output width n+1 bits
-------------------------------------------------------------------------------

-- Include  libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Declare entity
ENTITY adder IS
    generic (
        operand_width_g : integer);

    port (
        clk : in std_logic;
        rst_n : in std_logic;
        a_in : in std_logic_vector(operand_width_g-1 downto 0);
        b_in : in std_logic_vector(operand_width_g-1 downto 0);
        sum_out : out std_logic_vector(operand_width_g downto 0)
        );   
END adder ;
-------------------------------------------------------------------------------

-- Architecture called 'rtl' is  defined

architecture rtl of adder is

signal out_r: signed(operand_width_g downto 0); -- internal signal (reg)

begin -- rtl
    sum_out <= std_logic_vector(out_r);

    adder_sync : process (clk, rst_n) 

    begin -- process adder
    
        if rst_n = '0' then -- asynchronous reset (active low)
            out_r <= (others => '0');

        elsif clk'event and clk = '1' then -- rising clock edge
            -- the data types of input signals converted to signed and bit widths are matched to the output
            out_r <= resize(signed(a_in), operand_width_g+1) + resize(signed(b_in), operand_width_g+1);
            
    
        end if;

    end process adder_sync;

end rtl;

