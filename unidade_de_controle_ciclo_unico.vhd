-- Universidade Federal de Minas Gerais
-- Escola de Engenharia
-- Departamento de Engenharia Eletrônica
-- Autoria: Professor Ricardo de Oliveira Duarte
-- Unidade de controle ciclo único (look-up table) do processador
-- puramente combinacional
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- unidade de controle
entity unidade_de_controle_ciclo_unico is   
    generic (
        INSTR_WIDTH             : natural;
        OPCODE_WIDTH            : natural;
        FUNCT_WIDTH             : natural;
        dp_in_ctrl_bus_width    : natural;
        dp_out_ctrl_bus_width   : natural;
		  ula_ctrl_width			: natural
    );
    port (
        instrucao : in std_logic_vector(INSTR_WIDTH - 1 downto 0);       -- instrução
        datapath_out  : out std_logic_vector(dp_out_ctrl_bus_width - 1 downto 0); -- controle da via
        datapath_in :  in std_logic_vector(dp_in_ctrl_bus_width - 1 downto 0); -- controle da via
      
        interrupt_request : in std_logic;
        cop0_we : out std_logic;
		  --Acknowledge : out std_logic;
        --syscall : out std_logic;
        --bad_instr : out std_logic;

        data_mem_we : out std_logic;
		  data_mem_re :out std_logic
    );
end unidade_de_controle_ciclo_unico;

architecture beh of unidade_de_controle_ciclo_unico is


    component ALU_Decoder is
      generic (
        FUNCT_WIDTH   : natural
      );    
      port(
        Funct	: in std_logic_vector(5 downto 0);
        ALUOp	: in std_logic_vector(1 downto 0);
        ALUCtrl	: out std_logic_vector(2 downto 0)
      );
    end component;

    component main_decoder is
    	generic (
        OPCODE_WIDTH  : natural;
        FUNCT_WIDTH   : natural
      );
      port(
        --Instruction Memory
        Opcode	            : in std_logic_vector(5 downto 0);
        Funct	              : in std_logic_vector(5 downto 0);
        MoveC0Direction     : in std_logic;   --TEM QUE CONECTAR AINDA
        --Datapath Inputs
        less_than_0         :in  std_logic;
        zero                :in  std_logic;
        --Datapath Outputs
        srl_sll_sel         :out std_logic;
        ext_type            :out std_logic;
        sel_mult_div			  :out std_logic;
        alusrc					    :out std_logic;
        we_hi_lo				    :out std_logic;
        wregsrc					    :out std_logic_vector(1 downto 0);
        pcsrc               :out std_logic_vector(2 downto 0);
        wregdata            :out std_logic_vector(2 downto 0);
        we_pc					      :out std_logic;   
        reg_write           :out std_logic;
        data_mem_we         :out std_logic;
		  data_mem_re         :out std_logic; 
        --Alu
        ALUOp	              :out std_logic_vector(1 downto 0);
        --Coprocessor 0
        interrupt_request   :in std_logic;
        cop0_we             :out std_logic;
        syscall             :out std_logic;
        bad_instr           :out std_logic
    	);
    end component;
  
    -- As linhas abaixo não produzem erro de compilação no Quartus II, mas no Modelsim (GHDL) produzem.	
    --signal inst_aux : std_logic_vector (INSTR_WIDTH-1 downto 0);			-- instrucao
    --signal aux_opcode   : std_logic_vector (OPCODE_WIDTH-1 downto 0);			-- opcode
    --signal aux_funct   : std_logic_vector (FUNCT_WIDTH-1 downto 0);			-- opcode
    --signal ctrl_aux : std_logic_vector (DP_CTRL_BUS_WIDTH-1 downto 0);		-- controle

    signal inst_aux : std_logic_vector (12 downto 0); -- instrucao
    signal aux_opcode   : std_logic_vector (5 downto 0);  -- opcode
    signal aux_funct   : std_logic_vector (5 downto 0);  -- opcode
