-------------------------------------------------------------------------------
-- Title      : tb_lock
-- Project    : 
-------------------------------------------------------------------------------
-- File       : tb_lock.vhd
-- Author     :   <alhonena@BUMMALO>
-- Company    : 
-- Last update: 2008/06/18
-- Platform   : 
-------------------------------------------------------------------------------
-- Description: Testbench for lock.
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2008/06/18  1.0      alhonena	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lock_pkg.all;

entity tb_lock is
  -- Entity with no ports; clock and reset is generated in the testbench.
  -- Remember that this kind of clock generation works only in the simulation.
end tb_lock;

architecture testbench of tb_lock is

  signal clk, rst_n : std_logic := '0';
  constant clock_period_c : time := 20 ns;
  
  type intarray is array (0 to 3) of integer range 0 to 9;
  constant correct_sequence_c : intarray := (4,1,6,9);

  type state_type is (send1, send2, send3, send4, increment);
  signal state_r : state_type;

  signal current_value_r : intarray;

  component lock
    port (
      clk      : IN  STD_LOGIC;
      rst_n    : IN  STD_LOGIC;
      keys_in  : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
      lock_out : OUT STD_LOGIC);
  end component;

  signal simulated_keys_r : std_logic_vector(3 downto 0);
  signal lock_status : std_logic;
  
begin  -- testbench

  clk <= not clk after clock_period_c;
  rst_n <= '1' after clock_period_c*2;

  -- instantiation of the DUV, device under verification.
  lock_inst: lock
    port map (
        clk      => clk,
        rst_n    => rst_n,
        keys_in  => simulated_keys_r,
        lock_out => lock_status);

  -- All possible sequences are tried in this FSM.
  FSM: process (clk, rst_n)
  begin  -- process FSM
    if rst_n = '0' then                 -- asynchronous reset (active low)
      state_r <= send1;

      current_value_r <= (others => 0);
      
    elsif clk'event and clk = '1' then  -- rising clock edge
      case state_r is
        when send1 => simulated_keys_r <=
                        std_logic_vector(to_unsigned(current_value_r(0),4));
                      state_r <= send2;
        when send2 => simulated_keys_r <=
                        std_logic_vector(to_unsigned(current_value_r(1),4));
                      state_r <= send3;
        when send3 => simulated_keys_r <=
                        std_logic_vector(to_unsigned(current_value_r(2),4));
                      state_r <= send4;
        when send4 => simulated_keys_r <=
                        std_logic_vector(to_unsigned(current_value_r(3),4));
                      state_r <= increment;
        when increment => if current_value_r(0) = 9 then
                            current_value_r(0) <= 0;
                            if current_value_r(1) = 9 then
                              current_value_r(1) <= 0;
                              if current_value_r(2) = 9 then
                                current_value_r(2) <= 0;
                                if current_value_r(3) = 9 then  -- the last one
                                  assert false report
                                    "Simulation completed succesfully!"
                                    severity failure;
                                else
                                  current_value_r(3) <= current_value_r(3) + 1;
                                end if;
                              else
                                current_value_r(2) <= current_value_r(2) + 1;
                              end if;
                            else
                              current_value_r(1) <= current_value_r(1) + 1;
                            end if;
                          else
                            current_value_r(0) <= current_value_r(0) + 1;
                          end if;

                        state_r <= send1;
                              
        when others => null;
      end case;
    end if;
  end process FSM;

  -- Process that checks if the door opens with a wrong sequence or if
  -- the door doesn't open with the correct sequence.
  check: process (clk, rst_n)
  begin  -- process check
    if rst_n = '0' then                 -- asynchronous reset (active low)

    elsif clk'event and clk = '1' then  -- rising clock edge

      if lock_status = '1' then
        assert current_value_r = correct_sequence_c
          report "Lock opens with a wrong sequence!" severity failure;
      end if;

      -- The DUV should open the door after the fourth digit was
      -- sent, that is, when the state_r is 'increment'.
      if current_value_r = correct_sequence_c and state_r = increment then
        assert lock_status = '1'
          report "Lock does not open with the correct sequence!"
          severity failure;
      end if;
    end if;
  end process check;

end testbench;
