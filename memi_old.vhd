-- Universidade Federal de Minas Gerais
-- Escola de Engenharia
-- Departamento de Engenharia Eletronica
-- Autoria: Professor Ricardo de Oliveira Duarte
-- Memória de Programas ou Memória de Instruções de tamanho genérico
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memi is
	generic (
		INSTR_WIDTH   : natural; -- tamanho da instrucaoo em numero de bits
		MI_WORD_WIDTH : natural;
		MI_ADDR_WIDTH : natural  -- tamanho do endereco da memoria de instrucoes em numero de bits
	);
	port (
		clk       : in std_logic;
		reset     : in std_logic;
		Endereco  : in std_logic_vector(MI_ADDR_WIDTH - 1 downto 0);
		Instrucao : out std_logic_vector(INSTR_WIDTH - 1 downto 0)
	);
end entity;

architecture comportamental of memi is
	type rom_type is array (0 to 2 ** MI_ADDR_WIDTH - 1) of std_logic_vector(MI_WORD_WIDTH - 1 downto 0);
	signal rom : rom_type;
begin
	process (clk, reset, Endereco, rom) is
	--process (reset, Endereco) is
	begin
	if (falling_edge(clk)) then
			if (reset = '1') then
				rom <= (
					3 => X"20", 2 => X"21", 1 => X"00", 0 => X"00", -- exemplo de uma instrução qualquer de 16 bits (4 símbos em hexadecimal)
					7 => X"20",	6 => X"21", 5 => X"00", 4 => X"01",  
					11 => X"20", 10 => X"21", 9 => X"00", 8 => X"01", 
					15 => X"20", 14 => X"21", 13 => X"00", 12 => X"01",
					19 => X"20", 18 => X"21", 17 => X"00", 16 => X"01",
					23 => X"20", 22 => X"21", 21 => X"00", 20 => X"01",
					27 => X"20", 26 => X"21", 25 => X"00", 24 => X"01",
--					31 => X"00", 30 => X"01", 29 => X"18", 28 => X"2A",
--					35 => X"00", 34 => X"01", 33 => X"20", 32 => X"42",
--					39 => X"00", 38 => X"01", 37 => X"20", 36 => X"40",
--					43 => X"00", 42 => X"22", 41 => X"00", 40 => X"1A",
--					47 => X"00", 46 => X"00", 45 => X"20", 44 => X"12",
--					51 => X"00", 50 => X"00", 49 => X"20", 48 => X"11",
--					55 => X"00", 54 => X"41", 53 => X"00", 52 => X"18",
--					59 => X"00", 58 => X"00", 57 => X"18", 56 => X"12",
--					63 => X"3C", 62 => X"04", 61 => X"FF", 60 => X"FF",
--					67 => X"34", 66 => X"04", 65 => X"FF", 64 => X"FF",
--					71 => X"AC", 70 => X"03", 69 => X"00", 68 => X"00",
--					75 => X"8C", 74 => X"04", 73 => X"00", 72 => X"00",
					
	--				0011 1100 0000 0001 
				--	3C 01
					
					others => X"00"  -- exemplo de uma instrução qualquer de 16 bits (4 símbos em hexadecimal)
					);
				Instrucao <= x"20210000";
			else
				--Little Endianess
				--Instrucao <= rom(to_integer(unsigned(Endereco)+3)) & rom(to_integer(unsigned(Endereco)+2)) & rom(to_integer(unsigned(Endereco)+1)) & rom(to_integer(unsigned(Endereco)));
				Instrucao(31 downto 24) <= rom(to_integer(unsigned(Endereco)+3));
				Instrucao(23 downto 16) <= rom(to_integer(unsigned(Endereco)+2));
				Instrucao(15 downto 8) <= rom(to_integer(unsigned(Endereco)+1));
				Instrucao(7 downto 0) <= rom(to_integer(unsigned(Endereco)));
			end if;
		end if;
	end process;
end comportamental;