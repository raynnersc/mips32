library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_coprocessador_0 is
	generic (
			c0_out_data_in_bus_width      : natural := 56;          -- tamanho do barramento de entrada de dados que comunica com o Coprocessador 0
			c0_in_data_out_bus_width 		: natural := 50;          -- tamanho do barramento de saída de dados que comunica com o Coprocessador 0
			DATA_WIDTH 							: natural := 32; -- tamanho do barramento de dados em bits
			PROC_ADDR_WIDTH 					: natural := 12; -- tamanho do endereço da memória de programa do processador em bits
			fr_addr_width 						: natural := 5; -- tamanho da linha de endereços do banco de registradores em bits
			irq_vector_width					: natural := 7			
		 );  
end tb_coprocessador_0;

architecture teste of tb_coprocessador_0 is

	component coprocessador_0 is   
    generic (
		c0_out_data_in_bus_width      : natural;          -- tamanho do barramento de entrada de dados que comunica com o Coprocessador 0
		c0_in_data_out_bus_width 		: natural;          -- tamanho do barramento de saída de dados que comunica com o Coprocessador 0
		DATA_WIDTH 							: natural; -- tamanho do barramento de dados em bits
		PROC_ADDR_WIDTH 					: natural; -- tamanho do endereço da memória de programa do processador em bits
		fr_addr_width 						: natural; -- tamanho da linha de endereços do banco de registradores em bits
		irq_vector_width					: natural
    );
    port (
	 
		clock					: in std_logic;
		reset					: in std_logic;
	 
	 --IRQs
		irq_vector  		: in std_logic_vector(irq_vector_width-2 downto 0);	--Entradas de bits para requisição de interrupções dos perifericos
	 
	 --IOs Datapath
		c0_out_data_in  	: out std_logic_vector(c0_out_data_in_bus_width - 1 downto 0);	--Sai do c0 e vai pro datapath
		c0_in_data_out  	: in std_logic_vector(c0_in_data_out_bus_width   - 1 downto 0);	--Sai do datapath e vai pro c0

	 --IOs control unit
		interrupt_request : out std_logic;	--Para interromper a CPU
		c0_pc_en 			: out std_logic;				--
		cop0_we 				: in std_logic;	--Habilita escrita no banco de regs (instrução MTC0)
		cop0_re 				: in std_logic;	--Habilita leitura no banco de regs (instrução MFC0)
		Acknowledge			: in std_logic
		--syscall 			  : in std_logic;	--Exceção syscall
		--bad_instr 		  : in std_logic	--Exceção bad instruction
    );
	end component;
	
	signal clk						: std_logic;
	signal rst						: std_logic;
	 --IRQs
	signal irq_vector  			: std_logic_vector(irq_vector_width-2 downto 0);	--Entradas de bits para requisição de interrupções dos perifericos
	 --IOs Datapath
	signal c0_out_data_in  		: std_logic_vector(c0_out_data_in_bus_width - 1 downto 0);	--Sai do c0 e vai pro datapath
	signal c0_in_data_out  		: std_logic_vector(c0_in_data_out_bus_width   - 1 downto 0);	--Sai do datapath e vai pro c0
	 --IOs control unit
	signal interrupt_request 	: std_logic;	--Para interromper a CPU
	signal c0_pc_en 				: std_logic;				--
	signal cop0_we 				: std_logic;	--Habilita escrita no banco de regs (instrução MTC0)
	signal cop0_re 				: std_logic;	--Habilita leitura no banco de regs (instrução MFC0)
	signal Acknowledge			: std_logic;
	
	signal aux_IRQ_GPIO_A					: std_logic;
	signal aux_IRQ_GPIO_B					: std_logic;
	signal aux_IRQ_TIMER_A					: std_logic;
	signal aux_IRQ_TIMER_B					: std_logic;
	signal aux_IRQ_UART_Transmited		: std_logic;
	signal aux_IRQ_UART_Received			: std_logic;	
	
	signal aux_regwrite_data				: std_logic_vector(PROC_ADDR_WIDTH-1 downto 0);
	signal aux_DIV_0							: std_logic;
	signal aux_return_addr					: std_logic_vector(PROC_ADDR_WIDTH-1 downto 0);
	signal aux_datapath_reg_addr			: std_logic_vector(fr_addr_width-1 downto 0);
	signal int_vector							: std_logic_vector(PROC_ADDR_WIDTH-1 downto 0);
	

	constant PERIODO    : time := 5 ns;
	constant DUTY_CYCLE : real := 0.5;
	constant OFFSET     : time := 5 ns;
	
