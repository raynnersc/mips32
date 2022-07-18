--Controlador dos timers
--Instancia 2 timers: A e B
--Configurações: TargetA, TargetB, DivA, DivB (divisor de clock), InitA, InitB
--Divisões: 1,2,4,8,16,32,64,128. 8 fontes de clock, 3 bits do reg de config reservados.
--1 reg de config pra cada timer
--1 REG PARA TARGET DE CADA TIMER
--Saídas: InterA, InterB, CountA, CountB
--Reservar 1 endereço para cada timer para limpar a interrupção

--	xE 	: (W/R) 	ConfigA
-- xF 	: (W/R) 	TargetA
--	x10	: (W)		ClearA
--	x11	: (R) 	CountA
-- x12 	: (W/R) 	ConfigB
--	x13	: (W/R) 	TargetB
--	x14	: (W)		ClearB
-- x15	: (R) 	CountB

----6 Leituras:  MUX81
--	xE 	: (W/R) 	ConfigA
-- xF 	: (W/R) 	TargetA
--	x11	: (R) 	CountA
-- x12 	: (W/R) 	ConfigB
--	x13	: (W/R) 	TargetB
-- x15	: (R) 	CountB

----6 Escritas:		Gerar 4 WE (Os clears não escrevem em regs)
--	xE 	: (W/R) 	ConfigA		-> we_ConfigA
-- xF 	: (W/R) 	TargetA		-> we_TargetA
--	x10	: (W)		ClearA
-- x12 	: (W/R) 	ConfigB		-> we_ConfigB
--	x13	: (W/R) 	TargetB		-> we_TargetA
--	x14	: (W)		ClearB

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
 
entity timer_ctl is
	generic(
		DATA_WIDTH		: natural
	);
   port(
		clock			: in std_logic;
		reset			: in std_logic;
		
		reg_addr		: in std_logic_vector(5 downto 0);
		data_in			: in std_logic_vector(DATA_WIDTH-1 downto 0);
		write_enable	: in std_logic;
		data_out		: out std_logic_vector(DATA_WIDTH-1 downto 0);
		inter_out		: out std_logic_vector(1 downto 0)
	);
end entity timer_ctl;



architecture Behave of timer_ctl is
   
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
	
	component timer is
		port(
				clk    	: in  std_logic;
				reset  	: in  std_logic;
				we     	: in  std_logic;
				target  : in  std_logic_vector(31 downto 0);
				
				finish  : out std_logic;
				count   : out std_logic_vector(31 downto 0)
			);
	end component timer;
	
	component mux81 is
    generic (
        largura_dado : natural
    );
    port (
        dado_ent_0, dado_ent_1, dado_ent_2, dado_ent_3 : in std_logic_vector((largura_dado - 1) downto 0);
        dado_ent_4, dado_ent_5, dado_ent_6, dado_ent_7 : in std_logic_vector((largura_dado - 1) downto 0);
        sele_ent                                       : in std_logic_vector(2 downto 0);
        dado_sai                                       : out std_logic_vector((largura_dado - 1) downto 0)
    );
	end component;
	
	component DivisorClock_timer is
		port 
		(
			CLOCK_in 	: in std_logic;
			CLOCK_out   : out std_logic;
			div_factor	: in	std_logic_vector(7 downto 0)
		);

	end component;
	
	-------------------------
	
	signal aux_clear_timerA	: std_logic;
	signal aux_clear_timerB	: std_logic;
	signal clock_A			: std_logic;
	signal clock_B			: std_logic;
	signal aux_configA		: std_logic_vector(3 downto 0);
	signal aux_configB		: std_logic_vector(3 downto 0);
	signal aux_targetA		: std_logic_vector(31 downto 0);
	signal aux_targetB		: std_logic_vector(31 downto 0);
	signal aux_count_outA	: std_logic_vector(31 downto 0);
	signal aux_count_outB	: std_logic_vector(31 downto 0);
	
	signal aux_dado_ent_0, aux_dado_ent_1, aux_dado_ent_2, aux_dado_ent_3, aux_dado_ent_4, aux_dado_ent_6	: std_logic_vector(DATA_WIDTH-1 downto 0);	
	
	signal aux_sel_data_out : std_logic_vector(2 downto 0);
	
	signal aux_clock_divA	: std_logic;
	signal aux_clock_divB	: std_logic;
	
	signal aux_div_factorA	: std_logic_vector(7 downto 0);
	signal aux_div_factorB	: std_logic_vector(7 downto 0);	
	
	signal aux_we_configA	: std_logic;
	signal aux_we_configB	: std_logic;
	signal aux_we_targetA	: std_logic;
	signal aux_we_targetB	: std_logic;
	signal aux_reset_configB: std_logic;
	signal aux_reset_configA: std_logic;
	
	
