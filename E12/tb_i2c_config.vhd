-------------------------------------------------------------------------------
-- Title      : COMP.CE.240 Logic Synthesis, Exercise 12
-------------------------------------------------------------------------------
-- File       : tb_i2c_config.vhd
-- Author     : Nouman Zia, David Rama Jimeno
-- Group number : 6
-- Company    : TUNI
-- Created    : 2024-04-10
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: I2C-bus controller which configures the DA7212 audio codec before the synthesizer begins to feed data to it
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------
-- Empty entity
-------------------------------------------------------------------------------

entity tb_i2c_config is
end tb_i2c_config;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture testbench of tb_i2c_config is

  -- Number of parameters to expect
  constant n_params_c     : integer := 15;
  constant n_leds_c       : integer := 4;
  constant i2c_freq_c     : integer := 20000;
  constant ref_freq_c     : integer := 50000000;
  constant clock_period_c : time    := 20 ns;

  -- Every transmission consists several bytes and every byte contains given
  -- amount of bits. 
  constant n_bytes_c       : integer := 3;
  constant bit_count_max_c : integer := 8;
  
  CONSTANT max_sclk_c : INTEGER := (ref_freq_c/i2c_freq_c)/2; -- maximum value for sclk counter corresponding to half period (25µsec)
  CONSTANT max_bit_check_c  : INTEGER := max_sclk_c + max_sclk_c/2; -- maximum value for bit read counter
  CONSTANT max_sample_c  : INTEGER := max_sclk_c; -- maximum value for bit sample

  -- Signals fed to the DUV
  signal clk   : std_logic := '0';  -- Remember that default values supported
  signal rst_n : std_logic := '0';      -- only in synthesis

  -- The DUV prototype
  component i2c_config
    generic (
      ref_clk_freq_g : integer;
      i2c_freq_g     : integer;
      n_params_g     : integer;
	    n_leds_g       : integer);
    port (
      clk              : in    std_logic;
      rst_n            : in    std_logic;
      sdat_inout       : inout std_logic;
      sclk_out         : out   std_logic;
      param_status_out : out   std_logic_vector(n_leds_g-1 downto 0);
      finished_out     : out   std_logic
      );
  end component;

  -- Signals coming from the DUV
  signal sdat         : std_logic := 'Z';
  signal sclk         : std_logic;
  signal param_status : std_logic_vector(n_leds_c-1 downto 0);
  signal finished     : std_logic;

  -- To hold the value that will be driven to sdat when sclk is high.
  signal sdat_r : std_logic;

  -- storing incoming bit for later comparison with sampled bit
  signal sdat_temp_r : std_logic;
  -- sampled bit at the middle of sclk high
  signal sdat_sample_r : std_logic;

  -- Counters for receiving bits, bytes and parameter
  signal bit_counter_r  : integer range 0 to bit_count_max_c;
  signal byte_counter_r : integer range 0 to n_bytes_c-1;
  signal param_counter_r : integer range 0 to n_params_c;
  -- counter for reading bit from param_register_ref
  signal counter_refbit_r : integer range 0 to 2*max_sclk_c;
  -- counter for sampling incoming bit
  signal counter_samplebit_r : integer range 0 to 4*max_sclk_c+1;
  -- counter for sampling incoming bit
  signal counter_sclkedge_r : integer range 0 to bit_count_max_c;

  signal nack_r : std_logic;
  signal nack_done_r : std_logic;

  -- States for the FSM
  type   states is (wait_start, read_byte, send_ack, wait_stop);
  signal curr_state_r : states;

  -- Previous values of the I2C signals for edge detection
  signal sdat_old_r : std_logic;
  signal sclk_old_r : std_logic;
  -- device address, write signal flag
  signal device_ads_flag_r : std_logic;
  signal write_flag_r : std_logic;
  signal rgstr_ads_flag_r : std_logic;
  signal datvalue_flag_r : std_logic;
  signal data_stable_flag_r : std_logic;
  
  -- array of parameter data
  TYPE  configuration_data_array is ARRAY (0 to n_params_c-1) of std_logic_vector(bit_count_max_c*n_bytes_c-1 DOWNTO 0); -- an array type with elements containing vectors of bits to be sent
  CONSTANT param_register_ref : configuration_data_array := ("001101000001110110000000", "001101000010011100000100",
                                                    "001101000010001000001011", "001101000010100000000000",
                                                    "001101000010100110000001", "001101000110100100001000",
                                                    "001101000100011111100001", "001101000110101100001001",
                                                    "001101000110110000001000", "001101000100101100001000",
                                                    "001101000100110000001000", "001101000110111010001000",
                                                    "001101000110111110001000", "001101000110111110001000",
                                                    "001101000101000111110001"); -- constant array
  -- register to store single parameter data 
  SIGNAL data_r : std_logic_vector(bit_count_max_c*n_bytes_c-1 DOWNTO 0);

  -- register to store bit
  SIGNAL bit_check_r : std_logic;

