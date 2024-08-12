-------------------------------------------------------------------------------
-- Title      : COMP.CE.240 Logic Synthesis, Bonus 08
-------------------------------------------------------------------------------
-- File       : b8_task10.vhd
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
use ieee.numeric_std.all;

entity b8_task10 is
PORT (
    counter_out : out std_logic_vector(2-1 downto 0)
    );   
end b8_task10;

architecture rtl of b8_task10 is
    signal en : std_logic;
    signal counter : integer range 0 to 3;
  
begin
    counter_out <= std_logic_vector(to_unsigned(counter,2));
    en <= '1';
    process(counter,en)
    begin
        if en = '1' then
        counter <= counter + 1;
        end if;
    end process;
end rtl;