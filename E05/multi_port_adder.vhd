-------------------------------------------------------------------------------
-- Title      : TKT-1212, Exercise 04
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
        num_of_operands_g  : integer := 4
        );

    PORT (
        clk : in std_logic;
        rst_n : in std_logic;
        operands_in : in std_logic_vector(operand_width_g*num_of_operands_g-1 DOWNTO 0);
        sum_out     : out std_logic_vector(operand_width_g-1 DOWNTO 0)
        );   
END multi_port_adder;
-------------------------------------------------------------------------------

-- Architecture called 'structure' is  defined below

ARCHITECTURE structural of multi_port_adder IS

    -- component "adder" declaration
    COMPONENT adder 
        generic (
            operand_width_g : integer
            );

        PORT (
            clk : in std_logic;
            rst_n : in std_logic;
            a_in : in std_logic_vector(operand_width_g-1 DOWNTO 0);
            b_in : in std_logic_vector(operand_width_g-1 DOWNTO 0);
            sum_out : out std_logic_vector(operand_width_g DOWNTO 0)
            );   
    END COMPONENT;

    -- internal signals
    TYPE  subtotal_array is ARRAY (0 to num_of_operands_g/2-1) of std_logic_vector(operand_width_g DOWNTO 0); -- created an array with elements containing vectors of bits for the outputs from the first adders
    SIGNAL subtotal : subtotal_array; -- internal signal for subtotals defined
    SIGNAL total: std_logic_vector(operand_width_g+1 DOWNTO 0); -- output from the third adder


begin -- structural architecture
    -- creating three instantances of adder components required for summing 4 operands
    first_adder : adder
        generic map (
            operand_width_g => operand_width_g
        )
        PORT map (
            clk => clk, 
            rst_n => rst_n, 
            a_in => operands_in(operand_width_g-1 DOWNTO 0), 
            b_in => operands_in(2*operand_width_g-1 DOWNTO operand_width_g), 
            sum_out => subtotal(0)
            );

    second_adder : adder
        generic map (
            operand_width_g => operand_width_g+1
        )
        PORT map (
            clk => clk, 
            rst_n => rst_n, 
            a_in => operands_in(3*operand_width_g-1 DOWNTO 2*operand_width_g), 
            b_in => operands_in(4*operand_width_g-1 DOWNTO 3*operand_width_g), 
            sum_out => subtotal(1)
            );

    third_adder : adder
        generic map (
            operand_width_g => operand_width_g+1
        )
        PORT map (
            clk => clk, 
            rst_n => rst_n, 
            a_in => subtotal(0), 
            b_in => subtotal(1), 
            sum_out => total
            );
    
    -- connect part of the signal total to the output sum_out_top leaving two most significant bits unconnected    
    sum_out <= total(operand_width_g-1 DOWNTO 0);

    ASSERT  num_of_operands_g = 4
        REPORT "Number of operands should be 4"
        SEVERITY failure;

end structural;
