-------------------------------------------------------------------------------
-- Title      : COMP.CE.240 Logic Synthesis, Bonus 08
-------------------------------------------------------------------------------
-- File       : b8_task8.vhd
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

entity b8_task8 is
PORT (
    clk : in std_logic;
    rst_n : in std_logic;
    a_out : out std_logic;
    b_out : out std_logic
    );   
end b8_task8;

architecture rtl of b8_task8 is
signal a_r : std_logic;
signal b_r : std_logic;

-- Enumerate possible states with human readable names
type states_type is (init, assign_a, assign_b);
signal curr_state : states_type;

begin
  a_out <= a_r;
  b_out <= b_r;
  
  process ( clk, rst_n )
  begin
    if rst_n = '0' then
        a_r <= '0';
        b_r <= '0';
        curr_state <= init;
    elsif clk'event and clk = '1' then
        case curr_state is
        when init =>
            a_r <= '0';
            b_r <= '0';
            curr_state <= assign_a;
        when assign_a =>
            a_r <= '1';
            curr_state <= assign_b;
        when assign_b =>
            b_r <= '1';
            curr_state <= init;
      end case;
    end if;
  end process;

end rtl;