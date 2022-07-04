-- Universidade Federal de Minas Gerais
-- Escola de Engenharia
-- Departamento de Engenharia Eletrônica
-- Autoria: Professor Ricardo de Oliveira Duarte
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity processador_ciclo_unico is
  generic (
    DATA_WIDTH : natural := 32; -- tamanho do barramento de dados em bits
    PROC_INSTR_WIDTH : natural := 32; -- tamanho da instrução do processador em bits
    PROC_ADDR_WIDTH : natural := 12; -- tamanho do endereço da memória de programa do processador em bits
    MEM_ADDR_WIDTH : natural := 16; -- tamanho do endereço da memória de dados
    c0_out_data_in_bus_width : natural := 36; -- tamanho do barramento de entrada de dados que comunica com o Coprocessador 0
    c0_in_data_out_bus_width : natural := 50; -- tamanho do barramento de saída de dados que comunica com o Coprocessador 0'
    data_in_ctrl_out_bus_width : natural := 19; -- tamanho do barramento de controle da via de dados (DP) em bits-- WE_hi_lo
    data_out_ctrl_in_bus_width : natural := 2;
    pc_width : natural := 12;
    fr_addr_width : natural := 5; -- tamanho da linha de endereços do banco de registradores em bits
    ula_ctrl_width : natural := 3; -- tamanho da linha de controle da ULA
    immediate_width : natural := 16; -- tamanho do imediato
    number_of_words : natural := 2048; -- número de words que a sua memória é capaz de armazenar: 4kB 
    MD_DATA_WIDTH : natural := 32; -- tamanho do dado de leitura e escrita
    --	 	MD_WORD_WIDTH				  : natural := 8; -- Tamanho da palavra
    CONTROL_UNIT_INSTR_WIDTH : natural := 13;
    CONTROL_UNIT_OPCODE_WIDTH : natural := 6;
    CONTROL_UNIT_FUNCT_WIDTH : natural := 6;
    MI_WORD_WIDTH : natural := 8;
	 irq_vector_width : natural := 7
  );
  port (
    --		Chaves_entrada 			: in std_logic_vector(DATA_WIDTH-1 downto 0);
    --		Chave_enter				: in std_logic;
    --Leds_vermelhos_saida : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    Chave_reset : in std_logic;
    Clock : in std_logic;
    debug_read_Rs : out std_logic_vector(3 downto 0);
	 irq_vector	: in std_logic_vector(irq_vector_width-2 downto 0)
  );
end processador_ciclo_unico;

architecture comportamento of processador_ciclo_unico is
  -- declare todos os componentes que serão necessários no seu processador_ciclo_unico a partir deste comentário
  component via_de_dados_ciclo_unico is
    generic (
      -- declare todos os tamanhos dos barramentos (sinais) das portas da sua via_dados_ciclo_unico aqui.
      c0_bus_in_width : natural; -- tamanho do barramento de entrada de dados que comunica com o Coprocessador 0
      c0_bus_out_width : natural; -- tamanho do barramento de saída de dados que comunica com o Coprocessador 0
      in_ctrl_bus_width : natural; -- tamanho do barramento de controle da via de dados (DP) em bits-- WE_hi_lo
      out_ctrl_bus_width : natural;
      data_width : natural; -- tamanho do dado em bits
      pc_width : natural; -- tamanho da entrada de endereços da MI ou MP em bits (memi.vhd)
      fr_addr_width : natural; -- tamanho da linha de endereços do banco de registradores em bits
      ula_ctrl_width : natural; -- tamanho da linha de controle da ULA
      instr_width : natural; -- tamanho da instrução em bits
      immediate_width : natural -- tamanho do imediato em bits
    );
    port (
      clock : in std_logic;
      reset : in std_logic;
      --barramento que vem da Control Unit
      controle_in : in std_logic_vector(in_ctrl_bus_width - 1 downto 0);
      controle_out : out std_logic_vector(out_ctrl_bus_width - 1 downto 0);
      --barramento que vem do C0
      c0_bus_in : in std_logic_vector(c0_bus_in_width - 1 downto 0);
      c0_bus_out : out std_logic_vector(c0_bus_out_width - 1 downto 0);
      data_mem_data : in std_logic_vector(data_width - 1 downto 0);
      instrucao : in std_logic_vector(instr_width - 1 downto 0);
      pc_out : out std_logic_vector(pc_width - 1 downto 0);
      data_mem_write_data : out std_logic_vector(data_width - 1 downto 0);
      data_mem_addr : out std_logic_vector((data_width/2) - 1 downto 0);
      debug_read_Rs : out std_logic_vector(3 downto 0)

    );
  end component;

  component unidade_de_controle_ciclo_unico is
    generic (
      INSTR_WIDTH : natural;
      OPCODE_WIDTH : natural;
      FUNCT_WIDTH : natural;
      dp_in_ctrl_bus_width : natural;
      dp_out_ctrl_bus_width : natural;
      ula_ctrl_width : natural
    );
    port (
      instrucao : in std_logic_vector(INSTR_WIDTH - 1 downto 0); -- instrução
      datapath_out : out std_logic_vector(dp_out_ctrl_bus_width - 1 downto 0); -- controle da via
      datapath_in : in std_logic_vector(dp_in_ctrl_bus_width - 1 downto 0); -- controle da via
      interrupt_request : in std_logic;
      cop0_we : out std_logic;
      --syscall : out std_logic;
      --bad_instr : out std_logic;
      data_mem_we : out std_logic;
      data_mem_re : out std_logic
    );
  end component;

  component memi is
    generic (
      INSTR_WIDTH : natural; -- tamanho da instrução em número de bits
      MI_ADDR_WIDTH : natural; -- tamanho do endereço da memória de instruções em número de bits
      MI_WORD_WIDTH : natural
    );
    port (
      clk : in std_logic;
      reset : in std_logic;
      Endereco : in std_logic_vector(MI_ADDR_WIDTH - 1 downto 0);
      Instrucao : out std_logic_vector(INSTR_WIDTH - 1 downto 0)
    );
  end component;