begin  -- testbench

  clk   <= not clk after clock_period_c/2;
  rst_n <= '1'     after clock_period_c*4;

  -- Assign sdat_r when sclk is active, otherwise 'Z'.
  -- Note that sdat_r is usually 'Z'
  with sclk select
    sdat <=
    sdat_r when '1',
    'Z'    when others;


  -- Component instantiation
  i2c_config_1 : i2c_config
    generic map (
      ref_clk_freq_g => ref_freq_c,
      i2c_freq_g     => i2c_freq_c,
      n_params_g     => n_params_c,
	    n_leds_g       => n_leds_c)
    port map (
      clk              => clk,
      rst_n            => rst_n,
      sdat_inout       => sdat,
      sclk_out         => sclk,
      param_status_out => param_status,
      finished_out     => finished);

  -----------------------------------------------------------------------------
  -- The main process that controls the behavior of the test bench
  fsm_proc : process (clk, rst_n)
  begin  -- process fsm_proc
    if rst_n = '0' then                 -- asynchronous reset (active low)

      curr_state_r <= wait_start;

      sdat_old_r <= '0';
      sclk_old_r <= '0';
      device_ads_flag_r <= '0';
      write_flag_r <= '0';
      rgstr_ads_flag_r <= '0';
      datvalue_flag_r <= '0';
      data_stable_flag_r <= '0';

      byte_counter_r <= 0;
      bit_counter_r  <= 0;
      param_counter_r <= 0;
      counter_refbit_r <= 0;
      counter_samplebit_r <= 0;
      counter_sclkedge_r <= 0;

      nack_r <= '0';
      nack_done_r <= '0';

      sdat_r <= 'Z';
      sdat_sample_r <= '0';
      sdat_temp_r <= '0';

      bit_check_r <= '0';
      
    elsif clk'event and clk = '1' then  -- rising clock edge

      -- The previous values are required for the edge detection
      sclk_old_r <= sclk;
      sdat_old_r <= sdat;


      -- Falling edge detection for acknowledge control
      -- Must be done on the falling edge in order to be stable during
      -- the high period of sclk
      if sclk = '0' and sclk_old_r = '1' then

        -- If we are supposed to send ack
        if curr_state_r = send_ack then

          -- Send ack (low = ACK, high = NACK)
          if (param_counter_r = 7 and byte_counter_r = 2) and nack_done_r = '0' then
            sdat_r <= '1';
            nack_r <= '1';
          else
            sdat_r <= '0';
            nack_r <= '0';
          end if;

        else

          -- Otherwise, sdat is in high impedance state.
          sdat_r <= 'Z';
          
        end if;
        
      end if;


      -------------------------------------------------------------------------
      -- FSM
      case curr_state_r is

        -----------------------------------------------------------------------
        -- Wait for the start condition
        when wait_start =>

          data_r <= param_register_ref(param_counter_r);
          -- While clk stays high, the sdat falls
          if sclk = '1' and sclk_old_r = '1' and
            sdat_old_r = '1' and sdat = '0' then

            curr_state_r <= read_byte;
            counter_refbit_r <= counter_refbit_r + 1;

          end if;

          --------------------------------------------------------------------
          -- Wait for a byte to be read
        when read_byte =>
          -- reading bit from reference parameter register
          -- to check with transmitted parameter
          counter_refbit_r <= counter_refbit_r + 1;
          counter_samplebit_r <= counter_samplebit_r + 1;
          if counter_refbit_r = max_bit_check_c - 1 AND bit_counter_r = 0 then
            bit_check_r <= data_r(bit_count_max_c*n_bytes_c-1);                  
            data_r <= data_r(bit_count_max_c*n_bytes_c-2 downto 0) & '0'; 
            counter_refbit_r <= 0;
            counter_samplebit_r <= 0;
          elsif counter_refbit_r = 2*max_sclk_c - 1 AND bit_counter_r /= 0 then
            bit_check_r <= data_r(bit_count_max_c*n_bytes_c-1);                  
            data_r <= data_r(bit_count_max_c*n_bytes_c-2 downto 0) & '0'; 
            counter_refbit_r <= 0;
            counter_samplebit_r <= 0;
          end if;

          -- sample incoming bit at the mid of high SCLK         
          if counter_sclkedge_r /= 0 and counter_samplebit_r = max_sample_c then
            sdat_sample_r <= sdat;
          end if;
          -- compare sampled bit at next clock edge with the bit 
          -- received at the rising SCLK to verify data is stable
          if counter_sclkedge_r /= 0 and counter_samplebit_r = max_sample_c+1 then
            if sdat_sample_r /=  sdat_temp_r then
              data_stable_flag_r <= '1';
            end if;
          end if;
  
          -- Detect a rising edge
          if sclk = '1' and sclk_old_r = '0' then
            counter_sclkedge_r <= counter_sclkedge_r + 1;
            sdat_temp_r <= sdat; -- storing incoming bit at rising edge
            -- Verify the correctness of device address, 
            -- write bit, register address and data value
            if byte_counter_r = 0 then
              if sdat /= bit_check_r and bit_counter_r /= bit_count_max_c - 1 then
                device_ads_flag_r <= '1';
              elsif sdat /= bit_check_r and bit_counter_r = bit_count_max_c - 1 then
                write_flag_r <= '1';
              end if;            
            elsif byte_counter_r = 1 then
              if sdat /= bit_check_r then
                rgstr_ads_flag_r <= '1';
              end if;
            elsif byte_counter_r = 2 then
              if sdat /= bit_check_r then
                datvalue_flag_r <= '1';
              end if;           
            end if;           

            if bit_counter_r /= bit_count_max_c - 1 then

              -- Normally just receive a bit
              bit_counter_r <= bit_counter_r + 1;

            end if;

            if bit_counter_r = bit_count_max_c-1 then

              -- When terminal count is reached, let's send the ack
              counter_refbit_r <= 0;
              curr_state_r  <= send_ack;
              bit_counter_r <= 0;

            end if;  -- Bit counter terminal count
            
          end if;  -- sclk rising clock edge

          --------------------------------------------------------------------
          -- Send acknowledge
        when send_ack =>
          counter_samplebit_r <= counter_samplebit_r + 1;
          -- sample incoming bit at the mid of high SCLK         
          if counter_sclkedge_r /= 0 and counter_samplebit_r = max_sample_c then
            sdat_sample_r <= sdat;
          end if;

          -- compare sampled bit at next clock edge with the bit 
          -- received at the rising SCLK to verify data is stable
          if counter_sclkedge_r /= 0 and counter_samplebit_r = max_sample_c+1 then
            if sdat_sample_r /=  sdat_temp_r then
              data_stable_flag_r <= '1';
            end if;
          end if;

          -- Detect a rising edge
          if sclk = '1' and sclk_old_r = '0' then
            counter_sclkedge_r <= 0;
            sdat_temp_r <= sdat; -- storing incoming bit at rising edge

            if byte_counter_r /= n_bytes_c-1 then

              -- Transmission continues
              byte_counter_r <= byte_counter_r + 1;
              curr_state_r   <= read_byte;
              
            else

              -- Transmission is about to stop
              byte_counter_r <= 0;
              curr_state_r   <= wait_stop;
              --param_counter_r <= param_counter_r + 1;

              if nack_r = '1' and nack_done_r = '0' then
                param_counter_r <= param_counter_r;
                nack_done_r    <= '1';
              else
                param_counter_r <= param_counter_r + 1;
              end if;
              
            end if;

          end if;

          ---------------------------------------------------------------------
          -- Wait for the stop condition
        when wait_stop =>

          -- Stop condition detection: sdat rises while sclk stays high
          if sclk = '1' and sclk_old_r = '1' and
            sdat_old_r = '0' and sdat = '1' then

            curr_state_r <= wait_start;
            
          end if;

      end case;

    end if;
  end process fsm_proc;

  -----------------------------------------------------------------------------
  -- Asserts for verification
  -----------------------------------------------------------------------------

  -- SDAT should never contain X:s.
  assert sdat /= 'X' report "Three state bus in state X" severity error;
 -- Device address should be correct
 assert device_ads_flag_r /= '1' report "Device address incorrect" severity error;
 -- Controller should sent write
 assert write_flag_r /= '1' report "W/R bit incorrectly set" severity error;
 -- register address should be correct
 assert rgstr_ads_flag_r /= '1' report "Codec register address incorrect" severity error;
 -- data value should be correct
 assert datvalue_flag_r /= '1' report "Data value transmitted incorrect" severity error;
-- data value should be correct
assert data_stable_flag_r /= '1' report "Transmitted data not stable" severity error;

  -- End of simulation, but not during the reset
  assert finished = '0' or rst_n = '0' report
    "Simulation done" severity failure;
  
end testbench;
