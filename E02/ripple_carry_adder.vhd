-------------------------------------------------------------------------------
-- Title        : TKT-1212, Exercise 02
-------------------------------------------------------------------------------
-- File         : ripple_carry_adder.vhd
-- Author       : David Rama Jimeno & Nouman Zia
-- Group number : 6
-- Company      : TUT/DCS
-- Created      : 20.01.2024
-- Standard     : VHDL'87
-------------------------------------------------------------------------------
-- Description  : Program all combinations of summing two 3-bit values
-------------------------------------------------------------------------------


LIBRARY ieee;
USE ieee.std_logic_1164.ALL; --This library is needed in order to be able to use the "std_logic data type"



ENTITY ripple_carry_adder IS  -- We have 3 ports. 
 --Two of them are 3-bits inputs which will be the two variables to sum and the other is a 4-bit output
  PORT (
     a_in  : IN std_logic_vector(2 DOWNTO 0);
     b_in  : IN std_logic_vector(2 DOWNTO 0);
     s_out : OUT std_logic_vector(3 DOWNTO 0)
     );

END ripple_carry_adder;



-------------------------------------------------------------------------------

-- Architecture called 'gate' is already defined. Just fill it.
-- Architecture defines an implementation for an entity

-- In order to simplify the expressions, it was decided the use internal signals to reduce the code.
-- These signals correspond to logic gates operations.
architecture gate of ripple_carry_adder is

  signal C : unsigned;
  signal D : unsigned;
  signal E : unsigned;
  signal F : unsigned;
  signal G : unsigned;
  signal H : unsigned;
  signal Carry_ha : unsigned;
  signal Carry_fa : unsigned;
  
-- In this part of the code, logic operations of the internal signals and the output signal are defined.
begin  -- gate


  Carry_ha <= unsigned(a_in(0)) and unsigned(b_in(0));
  C <= unsigned(a_in(1)) xor unsigned(b_in(1));
  D <= Carry_ha and C;
  E <= unsigned(a_in(1)) and unsigned(b_in(1));
  Carry_fa <= D or E;
  F <= unsigned(a_in(2)) xor unsigned(b_in(2));
  G <= Carry_fa and F;
  H <= unsigned(a_in(2)) and unsigned(b_in(2));

  s_out(0) <= std_logic(unsigned(a_in(0)) xor unsigned(b_in(0)));
  s_out(1) <= std_logic(C xor Carry_ha);
  s_out(2) <= std_logic(F xor Carry_fa);
  s_out(3) <= std_logic(G or H);
    
end gate;
