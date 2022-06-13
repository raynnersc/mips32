library ieee;
use ieee.std_logic_1164.all;

entity hazard_unit is
	generic(
		fr_addr_width : natural
	);
	port (
		StallPC	: out std_logic;
		StallA	: out std_logic;
		--StallB	: out std_logic;
		FlushA	: out std_logic;
		FlushB	: out std_logic;
		FowardAC	: out std_logic;
		FowardBC	: out std_logic;
		
		Current_Rs_Addr    	: in std_logic_vector(fr_addr_width - 1 downto 0);
		Current_Rt_Addr    	: in std_logic_vector(fr_addr_width - 1 downto 0);
		Previous_Rdest_Addr 	: in std_logic_vector(fr_addr_width - 1 downto 0);
		--Previous_Reg_we		: in std_logic;
		Sel_Rdest_Data       : in std_logic_vector(2 downto 0);
		Sel_PC_Src				: in std_logic_vector(2 downto 0)	
	);
end entity;

architecture comportamental of hazard_unit is

	signal lwstall : std_logic;
	
begin

	process (Current_Rs_Addr,Current_Rt_Addr,Previous_Rdest_Addr,Sel_Rdest_Data,Sel_PC_Src) is
	begin
	
	
		if (Sel_PC_Src /= "000") then 
			FlushA <= '1';
		else
			FlushA <= '0';
		end if;
		
		if( ( (Current_Rs_Addr = Previous_Rdest_Addr) OR (Current_Rt_Addr = Previous_Rdest_Addr) ) AND (Sel_Rdest_Data = "001") ) then
			StallPC <= '0';
			StallA <= '0';
			FlushB <= '1';
		else
			StallPC <= '1';
			StallA <= '1';
			FlushB <= '0';
		end if;
		
		if ((Current_Rs_Addr/="00000") AND (Current_Rs_Addr = Previous_Rdest_Addr)) then
			FowardAC <= '1';
		else
			FowardAC <= '0';
		end if;

		if ((Current_Rt_Addr/="00000") AND (Current_Rt_Addr = Previous_Rdest_Addr)) then
			FowardBC <= '1';
		else
			FowardBC <= '0';
		end if;
		
	end process;
	
end comportamental;