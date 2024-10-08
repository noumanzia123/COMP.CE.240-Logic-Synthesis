-------------------------------------------------------------------------------
-- Title      : TKT-1212, Exercise 02
-- Project    : 
-------------------------------------------------------------------------------
-- File       : ripple_carry_adder.vhd
-- Author     : David Rama Jimeno, Nouman Zia
-- Group number : 6
-- Company    : TUNI
-- Created    : 2023-01-16
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: A 3-bit ripple-carry-adder which has a 4-bit output (s = a + b)
-------------------------------------------------------------------------------
-- Copyright (c) 2008 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2023-01-27  1.0      Nouman     Created
-------------------------------------------------------------------------------


-- Include default libraries
library ieee;
use ieee.std_logic_1164.all;

-- Declare entity
ENTITY ripple_carry_adder IS

   PORT (
      a_in  : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
      b_in  : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
      s_out : OUT  STD_LOGIC_VECTOR(3 DOWNTO 0)
     
      );

END ripple_carry_adder;
-------------------------------------------------------------------------------

-- Architecture called 'gate' is  defined
-- Architecture defines an implementation for an entity
architecture gate of ripple_carry_adder is
   -- internal signal declarations here
   SIGNAL Carry_ha, Carry_fa, c, d, e, f, g, h  : std_logic;
  
begin
   -- gate architecture implementation which includes one half adder and two full adders to 
   -- generate 4 bit sum (s_out) output. 
   -- The carry generated from first half adder is given as input to the first full adder
   -- and similarly the carry generated from first full adder is given as input to the second
   -- full adder

   -- s_out(0) is '0' if both input bits are '1', otherwise '1'
   s_out(0) <= a_in(0) xor b_in(0); 
   -- Carry_ha is '1' if both input bits are '1'
   Carry_ha <= a_in(0) and b_in(0); 
   -- c is '0' if both input bits are '1', otherwise '1'
   c <= a_in(1) xor b_in(1); 
   -- s_out(0) is '0' if both input bits are '1', otherwise '1'
   s_out(1) <= c xor Carry_ha; 
   -- d and e bits are '1' if both input bits are high
   d <= Carry_ha and c;
   e <= a_in(1) and b_in(1);
   -- Carry_fa is '1' if either 'd' or 'e' is high
   Carry_fa <= d or e;
   -- f is '0' if both input bits are '1', otherwise '1'
   f <= a_in(2) xor b_in(2);
   -- s_out(2) is '0' if both input bits are '1', otherwise '1'
   s_out(2) <= f xor Carry_fa;
   -- g and h bits are '1' if both input bits are high
   g <= f and Carry_fa;
   h <= a_in(2) and b_in(2);
   -- s_out(3) is '1' if g or h is '1'
   s_out(3) <= g or h;	

end gate;
