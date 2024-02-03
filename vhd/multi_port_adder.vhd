-------------------------------------------------------------------------------
-- Title      : TKT-1212, Exercise 02
-- Project    : 
-------------------------------------------------------------------------------
-- File       : multi_port_adder.vhd
-- Author     : David Rama Jimeno, Nouman Zia
-- Group number : 6
-- Company    : TUNI
-- Created    : 2023-01-16
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: A multiport adder using the premade adder block with structural architecture
-------------------------------------------------------------------------------

-- Include default libraries
library ieee;
use ieee.std_logic_1164.all;

-- Declare entity
ENTITY multi_port_adder IS
    generic (
        operand_width_g : integer := 16;
        num_of_operands_g  : integer := 4);

    port (
        clk : in std_logic;
        rst_n : in std_logic;
        operands_in : in std_logic_vector(operand_width_g*num_of_operands_g-1 downto 0);
        sum_out : out std_logic_vector(operand_width_g downto 0)
        );   
END multi_port_adder;
-------------------------------------------------------------------------------

-- Architecture called 'structure' is  defined below

architecture structural of multi_port_adder is

    COMPONENT adder
        generic (
            operand_width_g : integer := 16;
            num_of_operands_g : integer := 4
            );

        port (
            clk : in std_logic;
            rst_n : in std_logic;
            a_in : in std_logic_vector(operand_width_g-1 downto 0);
            b_in : in std_logic_vector(operand_width_g-1 downto 0);
            subadder_sum_out : out std_logic_vector(operand_width_g downto 0)
            );   
    END COMPONENT;

    -- internal signals
    TYPE  subtotal_array is ARRAY (0 to num_of_operands_g/2-1) of std_logic_vector(operand_width_g+1 downto 0); -- created an array with elements containing vectors of bits for the outputs from the first adders
    SIGNAL subtotal : subtotal_array; -- internal signal for subtotals defined
    SIGNAL total: std_logic_vector(operand_width_g+2 downto 0); -- output from the third adder

    -- values to assign for component generics
    constant num_of_operands : integer := 4;

begin -- structural architecture

    first_adder : adder
        port map (
            clk=>clk, 
            rst_n=>rst_n, 
            a_in=>operands_in(operand_width_g*num_of_operands_g-1 downto operand_width_g*num_of_operands_g-1-operand_width_g), 
            b_in=>operands_in(operand_width_g*num_of_operands_g-1-operand_width_g downto operand_width_g*num_of_operands_g-1-2*operand_width_g), 
            subadder_sum_out=>subtotal(0)
            );
    second_adder : adder
        port map (
            clk=>clk, 
            rst_n=>rst_n, 
            a_in=>operands_in(operand_width_g*num_of_operands_g-1-2*operand_width_g downto operand_width_g*num_of_operands_g-1-3*operand_width_g), 
            b_in=>operands_in(operand_width_g*num_of_operands_g-1-3*operand_width_g downto operand_width_g*num_of_operands_g-1-4*operand_width_g), 
            subadder_sum_out=>subtotal(1)
            );
    third_adder : adder
        port map (
            clk=>clk, 
            rst_n=>rst_n, 
            a_in=>subtotal(0), 
            b_in=>subtotal(1), 
            subadder_sum_out=>total
            );
    -- connect part of the signal total to the output sum_out leaving two most significant bits unconnected
    sum_out <= total(operand_width_g downto 0);

end structural;

--ASSERT  num_of_operands_g /= 4
--    REPORT “Number of operands should be 4”
--    SEVERITY failure;

    

    
