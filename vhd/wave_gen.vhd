-------------------------------------------------------------------------------
-- Title      : COMP.CE.240 Logic Synthesis, Exercise 06
-------------------------------------------------------------------------------
-- File       : wave_gen.vhd
-- Author     : Nouman Zia, David Rama Jimeno
-- Group number : 6
-- Company    : TUNI
-- Created    : 2024-02-21
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: A parameterizable triangular wave generator with a bidirection_ral step counter
-------------------------------------------------------------------------------

-- Include default libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Declare entity wave_gen
ENTITY wave_gen IS

    generic (
        width_g : integer := 4; -- counter width
        step_g : integer := 2 -- counter step
        );
    PORT (
        clk : in std_logic;
        rst_n : in std_logic;
        sync_clear_n_in : in std_logic;
        value_out : out std_logic_vector(width_g-1 DOWNTO 0)
        );   
END wave_gen;

-------------------------------------------------------------------------------
-- Architecture 'rtl' is  defined

architecture rtl of wave_gen is
   
-- Define internal signals and constants
signal counter_r : signed(width_g-1 downto 0); -- internal signal (reg)
signal direction_r : STD_LOGIC; -- '1' for counting upwards, '0' for counting downwards
CONSTANT max_c : integer := ((2**(width_g-1)-1)/step_g)*step_g;
CONSTANT min_c : integer := -max_c;


begin -- rtl
    
    -- type convert internal signal and assign to the entity output
    value_out <= std_logic_vector(counter_r);  

    counter : process (clk,rst_n) -- process counter 
    
    begin -- process counter
        
        IF rst_n = '0' then -- asynchronous reset initialize registers
            counter_r <= (others => '0');
            direction_r <= '1';   
        ELSIF clk'event and clk = '1' then -- clk edge            
            IF sync_clear_n_in = '0' then -- asynchronous reset clears the counter and sets the count direction_r upwards
                counter_r <= (others => '0');
                direction_r <= '1';            
            ELSIF sync_clear_n_in = '1' then
                --IF rst_n = '1' and sync_clear_n_in = '1' then counter starts from value zero and counting begins upwards     
                IF direction_r = '1' then
                    counter_r <= counter_r + to_signed(step_g,width_g);
                    IF counter_r + step_g = max_c  then -- check if counter is maximum, then change direction_r
                        direction_r <= '0';
                    end IF;
                ELSIF direction_r = '0' then
                    counter_r <= counter_r - to_signed(step_g,width_g);
                    IF counter_r - step_g = min_c  then  -- check if counter is minimum, then change direction_r
                        direction_r <= '1';
                    end IF;
                end IF;
            end IF;
        end IF;

    end process counter;

end rtl;