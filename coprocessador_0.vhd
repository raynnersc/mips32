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
entity coprocessador_0 is   
    generic (
		c0_out_data_in_bus_width      : natural;          -- tamanho do barramento de entrada de dados que comunica com o Coprocessador 0
		c0_in_data_out_bus_width 		: natural          -- tamanho do barramento de saída de dados que comunica com o Coprocessador 0
    );
    port (
	 --IOs Datapath
		c0_out_data_in  : out std_logic_vector(c0_out_data_in_bus_width - 1 downto 0);	--Sai do c0 e vai pro datapath
		c0_in_data_out  : in std_logic_vector(c0_in_data_out_bus_width   - 1 downto 0);	--Sai do datapath e vai pro c0

	 --IOs control unit
		interrupt_request : out std_logic;
		cop0_we : in std_logic;
		syscall : in std_logic;
		bad_instr : in std_logic
	  
    );
end coprocessador_0;

architecture beh of coprocessador_0 is

	begin
	
	c0_out_data_in <= std_logic_vector(to_unsigned(0 , c0_out_data_in'length));
	interrupt_request <= '0';
	

end beh;