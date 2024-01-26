LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.lock_pkg.ALL;

ENTITY lock IS

   PORT (
      clk      : IN  STD_LOGIC;
      rst_n    : IN  STD_LOGIC;
      keys_in  : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
      lock_out : OUT STD_LOGIC
      );

END lock;



ARCHITECTURE RTL OF lock IS

   SIGNAL curr_state_r : state_type;
   SIGNAL next_state   : state_type;

   SIGNAL reset_counter_r : BOOLEAN;

BEGIN  -- RTL

   ---------------------------------------------------------------------
   -- purpose: State Transitions
   -- type   : combinational
   -- inputs : curr_state_r
   -- outputs: lock_out
   ---------------------------------------------------------------------
   STTRAN            : PROCESS (curr_state_r, keys_in, reset_counter_r)
      VARIABLE count_v : INTEGER;
   BEGIN  -- PROCESS STTRAN

      -- Default output
      lock_out <= '0';

      IF (reset_counter_r = TRUE) THEN
         count_v := 0;
      ELSE
         count_v := count_v;
      END IF;

      CASE (curr_state_r) IS

         WHEN init =>
            IF (to_integer(UNSIGNED(keys_in)) = first_c) THEN
               next_state <= code_1;
            ELSE
               next_state <= init;
            END IF;

         WHEN code_1 =>
            IF (to_integer(UNSIGNED(keys_in)) = second_c) THEN
               next_state <= code_2;
            ELSE
               next_state <= init;
            END IF;

         WHEN code_2 =>
            IF (to_integer(UNSIGNED(keys_in)) = third_c) THEN
               next_state <= code_3;
            ELSE
               next_state <= init;
            END IF;

         WHEN code_3 =>
            IF (to_integer(UNSIGNED(keys_in)) = fourth_c) THEN
               lock_out <= '1';
               count_v := count_v + 1;
            ELSE
               lock_out <= '0';
            END IF;
            next_state  <= init;

         WHEN OTHERS =>
            next_state <= init;

      END CASE;

   END PROCESS STTRAN;

   ---------------------------------------------------------------------
   -- purpose: State Registers
   -- type   : sequential
   -- inputs : clk, rst_n
   -- outputs: curr_state_r
   ---------------------------------------------------------------------
   STREG : PROCESS (clk, rst_n)
   BEGIN  -- PROCESS STREG

      IF (rst_n = '0') THEN             -- asynchronous reset (active low)
         curr_state_r    <= init;
         reset_counter_r <= TRUE;
      ELSIF (clk'EVENT AND clk = '1') THEN  -- rising clock edge
         curr_state_r    <= next_state;
         reset_counter_r <= FALSE;
      END IF;

   END PROCESS STREG;

END RTL;
