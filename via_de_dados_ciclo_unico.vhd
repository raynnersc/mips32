-- Universidade Federal de Minas Gerais
-- Escola de Engenharia
-- Departamento de Engenharia Eletrônica
-- Autoria: Professor Ricardo de Oliveira Duarte
-- Via de dados do processador_ciclo_unico


library IEEE;
use IEEE.std_logic_1164.all;

entity via_de_dados_ciclo_unico is
	generic (
		-- declare todos os tamanhos dos barramentos (sinais) das portas da sua via_dados_ciclo_unico aqui.
		c0_bus_in_width      : natural;          -- tamanho do barramento de entrada de dados que comunica com o Coprocessador 0
    c0_bus_out_width     : natural;          -- tamanho do barramento de saída de dados que comunica com o Coprocessador 0
		in_ctrl_bus_width : natural;      -- tamanho do barramento de controle da via de dados (DP) em bits-- WE_hi_lo
    out_ctrl_bus_width: natural;
		data_width        : natural;    -- tamanho do dado em bits
		pc_width          : natural;    -- tamanho da entrada de endereços da MI ou MP em bits (memi.vhd)
		fr_addr_width     : natural;     -- tamanho da linha de endereços do banco de registradores em bits
		ula_ctrl_width    : natural;     -- tamanho da linha de controle da ULA
		instr_width       : natural;    -- tamanho da instrução em bits
    immediate_width   : natural     -- tamanho do imediato em bits
	);
	port (
		-- declare todas as portas da sua via_dados_ciclo_unico aqui.
		clock           : in std_logic;
		reset           : in std_logic;
    --barramento que vem da Control Unit
		controle_in        : in std_logic_vector(in_ctrl_bus_width - 1 downto 0);
    controle_out        : out std_logic_vector(out_ctrl_bus_width - 1 downto 0);
    -- WRegSrc 2 bits
    -- WE_hi_lo 
    -- WE_RF
    -- DM_WE
    -- ALU_src
    -- PC_SRC 2 bits
    -- MUL/DIV_SEL
    -- 
    --barramento que vem do C0
    c0_bus_in          : in std_logic_vector(c0_bus_in_width - 1 downto 0);  
    c0_bus_out          : out std_logic_vector(c0_bus_out_width - 1 downto 0);  
    
    data_mem_data   : in std_logic_vector(data_width - 1 downto 0);
		instrucao       : in std_logic_vector(instr_width - 1 downto 0);
    
		pc_out          : out std_logic_vector(pc_width - 1 downto 0);
		data_mem_write_data           : out std_logic_vector(data_width - 1 downto 0);
    data_mem_addr   : out std_logic_vector((data_width/2) - 1 downto 0);
	 
	 debug_read_Rs		: out std_logic_vector(3 downto 0)

    
	);
end entity via_de_dados_ciclo_unico;

