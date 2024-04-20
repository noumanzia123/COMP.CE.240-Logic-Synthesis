-------------------------------------------------------------------------------
-- Title      : COMP.CE.240 Logic Synthesis, Exercise 11
-------------------------------------------------------------------------------
-- File       : i2c_config.vhd
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
ENTITY i2c_config_backup IS

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
        param_status_out : out std_logic_vector(n_leds_g-1 DOWNTO 0);
        finished_out    : out std_logic
        );   
END i2c_config_backup;

-------------------------------------------------------------------------------
-- Architecture 'rtl' is  defined

ARCHITECTURE rtl of i2c_config_backup is

-- Define internal SIGNALs and constants
CONSTANT max_sclk_c : INTEGER := (ref_clk_freq_g/i2c_freq_g)/2; -- maximum value for sclk counter corresponding to half period (25µsec)
CONSTANT min_sda_c : INTEGER := max_sclk_c/2; -- sclk counter corresponding to quater duration of sclk period
CONSTANT data_width_c : INTEGER := 8;
CONSTANT n_bytes_c : INTEGER := 3;


TYPE  configuration_data_array is ARRAY (0 to n_params_g-1) of std_logic_vector(data_width_c*n_bytes_c-1 DOWNTO 0); -- an array type with elements containing vectors of bits to be sent
CONSTANT byte_register : configuration_data_array := ("001101000001110110000000", "001101000010011100000100",
                                                    "001101000010001000001011", "001101000010100000000000",
                                                    "001101000010100110000001", "001101000110100100001000",
                                                    "001101000100011111100001", "001101000110101100001001",
                                                    "001101000110110000001000", "001101000100101100001000",
                                                    "001101000100110000001000", "001101000110111010001000",
                                                    "001101000110111110001000", "001101000110111110001000",
                                                    "001101000101000111110001"); -- constant array
--CONSTANT byte_register : configuration_data_array := ("101010101010101010101010", "101010101010101010101010","101010101010101010101010"); -- constant array

 -- Counters for generating clock, sending bits and parameter
SIGNAL counter_sclk_r : INTEGER; -- counter for sclk
SIGNAL counter_param_r : INTEGER; -- counter for sda transmission
SIGNAL counter_bit_r : INTEGER; -- counter for sda transmission

-- signals to acknowlege
SIGNAL ack_flag_r : STD_LOGIC;
SIGNAL nack_r : STD_LOGIC;

-- internal signals
SIGNAL sclk_r : STD_LOGIC;
SIGNAL param_status_r : unsigned(n_leds_g-1 DOWNTO 0); -- counts parameters sent
SIGNAL finished_r : STD_LOGIC;
SIGNAL sdat_r : STD_LOGIC;

-- register to store data 
SIGNAL transmission_r : std_logic_vector(data_width_c*n_bytes_c-1 DOWNTO 0);

-- Enumerate possible states with human readable names
type states_type is (initial_state, wait_for_start, start, data_transmit, acknowledgement, stop_transmission, finish);
signal curr_state_r : states_type;
signal next_state   : states_type;

