-- Universidade Federal de Minas Gerais
-- Escola de Engenharia
-- Departamento de Engenharia EletrÃ´nica
-- Autoria: Professor Ricardo de Oliveira Duarte
-- Unidade de controle ciclo Ãºnico (look-up table) do processador
-- puramente combinacional
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- unidade de controle
entity coprocessador_0 is   
	generic (
			c0_out_data_in_bus_width      : natural;          	-- tamanho do barramento de entrada de dados que comunica com o Coprocessador 0
			c0_in_data_out_bus_width 		: natural;          	-- tamanho do barramento de saÃ­da de dados que comunica com o Coprocessador 0
			DATA_WIDTH 							: natural; 				-- tamanho do barramento de dados em bits
			PROC_ADDR_WIDTH 					: natural; 				-- tamanho do endereÃ§o da memÃ³ria de programa do processador em bits
			fr_addr_width 						: natural; 				-- tamanho da linha de endereÃ§os do banco de registradores em bits
			irq_vector_width					: natural				-- quantidade de interrupções 
		 );
    port (
		clock					: in std_logic;
		reset					: in std_logic;
	 --IRQs
		irq_vector  		: in std_logic_vector(irq_vector_width-2 downto 0);	--Entradas de bits para requisiÃ§Ã£o de interrupÃ§Ãµes dos perifericos
	 --IOs Datapath
		c0_out_data_in  	: out std_logic_vector(c0_out_data_in_bus_width - 1 downto 0);	--Sai do c0 e vai pro datapath
		c0_in_data_out  	: in std_logic_vector(c0_in_data_out_bus_width   - 1 downto 0);	--Sai do datapath e vai pro c0
	 --IOs control unit
		interrupt_request : out std_logic;	--Para interromper a CPU
		cop0_we 				: in std_logic;	--Habilita escrita no banco de regs (instruÃ§Ã£o MTC0)
		Acknowledge			: in std_logic
    );
end coprocessador_0;

architecture beh of coprocessador_0 is


component banco_registradores_c0 is
    generic (
        largura_dado : natural;
        largura_ende : natural
    );
    port (
        ent_Rs_ende : in std_logic_vector((largura_ende - 1) downto 0);
        ent_Rt_ende : in std_logic_vector((largura_ende - 1) downto 0);
        ent_Rd_ende : in std_logic_vector((largura_ende - 1) downto 0);
        ent_Rd_dado : in std_logic_vector((largura_dado - 1) downto 0);
        sai_Rs_dado : out std_logic_vector((largura_dado - 1) downto 0);
        sai_Rt_dado : out std_logic_vector((largura_dado - 1) downto 0);
        clk, WE, reset     : in std_logic
    );
end component;

component interrupt_ctl is
  generic (
    RESET_ACTIVE_LEVEL : std_ulogic := '1' --# Asynch. reset control level
  );
  port (
    --# {{clocks|}}
    Clock : in std_ulogic; --# System clock
    Reset : in std_ulogic; --# Asynchronous reset

    --# {{control|}}
    Int_mask    : in std_ulogic_vector;  --# Set bits correspond to active interrupts
    Int_request : in std_ulogic_vector;  --# Controls used to activate new interrupts
    Pending     : out std_ulogic_vector; --# Set bits indicate which interrupts are pending
    Current     : out std_ulogic_vector; --# Single set bit for the active interrupt

    Interrupt     : out std_ulogic; --# Flag indicating when an interrupt is pending
    Acknowledge   : in std_ulogic;  --# Clear the active interupt
    Clear_pending : in std_ulogic   --# Clear all pending interrupts
  );
end component;

component registrador is
    generic (
        largura_dado : natural
    );
    port (
        entrada_dados  : in std_logic_vector((largura_dado - 1) downto 0);
        WE, clk, reset : in std_logic;
        saida_dados    : out std_logic_vector((largura_dado - 1) downto 0)
    );