architecture comportamento of via_de_dados_ciclo_unico is

	-- declare todos os componentes que serão necessários na sua via_de_dados_ciclo_unico a partir deste comentário
	component pc is
		generic (
			pc_width : natural
		);
		port (
			entrada : in std_logic_vector(pc_width - 1 downto 0);
			saida   : out std_logic_vector(pc_width - 1 downto 0);
			clk     : in std_logic;
			we      : in std_logic;
			reset   : in std_logic
		);
	end component;

	component somador is
		generic (
			largura_dado : natural
		);
		port (
			entrada_a : in std_logic_vector((largura_dado - 1) downto 0);
			entrada_b : in std_logic_vector((largura_dado - 1) downto 0);
			saida     : out std_logic_vector((largura_dado - 1) downto 0)
		);
	end component;

	component banco_registradores is
		generic (
			largura_dado : natural;
			largura_ende : natural
		);
		port (
			ent_rs_ende : in std_logic_vector((largura_ende - 1) downto 0);
			ent_rt_ende : in std_logic_vector((largura_ende - 1) downto 0);
			ent_rd_ende : in std_logic_vector((largura_ende - 1) downto 0);
			ent_rd_dado : in std_logic_vector((largura_dado - 1) downto 0);
			sai_rs_dado : out std_logic_vector((largura_dado - 1) downto 0);
			sai_rt_dado : out std_logic_vector((largura_dado - 1) downto 0);
			clk         : in std_logic;
			we          : in std_logic;
			reset          : in std_logic
		);
	end component;

	component ula is
		generic (
			largura_dado : natural
		);
		port (
			entrada_a : in std_logic_vector((largura_dado - 1) downto 0);
			entrada_b : in std_logic_vector((largura_dado - 1) downto 0);
			seletor   : in std_logic_vector(2 downto 0);
--      shamt     : in std_logic_vector(4 downto 0);
			saida     : out std_logic_vector((largura_dado - 1) downto 0);
      zero      : out std_logic
		);
	end component;

  component multiplicador_divisor is
       generic (
        largura_dado : natural := 32
    );

    port (
        sel       : in std_logic;
        entrada_a : in std_logic_vector((largura_dado - 1) downto 0);
        entrada_b : in std_logic_vector((largura_dado - 1) downto 0);
        saida_hi  : out std_logic_vector((largura_dado - 1) downto 0);
        saida_lo  : out std_logic_vector((largura_dado - 1) downto 0);
        div_0     : out std_logic
    ); 
  end component;

  component registrador is
    generic (
     largura_dado : natural := 32
    );
    port (
        entrada_dados  : in std_logic_vector((largura_dado - 1) downto 0);
        WE, clk, reset : in std_logic;
        saida_dados    : out std_logic_vector((largura_dado - 1) downto 0)
    );
  end component;

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

  component extensor is
  	generic (
  		largura_dado  : natural;
  		largura_saida : natural
  	);
  
  	port (
      ExtType    : in std_logic;
  		entrada_Rs : in std_logic_vector((largura_dado - 1) downto 0);
  		saida      : out std_logic_vector((largura_saida - 1) downto 0)
  	);
  end component;

  component deslocador is
  	generic (
  		largura_dado : natural;
  		largura_qtde : natural
  	);
  
  	port (
  		ent_rs_dado           : in std_logic_vector((largura_dado - 1) downto 0);
  		ent_rt_ende           : in std_logic_vector((largura_qtde - 1) downto 0); -- o campo de endereços de rt, representa a quantidade a ser deslocada nesse contexto.
  		ent_tipo_deslocamento : in std_logic_vector(1 downto 0);
  		sai_rd_dado           : out std_logic_vector((largura_dado - 1) downto 0)
  	);
  end component;

	-- Declare todos os sinais auxiliares que serão necessários na sua via_de_dados_ciclo_unico a partir deste comentário.
	-- Você só deve declarar sinais auxiliares se estes forem usados como "fios" para interligar componentes.
	-- Os sinais auxiliares devem ser compatíveis com o mesmo tipo (std_logic, std_logic_vector, etc.) e o mesmo tamanho dos sinais dos portos dos
	-- componentes onde serão usados.
	-- Veja os exemplos abaixo:
	signal aux_read_rs    : std_logic_vector(fr_addr_width - 1 downto 0);
	signal aux_read_rt    : std_logic_vector(fr_addr_width - 1 downto 0);
	signal aux_write_rd   : std_logic_vector(fr_addr_width - 1 downto 0);
	signal aux_addr_a3	 : std_logic_vector(fr_addr_width - 1 downto 0);
