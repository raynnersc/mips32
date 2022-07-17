library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
 
entity timer is
   port(
      clk    	: in  std_logic;
      reset  	: in  std_logic;
      we     	: in  std_logic;
      target   : in  std_logic_vector(31 downto 0);
		
      finish   : out std_logic;
      count   	: out std_logic_vector(31 downto 0)
		);
end entity timer;

architecture Behave of timer is
   
   signal cnt      : integer := 0;
	
begin

   do_timer:
   process (clk,we,reset,target)
   begin
		
		if (reset='1') then
		
			cnt <= 0;
			finish <= '0';
	
      elsif rising_edge(clk) then
		
         if (we='1') then

				if(cnt <= to_integer(unsigned(target))) then
				
					cnt <= cnt + 1;
					finish <= '0';
					
				else
				
					finish <= '1';
				
				end if;
         
         end if; 
			
      end if; 
		
		count <= std_logic_vector(to_unsigned(cnt, count'length));
		
   end process do_timer;

end architecture Behave;