begin

	--Sinais das requisições de interrupção dos periféricos
	 irq_vector(5) <= aux_IRQ_GPIO_B ;
	 irq_vector(4) <= aux_IRQ_GPIO_A;
	 irq_vector(3) <= aux_IRQ_TIMER_B;
	 irq_vector(2) <= aux_IRQ_TIMER_A;
	 irq_vector(1) <= aux_IRQ_UART_Transmited;
	 irq_vector(0) <= aux_IRQ_UART_Received;
		
	c0_in_data_out(16 downto 5)  	<= aux_regwrite_data;
	c0_in_data_out(4 downto 0)  	<= aux_datapath_reg_addr;
	c0_in_data_out(49) 				<=  aux_DIV_0;	--Exceção de divisão por zero
	c0_in_data_out(48 downto 37) 	<= aux_return_addr;

	int_vector <= c0_out_data_in(11 downto 0);
	
	instancia_c0 : coprocessador_0
	generic map(
		c0_out_data_in_bus_width 	=>   c0_out_data_in_bus_width,
		c0_in_data_out_bus_width 	=>	  c0_in_data_out_bus_width,
		DATA_WIDTH 					 	=>	  DATA_WIDTH,
		PROC_ADDR_WIDTH 				=>   PROC_ADDR_WIDTH,
		fr_addr_width 					=>	  fr_addr_width,
		irq_vector_width				=>	  irq_vector_width
	 )
	 port map(
		clock								=>	clk  ,  
		reset								=>	rst  ,
	 --IRQs
		irq_vector  					=>	irq_vector  ,
	 --IOs Datapath
		c0_out_data_in  				=>	c0_out_data_in  ,
		c0_in_data_out  				=>	c0_in_data_out  ,
	 --IOs control unit
		interrupt_request 			=>	interrupt_request  ,
		c0_pc_en 						=>	c0_pc_en  ,
		cop0_we 							=>	cop0_we  ,
		cop0_re 							=>	cop0_re  ,
		Acknowledge						=> Acknowledge
		);
			
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
		
		aux_IRQ_GPIO_A <= '0';
		aux_IRQ_GPIO_B <= '0';
		aux_IRQ_TIMER_A <= '0';
		aux_IRQ_TIMER_B <= '0';
		aux_IRQ_UART_Transmited <= '0';
		aux_IRQ_UART_Received <= '0';
		Acknowledge <= '0';
		aux_DIV_0 <= '0';	--Exceção de divisão por zero
		cop0_we <= '0';
		aux_regwrite_data <= x"000";
		aux_datapath_reg_addr <= "00000";
		aux_return_addr <= x"ABC";	
		
		wait for 40 ns;
		