--	signal aux_data_in    : std_logic_vector(data_width - 1 downto 0);
	signal aux_data_outrs : std_logic_vector(data_width - 1 downto 0);
	signal aux_data_outrt : std_logic_vector(data_width - 1 downto 0);
	signal aux_reg_write  : std_logic;

	signal aux_ula_ctrl : std_logic_vector(ula_ctrl_width - 1 downto 0);
  signal aux_ula_out  : std_logic_vector(data_width - 1 downto 0);

	signal aux_pc_out  : std_logic_vector(pc_width - 1 downto 0);
	signal aux_novo_pc : std_logic_vector(pc_width - 1 downto 0);
	signal aux_we      : std_logic;

  --signal aux_shift2_branch_out   : std_logic_vector(pc_width - 1 downto 0);
  signal aux_branch_address      : std_logic_vector(pc_width - 1 downto 0);
  signal aux_ext_imediato        : std_logic_vector(data_width - 1 downto 0);
  signal aux_hi_out              : std_logic_vector(data_width - 1 downto 0);
  signal aux_lo_out              : std_logic_vector(data_width - 1 downto 0);
  signal aux_mult_div_out_hi     : std_logic_vector(data_width - 1 downto 0);
  signal aux_mult_div_out_lo     : std_logic_vector(data_width - 1 downto 0);
  signal aux_ext_type            : std_logic;
  signal aux_jump_address        : std_logic_vector(pc_width - 1 downto 0);
  signal aux_shamt_sa            : std_logic_vector(4 downto 0);
  signal aux_lui                 : std_logic_vector(data_width - 1 downto 0);
  signal aux_mem_data            : std_logic_vector(data_width - 1 downto 0);
  signal aux_mux21_a3_a_to_b     : std_logic_vector(fr_addr_width - 1 downto 0);
  signal aux_wregdata            : std_logic_vector(2 downto 0);
  signal aux_mux81_wd3_out     : std_logic_vector(data_width - 1 downto 0);
  signal aux_pc_plus4            : std_logic_vector(pc_width - 1 downto 0);
  signal aux_pcsrc               : std_logic_vector(2 downto 0);
  signal aux_mux41_pc_out        : std_logic_vector(pc_width - 1 downto 0);
  signal aux_alu_ent_b           : std_logic_vector(data_width - 1 downto 0);
  signal aux_alusrc					     : std_logic;
  signal aux_imediato            : std_logic_vector((data_width/2) - 1 downto 0);
  signal aux_jump		             : std_logic_vector(pc_width - 1 downto 0);
  signal aux_we_hi_lo				     : std_logic;
  signal aux_wregsrc					   : std_logic_vector(1 downto 0);
  signal aux_we_pc					     : std_logic;
  signal aux_sel_mult_div			   : std_logic;
  signal zero_alu			           : std_logic;
  signal aux_shifter_out         : std_logic_vector(data_width - 1 downto 0);
  signal aux_srl_sll_sel         : std_logic;
  
  signal div_0		            	: std_logic;
  signal aux_c0_rd					    : std_logic_vector(data_width - 1 downto 0);
  signal aux_c0_int_vector			: std_logic_vector(pc_width - 1 downto 0);
  signal aux_zero_extended_pc_plus4	: std_logic_vector(data_width - 1 downto 0);
  signal aux_ent_tipo_deslocamento	: std_logic_vector(1 downto 0);

 begin

	-- A partir deste comentário faça associações necessárias das entradas declaradas na entidade da sua via_dados_ciclo_unico com
	-- os sinais que você acabou de definir.
	-- Veja os exemplos abaixo:
  aux_read_rs   <= instrucao(25 downto 21);  -- OP OP OP OP OP OP RS RS RS RS RS RT RT RT RT RT RD RD RD RD RD SHAMT SHAMT SHAMT SHAMT SHAMT FUNCT(6bits)
  debug_read_Rs <= aux_data_outrs(3 downto 0);

  aux_read_rt   <= instrucao(20 downto 16);  -- OP OP OP OP OP OP RS RS RS RS RS RT RT RT RT RT RD RD RD RD RD
  aux_write_rd  <= instrucao(15 downto 11); -- OP OP OP OP OP OP RS RS RS RS RS RT RT RT RT RT RD RD RD RD RD
  aux_shamt_sa  <= instrucao(10 downto 6);
  aux_imediato  <= instrucao(15 downto 0);
  aux_jump      <= instrucao(11 downto 0);   

  c0_bus_out(49) <= div_0;
  c0_bus_out(48 downto 37) <= aux_pc_plus4;
  c0_bus_out(36 downto 5) <= aux_data_outrt;
  c0_bus_out(4 downto 0) <= aux_write_rd; 

  aux_c0_rd 			<= c0_bus_in(43 downto 12);
  aux_c0_int_vector 	<= c0_bus_in(11 downto 0);

  controle_out(1) <= aux_data_outrs(data_width - 1);
  controle_out(0) <= zero_alu;

  aux_srl_sll_sel <= controle_in(17);
  aux_ext_type <= controle_in(16);
  aux_sel_mult_div <= controle_in(15);
  aux_alusrc    <= controle_in(14);
  aux_we_hi_lo  <= controle_in(13);
  aux_wregsrc   <= controle_in(12 downto 11);
  aux_pcsrc     <= controle_in(10 downto 8);
  aux_wregdata  <= controle_in(7 downto 5);
  aux_we_pc     <= controle_in(4);            -- WE RW UL UL UL UL
  aux_reg_write <= controle_in(3);            -- WE RW UL UL UL UL
  aux_ula_ctrl  <= controle_in(2 downto 0);   -- WE RW UL UL UL UL
	
	data_mem_write_data         <= aux_data_outrt;
  pc_out        <= aux_pc_out;
  
  aux_mem_data  <= data_mem_data;
  data_mem_addr <= aux_ula_out((data_width/2) - 1 downto 0);
  
  aux_zero_extended_pc_plus4 <= x"00000" & aux_pc_plus4;
  aux_ent_tipo_deslocamento <=  "0" & aux_srl_sll_sel;

	-- A partir deste comentário instancie todos o componentes que serão usados na sua via_de_dados_ciclo_unico.
	-- A instanciação do componente deve começar com um nome que você deve atribuir para a referida instancia seguido de : e seguido do nome
	-- que você atribuiu ao componente.
	-- Depois segue o port map do referido componente instanciado.
	-- Para fazer o port map, na parte da esquerda da atribuição "=>" deverá vir o nome de origem da porta do componente e na parte direita da
	-- atribuição deve aparecer um dos sinais ("fios") que você definiu anteriormente, ou uma das entradas da entidade via_de_dados_ciclo_unico,
	-- ou ainda uma das saídas da entidade via_de_dados_ciclo_unico.
	-- Veja os exemplos de instanciação a seguir:

	instancia_ula1 : ula
  	generic map(
      largura_dado => data_width
    )	
    port map(
			entrada_a => aux_data_outrs,
			entrada_b => aux_alu_ent_b,
			seletor => aux_ula_ctrl,
--			shamt => aux_shamt_sa,
			saida => aux_ula_out,
      zero => zero_alu
 		);

	instancia_banco_registradores : banco_registradores
		generic map(
      largura_dado => data_width,
      largura_ende => fr_addr_width
    )
    port map(
			ent_rs_ende => aux_read_rs,
			ent_rt_ende => aux_read_rt,
			ent_rd_ende => aux_addr_a3,
			ent_rd_dado => aux_mux81_wd3_out,
			sai_rs_dado => aux_data_outrs,
			sai_rt_dado => aux_data_outrt,
			clk => clock,
			we => aux_reg_write,
			reset => reset
		);

  instancia_pc : pc
    generic map(
      PC_WIDTH => pc_width
    )
    port map(
			entrada => aux_novo_pc,
			saida => aux_pc_out,
			clk => clock,
			we => aux_we_pc,
			reset => reset
    );

  instancia_somador_pc : somador
    generic map(
      largura_dado => pc_width
    )
    port map(
			entrada_a => aux_pc_out,
			entrada_b => x"004",
			saida => aux_pc_plus4
    );

  instancia_somador_branch : somador
    generic map(
      largura_dado => pc_width
    )
    port map(
			entrada_a => aux_jump_address,
			entrada_b => aux_pc_plus4,
			saida => aux_branch_address
    );

    instancia_extensor : extensor
    	generic map(
        largura_dado => immediate_width,
        largura_saida => data_width
      )
      port map(
        ExtType => aux_ext_type,
    		entrada_Rs => aux_imediato,
    		saida => aux_ext_imediato
	    );

    instancia_shift_L2_jump : deslocador
    	generic map(
		    largura_dado => pc_width,
		    largura_qtde => 2
      )
      port map(
    		ent_rs_dado => aux_jump,        
    		ent_rt_ende => "10",    
    		ent_tipo_deslocamento => "01",
    		sai_rd_dado => aux_jump_address         
	    );

    instancia_shift_L16_lui : deslocador
    	generic map(
		    largura_dado => data_width,
		    largura_qtde => 5
      )
      port map(
    		ent_rs_dado => aux_ext_imediato,
    		ent_rt_ende => "10000",
    		ent_tipo_deslocamento => "01",
    		sai_rd_dado => aux_lui
	    );

    instancia_HI : registrador
      generic map(
        largura_dado => data_width
      )
      port map (
        entrada_dados => aux_mult_div_out_hi,
        WE => aux_we_hi_lo,
        clk => clock,
        reset => reset,
        saida_dados => aux_hi_out
      );
    instancia_LO : registrador
      generic map(
        largura_dado => data_width
      )
      port map (
        entrada_dados => aux_mult_div_out_lo,
        WE => aux_we_hi_lo,
        clk => clock,
        reset => reset,
        saida_dados => aux_lo_out
      );

    instancia_mul_div : multiplicador_divisor
      generic map(
        largura_dado => data_width
      )
      port map (
		  sel => aux_sel_mult_div,
        entrada_a => aux_data_outrs,
        entrada_b => aux_data_outrt,
        saida_hi => aux_mult_div_out_hi,
        saida_lo => aux_mult_div_out_lo,
        div_0   => div_0
      );

    instancia_mux41_pc : mux41
      generic map(
        largura_dado => pc_width
      )
      port map (
        dado_ent_0 => aux_pc_plus4,
        dado_ent_1 => aux_branch_address,
        dado_ent_2 => aux_jump_address,
        dado_ent_3 => aux_data_outrs(pc_width - 1 downto 0),
        sele_ent => aux_pcsrc(1 downto 0),
        dado_sai => aux_mux41_pc_out
      );

    instancia_mux21_pc : mux21
      generic map(
        largura_dado => pc_width
      )
      port map (
        dado_ent_0 => aux_mux41_pc_out,
        dado_ent_1 => aux_c0_int_vector, --saída do coprocessador INT_VECTOR
        sele_ent => aux_pcsrc(2),
        dado_sai => aux_novo_pc
      );

    instancia_mux81_wd3 : mux81
      generic map(
        largura_dado => data_width
      )
      port map (
		  sele_ent => aux_wregdata,
        dado_ent_0 => aux_ula_out,
        dado_ent_1 => aux_mem_data,
        dado_ent_2 => aux_lo_out,
        dado_ent_3 => aux_hi_out,
        dado_ent_4 => aux_c0_rd, --saída do coprocessador C0_RD
        dado_ent_5 => aux_zero_extended_pc_plus4,
        dado_ent_6 => aux_lui,
        dado_ent_7 => aux_shifter_out,
        dado_sai	 => aux_mux81_wd3_out
      );

    instancia_mux21_a3_a : mux21
      generic map(
        largura_dado => fr_addr_width
      )
      port map (
        dado_ent_0 => aux_read_rt,
        dado_ent_1 => aux_write_rd,
        sele_ent => aux_wregsrc(0),
        dado_sai => aux_mux21_a3_a_to_b
      );

    instancia_mux21_a3_b : mux21
      generic map(
        largura_dado => fr_addr_width
      )
      port map (
        dado_ent_0 => aux_mux21_a3_a_to_b,
        dado_ent_1 => "11111", -- REG 31 (RETURN ADDRESS REGISTER)
        sele_ent => aux_wregsrc(1),
        dado_sai => aux_addr_a3
      );

    instancia_mux21_alu : mux21
      generic map(
        largura_dado => data_width
      )
      port map (
        dado_ent_0 => aux_data_outrt,
        dado_ent_1 => aux_ext_imediato,
        sele_ent => aux_alusrc,
        dado_sai => aux_alu_ent_b
      );

    instancia_shift_sll_srl : deslocador
    	generic map(
		    largura_dado => data_width,
		    largura_qtde => 5
      )
      port map(
    		ent_rs_dado => aux_data_outrt,
    		ent_rt_ende => aux_shamt_sa,
    		ent_tipo_deslocamento => aux_ent_tipo_deslocamento,
    		sai_rd_dado => aux_shifter_out
	    );
      
end architecture comportamento;