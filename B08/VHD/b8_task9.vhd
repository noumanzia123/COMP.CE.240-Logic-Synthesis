-------------------------------------------------------------------------------
-- Title      : COMP.CE.240 Logic Synthesis, Bonus 08
-------------------------------------------------------------------------------
-- File       : b8_task9.vhd
-- Author     : Nouman Zia, David Rama Jimeno
-- Group number : 6
-- Company    : TUNI
-- Created    : 2024-04-10
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: bonus task 7
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity b8_task9 is
PORT (
    a_out : out std_logic;
    c_in : in std_logic
    );   
end b8_task9;

architecture rtl of b8_task9 is
  signal b : std_logic;
  signal a : std_logic;

begin
  a_out <= a;
    process (a,b,c_in)
    begin
        a <= not b;
        b <= b xor c_in;
    end process;
end rtl;