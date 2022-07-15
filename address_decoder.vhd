library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--Memory map:

--0x003F – 0x0000 : MMIO (64)
--0x0FFF – 0x0040 : MEMI (4096)
--0x1000 - 0x1FFF : MEMD (4096)



entity address_decoder is
	 generic(
		ADDR_PC_WIDTH 		: natural;
		ADDR_WIDTH 			: natural;
		ADDR_MEMD_WIDTH 	: natural;
		ADDR_MEMI_WIDTH 	: natural;
		ADDR_PERIPH_WIDTH : natural
	 );
    port (
		we						: in  std_logic;
		addr_pc				: in	std_logic_vector(ADDR_PC_WIDTH - 1 downto 0);
		addr					: in	std_logic_vector(ADDR_WIDTH - 1 downto 0);
		addr_memd			: out std_logic_vector(ADDR_MEMD_WIDTH - 1 downto 0);
		addr_memi			: out std_logic_vector(ADDR_MEMI_WIDTH - 1 downto 0);
		addr_periph			: out std_logic_vector(ADDR_PERIPH_WIDTH - 1 downto 0);
		sel_read_device	: out std_logic_vector(1 downto 0);	-- 0:MEMD ; 1:GPIO  ; 2:UART ; 3:TIMER
		we_memd				: out std_logic;
		we_gpio				: out std_logic;
		we_uart				: out std_logic;
		we_timer				: out std_logic
    );
end address_decoder;


architecture beh OF address_decoder IS
	begin
	process(addr, addr_pc, we) is
	begin
		case to_integer(unsigned(addr)) is
			when 0 to 9 =>                         --GPIO
				addr_memd 			<= x"000";
				addr_periph			<= addr(5 downto 0);
				sel_read_device	<= "01";
				we_memd   			<= '0';
				we_gpio   			<= we;
				we_uart   			<= '0';
				we_timer   			<= '0';
			when 10 to 13 =>                        --UART
				addr_memd 			<= x"000";
				addr_periph			<= addr(5 downto 0);
				sel_read_device	<= "10";
				we_memd   			<= '0';
				we_gpio   			<= '0';
				we_uart   			<= we;
				we_timer   			<= '0';	
			when 14 to 21 =>                        --TIMER
				addr_memd 			<= x"000";
				addr_periph			<= addr(5 downto 0);
				sel_read_device	<= "11";
				we_memd   			<= '0';
				we_gpio   			<= '0';
				we_uart   			<= '0';
				we_timer   			<= we;
			when 4096 to 8191 =>                    --MEMD
				addr_memd 			<= std_logic_vector(unsigned(addr) - 4096)(11 downto 0);
				addr_periph			<= "000000";
				sel_read_device	<= "00";
				we_memd   			<= we;
				we_gpio   			<= '0';
				we_uart   			<= '0';
				we_timer   			<= '0';
			when others =>
				addr_memd 			<= x"000";
				addr_periph			<= "000000";
				sel_read_device	<= "00";
				we_memd   			<= '0';
				we_gpio   			<= '0';
				we_uart   			<= '0';
				we_timer   			<= '0';
		end case;
		
		addr_memi <= std_logic_vector(unsigned(addr_pc) - 64); --Removendo offset do espaço de memória destinado aos periféricos
		
	end process;
	
end beh;