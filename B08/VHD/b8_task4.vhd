-------------------------------------------------------------------------------
-- Title      : COMP.CE.240 Logic Synthesis, Bonus 08
-------------------------------------------------------------------------------
-- File       : b8_task4.vhd
-- Author     : Nouman Zia, David Rama Jimeno
-- Group number : 6
-- Company    : TUNI
-- Created    : 2024-04-10
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: bonus task 4
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity b8_task4 is
PORT (
    clk : in std_logic;
    rst_n : in std_logic;
    a_out : out std_logic;
    c_in : in std_logic_vector(2-1 downto 0)
    );   
end b8_task4;

architecture rtl of b8_task4 is
  signal a_r : std_logic;

begin
  a_out <= a_r;

  process (clk, rst_n)
  begin
    if rst_n = '0' then
        a_r <= '0';
    elsif clk'event and clk = '1' then
        a_r <= '0';
      if c_in = "11" then
        a_r <= '1';
      elsif c_in = "00" then
        a_r <= '1';
      end if;
    end if;
  end process;

end rtl;