BEGIN -- rtl
    sclk_out <= sclk_r;
    param_status_out <= std_logic_vector(param_status_r);
    finished_out <= finished_r;
 
    controller  : process (clk, rst_n) -- state machine 
    
    begin   -- process single
        if rst_n = '0' then     -- asynchronous reset (active low)
            curr_state_r <= initial_state;     -- init state
            sdat_r <= '1';
            sclk_r <= '1';
            ack_flag_r <= '0';
            counter_sclk_r <= 0;
            counter_param_r <= 0;
            counter_bit_r <= 0;
            param_status_r <= (others => '0');
            finished_r <= '0';
            --transmission_r <= "101010101010101010101010"; 
            transmission_r <= (others => '0');
        
        elsif clk'event and clk = '1' then  -- rising clock edge
            -- FSM always checks what is the current state
            -- Here that is done with case-clause
            case curr_state_r is
                when initial_state =>
                    transmission_r <= byte_register(counter_param_r);
                    counter_sclk_r <= counter_sclk_r + 1;
                    if counter_sclk_r + 1 = min_sda_c THEN
                        counter_sclk_r <= 0;
                        curr_state_r <= wait_for_start;
                    end if;

                when wait_for_start =>
                --sdat_inout <= sdat_r;
                    counter_sclk_r <= counter_sclk_r + 1;
                    if counter_sclk_r + 1 = max_sclk_c THEN
                        sdat_r <= '0';
                        counter_sclk_r <= 0;
                        curr_state_r <= start;
                    end if;

                when start =>
                    counter_sclk_r <= counter_sclk_r + 1;
                    transmission_r <= byte_register(counter_param_r);
                    if counter_sclk_r + 1 = max_sclk_c THEN
                        sclk_r <= '0';
                        counter_sclk_r <= 0;
                        curr_state_r <= data_transmit;    
                    end if;
                    
                when data_transmit =>
                    counter_sclk_r <= counter_sclk_r + 1;
                    -- sclk generation
                    IF counter_sclk_r + 1 = max_sclk_c THEN 
                        sclk_r <= not sclk_r;                
                    ELSIF counter_sclk_r + 1 = 2*max_sclk_c THEN
                        sclk_r <= not sclk_r;
                        counter_sclk_r <= 0;
                    END IF;
                    -- data transmit after each quarter of clock duration
                    IF counter_sclk_r + 1 = min_sda_c AND (counter_bit_r /= data_width_c AND 
                    counter_bit_r /= 2*data_width_c+1 AND counter_bit_r /= 3*data_width_c+2) THEN
                        sdat_r <= transmission_r(data_width_c*n_bytes_c-1);                  
                        transmission_r <= transmission_r(data_width_c*n_bytes_c-2 downto 0) & '0';
                        counter_bit_r <= counter_bit_r + 1;
                    -- acknowledge after each byte
                    ELSIF counter_sclk_r + 1 = min_sda_c AND (counter_bit_r = data_width_c OR 
                    counter_bit_r = 2*data_width_c+1 OR counter_bit_r = 3*data_width_c+2) THEN
                        curr_state_r <= acknowledgement;
                        ack_flag_r <= '1';
                    END IF;                     
   
                when acknowledgement =>
                    counter_sclk_r <= counter_sclk_r + 1;                    
                    -- clk generation and check acknowledgement
                    IF counter_sclk_r + 1 = max_sclk_c THEN 
                        sclk_r <= not sclk_r;
                        IF nack_r = '1' THEN -- Check nack_r
                            curr_state_r <= stop_transmission;
                        END IF;
                    ELSIF counter_sclk_r + 1 = 2*max_sclk_c THEN
                        sclk_r <= not sclk_r;
                        counter_sclk_r <= 0;
                        counter_bit_r <= counter_bit_r + 1;
                        IF counter_bit_r + 1 = n_bytes_c*data_width_c+n_bytes_c THEN -- (27) all 3 bytes written (a full parameter sent)
                            ack_flag_r <= '0';
                            counter_param_r <= counter_param_r + 1;
                            param_status_r <= param_status_r + 1;
                            IF counter_param_r + 1 = n_params_g THEN -- finish I2C configuration if all parameters written
                                curr_state_r <= finish;  
                            ELSE -- send next parameter
                                curr_state_r <= stop_transmission;
                            END IF;                        
                        ELSE  -- otherwise send next byte
                            ack_flag_r <= '0';
                            curr_state_r <= data_transmit;
                        END IF;
                    END IF;

                    
                when stop_transmission =>
                    counter_sclk_r <= counter_sclk_r + 1;
                    if counter_sclk_r + 1 = max_sclk_c THEN
                        sclk_r <= '1';
                    end if;
                    if counter_sclk_r + 1 = 2*max_sclk_c THEN
                        sdat_r <= '1';
                    end if;
                    if counter_sclk_r + 1 = 3*max_sclk_c THEN
                        counter_sclk_r <= 0;
                        counter_bit_r <= 0;
                        curr_state_r <= wait_for_start;   
                    end if;
                
                when finish =>
                    finished_r <= '1';

            end case;
        end if;         
    end process controller;

    tri_state  : process(ack_flag_r,sdat_r) -- comb process: to decide sending data to codec or receving data from codec
    begin   -- process tri_state
            if ack_flag_r = '1'THEN
                sdat_inout <= 'Z';
                --IF sdat_inout = '1' THEN -- Check nack_r
                    --nack_r <= '0';
                --END IF;
            else
                sdat_inout <= sdat_r;
            end if;
    end process tri_state;
        
end rtl;