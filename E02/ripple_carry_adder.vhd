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
  -- If a_in(0) and b_in(0) are both 1, when we add them we store the carry value in this variable, 
  -- which will affect the next bits of s_out.   
  C <= unsigned(a_in(1)) xor unsigned(b_in(1));       
  -- It is the result of adding a_in(1) and b_in(1), but if the Carry_ha is also 1, it will affect the Carry_fa
  D <= Carry_ha and C;                                 
  -- If the C sum and the Carry_ha are 1, it will affect the value of Carry_fa, because we have an extra bit.
  E <= unsigned(a_in(1)) and unsigned(b_in(1));        
  -- If both a_in(1) and b_in(1) are 1, the carry value will be sent to Carry_fa through E
  Carry_fa <= D or E;
  -- Carry_fa carries the extra bit value of the sum of the first two bits of a_in and b_in
  F <= unsigned(a_in(2)) xor unsigned(b_in(2));        
  -- It is the result of adding a_in(2) and b_in(2), but if the Carry_fa is also 1, it will affect s_out(3)
  G <= Carry_fa and F;     
  -- If the F sum and the Carry_fa are 1, it will affect the value of s_out(3), because we have an extra bit                  
  H <= unsigned(a_in(2)) and unsigned(b_in(2));       
  -- If both a_in(2) and b_in(2) are 1, the carry value will be sent to s_out(3) through E


  s_out(0) <= std_logic(unsigned(a_in(0)) xor unsigned(b_in(0)));
  s_out(1) <= std_logic(C xor Carry_ha);
  s_out(2) <= std_logic(F xor Carry_fa);
  s_out(3) <= std_logic(G or H);
    
end gate;
