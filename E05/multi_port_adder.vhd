
-------------------------------------------------------------------------------
-- Title      : TKT-1212, Exercise 04
-------------------------------------------------------------------------------
-- File       : multi_port_adder.vhd
-- Author     : David Rama Jimeno & Nouman Zia
-- Group      : HRH056
-- Company    : TUT/DCS
-- Created    : 01.02.2024
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Program all combinations of summing two n-bit values
-------------------------------------------------------------------------------


LIBRARY ieee;
USE ieee.std_logic_1164.ALL; --This library is needed in order to be able to use the "std_logic data type"
USE ieee.numeric_std.ALL;


ENTITY multi_port_adder IS
   GENERIC(
      operand_width_g : INTEGER := 16;
      num_of_operands_g : INTEGER := 4
      );
   PORT(
      clk         : IN STD_LOGIC;
      rst_n       : IN STD_LOGIC;
      operands_in : IN STD_LOGIC_VECTOR(operand_width_g*num_of_operands_g-1 DOWNTO 0);
      sum_out     : OUT STD_LOGIC_VECTOR(operand_width_g-1 DOWNTO 0)
      );
END multi_port_adder;

ARCHITECTURE STRUCTURAL OF multi_port_adder IS

   COMPONENT adder
      GENERIC(
         operand_width_g : INTEGER := 16
	 );
      PORT(
         clk     : IN STD_LOGIC;
         rst_n   : IN  STD_LOGIC;
         a_in    : IN STD_LOGIC_VECTOR(operand_width_g-1 DOWNTO 0);
         b_in    : IN STD_LOGIC_VECTOR(operand_width_g-1 DOWNTO 0); 
         sum_out : OUT STD_LOGIC_VECTOR(operand_width_g DOWNTO 0)
         );
   END COMPONENT;

TYPE operand_vector IS ARRAY (num_of_operands_g/2-1 DOWNTO 0) OF STD_LOGIC_VECTOR(operand_width_g DOWNTO 0);
SIGNAL subtotal : operand_vector;
SIGNAL total    : std_logic_vector(operand_width_g+1 DOWNTO 0);

BEGIN

   adder_1 : adder 
      GENERIC MAP(
         operand_width_g => operand_width_g
         )
      PORT MAP(
         clk     => clk,
         rst_n   => rst_n,
         a_in    => operands_in(operand_width_g*num_of_operands_g-1 DOWNTO operand_width_g*(num_of_operands_g-1)),
         b_in    => operands_in(operand_width_g*(num_of_operands_g-1)-1 DOWNTO operand_width_g*(num_of_operands_g-2)),
         sum_out => subtotal(0)
         );

   adder_2 : adder 
      GENERIC MAP(
         operand_width_g => operand_width_g
         )
      PORT MAP(
         clk     => clk,
         rst_n   => rst_n,
         a_in    => operands_in(operand_width_g*(num_of_operands_g-2)-1 DOWNTO operand_width_g*(num_of_operands_g-3)),
         b_in    => operands_in(operand_width_g*(num_of_operands_g-3)-1 DOWNTO 0),
         sum_out => subtotal(1)
         );

   adder_3 : adder 
      GENERIC MAP(
         operand_width_g => operand_width_g+1
         )
      PORT MAP(
         clk     => clk,
         rst_n   => rst_n,
         a_in    => subtotal(0),
         b_in    => subtotal(1),
         sum_out => total
         );
sum_out <= total((operand_width_g-1) DOWNTO 0);
 
   ASSERT num_of_operands_g = 4
      REPORT "Parameter num_of_operands_g different than 4"
      SEVERITY failure;

END STRUCTURAL;
