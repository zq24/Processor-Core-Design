library ieee;
use ieee.std_logic_1164.all;
--use ieee.std_logic_unsigned.all;
--use ieee.std_logic_arith.all;
use IEEE.NUMERIC_STD.all;

ENTITY signextended IS
GENERIC(
	input_width : NATURAL := 17
);
PORT (
	immediate : IN STD_LOGIC_VECTOR(input_width - 1 DOWNTO 0);
	ext_immediate : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
);
END ENTITY;

ARCHITECTURE structure OF signextended IS
BEGIN
	ext_immediate <= STD_LOGIC_VECTOR(RESIZE(SIGNED(immediate), 32));
END structure;
