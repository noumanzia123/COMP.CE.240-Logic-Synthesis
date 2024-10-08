-------------------------------------------------------------------------------
-- Title      : COMP.CE.240 Logic Synthesis, Exercise 11
-------------------------------------------------------------------------------
-- File       : i2c_config.vhd
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

ENTITY i2c_config IS

    generic (
        ref_clk_freq_g : integer := 50000000; -- clk frequency
        i2c_freq_g     : integer := 20000; -- frequency of sclk
        n_params_g     : integer := 15;
        n_leds_g       : integer := 4
        );
    PORT (
        clk              : in std_logic;
        rst_n            : in std_logic;
        sdat_inout       : inout std_logic;
        sclk_out         : out std_logic; -- Bit clock
        param_status_out : out std_logic_vector(n_leds_g-1 downto 0);
        finished_out     : out std_logic -- Left-right clock
        );   
END i2c_config;

-------------------------------------------------------------------------------
-- Architecture 'rtl' is  defined

ARCHITECTURE rtl of i2c_config is

-- Define internal SIGNALs and constants

signal counter_sclk : integer;
signal sclk_r : std_logic;
signal sdat_r : std_logic;
signal wait_done : std_logic;
signal start_stop_done : std_logic;
signal wait_counter : integer;
--signal start_stop_counter : integer;
signal bits_counter : integer;
signal byte_counter : integer;
signal param_counter : integer;
signal ack_flag : std_logic;
signal stop_request : std_logic;
signal nack : std_logic;
constant data_width : integer := 8;
constant bytes_sent : integer := 3;
constant wait_delay : integer := 300;
constant start_stop_delay : integer := 300;

type data_type is array (n_params_g-1 downto 0) of std_logic_vector(data_width*bytes_sent-1 downto 0);
type state is (wait_start,start,write_data,ack,stop,finish);

signal curr_state_r : state;
signal data_register_r : std_logic_vector(data_width*bytes_sent - 1 downto 0);
signal byte_register_r : std_logic_vector(data_width - 1 downto 0);

constant data_transfer : data_type := ("001101000001110110000000", "001101000010011100000100",
                                       "001101000010001000001011", "001101000010100000000000", 
                                       "001101000010100110000001", "001101000110100100001000",
                                       "001101000110101000000000", "001101000100011111100001", 
                                       "001101000110101100001001", "001101000110110000001000", 
                                       "001101000100101100001000", "001101000100110000001000", 
                                       "001101000110111010001000", "001101000110111110001000", 
                                       "001101000101000111110001");
