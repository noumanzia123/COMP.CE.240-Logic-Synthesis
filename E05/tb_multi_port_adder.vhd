-------------------------------------------------------------------------------
-- Title      : TKT-1212, Exercise 05
-- Project    : 
-------------------------------------------------------------------------------
-- File       : tb_multi_port_adder.vhd
-- Author     : Nouman Zia & David Rama
-- Company    : TUT/DCS
-- Created    : 2024-02-08
-- Last update: 2024-02-18
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Tests all combinations of a multiport adder
-------------------------------------------------------------------------------
-- Copyright (c) 2008 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2024-11-28  1.0      ege	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;



entity tb_multi_port_adder is
   generic(
      operand_width_g : integer :=3
      );
end tb_multi_port_adder;


architecture testbench of tb_multi_port_adder is

  -- Define constants: bit widths and duration of clk period 

   constant clk_period_c        : time    := 10 ns;
   constant num_of_operands_g_c : integer := 4;
   constant duv_delay_c         : integer := 2;

   signal clk   : std_logic := '0';
   signal rst_n : std_logic := '0';
   signal end_simulation_r : std_logic;

   signal operands_r     : std_logic_vector(15 downto 0);
   signal sum            : std_logic_vector(operand_width_g downto 0);
   signal output_valid_r : std_logic_vector(duv_delay_c+1-1 downto 0);

   file input_f       : text open read_mode is "/home/kddara/logsyn/input.txt";
   file ref_results_f : text open read_mode is "/home/kddara/logsyn/ref_results.txt";
   file output_f      : text open write_mode is "/home/kddara/logsyn/output.txt";

  
  -- Component declaration of DUV
   component multi_port_adder
      generic (
         operand_width_g   : integer;
         num_of_operands_g : integer
         );
      port (
         clk         : in  std_logic;
         rst_n       : in  std_logic;
         operands_in : in std_logic_vector(operand_width_g*num_of_operands_g_c-1 DOWNTO 0);
         sum_out     : out std_logic_vector(operand_width_g-1 DOWNTO 0));
   end component;

  
  -- Note: Init values are not supported in synthesis
  
begin  -- testbench

   -- Instantiate DUV and connect the ports to testbench's signals
   DUV : multi_port_adder
      generic map (
         operand_width_g   => operand_width_g+1,
         num_of_operands_g => num_of_operands_g_c
         )
      port map (
         clk         => clk,
         rst_n       => rst_n,
         operands_in => operands_r,
         sum_out     => sum
         );

   -- Reset the DUV
   rst_n <= '1' after 4*clk_period_c;

   -- purpose: Generate clock signal for DUV
   -- type   : combinational
   -- inputs : clk  (this is a special case for test purposes!)
   -- outputs: clk  (this is a special case for test purposes!)
   clk_gen : process (clk)
   begin  -- process clk_gen
      clk <= not clk after clk_period_c/2;
   end process clk_gen;

   -- purpose: Read input files
   -- type   : combinational
   -- inputs : clk,rst_n
   -- outputs: operands_r,output_valid_r

   input_reader : process (clk,rst_n)
      type int_array is array (num_of_operands_g_c-1 downto 0) of integer; 
      variable line_in_v : line;
      variable value_reader_v : int_array;
   begin -- process input_reader

      if rst_n = '0' then                 -- asynchronous reset (active low)
         operands_r     <= (others => '0');
         output_valid_r <= (others => '0'); 

      elsif clk'event and clk ='1' then   -- rising clock edge
         output_valid_r    <= output_valid_r(duv_delay_c-1 downto 0) & '1';
         if not (endfile(input_f)) then
            readline(input_f,line_in_v);
            for i in num_of_operands_g_c-1 downto 0 loop
               read(line_in_v,value_reader_v(i));
               operands_r(((num_of_operands_g_c * (i + 1)) - 1) downto (num_of_operands_g_c * i)) 
               <= std_logic_vector(to_signed(value_reader_v(i),num_of_operands_g_c));
            end loop;
         end if;
      end if;	
   end process input_reader;

  -- purpose: Generate all possible inputs values and check the result
  -- type   : sequential
  -- inputs : clk, rst_n
  -- outputs: operands_r,output_valid_r 
   checker : process (clk, rst_n)
      variable line_ref_v : line;
      variable line_out_v : line;
      variable value_check_v : integer;
   begin  -- process input_gen_output_check 
      if rst_n = '0' then                 -- asynchronous reset (active low)
         operands_r     <= (others => '0');
         output_valid_r <= (others => '0'); 
      
      elsif clk'event and clk = '1' then  -- rising clock edge
    
         if output_valid_r(duv_delay_c) = '1' then
            if not (endfile(ref_results_f)) then
               readline(ref_results_f,line_ref_v);
               read(line_ref_v,value_check_v);
               assert to_integer(signed(sum)) = value_check_v
                  report "output signal is not equal to the sum of the inputs"
               severity failure;
               write(line_out_v, (to_integer(signed(sum))));
               writeline(output_f,line_out_v);
            else
               assert end_simulation_r = '0'
                  report "Simulation ended!" severity failure;
               end if;
            end if;
         end if;

      
      -- Stop the simulator
   end process checker;


end testbench;
