-------------------------------------------------------------------------------
-- Title      : COMP.CE.240 Logic Synthesis, Exercise 08
-------------------------------------------------------------------------------
-- File       : tb_audio_ctrl.vhd
-- Author     : Nouman Zia, David Rama Jimeno
-- Group number : 6
-- Company    : TUNI
-- Created    : 2024-03-05
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description:  A top level structural description of the synthesizer by connecting the sub-blocks together. 
-------------------------------------------------------------------------------

-- Include default libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Declare entity
ENTITY synthesizer IS
    generic (
        clk_freq_g : integer := 12288000,
        sample_rate_g : integer := 48000,
        data_width_g : integer := 16,
        n_keys_g : integer := 4
    );

    PORT (
        clk : in std_logic;
        rst_n : in std_logic;
        keys_in  : in std_logic_vector(n_keys_g-1 DOWNTO 0);
        aud_bclk_out  : in std_logic;
        aud_data_out  : in std_logic;
        aud_lrclk_out  : in std_logic
        );  

END synthesizer;

-- Architecture called 'structural' is  defined below
ARCHITECTURE structural of synthesizer IS

-- internal signals
SIGNAL wave_gen_out1 : std_logic_vector(data_width_g-1 DOWNTO 0);
SIGNAL wave_gen_out2 : std_logic_vector(data_width_g-1 DOWNTO 0);
SIGNAL wave_gen_out3 : std_logic_vector(data_width_g-1 DOWNTO 0);
SIGNAL wave_gen_out4 : std_logic_vector(data_width_g-1 DOWNTO 0);
SIGNAL multi_port_adder_in : std_logic_vector(n_keys_g*data_width_g-1 DOWNTO 0);
SIGNAL multi_port_adder_out : std_logic_vector(n_keys_g*data_width_g-1 DOWNTO 0);

    -- Define components 
    
    -- waveform generation component
    COMPONENT wave_gen
        generic (
        width_g : integer; -- counter width
        step_g : integer -- counter step
        );
        PORT (
        clk : in std_logic;
        rst_n : in std_logic;
        sync_clear_n_in : in std_logic;
        value_out : out std_logic_vector(width_g-1 DOWNTO 0)
        );   
    END COMPONENT;
    -- audio controller component
    COMPONENT audio_ctrl
        generic (
            ref_clk_freq_g : integer; -- frequency of lrclk
            sample_rate_g : integer; -- frequency of bclk
            data_width_g : integer
            );
        PORT (
            clk : in std_logic;
            rst_n : in std_logic;
            left_data_in  : in std_logic_vector(data_width_g-1 DOWNTO 0);
            right_data_in   : in std_logic_vector(data_width_g-1 DOWNTO 0);
            aud_bclk_out  : out std_logic; -- Bit clock
            aud_data_out  : out std_logic;
            aud_lrclk_out  : out std_logic -- Left-right clock
            );   
    END COMPONENT;
    -- audio codec model component
    COMPONENT multi_port_adder        
            generic (
            operand_width_g : integer;
            num_of_operands_g  : integer
            );

            PORT (
            clk : in std_logic;
            rst_n : in std_logic;
            operands_in : in std_logic_vector(operand_width_g*num_of_operands_g-1 DOWNTO 0);
            sum_out : out std_logic_vector(operand_width_g-1 DOWNTO 0)
            );
    END COMPONENT;


begin -- testbench architecture

     -- Port mappings
    left_channel : wave_gen
        generic map (
        width_g => data_width_c,
        step_g => stepl_c
        )
        PORT map (
        clk => clk, 
        rst_n => rst_n, 
        sync_clear_n_in => sync_clear, 
        value_out => l_data_wg_actrl
        );
    
    right_channel : wave_gen
        generic map (
        width_g => data_width_c,
        step_g => stepr_c
        )
        PORT map (
        clk => clk, 
        rst_n => rst_n, 
        sync_clear_n_in => sync_clear, 
       value_out => r_data_wg_actrl
        );
    
    controller : audio_ctrl
        generic map (
        ref_clk_freq_g => ref_clk_freq_c, -- frequency of lrclk
        sample_rate_g => sample_rate_c, -- frequency of bclk
        data_width_g => data_width_c
        )
        PORT map (
        clk => clk,
        rst_n => rst_n,
        left_data_in => l_data_wg_actrl,
        right_data_in => r_data_wg_actrl,
        aud_bclk_out => aud_bit_clk,
        aud_data_out => aud_data,
        aud_lrclk_out => aud_lr_clk
        );

    model: audio_codec_model
        generic map (
        data_width_g => data_width_c
        )
        PORT map (
        aud_bclk_in => aud_bit_clk, -- works as a clock
        rst_n => rst_n,
        aud_data_in => aud_data,
        aud_lrclk_in => aud_lr_clk,
        value_left_out => l_data_codec_tb,
        value_right_out => r_data_codec_tb
        );

end testbench;
