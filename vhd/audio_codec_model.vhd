-------------------------------------------------------------------------------
-- Title      : COMP.CE.240 Logic Synthesis, Exercise 08
-------------------------------------------------------------------------------
-- File       : audio_codec_model.vhd
-- Author     : Nouman Zia, David Rama Jimeno
-- Group number : 6
-- Company    : TUNI
-- Created    : 2024-02-21
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: A a model implementation for the audio codec using state machine
-------------------------------------------------------------------------------

-- Include default libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Declare entity audio_codec_model
ENTITY audio_codec_model IS

    generic (
        data_width_g : integer := 16
        );
    PORT (
        aud_bclk_in : in std_logic; -- works as a clock
        rst_n : in std_logic;
        aud_data_in : in std_logic;
        aud_lrclk_in : in std_logic;
        value_left_out  : out std_logic_vector(data_width_g-1 DOWNTO 0);
        value_right_out   : out std_logic_vector(data_width_g-1 DOWNTO 0)
        );   
END audio_codec_model;


architecture rtl_mealy_1_reg of audio_codec_model is

    -- Enumerate possible states with human readable names
    type states_type is (wait_for_input, read_left, read_right);
    signal curr_state_r : states_type;
    signal next_state   : states_type;

    -- counter to stop storing input data 
    SIGNAL counter_r  : signed(data_width_g-1 DOWNTO 0); 

    -- shift registers and output registers
    signal left_data_r  : std_logic_vector(data_width_g-1 DOWNTO 0);
    signal right_data_r  : std_logic_vector(data_width_g-1 DOWNTO 0);
    signal value_left_r  : std_logic_vector(data_width_g-1 DOWNTO 0);
    signal value_right_r  : std_logic_vector(data_width_g-1 DOWNTO 0);

begin  -- rtl_mealy_1_reg
    value_left_out <= value_left_r;
    value_right_out <= value_right_r;
    -- This only process handles the state changes as well as output.
    -- Hence, output will be registered. It will change simultaneously with
    -- curr_state_r in this example.

    single : process (aud_bclk_in, rst_n)
    
    begin   -- process single
        if rst_n = '0' then     -- asynchronous reset (active low)
            curr_state_r <= wait_for_input;     -- init state
            left_data_r <= (OTHERS => '0');
            right_data_r <= (OTHERS => '0');
            counter_r <= (OTHERS => '0');
            value_left_r <= (OTHERS => '0');
            value_right_r <= (OTHERS => '0');
    
        elsif aud_bclk_in'event and aud_bclk_in = '1' then  -- rising clock edge
            -- FSM always checks what is the current state
            -- Here that is done with case-clause
            case curr_state_r is

                when wait_for_input =>
                    if aud_lrclk_in = '1' then -- lrclk raising edge
                        left_data_r <= left_data_r(data_width_g-2 downto 0) 
                        & aud_data_in; -- serial to parallel data transfer by left shift
                        curr_state_r <= read_left;
                    end if;
                    
                when read_left =>
                    if counter_r + 1 /= data_width_g then
                        left_data_r <= left_data_r(data_width_g-2 downto 0) 
                        & aud_data_in; -- serial to parallel data transfer by left shift
                        counter_r <= counter_r + 1;
                    end if;
                    if counter_r = data_width_g - 1 then -- loading data to output register when all bits are recieved
                        value_left_r <= left_data_r; 
                    end if;
                    
                    if aud_lrclk_in = '0' then -- lrclk falling edge
                        counter_r <= (OTHERS => '0');
                        left_data_r <= (OTHERS => '0');
                        right_data_r <= right_data_r(data_width_g-2 downto 0) 
                        & aud_data_in; -- serial to parallel data transfer by left shift
                        curr_state_r <= read_right;
                    end if;
                    
                when read_right =>
                    if counter_r + 1 /= data_width_g then
                        right_data_r <= right_data_r(data_width_g-2 downto 0)
                         & aud_data_in; -- serial to parallel data transfer by left shift
                        counter_r <= counter_r + 1;
                    end if;
                    if counter_r = data_width_g - 1 then -- loading data to output register when all bits are recieved
                        value_right_r <= right_data_r;
                    end if;                        
                    if aud_lrclk_in = '1' then -- lrclk raising edge
                        right_data_r <= (OTHERS => '0');
                        counter_r <= (OTHERS => '0');
                        left_data_r <= left_data_r(data_width_g-2 downto 0) & aud_data_in; -- joining input data by shifting right
                        curr_state_r <= read_left;
                    end if;
            end case;
        end if;                       
    
    end process single;

end rtl_mealy_1_reg;


