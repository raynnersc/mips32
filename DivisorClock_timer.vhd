library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DivisorClock_timer is
	port 
	(
		CLOCK_in : in std_logic;
		CLOCK_out   : out std_logic;
		div_factor	: in	std_logic_vector(7 downto 0)
	);

end entity;

architecture rtl of DivisorClock_timer is
	
begin

	process (CLOCK_in, div_factor)
		variable cnt : integer := 0;
		variable clk : std_logic:='0';
	begin
		if(to_integer(unsigned(div_factor))=1) then
			clk := CLOCK_in;
		elsif (rising_edge(CLOCK_in)) then
		   if (cnt = (to_integer(unsigned(div_factor))-1)/2 ) then
			   clk := not clk;
				cnt := 0;
			else
		      cnt := cnt + 1;	
			end if;
		end if;
		CLOCK_out <= clk;
	end process;

end rtl;