-------------------------------------------------------------------------------
-- Title      : TKT-1212, Exam Question
-- Project    : 
-------------------------------------------------------------------------------
-- File       : exam.vhd
-- Author     : Nouman Zia
-- Group number : 6
-- Company    : TUNI
-- Created    : 2023-01-16
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: synthesis of an exam question
-------------------------------------------------------------------------------

-- Include  libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Declare entity
ENTITY exam IS
port (
        clk : in std_logic;
        rst_n : in std_logic;
        d_in : in std_logic_vector(4-1 downto 0);
        a_out : out std_logic_vector(4-1 downto 0);
        ctrl_in : in std_logic_vector(2-1 downto 0)
        );   
END exam ;
-------------------------------------------------------------------------------

-- Architecture called 'rtl' is  defined

architecture rtl of exam is

    signal out_r: std_logic_vector(4-1 downto 0); -- internal signal (reg)
    signal b_comb: std_logic_vector(4-1 downto 0);

begin -- rtl

    a_out <= out_r;

    process (clk, rst_n) 

    begin -- process
    
        if rst_n = '0' then -- asynchronous reset (active low)
            out_r <= (others => '0');

        elsif clk'event and clk = '1' then -- rising clock edge
            out_r <= b_comb;   
        end if;

    end process;

    with ctrl_in select
    b_comb <=
        out_r when "00",
        out_r(3 downto 1) & d_in(0) when "01",
        d_in(3) & out_r(3 downto 1) when "10",
        d_in when others;

end rtl;