end component;

component mux21 is
    generic (
        largura_dado : natural
    );
    port (
        dado_ent_0, dado_ent_1 : in std_logic_vector((largura_dado - 1) downto 0);
        sele_ent               : in std_logic;
        dado_sai               : out std_logic_vector((largura_dado - 1) downto 0)
    );
end component;

component mux41 is
    generic (
        largura_dado : natural
    );
    port (
        dado_ent_0, dado_ent_1, dado_ent_2, dado_ent_3 : in std_logic_vector((largura_dado - 1) downto 0);
        sele_ent                                       : in std_logic_vector(1 downto 0);
        dado_sai                                       : out std_logic_vector((largura_dado - 1) downto 0)
    );
end component;
	
	--Sinais para leitura e escrita dos registradores (para instruÃ§Ãµes MTC0 e MFC0)
	signal aux_regwrite_data				: std_logic_vector(PROC_ADDR_WIDTH-1 downto 0);
	signal aux_regread_data					: std_logic_vector(PROC_ADDR_WIDTH-1 downto 0);
	signal aux_datapath_reg_addr			: std_logic_vector(fr_addr_width-1 downto 0);
	signal aux_regread_addr					: std_logic_vector(fr_addr_width-1 downto 0);
	signal aux_return_addr					: std_logic_vector(PROC_ADDR_WIDTH-1 downto 0);
		
	-- EndereÃ§o da rotina de tratamento da interrupÃ§Ã£o
	signal aux_isr_addr						: std_logic_vector(PROC_ADDR_WIDTH-1 downto 0);
		
	signal aux_DIV_0							: std_logic;
	
	signal aux_ier_read						: std_logic_vector(irq_vector_width-1 downto 0);
	signal aux_ifr_read						: std_logic_vector(irq_vector_width-1 downto 0);
	signal aux_epc_read						: std_logic_vector(PROC_ADDR_WIDTH-1 downto 0);
	
	signal aux_ier_write_data				: std_logic_vector(irq_vector_width-1 downto 0);
	signal aux_ifr_write_data				: std_logic_vector(irq_vector_width-1 downto 0);
	signal aux_pending						: std_ulogic_vector(irq_vector_width-1 downto 0);
	signal offset								: std_logic_vector(3 downto 0);
	signal aux_current						: std_ulogic_vector(irq_vector_width-1 downto 0);
	
	signal aux_sel_readreg					: std_logic_vector(1 downto 0);
	signal aux_cpu_we_ifr					: std_logic;
	signal aux_cpu_we_ier					: std_logic;
	signal aux_scratchpad_we				: std_logic;
	signal aux_scratchpad_out				: std_logic_vector(PROC_ADDR_WIDTH-1 downto 0);
	signal aux_interrupt_request			: std_logic;
	
	signal aux_rt_ende						: std_logic_vector(fr_addr_width-1 downto 0);		
	signal aux_dado_ent_1					: std_logic_vector(PROC_ADDR_WIDTH-1 downto 0);	
	signal aux_dado_ent_2					: std_logic_vector(PROC_ADDR_WIDTH-1 downto 0);
	signal irq_vector_with_div0			: std_logic_vector(irq_vector_width-1 downto 0);
	signal aux_we_epc							: std_logic;
	signal aux_interrupt_request_out		:std_logic;
			
	begin 
	
	aux_rt_ende <= '0' & offset;
	aux_dado_ent_1 <= "00000" & aux_ier_read;
	aux_dado_ent_2 <= "00000" & aux_ifr_read;
	irq_vector_with_div0 <= aux_DIV_0 & irq_vector;
	aux_we_epc <= not(aux_interrupt_request);
	
	interrupt_request <= aux_interrupt_request_out;
	
	--Sinais para escrita dos registradores (para instruÃ§Ãµes MTC0)
	aux_regwrite_data 				<= c0_in_data_out(16 downto 5);
	c0_out_data_in(23 downto 12)	<= aux_regread_data;
	aux_datapath_reg_addr	 		<= c0_in_data_out(4 downto 0);
	
	aux_DIV_0							<= c0_in_data_out(49);	--ExceÃ§Ã£o de divisÃ£o por zero
	aux_return_addr					<= c0_in_data_out(48 downto 37);
	
	
	-- EndereÃ§o da rotina de tratamento da interrupÃ§Ã£o
	c0_out_data_in(11 downto 0)<= aux_isr_addr;
	
	--EndereÃ§o de retorno
	c0_out_data_in(35 downto 24)<= aux_epc_read;

	--Registradores que contém as ISRs de cada interrupção
	instancia_scratchpad : banco_registradores_c0
	generic map(
		largura_dado => PROC_ADDR_WIDTH,
		largura_ende => fr_addr_width
	 )
	 port map(
			ent_rs_ende => aux_datapath_reg_addr,	--Para a CPU
			ent_rt_ende => aux_rt_ende,								--Para a controladora de int
			ent_rd_ende => aux_datapath_reg_addr,
			ent_rd_dado => aux_regwrite_data,
			sai_rs_dado => aux_scratchpad_out,
			sai_rt_dado => aux_isr_addr,
			clk => clock,
			we => aux_scratchpad_we,
			reset => reset
		);
	
	--Controladora de interrupções
  ic: interrupt_ctl
    port map (
      Clock => clock,
      Reset => reset,

      Int_mask    => to_stdulogicvector(aux_ier_read),   -- Mask to enable/disable interrupts
      Int_request => to_stdulogicvector(irq_vector_with_div0),   -- Interrupt sources  
		
      Pending     => aux_pending,   -- Current set of pending interrupts
      Current     => aux_current,   -- Vector identifying which interrupt is active

      Interrupt     => aux_interrupt_request,     -- Signal when an interrupt is pending
      Acknowledge   => Acknowledge, -- Acknowledge the interrupt has been serviced
      Clear_pending =>  '0'
    );
	 
    instancia_IER : registrador
      generic map(
        largura_dado => irq_vector_width
      )
      port map (
        entrada_dados => aux_regwrite_data(6 downto 0),
        WE => aux_cpu_we_ier,
        clk => clock,
        reset => reset,
        saida_dados => aux_ier_read
      );
		
	 instancia_IFR : registrador
      generic map(
        largura_dado => irq_vector_width
      )
      port map (
        entrada_dados => aux_ifr_write_data,
        WE => '1',
        clk => clock,
        reset => reset,
        saida_dados => aux_ifr_read
      );

	 instancia_mux21_IFR : mux21
      generic map(
        largura_dado => irq_vector_width
      )
      port map (
        dado_ent_0 => to_stdlogicvector(aux_pending),
		  dado_ent_1 => aux_regwrite_data(6 downto 0),
        sele_ent   => aux_cpu_we_ifr,      
        dado_sai   => aux_ifr_write_data
      );
		
	 instancia_mux41_MTC0 : mux41
      generic map(
        largura_dado => PROC_ADDR_WIDTH
      )
      port map (
        dado_ent_0 => aux_scratchpad_out,
		  dado_ent_1 => aux_dado_ent_1,    
		  dado_ent_2 => aux_dado_ent_2,  
		  dado_ent_3 => aux_epc_read,
        sele_ent   => aux_sel_readreg,      
        dado_sai   => aux_regread_data
      );
		
		
	 instancia_EPC : registrador
      generic map(
        largura_dado => PROC_ADDR_WIDTH
      )
      port map (
        entrada_dados => aux_return_addr,
        WE => aux_we_epc, --Acho q nao vai funcionar pq esse bit Ã© saida
        clk => clock,
        reset => reset,
        saida_dados => aux_epc_read
      );
		
	--Decoder para transformar o sinal Current em uma sequência binária para poder gerar o offset e pegar
	--	o endereço da ISR correta na scratchpad memory
	process(aux_current) is
		begin
		
			for i in aux_current'low to aux_current'high loop
				if aux_current(i) = '1' then
					offset <= std_logic_vector(to_unsigned(i, offset'length));
					exit;
				else offset <= std_logic_vector(to_unsigned(0, offset'length));
				end if;
			end loop;
		
	end process;
		
	--Decodificador de endereço para leitura/escrita nos registradores por meio de MFC0 e MTC0	
	--No modelsim nao funciona com o case
	 process(aux_datapath_reg_addr, cop0_we) is
		begin
	
		if (unsigned(aux_datapath_reg_addr) < 9) then
			aux_sel_readreg <= "00";
			aux_scratchpad_we <= cop0_we;
			aux_cpu_we_ier <= '0';
			aux_cpu_we_ifr <= '0';
		elsif(aux_datapath_reg_addr = "01001") then
			aux_sel_readreg <= "01";
			aux_cpu_we_ier <= cop0_we;
			aux_scratchpad_we <= '0';
			aux_cpu_we_ifr <= '0';
		elsif(aux_datapath_reg_addr = "01010") then
			aux_sel_readreg <= "10";
			aux_cpu_we_ifr <= cop0_we;
			aux_cpu_we_ier <= '0';
			aux_scratchpad_we <= '0';
		elsif(aux_datapath_reg_addr = "01011") then
			aux_sel_readreg <= "11";
			aux_cpu_we_ifr <= '0';
			aux_cpu_we_ier <= '0';
			aux_scratchpad_we <= '0';
		else
			aux_sel_readreg <= "00";
			aux_cpu_we_ifr <= '0';
			aux_cpu_we_ier <= '0';
			aux_scratchpad_we <= '0';
		end if;	
--			case aux_datapath_reg_addr is
--				when "00000" to "01000"
--					aux_sel_readreg <= "00";
--					aux_scratchpad_we <= cop0_we;
--					aux_cpu_we_ier <= '0';
--					aux_cpu_we_ifr <= '0';
--				when "01001" => 
--					aux_sel_readreg <= "01";
--					aux_cpu_we_ier <= cop0_we;
--					aux_scratchpad_we <= '0';
--					aux_cpu_we_ifr <= '0';
--				when "01010" => 
--					aux_sel_readreg <= "10";
--					aux_cpu_we_ifr <= cop0_we;
--					aux_cpu_we_ier <= '0';
--					aux_scratchpad_we <= '0';
--				when "01011" => 
--					aux_sel_readreg <= "11";
--					aux_cpu_we_ifr <= '0';
--					aux_cpu_we_ier <= '0';
--					aux_scratchpad_we <= '0';
--				when others => 
--			aux_sel_readreg <= "00";
--			aux_cpu_we_ifr <= '0';
--			aux_cpu_we_ier <= '0';
--			aux_scratchpad_we <= '0';				
--			end case;		
	
	end process;
	
	--FSM para gerar um pulso em interrupt_request ao invés de ficar um sinal constantemente alto
	process(aux_interrupt_request, clock, Acknowledge, reset)
		type StateType is (A,B,C);
		variable current_state : StateType;
		variable next_state : StateType;
	begin
		if(reset = '1') then
			current_state := A;
		elsif (rising_edge(clock)) then
			current_state := next_state;
		end if;
		
		case current_state is
			when A =>
				if(aux_interrupt_request = '0') then
					next_state := A;
				else
					next_state := B;
				end if;
			when B =>
				next_state := C;
			when C =>
				if(Acknowledge = '0') then
					next_state := C;
				else
					next_state := A;
				end if;
		end case;
		
		if(current_state = B) then
			aux_interrupt_request_out <= '1';
		else
			aux_interrupt_request_out <= '0';
		end if;
		
	end process;
	
end beh;