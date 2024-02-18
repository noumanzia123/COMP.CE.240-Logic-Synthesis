-------------------------------------------------------------------------------
-- Title      : TKT-1212, Exercise 05
-- Project    : 
-------------------------------------------------------------------------------
-- File       : tb_multi_port_adder.vhd
-- Author     : David Rama Jimeno, Nouman Zia
-- Group number : 6
-- Company    : TUNI
-- Created    : 2024-02-10
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: A test bench for the multiport adder
-------------------------------------------------------------------------------

-- Include default libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

-- Declare entity
ENTITY tb_multi_port_adder IS
    generic (
        operand_width_g : integer := 3
        );
END tb_multi_port_adder;
-----------------------------------------


-- Architecture called 'testbench' is  defined below
ARCHITECTURE testbench of tb_multi_port_adder IS

    -- Define constants
    CONSTANT period_c : TIME := 10 ns;
    CONSTANT num_of_operands_c : integer := 4;
    CONSTANT duv_delay_c : integer := 2;

    -- create signals
    SIGNAL clk : std_logic := '0'; -- init values only in tb
    SIGNAL rst_n : std_logic := '0'; -- init values only in tb
    SIGNAL operands_r : std_logic_vector(operand_width_g*num_of_operands_c-1 DOWNTO 0);
    SIGNAL sum : std_logic_vector(operand_width_g-1 DOWNTO 0);
    SIGNAL output_valid_r : std_logic_vector(duv_delay_c+1-1 DOWNTO 0); --Shift register for delay compensation

    -- Define two files in read and one in write mode
    FILE input_f : TEXT OPEN READ_MODE IS "input.txt";
    FILE ref_results_f : TEXT OPEN READ_MODE IS "ref_results.txt";
    FILE output_f : TEXT OPEN WRITE_MODE IS "output.txt";

    
    -- Declare the components DUT
    COMPONENT multi_port_adder        
            generic (
            operand_width_g : integer;
            num_of_operands_g  : integer
            );

            PORT (
            clk : in std_logic;
            rst_n : in std_logic;
            operands_in : in std_logic_vector(operand_width_g*num_of_operands_g-1 DOWNTO 0);
            sum_out_top : out std_logic_vector(operand_width_g-1 DOWNTO 0)
            );
    END COMPONENT;


begin -- testbench architecture

    -- Port mappings of the DUT
    DUT : multi_port_adder
        generic map (
            operand_width_g => 3,
            num_of_operands_g => num_of_operands_c
            )

        PORT map (
        clk => clk, 
        rst_n => rst_n, 
        operands_in => operands_r, 
        sum_out_top => sum
        );

    -- create clock and reset signals
    clk <= NOT clk AFTER period_c/2; -- this style needs init value
    rst_n <= '0', '1' AFTER 4*period_c;





input_reader : process (clk, rst_n) -- synchronous process for reading input files

-- variables for the input and output files
VARIABLE line_in_v : LINE;


-- variables for the value in one line
TYPE int_array IS ARRAY(1 to num_of_operands_c) OF INTEGER;  
--VARIABLE input_tmp_v : int _array (num_of_operands_c-1 DOWNTO 0);
VARIABLE input_tmp_v : int_array;
VARIABLE output_value_v : INTEGER;

begin -- process input_reader
    
    IF rst_n = '0' THEN -- asynchronous reset 
        operands_r  <= (OTHERS => '0');
        output_valid_r <= (OTHERS => '0');
        
    ELSIF clk'EVENT AND clk = '1' THEN
        output_valid_r <= std_logic_vector(shift_left(unsigned(output_valid_r), 1));
        output_valid_r(0) <= '1';
        
        IF NOT (ENDFILE(input_f)) THEN
            READLINE(input_f, line_in_v);
            for kk in 1 to num_of_operands_c loop
                read(line_in_v, input_tmp_v(kk));
                operands_r(operand_width_g*num_of_operands_c-1-(kk-1)*3 DOWNTO operand_width_g*num_of_operands_c-1-(kk-1)*3-2) 
                <= std_logic_vector(to_signed(input_tmp_v(kk),3));
		     END loop;
        end IF;
    end IF;

end process input_reader;





checker : process (clk, rst_n) -- synchronous process for the checker 

VARIABLE line_refin_v : LINE;
VARIABLE line_out_v : LINE;

VARIABLE ref_input_tmp_v : INTEGER;

begin -- process checker
    
    IF rst_n = '0' THEN -- asynchronous reset

    ELSIF clk'EVENT and clk = '1' then 
        -- output available to check after two clock cyclyes
        IF output_valid_r(operand_width_g-1) = '1' THEN
            IF NOT (ENDFILE(ref_results_f)) THEN
                READLINE(ref_results_f, line_refin_v);
                read(line_refin_v, ref_input_tmp_v);
                ASSERT  to_integer(signed(sum)) = ref_input_tmp_v
                    REPORT "Test bench failed"
                    SEVERITY failure;
                write(line_out_v, to_integer(signed(sum)));
                writeline(output_f, line_out_v);
            ELSE
                report "Simulation done sucessfully!"; 
            end IF;

        end IF;

    end IF;

end process checker;


end testbench;
