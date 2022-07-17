library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
 
entity tb_timer is
		generic(
			DATA_WIDTH		: natural := 32
		);
end entity tb_timer;

architecture beh of tb_timer is

	component timer_ctl is
		generic(
			DATA_WIDTH		: natural := 32
		);
		port(
			clock				: in std_logic;
			reset				: in std_logic;
			
			reg_addr			: in std_logic_vector(4 downto 0);
			data_in			: in std_logic_vector(DATA_WIDTH-1 downto 0);
			write_enable	: in std_logic;
			data_out			: out std_logic_vector(DATA_WIDTH-1 downto 0);
			inter_out		: out std_logic_vector(1 downto 0)
			);
	end component;

	signal clock				: std_logic := '0';
	signal reset				: std_logic := '1';
	
	signal reg_addr			: std_logic_vector(4 downto 0) := (others => '0');
	signal data_in				: std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal write_enable		: std_logic := '0';
	signal data_out			: std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal inter_out			: std_logic_vector(1 downto 0) := (others => '0');
	
	constant clock_half_period : time := 10 ns;
	
begin


	instancia_timer : timer_ctl
		generic map(
			DATA_WIDTH => DATA_WIDTH 
		)
		port map(
			clock	=> clock,
			reset	=> reset,
			reg_addr => reg_addr,
			data_in => data_in,
			write_enable => write_enable,
			data_out	=> data_out,
			inter_out => inter_out
		);
	
	clock <= not clock after clock_half_period;
	
	process
	
		begin
			
			wait for clock_half_period*3;
			reset <= '0';
			
			--Write TargetA:
			write_enable 	<= '1';
			reg_addr			<= "01111";
			data_in			<=	x"00000030";	--Conta até 48
			
			wait for clock_half_period*2;
			
			--Write ConfigA:
			reg_addr			<= "01110";
			data_in			<=	x"0000000" & "1001";				--Clock dividido por 16, já ativa a contagem  -> 15,36us
			
			wait for clock_half_period*2;
			
			--Keep reading CountA until interupt set up
			write_enable 	<= '0';
			reg_addr			<= "10001";
			
			wait until  inter_out(0) = '1';
			wait for clock_half_period*2;
			
			--Clear interrupt and reset timer
			write_enable 	<= '1';
			reg_addr			<= "10000";
			data_in			<=	x"00000001";
			
			wait for clock_half_period*2;
			
			--Write TargetB:
			reg_addr			<= "10011";
			data_in			<=	x"00000300";	--Conta até 768
			
			wait for clock_half_period*2;
			
			--Write ConfigB:
			reg_addr			<= "10010";	
			data_in			<=	x"00000001";				--Clock de 50MHz, já ativa a contagem	-> 15,36us
			
			wait for clock_half_period*2;
			
			--Keep reading CountB until interupt set up
			write_enable 	<= '0';
			reg_addr			<= "10101";
			
			wait until  inter_out(1) = '1';
			wait for clock_half_period*2;
			
			--Clear interrupt and reset timer
			write_enable 	<= '1';
			reg_addr			<= "10100";
			data_in			<=	x"00000001";
			
			wait for clock_half_period*2;
	
	end process;
	

end architecture beh;