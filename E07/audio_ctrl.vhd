
-------------------------------------------------------------------------------
-- Title      : TKT-1212, Exercise 07
-------------------------------------------------------------------------------
-- File       : audio_ctrl.vhd
-- Author     : David Rama Jimeno & Nouman Zia
-- Group      : HRH056
-- Company    : TUT/DCS
-- Created    : 210.02.2024
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Generate the audio controller
-------------------------------------------------------------------------------


LIBRARY ieee;
USE ieee.std_logic_1164.ALL; --This library is needed in order to be able to use the "std_logic data type"
USE ieee.numeric_std.ALL;


ENTITY audio_ctrl IS
   GENERIC(
      ref_clk_freq_g : integer := 12288000;
      sample_rate_g  : integer := 48000;
      data_width_g   : integer := 16	
      );
   PORT(
      clk           : IN std_logic;
      rst_n         : IN std_logic;
      left_data_in  : IN std_logic_vector(data_width_g-1 DOWNTO 0);
      right_data_in : IN std_logic_vector(data_width_g-1 DOWNTO 0);
      aud_bclk_out  : OUT std_logic;
      aud_data_out  : OUT std_logic;
      aud_lrclk_out : OUT std_logic
      );
END audio_ctrl;

ARCHITECTURE RTL OF audio_ctrl IS

constant max_bit   : integer := (ref_clk_freq_g/sample_rate_g)/2;
constant max_lr    : integer := data_width_g+5;
signal counter_bit : integer;
signal counter_lr  : integer;
signal phase       : integer;
signal clock_bit_r : std_logic;
signal clock_lr_r  : std_logic;
signal lr_data_r   : std_logic;

BEGIN

---------------------------------------------------------------------
   -- purpose: State Registers
   -- type   : sequential
   -- inputs : clk, rst_n
---------------------------------------------------------------------
  COUNTER_CLOCKS : PROCESS (clk, rst_n)
 
  BEGIN  -- PROCESS STREG
   
  --max_bit       := (ref_clk_freq_g/sample_rate_g)/2;
  --max_lr        := data_width_g+5;
  aud_bclk_out  <= clock_bit_r;
  aud_lrclk_out <= clock_lr_r;
  aud_data_out  <= lr_data_r;

    if (rst_n = '0') then             -- asynchronous reset (active low)
      counter_bit <=  0;
      counter_lr  <=  max_lr;
      phase       <=  0;
      clock_bit_r <= '0';
      clock_lr_r  <= '0';
      lr_data_r   <= '0';      

    elsif (clk'EVENT and clk = '1') then  -- rising clock edge
      if (counter_bit /= max_bit) then
        counter_bit <= counter_bit + 1;
      elsif (counter_bit = max_bit) then
        counter_bit  <= 0;
        clock_bit_r  <= not clock_bit_r;
        if (clock_bit_r'EVENT and clock_bit_r = '0') then 
          if (counter_lr /= 0) then
            counter_lr <= counter_lr - 1;

            if (clock_lr_r = '1') then
              if (counter_lr+phase /= 5) then
                lr_data_r <= left_data_in(counter_lr-phase);
              elsif (counter_lr+phase = 5) then
                lr_data_r <= '0';
                phase <= phase+1;
              end if;

            elsif (clock_lr_r = '0') then
              if (counter_lr+phase /= 5) then
                lr_data_r <= right_data_in(counter_lr-phase);
              elsif (counter_lr+phase = 5) then
                lr_data_r <= '0';
                phase <= phase+1;
              end if;
            end if;
---
          elsif (counter_lr = 0) then
            counter_lr <= max_lr;
            phase      <= 0;
            clock_lr_r <= not clock_lr_r;
          end if;
        end if;
      end if;
    end if;

  END PROCESS COUNTER_CLOCKS;

END RTL;