begin

	aux_dado_ent_0 <= x"0000000" & aux_configA;
	aux_dado_ent_3 <= x"0000000" & aux_configB;
	aux_reset_configA <= reset OR aux_clear_timerA;
	aux_reset_configB <= reset OR aux_clear_timerB;

	instancia_timerA : timer
		port map(
			clk    	=> clock_A,
			reset  	=>	aux_clear_timerA,
			we     	=>	aux_configA(0),
			target   => aux_targetA,
			
			finish   => inter_out(0),
			count   	=>	aux_count_outA
		);
		
	instancia_timerB : timer
		port map(
			clk    	=> clock_B,
			reset  	=>	aux_clear_timerB,
			we     	=> aux_configB(0),
			target   => aux_targetB,
			
			finish   => inter_out(1),
			count   	=> aux_count_outB
		);
		

	instancia_mux81_out : mux81
      generic map(
        largura_dado => DATA_WIDTH
      )
      port map (
        dado_ent_0 => aux_dado_ent_0,
        dado_ent_1 => aux_targetA,
        dado_ent_2 => aux_count_outA,
        dado_ent_3 => aux_dado_ent_3,
		dado_ent_4 => aux_targetB,
        dado_ent_5 => aux_count_outB,
        dado_ent_6 => (others=>'0'),
        dado_ent_7 => (others=>'0'),
        sele_ent => aux_sel_data_out,
        dado_sai => data_out
      );
		
		
    instancia_reg_configA : registrador
      generic map(
        largura_dado => 4	
      )
      port map (
        entrada_dados => data_in(3 downto 0),
        WE => aux_we_configA,
        clk => clock,
        reset => aux_reset_configA,
        saida_dados => aux_configA
      );
				
	 instancia_reg_targetA : registrador
      generic map(
        largura_dado => 32
      )
      port map (
        entrada_dados => data_in(31 downto 0),
        WE => aux_we_targetA,
        clk => clock,
        reset => reset,
        saida_dados => aux_targetA
      );
		
	 instancia_reg_configB : registrador
      generic map(
        largura_dado =>  4
      )
      port map (
        entrada_dados => data_in(3 downto 0),
        WE => aux_we_configB,
        clk => clock,
        reset => aux_reset_configB,
        saida_dados => aux_configB
      );
		
	 instancia_reg_targetB : registrador
      generic map(
        largura_dado =>  32
      )
      port map (
        entrada_dados => data_in(31 downto 0),
        WE => aux_we_targetB,
        clk => clock,
        reset => reset,
        saida_dados => aux_targetB
      );
		
	
	  instancia_div_clockA : DivisorClock_timer 
		port map
		(
			CLOCK_in 	=> clock,
			CLOCK_out 	=> clock_A,
			div_factor	=>	aux_div_factorA
		);
		
	  instancia_div_clockB : DivisorClock_timer 
		port map
		(
			CLOCK_in 	=> clock,
			CLOCK_out 	=> clock_B,
			div_factor	=> aux_div_factorB
		);
		
			
	  instancia_mux81_DivA : mux81
      generic map(
        largura_dado => 8
      )
      port map (
        dado_ent_0 => "00000001",
        dado_ent_1 => "00000010",
        dado_ent_2 => "00000100",
        dado_ent_3 => "00001000",
		dado_ent_4 => "00010000",
        dado_ent_5 => "00100000",
        dado_ent_6 => "01000000",
        dado_ent_7 => "10000000",
        sele_ent => aux_configA(3 downto 1),
        dado_sai => aux_div_factorA
      );
		
	  instancia_mux81_DivB : mux81
      generic map(
        largura_dado => 8
      )
      port map (
        dado_ent_0 => "00000001",
        dado_ent_1 => "00000010",
        dado_ent_2 => "00000100",
        dado_ent_3 => "00001000",
		dado_ent_4 => "00010000",
        dado_ent_5 => "00100000",
        dado_ent_6 => "01000000",
        dado_ent_7 => "10000000",
        sele_ent => aux_configB(3 downto 1),
        dado_sai => aux_div_factorB
      );
		
	
		--aux_clear_timerA <= (reg_addr=x"10" AND write_enable='1' AND data_in=x"00000001");
		process(reg_addr,write_enable,data_in)
		begin
			if (reg_addr="010010" AND write_enable='1' AND data_in=x"00000001") then
				aux_clear_timerA <= '1';
			else
				aux_clear_timerA <= '0';
			end if;
			
			if (reg_addr="010110" AND write_enable='1' AND data_in=x"00000001") then
				aux_clear_timerB <= '1';
			else
				aux_clear_timerB <= '0';
			end if;
		end process;
		
		--aux_clear_timerB <= (reg_addr=x"14" AND write_enable='1' AND data_in=x"00000001");
		
		process(reg_addr,write_enable)
		begin
		
			aux_sel_data_out <= "000";
			aux_we_configA	  <= '0';
			aux_we_configB	  <= '0';
			aux_we_targetA	  <= '0';
			aux_we_targetB	  <= '0';
		
			case(reg_addr) is
					
				when "010000" =>
				
					aux_we_configA	  <= write_enable;
					
				when "010001" =>
				
					aux_sel_data_out <= "001";
					aux_we_targetA	  <= write_enable;
					
				when "010011" =>
				
					aux_sel_data_out <= "010";
					
				when "010100" =>
				
					aux_sel_data_out <= "011";
					aux_we_configB	  <= write_enable;
					
				when "010101" =>
				
					aux_sel_data_out <= "100";
					aux_we_targetB	  <= write_enable;
				
				when "010111" =>
				
					aux_sel_data_out <= "101";
					
				when others =>
				
					aux_sel_data_out <= "000";
					aux_we_configA	  <= '0';
					aux_we_configB	  <= '0';
					aux_we_targetA	  <= '0';
					aux_we_targetB	  <= '0';	
					
			end case;
		
		end process;


end architecture Behave;