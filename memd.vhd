-- Universidade Federal de Minas Gerais
-- Escola de Engenharia
-- Departamento de Engenharia Eletronica
-- Autoria: Professor Ricardo de Oliveira Duarte
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memd is
    generic (
        number_of_words : natural; -- número de words que a sua memória é capaz de armazenar
        MD_DATA_WIDTH   : natural; -- tamanho do dado de leitura e escrita
	--	  MD_WORD_WIDTH	: natural;  -- Tamanho da palavra
        MD_ADDR_WIDTH   : natural  -- tamanho do endereco da memoria de dados em bits
    );
    port (
        clk                 : in std_logic;
        mem_write, mem_read : in std_logic; --sinais do controlador
        write_data_mem      : in std_logic_vector(MD_DATA_WIDTH - 1 downto 0);
        adress_mem          : in std_logic_vector(MD_ADDR_WIDTH - 1 downto 0);
        read_data_mem       : out std_logic_vector(MD_DATA_WIDTH - 1 downto 0)
    );
end memd;

architecture comportamental of memd is
    --alocar espaço para a memoria e iniciar com 0
    type data_mem is array (0 to number_of_words - 1) of std_logic_vector(MD_DATA_WIDTH - 1 downto 0);
    
	 function init_ram
		return data_mem is 
		variable tmp : data_mem := (others => (others => '0'));
	begin 
		for addr_pos in 0 to 2047 loop 
			-- Initialize each address with the address itself
			tmp(addr_pos) := std_logic_vector(to_unsigned(addr_pos, MD_DATA_WIDTH));
		end loop;
		return tmp;
	end init_ram;
	 
	 --signal ram      : data_mem := (others => (others => '0'));
	 signal ram      	 : data_mem := init_ram;
    signal ram_addr	 : std_logic_vector(MD_ADDR_WIDTH - 1 downto 0) := std_logic_vector( to_unsigned(0, MD_ADDR_WIDTH) );
	 signal ram_addr_r : std_logic_vector(MD_ADDR_WIDTH - 1 downto 0) := std_logic_vector( to_unsigned(0, MD_ADDR_WIDTH) );
begin
    ram_addr <= adress_mem(MD_ADDR_WIDTH - 1 downto 0);
    process (clk)
    --process(ram_addr,write_data_mem,mem_write,mem_read,ram)
	 begin
        if (rising_edge(clk)) then
            if (mem_write = '1') then
					 ram(to_integer(unsigned(ram_addr))) <= write_data_mem;
            end if;
				ram_addr_r <= ram_addr;
		end if;
    end process;
	
	read_data_mem	<= ram(to_integer(unsigned(ram_addr_r))) when mem_read = '1';
        
end comportamental;