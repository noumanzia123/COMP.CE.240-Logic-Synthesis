-------------------------------------------------------------------------------
-- Title      : COMP.CE.240 Logic Synthesis, Exercise 09
-------------------------------------------------------------------------------
-- File       : synthesizer.vhd
-- Author     : Nouman Zia, David Rama Jimeno
-- Group number : 6
-- Company    : TUNI
-- Created    : 2024-03-17
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Top level synthesizer 
-------------------------------------------------------------------------------

-- Include default libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Declare entity synthesizer

ENTITY synthesizer IS

    generic (
        clk_freq_g    : integer := 10000000; -- clk frequency
        sample_rate_g : integer := 48000; -- frequency of lrclk
        data_width_g  : integer := 16;     -- data width
        n_keys_g      : integer := 4           -- number of buttons
        );
    PORT (
        clk           : in std_logic;
        rst_n         : in std_logic;
        keys_in       : in std_logic_vector(n_keys_g-1 downto 0);
        aud_bclk_out  : out std_logic; -- Bit clock
        aud_data_out  : out std_logic;
        aud_lrclk_out : out std_logic -- Left-right clock
        );   
END synthesizer;

-------------------------------------------------------------------------------
-- Architecture 'structural' is  defined

ARCHITECTURE structural of synthesizer is --Each component block is defined

  component wave_gen is   -- input wave generation
    generic(
      step_g  : integer := 2;         -- Step size (frequency divider)
      width_g : integer := 16         -- Data width in bits
      ); 
    port (
      clk             : in std_logic;
      rst_n           : in std_logic;
      sync_clear_n_in : in std_logic;
      value_out       : out std_logic_vector(data_width_g-1 downto 0)
      );  
  end component;

  component multi_port_adder is  -- adder of the waves' output values
    generic (
      operand_width_g   : integer := 16;  -- Data width of each operand
      num_of_operands_g : integer := 4   -- Number of operands
      );
    port (
      clk         : in std_logic;
      rst_n       : in std_logic;
      operands_in : in std_logic_vector(operand_width_g * num_of_operands_g - 1 downto 0); --data matches all the data size comming from the waves
      sum_out     : out std_logic_vector(operand_width_g - 1 downto 0)
      );
  end component;

  component audio_ctrl is                     -- generates the clocks and output data
    generic (
      ref_clk_freq_g : integer := 12288000;   -- Reference clock frequency in Hz
      sample_rate_g  : integer := 48000;        -- Sample rate in Hz
      data_width_g   : integer := 16             -- Data width in bits
      );
    port (
      clk           : in std_logic;
      rst_n         : in std_logic;
      left_data_in  : in std_logic_vector(data_width_g - 1 downto 0);
      right_data_in : in std_logic_vector(data_width_g - 1 downto 0);
      aud_bclk_out  : out std_logic;
      aud_data_out  : out std_logic;
      aud_lrclk_out : out std_logic
      );
  end component;

  constant step_g              : integer :=2;
  constant num_of_operands_g   : integer := 4;
  signal aud_data_out_internal : std_logic_vector(num_of_operands_g*data_width_g-1 downto 0);
  signal aud_sum_out           : std_logic_vector(data_width_g-1 downto 0);


begin -- structural
 
  gen1: wave_gen --Wave generation for step=1
    generic map (
      step_g  => step_g**0,
      width_g => data_width_g
      )
    port map (
      clk             => clk,
      rst_n           => rst_n,
      sync_clear_n_in => keys_in(0),  -- Connect push-button 0 to sync_clear_in of gen1
      value_out       => aud_data_out_internal((num_of_operands_g-3)*data_width_g-1 downto 0)
      );
    
  gen2: wave_gen -- Wave generation for step=2
    generic map (
      step_g  => step_g**1,
      width_g => data_width_g
      )
    port map (
      clk             => clk,
      rst_n           => rst_n,
      sync_clear_n_in => keys_in(1),  -- Connect push-button 1 to sync_clear_in of gen1
      value_out       => aud_data_out_internal((num_of_operands_g-2)*data_width_g-1 downto (num_of_operands_g-3)*data_width_g)
      ); 

  gen4: wave_gen -- Wave generation for step=4
    generic map (
      step_g  => step_g**2,
      width_g => data_width_g
      )
    port map (
      clk             => clk,
      rst_n           => rst_n,
      sync_clear_n_in => keys_in(2),  -- Connect push-button 2 to sync_clear_in of gen1
      value_out       => aud_data_out_internal((num_of_operands_g-1)*data_width_g-1 downto (num_of_operands_g-2)*data_width_g)
      ); 

  gen8: wave_gen -- Wave generation for step=8
    generic map (
      step_g => step_g**3,
      width_g => data_width_g
      )
    port map (
      clk => clk,
      rst_n => rst_n,
      sync_clear_n_in => keys_in(3),  -- Connect push-button 3 to sync_clear_in of gen1
      value_out => aud_data_out_internal(num_of_operands_g*data_width_g-1 downto (num_of_operands_g-1)*data_width_g)
      );

  adder: multi_port_adder  -- It adds all the incoming data from the output wave generators
    generic map (
      operand_width_g   => data_width_g,
      num_of_operands_g => 4
      )
    port map (
      clk         => clk,
      rst_n       => rst_n,
      operands_in => aud_data_out_internal,  -- Connect aud_data_out_internal of all generators to adder
      sum_out     => aud_sum_out
      );

  ctrl: audio_ctrl --Generates the new clock signals and transfers the output data
    generic map (
      ref_clk_freq_g => clk_freq_g,
      sample_rate_g  => sample_rate_g,
      data_width_g   => data_width_g
      )
    port map (
      clk           => clk,
      rst_n         => rst_n,
      left_data_in  => aud_sum_out,
      right_data_in => aud_sum_out,
      aud_bclk_out  => aud_bclk_out,
      aud_data_out  => aud_data_out,  -- Connect aud_data_out_internal of audio controller to generators
      aud_lrclk_out => aud_lrclk_out
      );
    
end structural;
