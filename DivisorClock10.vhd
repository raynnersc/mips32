library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DivisorClock10 is
	port 
	(
		CLOCK_50MHz : in std_logic;
		reset	      : in std_logic;
		CLOCK_10Hz   : out std_logic
	);

end entity;

architecture rtl of DivisorClock10 is
	
begin

	process (CLOCK_50MHz,reset)
		variable cnt : integer range 0 to 2500;
		variable clk : std_logic:='0';
	begin
		if (rising_edge(CLOCK_50MHz)) then
		   if (cnt = 2500) then
			   clk := not clk;
				cnt := 0;
			else
		      cnt := cnt + 1;	
			end if;
		end if;
		CLOCK_10Hz <= clk;
	end process;

end rtl;