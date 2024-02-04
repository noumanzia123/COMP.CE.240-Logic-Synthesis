<<<<<<< HEAD
-------------------------------------------------------------------------------
-- Title      : TKT-1212, Exercise 03
-- Project    : 
-------------------------------------------------------------------------------
-- File       : adder.vhd
-- Author     : David Rama Jimeno, Nouman Zia
-- Group number : 6
-- Company    : TUNI
-- Created    : 2023-01-16
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: An RTL based synchronous adder which has n-bit inputs and the output width n+1 bits
-------------------------------------------------------------------------------

-- Include  libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Declare entity
ENTITY adder IS
    generic (
        operand_width_g : integer);

    port (
        clk : in std_logic;
        rst_n : in std_logic;
        a_in : in std_logic_vector(operand_width_g-1 downto 0);
        b_in : in std_logic_vector(operand_width_g-1 downto 0);
        sum_out : out std_logic_vector(operand_width_g downto 0)
        );   
END adder ;
-------------------------------------------------------------------------------

-- Architecture called 'rtl' is  defined

architecture rtl of adder is

signal out_r: signed(operand_width_g downto 0); -- internal signal (reg)

begin -- rtl
    sum_out <= std_logic_vector(out_r);

    adder_sync : process (clk, rst_n) 

    begin -- process adder
    
        if rst_n = '0' then -- asynchronous reset (active low)
            out_r <= (others => '0');

        elsif clk'event and clk = '1' then -- rising clock edge
            -- the data types of input signals converted to signed and bit widths are matched to the output
            out_r <= resize(signed(a_in), operand_width_g+1) + resize(signed(b_in), operand_width_g+1);
            
    
        end if;

    end process adder_sync;

end rtl;

=======

-------------------------------------------------------------------------------
-- Title      : TKT-1212, Exercise 03
-------------------------------------------------------------------------------
-- File       : adder.vhd
-- Author     : David Rama Jimeno & Nouman Zia
-- Group      : HRH056
-- Company    : TUT/DCS
-- Created    : 20.01.2024
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Program all combinations of summing two n-bit values
-------------------------------------------------------------------------------


LIBRARY ieee;
USE ieee.std_logic_1164.ALL; --This library is needed in order to be able to use the "std_logic data type"
USE ieee.numeric_std.ALL;


ENTITY adder IS
   GENERIC(
      operand_width_g :integer
      );
   PORT(
      clk     : IN STD_LOGIC;
      rst_n   : IN  STD_LOGIC;
      a_in    : IN STD_LOGIC_VECTOR(operand_width_g-1 DOWNTO 0);
      b_in    : IN STD_LOGIC_VECTOR(operand_width_g-1 DOWNTO 0); 
      sum_out : OUT STD_LOGIC_VECTOR(operand_width_g DOWNTO 0)
      );
END ADDER;

ARCHITECTURE RTL OF adder IS

SIGNAL sum_signed      : SIGNED(operand_width_g DOWNTO 0);

BEGIN

   sum_out <= std_logic_vector(sum_signed); --Reconverted to std_logic as we want the output in such data type

---------------------------------------------------------------------
   -- purpose: State Registers
   -- type   : sequential
   -- inputs : clk, rst_n
---------------------------------------------------------------------
   STREG : PROCESS (clk, rst_n)
   BEGIN  -- PROCESS STREG

      IF (rst_n = '0') THEN             -- asynchronous reset (active low)
	 sum_signed <= (OTHERS=>'0');
      ELSIF (clk'EVENT AND clk = '1') THEN  -- rising clock edge
	 sum_signed <= resize(signed(a_in),operand_width_g+1)+ --resized with the width of sum_out
                       resize(signed(b_in),operand_width_g+1); --converted to signed so they can be summed
      END IF;
   END PROCESS STREG;

END RTL;
>>>>>>> f0eeb963188abd7c0c6a788276acca3166fd7d87
