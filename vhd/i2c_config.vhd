-------------------------------------------------------------------------------
-- Title      : COMP.CE.240 Logic Synthesis, Exercise 11
-------------------------------------------------------------------------------
-- File       : audio_codec_model.vhd
-- Author     : Nouman Zia, David Rama Jimeno
-- Group number : 6
-- Company    : TUNI
-- Created    : 2024-04-10
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: I2C-bus controller which configures the DA7212 audio codec before the synthesizer begins to feed data to it
-------------------------------------------------------------------------------

-- Include default libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Declare entity audio_codec_model
ENTITY i2c_config IS

    generic (
        ref_clk_freq_g : integer := 50000000; -- frequency of clk-signal as information to your block
        i2c_freq_g : integer := 20000; -- i2c-bus (sclk_out) frequency
        n_params_g : integer := 15; -- number of configuration parameters
        n_leds_g : integer := 4 -- number of leds on the board
        );
    PORT (
        clk : in std_logic; -- works as a clock
        rst_n : in std_logic;
        sdat_inout  : inout std_logic;
        sclk_out  : out std_logic;
        param_status_out : out unsigned(n_leds_g-1 DOWNTO 0);
        finished_out    : out std_logic
        );   
END i2c_config;

-------------------------------------------------------------------------------
-- Architecture 'rtl' is  defined

ARCHITECTURE rtl of i2c_config is

-- Define internal SIGNALs and constants
CONSTANT max_sclk : INTEGER := (ref_clk_freq_g/i2c_freq_g)/2; -- maximum value for sclk (25µsec)
CONSTANT min_sda : INTEGER := max_sclk/2; -- min value for sclk (14.5µs)
CONSTANT max_sda : INTEGER := 2*max_sclk+max_sclk/2; -- maximum value for sclk
CONSTANT data_width : INTEGER := 8; -- maximum value for sclk
CONSTANT byte_sent : INTEGER := 3; -- maximum value for sclk


TYPE  configuration_data_array is ARRAY (0 to n_params_g-1) of std_logic_vector(data_width*byte_sent-1 DOWNTO 0); -- an array type with elements containing vectors of bits to be sent
CONSTANT byte_register : configuration_data_array := ("001101000001110110000000", "001101000010011100000100"
                                                    "001101000010001000001011", "001101000010100000000000"
                                                    "001101000010100110000001", "001101000110100100001000"
                                                    "001101000100011111100001", "001101000110101100001001"
                                                    "001101000110110000001000", "001101000100101100001000"
                                                    "001101000100110000001000", "001101000110111010001000"
                                                    "001101000110111110001000", "001101000110111110001000"
                                                    "001101000101000111110001"); -- constant array


SIGNAL counter_sclk : INTEGER; -- counter for sclk
SIGNAL counter_sda : INTEGER; -- counter for sda transmission
SIGNAL counter_bit : INTEGER; -- counter for sda transmission
SIGNAL sclk_r : STD_LOGIC;
SIGNAL param_status_r : unsigned(n_leds_g-1 DOWNTO 0); -- counter for lrclk
SIGNAL finished_r : STD_LOGIC;
SIGNAL sdat_r : STD_LOGIC;
SIGNAL transmission_r : std_logic_vector(24-1 DOWNTO 0);


-- Enumerate possible states with human readable names
type states_type is (wait_for_start, start, data_transmit, acknowledgement, stop_transmission);
signal curr_state_r : states_type;
signal next_state   : states_type;

BEGIN -- rtl
    sclk_out <= sclk_r;
    param_status_out <= param_status_r;
    finished_out <= finished_r;
    sdat_inout <= sdat_r;
 
    controller  : process (clk, rst_n) -- state machine 
    
    begin   -- process single
        if rst_n = '0' then     -- asynchronous reset (active low)
            curr_state_r <= wait_for_start;     -- init state
            sdat_r <= '1';
            sclk_r <= '1';
            counter_sclk <= 0;
            counter_sda <= 0;
            counter_bit <= 0;
            transmission_r <= "101010101010101010101010"; 
        elsif clk'event and clk = '1' then  -- rising clock edge
            -- FSM always checks what is the current state
            -- Here that is done with case-clause
            case curr_state_r is

                when wait_for_start =>
                    counter_sclk <= counter_sclk + 1;
                    if counter_sclk + 1 = max_sclk THEN
                        sdat_r <= '0';
                        counter_sclk <= 0;
                        curr_state_r <= start;
                    end if;

                when start =>
                    counter_sclk <= counter_sclk + 1;
                    if counter_sclk + 1 = max_sclk THEN
                        sclk_r <= '0';
                        counter_sclk <= 0;
                        curr_state_r <= data_transmit;
                    end if;
                    
                when data_transmit =>
                    counter_sclk <= counter_sclk + 1;
                    counter_sda <= counter_sda + 1;
                    -- sclk
                    IF counter_sclk + 1 = max_sclk THEN 
                        sclk_r <= not sclk_r;                
                    ELSIF counter_sclk + 1 = 2*max_sclk THEN
                        sclk_r <= not sclk_r;
                        counter_sclk <= 0;
                    END IF;
                    -- data transmit
                    IF counter_sclk + 1 = min_sda THEN --AND counter_bit /= 0 AND counter_bit /= 1 THEN
                        sdat_r <= transmission_r(24-1);                  
                        transmission_r <= transmission_r(24-2 downto 0) & '0';
                        counter_bit <= counter_bit + 1;
                        --counter_sda <= 0;
                        IF counter_bit = 8 OR counter_bit = 17 OR counter_bit = 26 THEN
                            curr_state_r <= acknowledgement;
                        END IF;  
                    END IF;
   
                when acknowledgement =>
                    counter_sclk <= counter_sclk + 1;
                    --sdat_inout <= 'Z';
                    counter_sda <= counter_sda + 1;
                    IF counter_sda + 1 = 2*max_sclk THEN
                        sdat_r <= transmission_r(24-1);                  
                        transmission_r <= transmission_r(24-2 downto 0) & '0';
                        counter_bit <= counter_bit + 1;
                        counter_sda <= 0;
                    END IF;
                    -- sclk
                    IF counter_sclk + 1 = max_sclk THEN 
                        sclk_r <= not sclk_r;                
                    ELSIF counter_sclk + 1 = 2*max_sclk THEN
                        sclk_r <= not sclk_r;
                        counter_sclk <= 0;
                        curr_state_r <= data_transmit;
                    END IF;
                    IF counter_bit = 27 THEN
                        curr_state_r <= stop_transmission;
                    END IF;
                when stop_transmission =>
                    counter_sclk <= counter_sclk + 1;
                    counter_sda <= counter_sda + 1;
                    if counter_sclk + 1 = max_sclk THEN
                        sclk_r <= '1';
                        counter_sclk <= 0;
                        --curr_state_r <= data_transmit;
                    end if;
                    if counter_sda + 1 = min_sda*3 THEN
                        sdat_r <= '1';
                        counter_sda <= 0;
                        --curr_state_r <= data_transmit;
                    end if;                     
            end case;
        end if;         
    end process controller;
end rtl;   
    