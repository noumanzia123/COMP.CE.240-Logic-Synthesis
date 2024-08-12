-------------------------------------------------------------------------------
-- Title      : COMP.CE.240 Logic Synthesis, Bonus 08
-------------------------------------------------------------------------------
-- File       : b8_task5.vhd
-- Author     : Nouman Zia, David Rama Jimeno
-- Group number : 6
-- Company    : TUNI
-- Created    : 2024-04-10
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: bonus task 5
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity b8_task5 is
PORT (
    clk : in std_logic;
    rst_n : in std_logic;
    a_out : out std_logic;
    cmd_in : in std_logic_vector(2-1 downto 0);
    sel_in : in std_logic_vector(2-1 downto 0)
    );   
end b8_task5;

architecture rtl of b8_task5 is
  signal a_r : std_logic;
  signal s : std_logic;

begin
  a_out <= a_r;

  process ( clk, rst_n )
  begin
    if rst_n = '0' then
    a_r <= '0';
    elsif clk'event and clk = '1' then
        case sel_in is
        when "00" => a_r <= '1';
        when "11" => a_r <= '1';
        when others => a_r <= s;
        end case;
    end if;
  end process;

  with cmd_in select
    s <=
      '0' when "00",
      '0' when "01",
      '1' when others;

end rtl;