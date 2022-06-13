-- Universidade Federal de Minas Gerais
-- Escola de Engenharia
-- Departamento de Engenharia Eletrônica
-- Autoria: --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ula is
    generic (
        largura_dado : natural
    );

    port (
        entrada_a : in std_logic_vector((largura_dado - 1) downto 0);
        entrada_b : in std_logic_vector((largura_dado - 1) downto 0);
        seletor   : in std_logic_vector(2 downto 0);
--        shamt     : in std_logic_vector(4 downto 0);
        saida     : out std_logic_vector((largura_dado - 1) downto 0);
        zero      : out std_logic
    );
end ula;

architecture comportamental of ula is
    signal resultado_ula : std_logic_vector((largura_dado - 1) downto 0);
	 signal aux_resultado_ula : std_logic_vector((largura_dado - 1) downto 0);

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

begin
    process (entrada_a, entrada_b, seletor, resultado_ula) is
	 
	 begin
        case(seletor) is
            when "000" => -- soma com sinal
            resultado_ula <= std_logic_vector(signed(entrada_a) + signed(entrada_b));
            when "001" => -- subtração com sinal
            resultado_ula <= std_logic_vector(signed(entrada_a) - signed(entrada_b));
            when "010" => -- and lógico
            resultado_ula <= entrada_a and entrada_b;
            when "011" => -- or lógico
            resultado_ula <= entrada_a or entrada_b;
            when "100" => -- xor lógico
            resultado_ula <= entrada_a xor entrada_b;
            when "101" => -- nor lógico
            resultado_ula <= entrada_a nor entrada_b;
            when "110" => -- set less than
					if(entrada_a < entrada_b) then
						resultado_ula <= (others => '1');
					else
						resultado_ula <= (others => '0');
					end if;
--            when "0111" => -- shift left
--				resultado_ula <= STD_LOGIC_VECTOR( shift_left(unsigned(entrada_a),to_integer(unsigned(shamt))));
--           when "1000" => -- shift right
--				resultado_ula <= STD_LOGIC_VECTOR( shift_right(unsigned(entrada_a),to_integer(unsigned(shamt))));
            when others => -- NOT USED
              resultado_ula <= x"FFFFFFFF";
--            resultado_ula <= entrada_a xnor entrada_b;
        end case;
        if(resultado_ula = x"00000000") then
          zero <= '1';
        else
          zero <= '0';
        end if;
    end process;
    saida <= resultado_ula;
end comportamental;