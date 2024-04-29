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

signal counter_sclk_r : integer range 0 to 10000;
signal sclk_r : std_logic;
signal sdat_r : std_logic;
signal wait_done_r : std_logic;
signal start_stop_done_r : std_logic;
signal wait_counter_r : integer range 0 to 10000;
signal bits_counter_r : integer range 0 to 10000;
signal byte_counter_r : integer range 0 to 10000;
signal param_counter_r : integer range 0 to 10000;
signal ack_flag_r : std_logic;
signal stop_request_r : std_logic;
signal nack_r : std_logic;
signal nack_done_r : std_logic;
constant data_width_c : integer := 8;
constant bytes_sent_c : integer := 3;
constant wait_delay_c : integer := 5000;
constant start_stop_delay_c : integer := 5000;

type data_type is array (n_params_g-1 downto 0) of std_logic_vector(data_width_c*bytes_sent_c-1 downto 0);
type state is (wait_start,start,write_data,ack,stop,finish);

signal curr_state_r : state;
signal data_register_r : std_logic_vector(data_width_c*bytes_sent_c - 1 downto 0);
signal byte_register_r : std_logic_vector(data_width_c - 1 downto 0);

constant data_transfer_c : data_type := ("001101000001110110000000", "001101000010011100000100",
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
      counter_sclk_r <= 0;
    elsif (clk'EVENT and clk='1') then
      if counter_sclk_r = (ref_clk_freq_g / i2c_freq_g)/2-1 then
        if curr_state_r = write_data or curr_state_r = ack then -- The clock operates only in these states
          sclk_r <= not sclk_r;
        else 
          sclk_r <= '1';  -- After the clock cycle it remains low and goes to wait_start
        end if;
        counter_sclk_r <= 0;
      else
        counter_sclk_r <= counter_sclk_r+1;
      end if;
    end if;

  END PROCESS clk_generation;

  FSM_PROC : PROCESS (clk,rst_n) -- i2c implemented with state machines

  BEGIN	

    if (rst_n = '0') then
      sdat_r <= '1';
      sdat_inout <= '1';
      finished_out <= '0';
      curr_state_r <= wait_start;
      wait_done_r <= '0';
      start_stop_done_r <= '0';
      ack_flag_r <= '0';
      stop_request_r <= '0';
      nack_r <= '0';
      nack_done_r <= '0';
      param_counter_r <= 0;
      byte_counter_r <= 0;
      bits_counter_r <= 0;
      wait_counter_r <= 0;
      data_register_r <= (OTHERS => '0');
      byte_register_r <= (OTHERS => '0');
    elsif (clk'EVENT and clk='1') then
      case curr_state_r is
-----------------------------------------------------------------------
                         --WAIT_START--
-----------------------------------------------------------------------
        when wait_start =>
          if wait_done_r = '1' and rst_n = '1' then -- We wait until the reset signal is high and we waited the buffer time
            curr_state_r <= start;
          else
            curr_state_r <= wait_start;
          end if;
-----------------------------------------------------------------------
                         --START--
-----------------------------------------------------------------------
        when start =>
          if wait_done_r = '1' and start_stop_done_r = '1' then -- In this state we pull the sdat line to low
            curr_state_r <= write_data;
          else
            curr_state_r <= start;
          end if;
-----------------------------------------------------------------------
                        --WRITE_DATA--
-----------------------------------------------------------------------
        when write_data =>
          if bits_counter_r = data_width_c and sclk_r = '0'
           and counter_sclk_r = (ref_clk_freq_g / i2c_freq_g)/4-1 then -- Data transmission can only be done when the clock is low
            curr_state_r <= ack;
          else
            curr_state_r <= write_data;
          end if;
-----------------------------------------------------------------------
                          --ACK--
-----------------------------------------------------------------------
        when ack =>
          if ack_flag_r = '1' or nack_r = '1'  then
            if stop_request_r = '1' then
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
          if start_stop_done_r = '1' then
            if param_counter_r = n_params_g then
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
        if wait_counter_r = wait_delay_c-1 and sclk_r = '1' then --Wait delay is the buffer time between stop and start
          wait_done_r <= '1';
          wait_counter_r <= 0;
        else
          wait_counter_r <= wait_counter_r + 1;
        end if;
      end if;

      if curr_state_r = start then
        nack_done_r <= '0';
        if sclk_r = '1' then
          start_stop_done_r <= '1';
          sdat_r <= '0';
          wait_done_r <= '0';
          nack_r <= '0';
        else
          start_stop_done_r <= '0';
        end if;
        if start_stop_done_r = '1' then
          if wait_counter_r = wait_delay_c-1 and sclk_r = '1' then 
            wait_done_r <= '1';  -- After we pull sdat low, we wait a prudential time before the data transmission
            wait_counter_r <= 0;
          else
            wait_counter_r <= wait_counter_r + 1;
          end if;
        end if;
      end if;
      
      if curr_state_r = write_data then
        wait_done_r <= '0';
        ack_flag_r <= '0';
        start_stop_done_r <= '0';
        data_register_r <= data_transfer_c(n_params_g-param_counter_r-1);
        byte_register_r <= data_register_r((bytes_sent_c-byte_counter_r)*data_width_c-1 downto (bytes_sent_c-byte_counter_r-1)*data_width_c);
        if bits_counter_r /= data_width_c and bits_counter_r /= data_width_c+1 
        and sclk_r = '0' and counter_sclk_r = (ref_clk_freq_g / i2c_freq_g)/4-1 then
          sdat_r <= byte_register_r(data_width_c-bits_counter_r-1);
        end if;
        if sclk_r = '0' and counter_sclk_r = (ref_clk_freq_g / i2c_freq_g)/4-1 then
          bits_counter_r <= bits_counter_r+1;
        end if;
      end if;

      if curr_state_r = ack then
        data_register_r <= (OTHERS => '0');
        byte_register_r <= (OTHERS => '0');
        if sdat_inout = '1' and sclk_r = '1' and counter_sclk_r = (ref_clk_freq_g / i2c_freq_g)/2-1 then
          nack_r <= '1';
          stop_request_r <= '1';
          byte_counter_r <= 0;
          bits_counter_r <= 0;
        else
          nack_r <= nack_r;
        end if;
        if sclk_r = '1' and counter_sclk_r = (ref_clk_freq_g / i2c_freq_g)/2-1 
        and (nack_r = '0' and nack_done_r = '0') and sdat_inout = '0'  then
          ack_flag_r <= '1';
          sdat_r <= '0';
          bits_counter_r <= 0;
          if byte_counter_r /= bytes_sent_c-1 and nack_r = '0' then
            byte_counter_r <= byte_counter_r + 1;
          end if;
          if byte_counter_r = bytes_sent_c-1 then
            stop_request_r <= '1';
            byte_counter_r <= 0;
          end if;
        else
          ack_flag_r <= '0';
        end if;
      end if;
      
      if curr_state_r = ack then
        sdat_inout <= 'Z';
      else
        sdat_inout <= sdat_r;
      end if;

      if curr_state_r = stop then
        start_stop_done_r <= '0';
        stop_request_r <= '0';
        if sclk_r = '1' and counter_sclk_r = (ref_clk_freq_g / i2c_freq_g)/2-1 then
          start_stop_done_r <= '1';
          sdat_r <= '1';
          if nack_r = '1' then
            param_counter_r <= param_counter_r;
            nack_done_r <= '1';
          else
            param_counter_r <= param_counter_r + 1;
          end if;
        else
          start_stop_done_r <= '0';
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

param_status_out <= std_logic_vector(to_unsigned(param_counter_r,n_leds_g));
   
end rtl;