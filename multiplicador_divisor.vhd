-- Universidade Federal de Minas Gerais
-- Escola de Engenharia
-- Departamento de Engenharia Eletrônica
-- Autoria: Professor Ricardo de Oliveira Duarte
-- Multiplicador puramente combinacional
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multiplicador_divisor is
    generic (
        largura_dado : natural
    );

    port (
        sel       : in std_logic;
        entrada_a : in std_logic_vector((largura_dado - 1) downto 0);
        entrada_b : in std_logic_vector((largura_dado - 1) downto 0);
        saida_hi  : out std_logic_vector((largura_dado - 1) downto 0);
        saida_lo  : out std_logic_vector((largura_dado - 1) downto 0);
		    div_0 : out std_logic -- flag de divisão por zero p/ tratamento de excecao
    );
end multiplicador_divisor;

architecture comportamental of multiplicador_divisor is

signal aux_saida : std_logic_vector((2*largura_dado - 1) downto 0);

begin
  process(sel, aux_saida, entrada_a, entrada_b)
  begin
	 aux_saida <= std_logic_vector( to_unsigned(0, aux_saida'length) );
    if(sel = '1') then
      aux_saida <= std_logic_vector(signed(entrada_a) * signed(entrada_b));
      saida_hi <= aux_saida((2*largura_dado - 1) downto largura_dado);
      saida_lo <= aux_saida((largura_dado - 1) downto 0);
		div_0 <= '0';
	  elsif(sel='0') and entrada_b = x"00000000" then
		  saida_lo <= x"00000000";
		  saida_hi <= x"00000000";
		  div_0 <= '1';
	  else
		  saida_lo <= std_logic_vector(signed(entrada_a) / signed(entrada_b));
		  saida_hi <= std_logic_vector(signed(entrada_a) mod signed(entrada_b));
		  div_0 <= '0';
	  end if;
  end process;
end comportamental;