--    signal ctrl_aux : std_logic_vector (5 downto 0);  -- controle

    signal aux_less_than_0 : std_logic;
    signal aux_zero  :  std_logic;

    signal aux_srl_sll_sel         : std_logic;
    signal aux_ext_type            : std_logic;
    signal aux_sel_mult_div			   : std_logic;
    signal aux_alusrc					     : std_logic;
    signal aux_we_hi_lo				     : std_logic;
    signal aux_wregsrc					   : std_logic_vector(1 downto 0);
    signal aux_pcsrc               : std_logic_vector(2 downto 0);
    signal aux_wregdata            : std_logic_vector(2 downto 0);
    signal aux_we_pc					     : std_logic;   
  	signal aux_reg_write           : std_logic;        
  	signal aux_ula_ctrl            : std_logic_vector(ula_ctrl_width - 1 downto 0);

    signal aux_ula_op              : std_logic_vector(1 downto 0);

    signal aux_MoveC0Direction     : std_logic;
	 signal Acknowledge				  : std_logic;

begin

    aux_less_than_0 <= datapath_in(1);
    aux_zero <= datapath_in(0);

	 datapath_out(18) <= Acknowledge;
    datapath_out(17) <= aux_srl_sll_sel;
    datapath_out(16) <= aux_ext_type;
    datapath_out(15) <= aux_sel_mult_div;
    datapath_out(14) <= aux_alusrc;
    datapath_out(13) <= aux_we_hi_lo;
    datapath_out(12 downto 11) <= aux_wregsrc;
    datapath_out(10 downto 8) <= aux_pcsrc;
    datapath_out(7 downto 5) <= aux_wregdata;
    datapath_out(4) <= aux_we_pc;            
    datapath_out(3) <= aux_reg_write;          
    datapath_out(2 downto 0) <= aux_ula_ctrl;   
  
    inst_aux <= instrucao;
    -- A linha abaixo não produz erro de compilação no Quartus II, mas no Modelsim (GHDL) produz.	
    --  aux_MoveC0Direction <= inst_aux(INSTR_WIDTH);
    --	aux_opcode <= inst_aux (INSTR_WIDTH-1 downto INSTR_WIDTH-OPCODE_WIDTH);
    --	aux_funct <= inst_aux (INSTR_WIDTH-OPCODE_WIDTH-1 downto 0);
    aux_MoveC0Direction <= inst_aux (12);
    aux_opcode <= inst_aux (11 downto 6);
    aux_funct <= inst_aux (5 downto 0);

    instancia_alu_decoder : ALU_Decoder
      generic map( 
        FUNCT_WIDTH => FUNCT_WIDTH
      )
      port map(
          Funct	=> aux_funct,
          ALUOp	=> aux_ula_op,
          ALUCtrl	=> aux_ula_ctrl
      );

    instancia_main_decoder : main_decoder
      generic map(
        OPCODE_WIDTH => OPCODE_WIDTH, 
        FUNCT_WIDTH => FUNCT_WIDTH
      )
      port map(
        Opcode => aux_opcode,	      
        Funct => aux_funct,
        MoveC0Direction => aux_MoveC0Direction,
        
    		less_than_0 => aux_less_than_0,       
        zero => aux_zero,             
    	
        srl_sll_sel => aux_srl_sll_sel,         
        ext_type => aux_ext_type,           
        sel_mult_div => aux_sel_mult_div,			
        alusrc => aux_alusrc,					  
        we_hi_lo => aux_we_hi_lo,			   
        wregsrc => aux_wregsrc,					   
        pcsrc => aux_pcsrc,               
        wregdata => aux_wregdata,          
        we_pc	=> aux_we_pc,				     
      	reg_write => aux_reg_write,    
        
        ALUOp => aux_ula_op,

        interrupt_request => interrupt_request,
        cop0_we => cop0_we,
        --syscall => syscall,
        --bad_instr => bad_instr,
        data_mem_we => data_mem_we,
		  data_mem_re => data_mem_re
      );

end beh;