component ram1port_ciclounico IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (10 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		wren		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
END component;
  
component coprocessador_0 is   
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
end component;

  -- Declare todos os sinais auxiliares que serão necessários no seu processador_ciclo_unico a partir deste comentário.
  -- Você só deve declarar sinais auxiliares se estes forem usados como "fios" para interligar componentes.
  -- Os sinais auxiliares devem ser compatíveis com o mesmo tipo (std_logic, std_logic_vector, etc.) e o mesmo tamanho dos sinais dos portos dos
  -- componentes onde serão usados.
  -- Veja os exemplos abaixo:

  -- A partir deste comentário faça associações necessárias das entradas declaradas na entidade do seu processador_ciclo_unico com 
  -- os sinais que você acabou de definir.
  -- Veja os exemplos abaixo:
  signal aux_instrucao : std_logic_vector(PROC_INSTR_WIDTH - 1 downto 0);
  signal aux_ctrl_in_data_out : std_logic_vector(data_out_ctrl_in_bus_width - 1 downto 0);
  signal aux_ctrl_out_data_in : std_logic_vector(data_in_ctrl_out_bus_width - 1 downto 0);

  signal aux_c0_out_data_in : std_logic_vector(c0_out_data_in_bus_width - 1 downto 0);
  signal aux_c0_in_data_out : std_logic_vector(c0_in_data_out_bus_width - 1 downto 0);

  signal aux_endereco : std_logic_vector(PROC_ADDR_WIDTH - 1 downto 0);

  signal aux_mem_write_enable : std_logic;
  signal aux_write_data_mem : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal aux_read_data_mem : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal aux_addr_mem : std_logic_vector(MEM_ADDR_WIDTH - 1 downto 0) := std_logic_vector(to_unsigned(0, MEM_ADDR_WIDTH));

  signal aux_interrupt_request : std_logic;
  --signal aux_syscall : std_logic;
  signal aux_cop0_we : std_logic;
  --signal aux_bad_instr : std_logic;

  signal aux_instrucao_control_unit : std_logic_vector(CONTROL_UNIT_INSTR_WIDTH - 1 downto 0);
  signal aux_mem_read_enable : std_logic;
  
  signal aux_acknowledge		: std_logic;

  -- signal Clock 					: std_logic;
  --signal Chave_reset				: std_logic;

begin
  -- A partir deste comentário instancie todos o componentes que serão usados no seu processador_ciclo_unico.
  -- A instanciação do componente deve começar com um nome que você deve atribuir para a referida instancia seguido de : e seguido do nome
  -- que você atribuiu ao componente.
  -- Depois segue o port map do referido componente instanciado.
  -- Para fazer o port map, na parte da esquerda da atribuição "=>" deverá vir o nome de origem da porta do componente e na parte direita da 
  -- atribuição deve aparecer um dos sinais ("fios") que você definiu anteriormente, ou uma das entradas da entidade processador_ciclo_unico,
  -- ou ainda uma das saídas da entidade processador_ciclo_unico.
  -- Veja os exemplos de instanciação a seguir:
  --Clock<= Clock;
  --Chave_reset<= Chave_reset;

  aux_acknowledge <= aux_ctrl_out_data_in(18);
  aux_instrucao_control_unit <= aux_instrucao(23) & aux_instrucao(31 downto 26) & aux_instrucao(5 downto 0);
  --  aux_mem_read_enable <= NOT(aux_mem_write_enable);

  instancia_memi : memi
  generic map(
    INSTR_WIDTH => PROC_INSTR_WIDTH, -- tamanho da instrução em número de bits
    MI_ADDR_WIDTH => PROC_ADDR_WIDTH, -- tamanho do endereço da memória de instruções em número de bits
    MI_WORD_WIDTH => MI_WORD_WIDTH
  )
  port map(
    clk => Clock,
    reset => Chave_reset,
    Endereco => aux_endereco,
    Instrucao => aux_instrucao
  );

  instancia_memd : ram1port_ciclounico

  port map(
    clock => Clock,
    wren => aux_mem_write_enable,
    data => aux_write_data_mem,
    address => aux_addr_mem(10 downto 0),
    q => aux_read_data_mem
  );
  

  instancia_unidade_de_controle_ciclo_unico : unidade_de_controle_ciclo_unico
  generic map(
    INSTR_WIDTH => CONTROL_UNIT_INSTR_WIDTH,
    OPCODE_WIDTH => CONTROL_UNIT_OPCODE_WIDTH,
    FUNCT_WIDTH => CONTROL_UNIT_FUNCT_WIDTH,
    dp_in_ctrl_bus_width => data_out_ctrl_in_bus_width,
    dp_out_ctrl_bus_width => data_in_ctrl_out_bus_width,
    ula_ctrl_width => ula_ctrl_width
  )
  port map(
    instrucao => aux_instrucao_control_unit,
    datapath_out => aux_ctrl_out_data_in, --conecta a saída da ControlUnit com a entrada do Datapath
    datapath_in => aux_ctrl_in_data_out, --conecta a saída do Datapath com a entrada da ControlUnit
    interrupt_request => aux_interrupt_request,
    cop0_we => aux_cop0_we,
    --syscall => aux_syscall,
    --bad_instr => aux_bad_instr,
    data_mem_we => aux_mem_write_enable,
    data_mem_re => aux_mem_read_enable
  );

  instancia_via_de_dados_ciclo_unico : via_de_dados_ciclo_unico
  generic map(
    c0_bus_in_width => c0_out_data_in_bus_width, -- tamanho do barramento de entrada de dados que comunica com o Coprocessador 0
    c0_bus_out_width => c0_in_data_out_bus_width, -- tamanho do barramento de saída de dados que comunica com o Coprocessador 0
    in_ctrl_bus_width => data_in_ctrl_out_bus_width, -- tamanho do barramento de controle da via de dados (DP) em bits-- WE_hi_lo
    out_ctrl_bus_width => data_out_ctrl_in_bus_width,
    data_width => DATA_WIDTH, -- tamanho do dado em bits
    pc_width => pc_width, -- tamanho da entrada de endereços da MI ou MP em bits (memi.vhd)
    fr_addr_width => fr_addr_width, -- tamanho da linha de endereços do banco de registradores em bits
    ula_ctrl_width => ula_ctrl_width, -- tamanho da linha de controle da ULA
    instr_width => PROC_INSTR_WIDTH, -- tamanho da instrução em bits
    immediate_width => immediate_width -- tamanho do imediato em bits
  )
  port map(
    -- declare todas as portas da sua via_dados_ciclo_unico aqui.
    clock => Clock,
    reset => Chave_reset,
    --barramento que vem da Control Unit
    controle_in => aux_ctrl_out_data_in, --conecta a saída da ControlUnit com a entrada do Datapath
    controle_out => aux_ctrl_in_data_out, --conecta a saída do Datapath com a entrada da ControlUnit
    --barramento que vem do C0
    c0_bus_in => aux_c0_out_data_in, --conecta saída do Coprocessador 0 para a entrada do Datapath 
    c0_bus_out => aux_c0_in_data_out, --conecta saída do Datapath para a entrada do Coprocessador 0
    --barramento com o Program Counter
    instrucao => aux_instrucao,
    pc_out => aux_endereco,
    --barramento com a memória de dados
    data_mem_write_data => aux_write_data_mem,
    data_mem_addr => aux_addr_mem,
    data_mem_data => aux_read_data_mem,
    debug_read_Rs => debug_read_Rs
  );
  
  instancia_coprocessador_0 : coprocessador_0
  generic map(
    c0_out_data_in_bus_width 	=> c0_out_data_in_bus_width, -- tamanho do barramento de entrada de dados que comunica com o Coprocessador 0
    c0_in_data_out_bus_width 	=> c0_in_data_out_bus_width, -- tamanho do barramento de saída de dados que comunica com o Coprocessador 0
	 DATA_WIDTH 					=> DATA_WIDTH,							 				-- tamanho do barramento de dados em bits
	 PROC_ADDR_WIDTH 				=> PROC_ADDR_WIDTH,				 				-- tamanho do endereÃ§o da memÃ³ria de programa do processador em bits
	 fr_addr_width 				=> fr_addr_width,					 				-- tamanho da linha de endereÃ§os do banco de registradores em bits
	 irq_vector_width				=> irq_vector_width									-- quantidade de interrupções 
  )
  port map(
	 clock => Clock,					
	 reset => Chave_reset,					
	 --IRQs
	 irq_vector => irq_vector, 			--Entradas de bits para requisiÃ§Ã£o de interrupÃ§Ãµes dos perifericos
    --IOs Datapath
    c0_out_data_in => aux_c0_out_data_in, --Sai do c0 e vai pro datapath
    c0_in_data_out => aux_c0_in_data_out, --Sai do datapath e vai pro c0
    --IOs control unit	
    interrupt_request => aux_interrupt_request,
    cop0_we => aux_cop0_we,
	 Acknowledge => aux_acknowledge
  );  

end comportamento;