-------------------------------------------------------------------------------
-- Title      : COMP.CE.240 Logic Synthesis, Exercise 07
-------------------------------------------------------------------------------
-- File       : tb_audio_ctrl.vhd
-- Author     : Nouman Zia, David Rama Jimeno
-- Group number : 6
-- Company    : TUNI
-- Created    : 2024-03-05
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Test bench to validate the functionality of audio controller
-------------------------------------------------------------------------------

-- Include default libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Declare entity
ENTITY tb_audio_ctrl IS

END tb_audio_ctrl;

-- Architecture called 'testbench' is  defined below
ARCHITECTURE testbench of tb_audio_ctrl IS

-- set the clock period
CONSTANT period_c : TIME := 33.5 ns; -- 30ns = 33 MHz

-- Set the time when generator is cleared synchronously
CONSTANT clear_delay_c    : INTEGER := 74000;
CONSTANT clear_duration_c : INTEGER := 6000;

-- set data width and waveform frequency for wave generators
CONSTANT data_width_c : INTEGER := 16;
CONSTANT stepl_c    : INTEGER := 2;
CONSTANT stepr_c    : INTEGER := 10;

-- audio controller parameters
CONSTANT ref_clk_freq_c : INTEGER := 29851000; -- 0 ns
CONSTANT sample_rate_c  : INTEGER := 48000; -- lrclk

-- internal signals
SIGNAL clk : std_logic := '0'; -- init values only in tb
SIGNAL rst_n : std_logic := '0'; -- init values only in tb   
SIGNAL l_data_wg_actrl : std_logic_vector(data_width_c-1 DOWNTO 0);
SIGNAL r_data_wg_actrl : std_logic_vector(data_width_c-1 DOWNTO 0);
SIGNAL aud_bit_clk : std_logic; 
SIGNAL aud_lr_clk : std_logic;
SIGNAL aud_data : std_logic;
SIGNAL l_data_codec_tb : std_logic_vector(data_width_c-1 DOWNTO 0);
SIGNAL r_data_codec_tb : std_logic_vector(data_width_c-1 DOWNTO 0);
SIGNAL sync_clear : std_logic; 

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
    COMPONENT audio_codec_model
    generic (
        data_width_g : integer
        );
    PORT (
        aud_bclk_in : in std_logic; -- works as a clock
        rst_n : in std_logic;
        aud_data_in : in std_logic;
        aud_lrclk_in : in std_logic;
        value_left_out  : out std_logic_vector(data_width_g-1 DOWNTO 0);
        value_right_out   : out std_logic_vector(data_width_g-1 DOWNTO 0)
        );   
    END COMPONENT;


begin -- testbench architecture

    -- create clock and reset signals
    clk <= NOT clk AFTER period_c/2; -- this style needs init value
    rst_n <= '0', '1' AFTER 4*period_c;
    -- Create synchronous clear signal
    sync_clear <= '1',
    '0' AFTER period_c*clear_delay_c,
    '1' AFTER period_c*(clear_delay_c+clear_duration_c);
  
    l_data_wg_actrl <= "1110101010101011";
    r_data_wg_actrl <= "1110101010101011";
    -- Port mappings
    --left_channel : wave_gen
    --    generic map (
    --    width_g => data_width_c,
    --    step_g => stepl_c
    --    )
    --    PORT map (
    --    clk => clk, 
    --    rst_n => rst_n, 
    --    sync_clear_n_in => sync_clear, 
    --    value_out => l_data_wg_actrl
    --    );
    
    --right_channel : wave_gen
    --    generic map (
    --    width_g => data_width_c,
    --    step_g => stepr_c
    --    )
    --    PORT map (
    --    clk => clk, 
    --    rst_n => rst_n, 
    --    sync_clear_n_in => sync_clear, 
    --   value_out => r_data_wg_actrl
    --    );
    
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
