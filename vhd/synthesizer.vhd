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
        clk_freq_g : integer := 12288000;
        sample_rate_g : integer := 48000;
        data_width_g : integer := 16;
        n_keys_g : integer := 4
    );

    PORT (
        clk : in std_logic;
        rst_n : in std_logic;
        keys_in  : in std_logic_vector(n_keys_g-1 DOWNTO 0);
        aud_bclk_out  : out std_logic;
        aud_data_out  : out std_logic;
        aud_lrclk_out  : out std_logic
        );  

END synthesizer;

-- Architecture called 'structural' is  defined below
ARCHITECTURE structural of synthesizer IS

-- set data width and waveform frequency for wave generators
CONSTANT step1_c    : INTEGER := 1;
CONSTANT step2_c    : INTEGER := 2;
CONSTANT step3_c    : INTEGER := 4;
CONSTANT step4_c    : INTEGER := 8;
CONSTANT num_of_operands_c : integer := 4;

-- internal signals
SIGNAL wave_gen_out1 : std_logic_vector(data_width_g-1 DOWNTO 0);
SIGNAL wave_gen_out2 : std_logic_vector(data_width_g-1 DOWNTO 0);
SIGNAL wave_gen_out3 : std_logic_vector(data_width_g-1 DOWNTO 0);
SIGNAL wave_gen_out4 : std_logic_vector(data_width_g-1 DOWNTO 0);
SIGNAL multi_port_adder_in : std_logic_vector(n_keys_g*data_width_g-1 DOWNTO 0);
SIGNAL multi_port_adder_out : std_logic_vector(data_width_g-1 DOWNTO 0);
SIGNAL bclk : std_logic;
SIGNAL lrclk : std_logic;
SIGNAL data : std_logic;
SIGNAL sync_clear1 : std_logic;
SIGNAL sync_clear2 : std_logic;
SIGNAL sync_clear3 : std_logic;
SIGNAL sync_clear4 : std_logic;


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

    aud_bclk_out  <= bclk;
    aud_data_out  <= data;
    aud_lrclk_out <= lrclk;
    sync_clear1 <= keys_in(0);
    sync_clear2 <= keys_in(1);
    sync_clear3 <= keys_in(2);
    sync_clear4 <= keys_in(3);
    multi_port_adder_in <= wave_gen_out1 & wave_gen_out2 & wave_gen_out3 & wave_gen_out4;

    
     -- Port mappings
     wave_gen1 : wave_gen
        generic map (
        width_g => data_width_g,
        step_g => step1_c
        )
        PORT map (
        clk => clk, 
        rst_n => rst_n, 
        sync_clear_n_in => sync_clear1, 
        value_out => wave_gen_out1
        );
    
    wave_gen2 : wave_gen
        generic map (
        width_g => data_width_g,
        step_g => step2_c
        )
        PORT map (
        clk => clk, 
        rst_n => rst_n, 
        sync_clear_n_in => sync_clear2, 
       value_out => wave_gen_out2
        );

    wave_gen3 : wave_gen
        generic map (
        width_g => data_width_g,
        step_g => step3_c
        )
        PORT map (
        clk => clk, 
        rst_n => rst_n, 
        sync_clear_n_in => sync_clear3, 
        value_out => wave_gen_out3
        );

    wave_gen4 : wave_gen
        generic map (
        width_g => data_width_g,
        step_g => step4_c
        )
        PORT map (
        clk => clk, 
        rst_n => rst_n, 
        sync_clear_n_in => sync_clear4, 
        value_out => wave_gen_out4
        );
    
    adder : multi_port_adder
        generic map (
        operand_width_g => data_width_g,
        num_of_operands_g => num_of_operands_c
        )
        PORT map (
        clk => clk,
        rst_n => rst_n,
        operands_in => multi_port_adder_in,
        sum_out => multi_port_adder_out
        );

    controller : audio_ctrl
        generic map (
        ref_clk_freq_g => clk_freq_g, -- frequency of lrclk
        sample_rate_g => sample_rate_g, -- frequency of bclk
        data_width_g => data_width_g
        )
        PORT map (
        clk => clk,
        rst_n => rst_n,
        left_data_in => multi_port_adder_out,
        right_data_in => multi_port_adder_out,
        aud_bclk_out => bclk,
        aud_data_out => data,
        aud_lrclk_out => lrclk
        );


end structural;
