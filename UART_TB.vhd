 ----------------------------------------------------------------------
-- File Downloaded from http://www.nandland.com
----------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
 
entity uart_tb is
end uart_tb;
 
architecture behave of uart_tb is
 
component UART_CTL is
	generic(
		clocks_pbit_width : natural := 19; --Min standard baud rate is 110 and max clock em DE10 is 50MHz, which yields 454545 clocks per bit. 19 bits is enough for this.
		tx_setup_width		: natural := 9; --8 bits de dado e 1 bit de configuração (MSB)
		DATA_WIDTH			: natural := 32
	);
	port(
		clock				: in std_logic;
		reset				: in std_logic;
		
		tx					: out std_logic;
		rx					: in std_logic;
		
		reg_addr			: in std_logic_vector(3 downto 0);
		data_in			: in std_logic_vector(DATA_WIDTH-1 downto 0);
		write_enable	: in std_logic;
		data_out			: out std_logic_vector(DATA_WIDTH-1 downto 0);
		inter_out		: out std_logic_vector(1 downto 0)
		
	);
end component;
 
  constant clk_half_period : time := 10 ns;
   
		signal clock				: std_logic := '0';
		signal reset				: std_logic := '0';
		
		signal tx_rx				: std_logic := '1';
		
		signal reg_addr			: std_logic_vector(3 downto 0) := (others=>'0');
		signal data_in				: std_logic_vector(31 downto 0) := (others=>'0');
		signal write_enable		: std_logic := '0';
		signal data_out			: std_logic_vector(31 downto 0);
		signal inter_out			: std_logic_vector(1 downto 0);
   
begin
 
  -- Instantiate UART transmitter

  
   instancia_uart : UART_CTL
	port map(
		clock	=> clock,				
		reset	=> reset,	
		
		tx	=> tx_rx,			
		rx	=> tx_rx,				
		
		reg_addr	=> reg_addr,	
		data_in	=> data_in,		
		write_enable => write_enable,	
		data_out	=> data_out,		
		inter_out	=> inter_out
	);
  
 
  clock <= not clock after clk_half_period;
   
  process is
  begin
 
	reset <='1';
	wait for clk_half_period*4;
	reset <='0';
	
	--Config baud rate: Clock is 50MHz, i want 256000, so i need 195 clocks per bit (C3 em HEXA)
	
	reg_addr <= x"A";
	data_in	<=	x"000000C3";
	write_enable <='1';	
	wait for clk_half_period*4;
	
	--Setup TX
	reg_addr <= x"C";
	data_in	<=	x"000001AB";
	wait for clk_half_period*4;
	write_enable <='0';	
	
	--Read TX status
	reg_addr <= x"D";
	
	--Wait till Rx receive data
	wait until inter_out(0)='1';
	
	--Then read data
	reg_addr <= x"B";
	
  end process;
   
end behave;