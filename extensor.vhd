-- Universidade Federal de Minas Gerais
-- Escola de Engenharia
-- Departamento de Engenharia Eletronica
-- Autoria: Professor Ricardo de Oliveira Duarte
-- Extensor de sinais. Replica o bit de sinal da entrada Rs (largura_saida-largura_dado) vezes.
library ieee;
use ieee.std_logic_1164.all;

entity extensor is
	generic (
		largura_dado  : natural;
		largura_saida : natural
	);

	port (
		ExtType    : in std_logic;
		entrada_Rs : in std_logic_vector((largura_dado - 1) downto 0);
		saida      : out std_logic_vector((largura_saida - 1) downto 0)
	);
end extensor;

architecture comportamental of extensor is
	signal extensao : std_logic_vector((largura_dado - 1) downto 0);
begin
  process(ExtType, entrada_Rs, extensao)
  begin
    if(ExtType = '1') then
  	  extensao <= (others => entrada_Rs(largura_dado - 1)); -- todos os bits da extensão correspondem ao bit mais significativo da entrada Rs
  	  saida    <= extensao & entrada_Rs;                    -- saida com o sinal estendido de Rs, concatenado com Rs. 
    else
      extensao <= (others => '0');
      saida <= extensao & entrada_Rs;
    end if;
  end process;
end comportamental;