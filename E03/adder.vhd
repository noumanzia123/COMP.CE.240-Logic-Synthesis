
-------------------------------------------------------------------------------
-- Title      : TKT-1212, Exercise 03
-------------------------------------------------------------------------------
-- File       : adder.vhd
-- Author     : David Rama Jimeno & Nouman Zia
-- Group      : HRH056
-- Company    : TUT/DCS
-- Created    : 20.01.2024
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Program all combinations of summing two n-bit values
-------------------------------------------------------------------------------


LIBRARY ieee;
USE ieee.std_logic_1164.ALL; --This library is needed in order to be able to use the "std_logic data type"
USE ieee.numeric_std.ALL;


ENTITY adder IS
   GENERIC(
      operand_width_g :integer
      );
   PORT(
      clk     : IN STD_LOGIC;
      rst_n   : IN  STD_LOGIC;
      a_in    : IN STD_LOGIC_VECTOR(operand_width_g-1 DOWNTO 0);
      b_in    : IN STD_LOGIC_VECTOR(operand_width_g-1 DOWNTO 0); 
      sum_out : OUT STD_LOGIC_VECTOR(operand_width_g DOWNTO 0)
      );
END ADDER;

ARCHITECTURE RTL OF adder IS

SIGNAL sum_signed      : SIGNED(operand_width_g DOWNTO 0);

BEGIN

   sum_out <= std_logic_vector(sum_signed); --Reconverted to std_logic as we want the output in such data type

---------------------------------------------------------------------
   -- purpose: State Registers
   -- type   : sequential
   -- inputs : clk, rst_n
---------------------------------------------------------------------
   STREG : PROCESS (clk, rst_n)
   BEGIN  -- PROCESS STREG

      IF (rst_n = '0') THEN             -- asynchronous reset (active low)
	 sum_signed <= (OTHERS=>'0');
      ELSIF (clk'EVENT AND clk = '1') THEN  -- rising clock edge
	 sum_signed <= resize(signed(a_in),operand_width_g+1)+ --resized with the width of sum_out
                       resize(signed(b_in),operand_width_g+1); --converted to signed so they can be summed
      END IF;
   END PROCESS STREG;

END RTL;
