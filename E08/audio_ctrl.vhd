-------------------------------------------------------------------------------
-- Title      : COMP.CE.240 Logic Synthesis, Exercise 07
-------------------------------------------------------------------------------
-- File       : audio_ctrl.vhd
-- Author     : Nouman Zia, David Rama Jimeno
-- Group number : 6
-- Company    : TUNI
-- Created    : 2024-02-25
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: controller for the DA7212 Audio codec
-------------------------------------------------------------------------------

-- Include default libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Declare entity audio_ctrl

ENTITY audio_ctrl IS

    generic (
        ref_clk_freq_g : integer := 20000000; -- clk frequency
        sample_rate_g : integer := 48000; -- frequency of lrclk
        data_width_g : integer := 16
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
END audio_ctrl;

-------------------------------------------------------------------------------
-- Architecture 'rtl' is  defined

ARCHITECTURE rtl of audio_ctrl is

-- Define internal SIGNALs and constants
SIGNAL counter1_r  : signed(data_width_g-1 DOWNTO 0); -- counter for lrclk
SIGNAL counter2_r  : signed(data_width_g-1 DOWNTO 0); -- counter for bclk
SIGNAL left_channel_data_r : std_logic_vector(data_width_g-1 downto 0);  -- internal data
SIGNAL right_channel_data_r : std_logic_vector(data_width_g-1 downto 0);  -- internal data
SIGNAL right_channel_r : STD_LOGIC; -- '1' for counting upwards, '0' for counting downwards
SIGNAL left_channel_r : STD_LOGIC; -- '1' for counting upwards, '0' for counting downwards
SIGNAL lrclk_r : STD_LOGIC;
SIGNAL bclk_r : STD_LOGIC;
SIGNAL aud_data_r : STD_LOGIC;
CONSTANT max_lr_c : integer := (ref_clk_freq_g/sample_rate_g)/2; -- limit value for Left-right clock divider 
CONSTANT max_bit_c : integer := (max_lr_c/(data_width_g))/2; -- limit value for Bit clock divider 


begin -- rtl
    aud_data_out <= aud_data_r;
    aud_lrclk_out <= lrclk_r;
    aud_bclk_out <= bclk_r;

    parallel_serial : PROCESS (clk,rst_n) -- process for parallel-serial transfer
    
    BEGIN -- process parallel_serial
        IF rst_n = '0' THEN -- asynchronous reset initialize registers
            aud_data_r <= '0';
            left_channel_data_r <= (OTHERS => '0');
            right_channel_data_r <= (OTHERS => '0'); 

        ELSIF clk'event AND clk = '1' THEN -- clk edge
            -- load the data to registers before lrclk rising edge 
            IF counter2_r + 2 = 2*max_bit_c AND (counter1_r + 1 = 1 OR counter1_r = 2*data_width_g)  THEN 
                left_channel_data_r <= left_data_in;
                right_channel_data_r <= right_data_in;
            END IF;
            IF left_channel_r = '1' THEN
                IF counter2_r + 1 = 2*max_bit_c THEN -- sampling left channel at bclk edge by shifting left
                    aud_data_r <= left_channel_data_r(data_width_g-1);                  
                    left_channel_data_r <= left_channel_data_r(data_width_g-2 downto 0) & '0';   
                END IF;             
            ELSIF right_channel_r = '1' THEN
                IF counter2_r + 1 = 2*max_bit_c THEN -- sampling right channel at bclk by shifting left    
                    aud_data_r <= right_channel_data_r(data_width_g-1);                  
                    right_channel_data_r <= right_channel_data_r(data_width_g-2 downto 0) & '0'; 
                END IF;
            END IF;
        END IF;        
    
    END PROCESS parallel_serial;

    clock_divider: process (clk,rst_n) -- process for generation of clk SIGNALs for DA7212 codec
    BEGIN -- process clock_divider
        IF rst_n = '0' THEN -- asynchronous reset initialize registers
            counter1_r <= (OTHERS => '0'); -- lrclk
            counter2_r <= (OTHERS => '0'); -- bclk
            bclk_r <= '0';
            lrclk_r <= '0';
            right_channel_r <= '0'; -- flag for right channel data tranmission
            left_channel_r <= '0';  -- flag for left channel data tranmission
        ELSIF clk'event AND clk = '1' THEN -- clk edge       
            counter2_r <= counter2_r + 1;
            -- BCLK & LRCLK generation 
            IF counter2_r + 1 = max_bit_c THEN -- bclk set '1' when counter reaches half of the clock period length
                bclk_r <= '1';
            ELSIF counter2_r + 1 = 2*max_bit_c THEN -- bclk set '0' when counter reaches full clock period length
                bclk_r <= '0';
                counter2_r <= (OTHERS => '0');
                counter1_r <= counter1_r + 1;
                IF counter1_r + 1 = 1 THEN -- rising edge of lrclk
                    lrclk_r <= '1';              
                ELSIF counter1_r = data_width_g THEN -- falling edge of lrclk
                    lrclk_r <= '0';
                ELSIF counter1_r = 2*data_width_g THEN -- rising edge of lrclk
                    lrclk_r <= '1';
                    counter1_r <= "0000000000000001";                     
                END IF;
            END IF;
            -- flags for right and left channel data tranmission
            IF counter2_r + 2 = 2*max_bit_c AND (counter1_r + 1 = 1 OR counter1_r = 2*data_width_g) THEN
                left_channel_r <= '1';
                right_channel_r <= '0';
            ELSIF counter2_r + 2 = 2*max_bit_c AND counter1_r = data_width_g THEN
                left_channel_r <= '0';
                right_channel_r <= '1';                    
            END IF;            
        END IF;
    END PROCESS clock_divider;
end rtl;