begin -- rtl

  sclk_out <= sclk_r;
  clk_generation : PROCESS (clk,rst_n)

  BEGIN	

    if (rst_n = '0') then
      sclk_r <= '1';
      counter_sclk <= 0;
    elsif (clk'EVENT and clk='1') then
      if counter_sclk = (ref_clk_freq_g / i2c_freq_g)/2-1 then
        if curr_state_r = write_data or curr_state_r = ack then -- The clock operates only in these states
          sclk_r <= not sclk_r;
        else 
          sclk_r <= '1';  -- After the clock cycle it remains low and goes to wait_start
        end if;
        counter_sclk <= 0;
      else
        counter_sclk <= counter_sclk+1;
      end if;
    end if;

  END PROCESS clk_generation;

  FSM_PROC : PROCESS (clk,rst_n) -- i2c implemented with state machines

  BEGIN	

    if (rst_n = '0') then
      sdat_r <= '1';
      sdat_inout <= 'Z';
      curr_state_r <= wait_start;
      wait_done <= '0';
      start_stop_done <= '0';
      ack_flag <= '0';
      stop_request <= '0';
      nack <= '0';
      param_counter <= 0;
      byte_counter <= 0;
      bits_counter <= 0;
      wait_counter <= 0;
    elsif (clk'EVENT and clk='1') then
      case curr_state_r is
-----------------------------------------------------------------------
                         --WAIT_START--
-----------------------------------------------------------------------
        when wait_start =>
          if wait_done = '1' and rst_n = '1' then -- We wait until the reset signal is high and we waited the buffer time
            curr_state_r <= start;
          else
            curr_state_r <= wait_start;
          end if;
-----------------------------------------------------------------------
                         --START--
-----------------------------------------------------------------------
        when start =>
          if wait_done = '1' and start_stop_done = '1' then -- In this state we pull the sdat line to low
            curr_state_r <= write_data;
          else
            curr_state_r <= start;
          end if;
-----------------------------------------------------------------------
                        --WRITE_DATA--
-----------------------------------------------------------------------
        when write_data =>
          if bits_counter = data_width and sclk_r = '0'
           and counter_sclk = (ref_clk_freq_g / i2c_freq_g)/4-1 then -- Data transmission can only be done when the clock is low
            curr_state_r <= ack;
          else
            curr_state_r <= write_data;
          end if;
-----------------------------------------------------------------------
                          --ACK--
-----------------------------------------------------------------------
        when ack =>
          if ack_flag = '1'  then
            if stop_request = '1' then
              curr_state_r <= stop;        -- Once all the three bytes have been sent or a nack is received, we go to stop state
            else
              curr_state_r <= write_data;
            end if;
          else
            curr_state_r <= ack;
          end if;
-----------------------------------------------------------------------
                          --STOP--
-----------------------------------------------------------------------
        when stop =>
          if start_stop_done = '1' then
            if param_counter = n_params_g then
              curr_state_r <= finish;     -- Only if all the parameters have been sent we can go to finish state
            else
              curr_state_r <= wait_start;
            end if;
          else
            curr_state_r <= stop;
          end if;
-----------------------------------------------------------------------
                       --FINISH--
-----------------------------------------------------------------------
        when finish =>
          curr_state_r <= finish;
-----------------------------------------------------------------------
                       --OTHERS--
-----------------------------------------------------------------------
        when others =>
          curr_state_r <= wait_start;

      end case;

      if curr_state_r = wait_start then
        sdat_r <= '1';
        --sclk_r <= '1';
        if wait_counter = wait_delay-1 and sclk_r = '1' then --Wait delay is the buffer time between stop and start
          wait_done <= '1';
          wait_counter <= 0;
        else
          wait_counter <= wait_counter + 1;
        end if;
      end if;

      if curr_state_r = start then
        if sclk_r = '1' then
          start_stop_done <= '1';
          sdat_r <= '0';
          wait_done <= '0';
          nack <= '0';
        else
          start_stop_done <= '0';
        end if;
        if start_stop_done = '1' then
          if wait_counter = wait_delay-1 and sclk_r = '1' then 
            wait_done <= '1';  -- After we pull sdat low, we wait a prudential time before the data transmission
            wait_counter <= 0;
          else
            wait_counter <= wait_counter + 1;
          end if;
        end if;
      end if;
      
      if curr_state_r = write_data then
        --nack <= '0';
        wait_done <= '0';
        ack_flag <= '0';
        start_stop_done <= '0';
        data_register_r <= data_transfer(n_params_g-param_counter-1);
        byte_register_r <= data_register_r((bytes_sent-byte_counter)*data_width-1 downto (bytes_sent-byte_counter-1)*data_width);
        if bits_counter /= data_width and sclk_r = '0' and counter_sclk = (ref_clk_freq_g / i2c_freq_g)/4-1 then
          sdat_r <= byte_register_r(data_width-bits_counter-1);
        end if;
        if sclk_r = '0' and counter_sclk = (ref_clk_freq_g / i2c_freq_g)/4-1 then
          bits_counter <= bits_counter+1;
        end if;
      end if;

      if curr_state_r = ack then
        sdat_inout <= 'Z';
        if sdat_inout = '1' and sclk_r = '1' and counter_sclk = (ref_clk_freq_g / i2c_freq_g)/2-1 then
          nack <= '1';
        else
          nack <= nack;
        end if;
        if sclk_r = '1' and counter_sclk = (ref_clk_freq_g / i2c_freq_g)/2-1 then
          ack_flag <= '1';
          sdat_r <= '0';
          bits_counter <= 0;
          byte_counter <= byte_counter + 1;
          if byte_counter = bytes_sent-1 then
            stop_request <= '1';
            byte_counter <= 0;
          end if;
        else
          ack_flag <= '0';
        end if;
      end if;
      
      if curr_state_r = ack then
        sdat_inout <= 'Z';
      else
        sdat_inout <= sdat_r;
      end if;

      if curr_state_r = stop then
        --nack <= '0';
        start_stop_done <= '0';
        stop_request <= '0';
        sdat_r <= '0';
        if sclk_r = '1' and counter_sclk = (ref_clk_freq_g / i2c_freq_g)/2-1 then
          start_stop_done <= '1';
          sdat_r <= '1';
          if nack = '1' then
            param_counter <= param_counter;
          else
            param_counter <= param_counter + 1;
          end if;
        else
          start_stop_done <= '0';
        end if;
      end if;
      if curr_state_r = finish then
        finished_out <= '1';
        sdat_r <= '0';
      else
        finished_out <= '0';
      end if;
    end if;

  END PROCESS FSM_PROC;
  
param_status_out <= std_logic_vector(to_unsigned(param_counter,n_leds_g));
   
end rtl;