--TESTE DE MTC0
		
		--habilita todas as interrupções
		aux_regwrite_data <= x"FFF";
		cop0_we <= '1';
		aux_datapath_reg_addr <= "01001";
		
		wait for 40 ns;
		
		--escreve ISR
		aux_regwrite_data <= x"000";
		aux_datapath_reg_addr <= "00000";
		
		wait for 40 ns;
		
		--escreve ISR
		aux_regwrite_data <= x"001";
		aux_datapath_reg_addr <= "00001";
		
		wait for 40 ns;
		
		--escreve ISR
		aux_regwrite_data <= x"002";
		aux_datapath_reg_addr <= "00010";
		
		wait for 40 ns;
		
		--escreve ISR
		aux_regwrite_data <= x"003";
		aux_datapath_reg_addr <= "00011";
		
		wait for 40 ns;
		
		--escreve ISR
		aux_regwrite_data <= x"004";
		aux_datapath_reg_addr <= "00100";
		
		wait for 40 ns;
		
		--escreve ISR
		aux_regwrite_data <= x"005";
		aux_datapath_reg_addr <= "00101";
		
		wait for 40 ns;
		
		--escreve ISR
		aux_regwrite_data <= x"006";
		aux_datapath_reg_addr <= "00110";
		
		wait for 40 ns;
		
		--escreve ISR
		aux_regwrite_data <= x"007";
		aux_datapath_reg_addr <= "00111";
		
		wait for 40 ns;
		
		--escreve ISR
		aux_regwrite_data <= x"008";
		aux_datapath_reg_addr <= "01000";
		
		wait for 40 ns;
		
		--escreve IFR
		aux_regwrite_data <= x"00A";
		aux_datapath_reg_addr <= "01010";
		
		wait for 40 ns;
		
--TESTE DE MFC0
		cop0_we <= '0';
		for i in 0 to 11 loop
			
			aux_datapath_reg_addr <= std_logic_vector(to_unsigned(i, aux_datapath_reg_addr'length));
			wait for 40 ns;
			
		end loop;

--TESTE DE PRIORIDADE E ACKnowledge

		aux_IRQ_GPIO_A <= '1';
		aux_IRQ_GPIO_B <= '1';
		aux_IRQ_TIMER_A <= '1';
		aux_IRQ_TIMER_B <= '1';
		aux_IRQ_UART_Transmited <= '1';
		aux_IRQ_UART_Received <= '1';
		aux_DIV_0 <= '1';	--Exceção de divisão por zero
		
		wait until rising_edge(clk);
		wait for 20 ns;
		wait until rising_edge(clk);
		Acknowledge <= '1';
		wait until rising_edge(clk);
		Acknowledge <= '0';
		
		aux_IRQ_UART_Received <= '0';
		wait until rising_edge(clk);
		wait for 20 ns;
		wait until rising_edge(clk);
		Acknowledge <= '1';
		wait until rising_edge(clk);
		Acknowledge <= '0';

		aux_IRQ_UART_Transmited <= '0';
		wait until rising_edge(clk);
		wait for 20 ns;
		wait until rising_edge(clk);
		Acknowledge <= '1';
		wait until rising_edge(clk);
		Acknowledge <= '0';

		aux_IRQ_TIMER_A <= '0';
		wait until rising_edge(clk);
		wait for 20 ns;
		wait until rising_edge(clk);
		Acknowledge <= '1';
		wait until rising_edge(clk);
		Acknowledge <= '0';
		
		aux_IRQ_TIMER_B <= '0';
		wait until rising_edge(clk);
		wait for 20 ns;
		wait until rising_edge(clk);
		Acknowledge <= '1';
		wait until rising_edge(clk);
		Acknowledge <= '0';

		aux_IRQ_GPIO_A <= '0';
		wait until rising_edge(clk);
		wait for 20 ns;
		wait until rising_edge(clk);
		Acknowledge <= '1';
		wait until rising_edge(clk);
		Acknowledge <= '0';
		
		aux_IRQ_GPIO_B <= '0';
		wait until rising_edge(clk);
		wait for 20 ns;
		wait until rising_edge(clk);
		Acknowledge <= '1';
		wait until rising_edge(clk);
		Acknowledge <= '0';
		
		aux_DIV_0 <= '0';	--Exceção de divisão por zero
		wait until rising_edge(clk);
		wait for 20 ns;
		wait until rising_edge(clk);
		Acknowledge <= '1';
		wait until rising_edge(clk);
		Acknowledge <= '0';
		
		wait;
		
	end process gera_reset;

end teste;