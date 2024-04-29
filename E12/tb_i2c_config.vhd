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
  constant n_leds_c : integer := 4;
  constant i2c_freq_c     : integer := 20000;
  constant ref_freq_c     : integer := 50000000;
  constant clock_period_c : time    := 20 ns;

  -- Every transmission consists several bytes and every byte contains given
  -- amount of bits. 
  constant n_bytes_c       : integer := 3;
  constant bit_count_max_c : integer := 8;

  -- Signals fed to the DUV
  signal clk   : std_logic := '0';  -- Remember that default values supported
  signal rst_n : std_logic := '0';      -- only in synthesis

  -- The DUV prototype
  component i2c_config
    generic (
      ref_clk_freq_g : integer;
      i2c_freq_g     : integer;
      n_params_g     : integer;
	  n_leds_g : integer);
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

  -- Counters for receiving bits and bytes
  signal bit_counter_r  : integer range 0 to bit_count_max_c-1;
  signal byte_counter_r : integer range 0 to n_bytes_c-1;

  -- States for the FSM
  type   states is (wait_start, read_byte, send_ack, wait_stop);
  signal curr_state_r : states;

  -- Previous values of the I2C signals for edge detection
  signal sdat_old_r : std_logic;
  signal sclk_old_r : std_logic;

  type data_type is array (n_params_c-1 downto 0) of std_logic_vector(bit_count_max_c*n_bytes_c-1 downto 0);
  signal data_register_r : std_logic_vector(bit_count_max_c*n_bytes_c - 1 downto 0);
  signal byte_register_r : std_logic_vector(bit_count_max_c - 1 downto 0);
  signal sdat_register_r : std_logic_vector(bit_count_max_c - 1 downto 0);
  signal param_counter_r : integer range 0 to n_params_c;
  signal nack_r : std_logic := '0';
  signal nack_done_r : std_logic := '0';
  constant delay_c : integer := 300;
  signal wait_delay_r : integer range 0 to 1000;


  constant data_transfer_c : data_type := ("001101000001110110000000", "001101000010011100000100",
                                           "001101000010001000001011", "001101000010100000000000", 
                                           "001101000010100110000001", "001101000110100100001000",
                                           "001101000110101000000000", "001101000100011111100001", 
                                           "001101000110101100001001", "001101000110110000001000", 
                                           "001101000100101100001000", "001101000100110000001000", 
                                           "001101000110111010001000", "001101000110111110001000", 
                                           "001101000101000111110001");
  
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
	  n_leds_g => n_leds_c)
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

      byte_counter_r <= 0;
      bit_counter_r  <= 0;
      param_counter_r <= 0;

      sdat_r <= 'Z';

      data_register_r <= (OTHERS => '0');
      byte_register_r <= (OTHERS => '0');
      sdat_register_r <= (OTHERS => '0');
      nack_r <= '0';
      nack_done_r <= '0';
      
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
          if (param_counter_r = 3 and byte_counter_r = 0) and nack_done_r = '0'  then
            sdat_r <= '1';
            nack_r <= '1';
          else
            sdat_r <= '0';
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
          
          if sclk = '1' and sclk_old_r = '1' then
            if wait_delay_r = delay_c and sdat_old_r = '1' and sdat = '0'  then
              curr_state_r <= read_byte;
            elsif wait_delay_r /= delay_c then
              wait_delay_r <= wait_delay_r+1;
            end if;
          end if;

          --------------------------------------------------------------------
          -- Wait for a byte to be read
        when read_byte =>
          wait_delay_r <= 0;
          -- Detect a rising edge
          if sclk = '1' and sclk_old_r = '0' then

            if bit_counter_r /= bit_count_max_c-1 then

              -- Normally just receive a bit
              bit_counter_r <= bit_counter_r + 1;

            else

              -- When terminal count is reached, let's send the ack
              curr_state_r  <= send_ack;
              bit_counter_r <= 0;

            end if;  -- Bit counter terminal count

            if bit_counter_r /= bit_count_max_c then
              sdat_register_r((bit_count_max_c - bit_counter_r) - 1) <= sdat;
              data_register_r  <= data_transfer_c((n_params_c - param_counter_r) - 1);
              byte_register_r <= data_register_r((bit_count_max_c * (n_bytes_c - byte_counter_r) - 1)
                                                  downto ((bit_count_max_c * ((n_bytes_c - 1) - byte_counter_r))));
            else
              if (param_counter_r = 3) and (nack_r = '0')
                and (byte_counter_r = 0) and (bit_counter_r = bit_count_max_c) then
                sdat_r         <= '1';
                nack_r         <= '1';
              end if;
            end if;
            
          end if;  -- sclk rising clock edge

          --------------------------------------------------------------------
          -- Send acknowledge
        when send_ack =>


          -- Detect a rising edge
            
          if sclk = '1' and sclk_old_r = '0' then

            if nack_r = '1' and nack_done_r = '0' then
              param_counter_r <= param_counter_r;
              nack_done_r    <= '1';
              byte_counter_r <= 0;
              curr_state_r   <= wait_stop;

            elsif byte_counter_r /= n_bytes_c-1 then

              -- Transmission continues
              byte_counter_r <= byte_counter_r + 1;
              curr_state_r   <= read_byte;

            else
              -- Transmission is about to stop
              byte_counter_r <= 0;
              curr_state_r   <= wait_stop;
              param_counter_r <= param_counter_r + 1;
            end if;

            if byte_counter_r = 0 then
              assert sdat_register_r = byte_register_r report "Audio codec address is incorrect" severity error;
            end if;

            if byte_counter_r = 1 then
              assert sdat_register_r = byte_register_r report "Register address is incorrect" severity error;
            end if;

            if byte_counter_r = 2 then
              assert sdat_register_r = byte_register_r report "Configuration Value is incorrect" severity error;
            end if;

          end if;

          ---------------------------------------------------------------------
          -- Wait for the stop condition
        when wait_stop =>
 
          --sdat_r <= 'Z';

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


  -- End of simulation, but not during the reset
  assert finished = '0' or rst_n = '0' report
    "Simulation done" severity failure; 
end testbench;