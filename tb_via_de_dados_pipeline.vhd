-- Universidade Federal de Minas Gerais
-- Escola de Engenharia
-- Departamento de Engenharia Eletrônica
-- Autoria: Professor Ricardo de Oliveira Duarte
-- Testbench para o via_de_dados_ciclo_unico
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- Este arquivo irá gerar um sinal de clock e reset de modo a possibilitar a simulação do DUT via_de_dados_ciclo_unico

entity tb_via_de_dados_ciclo_unico is
end tb_via_de_dados_ciclo_unico;

architecture estimulos of tb_via_de_dados_ciclo_unico is
	-- Declarar a unidade sob teste
	component via_de_dados_ciclo_unico
		port (
		Chave_reset  : in std_logic;
		Clock   : in std_logic;
		controle_in        : in std_logic_vector(in_ctrl_bus_width - 1 downto 0);
		controle_out        : out std_logic_vector(out_ctrl_bus_width - 1 downto 0);
		 --barramento que vem do C0
		c0_bus_in          : in std_logic_vector(c0_bus_in_width - 1 downto 0);  
		c0_bus_out          : out std_logic_vector(c0_bus_out_width - 1 downto 0);  
		data_mem_data   : in std_logic_vector(31 downto 0);
		instrucao       : in std_logic_vector(31 downto 0);  
		pc_out          : out std_logic_vector(11 downto 0);
		data_mem_write_data  : out std_logic_vector(31 downto 0);
		data_mem_addr   : out std_logic_vector(15 downto 0);
		
		debug_read_Rs : out std_logic_vector(3 downto 0);
		debug_ula		: out std_logic_vector(15 downto 0)
		);
	end component;

	signal clk : std_logic;
	signal rst : std_logic;
	signal debug_read_Rs : std_logic_vector(3 downto 0);
	signal debug_ula	: std_logic_vector(15 downto 0);
	signal instrucao  : std_logic_vector(instr_width - 1 downto 0);  
	signal pc_out    : std_logic_vector(pc_width - 1 downto 0);

	-- Definição das configurações de clock				
	constant PERIODO    : time := 20 ns;
	constant DUTY_CYCLE : real := 0.5;
	constant OFFSET     : time := 5 ns;
begin
	-- instancia o componente 
	instancia : via_de_dados_ciclo_unico port map(
	
	Clock => clk, 
	Chave_reset  => rst, 
	debug_read_Rs => debug_read_Rs, 
	debug_ula =>debug_ula,
	instrucao => instrucao,
	pc_out => pc_out
	
	);
	
	----------------------------------------
	
	instrucao <= x"20210001";
	controle_in <= "00";
	c0_bus_in <= x"00000000000";
	data_mem_data <= x"00000000";
	
	-- processo para gerar o sinal de clock 		
	gera_clock : process
	begin
		wait for OFFSET;
		CLOCK_LOOP : loop
			clk <= '0';
			wait for (PERIODO - (PERIODO * DUTY_CYCLE));
			clk <= '1';
			wait for (PERIODO * DUTY_CYCLE);
		end loop CLOCK_LOOP;
	end process gera_clock;
	-- processo para gerar o estimulo de reset		
	gera_reset : process
	begin
		rst <= '1';
		for i in 1 to 2 loop
			wait until rising_edge(clk);
		end loop;
		rst <= '0';
		wait;
	end process gera_reset;
end;