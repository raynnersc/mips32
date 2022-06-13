-- Universidade Federal de Minas Gerais
-- Escola de Engenharia
-- Departamento de Engenharia Eletrônica
-- Autoria: Daniel, Raynner e Stephanie

library ieee;
use ieee.std_logic_1164.all;

entity ALU_Decoder is
	generic(
    FUNCT_WIDTH : natural
  );
  port(
			Funct	: in std_logic_vector(5 downto 0);
			ALUOp	: in std_logic_vector(1 downto 0);
			ALUCtrl	: out std_logic_vector(2 downto 0)
		);
end ALU_Decoder;

architecture behavior of ALU_Decoder is
begin

	process(Funct,ALUOp) is
	begin
		case ALUOp is
			when "00" =>
				ALUCtrl	<=	"000"; --ADD
			
			when "01" =>
				ALUCtrl	<=	"001"; --SUBTRACT
			
			when "11" =>
				ALUCtrl	<=	"011"; --OR
				
			when "10" => 	--VERIFICA CAMPO FUNCT
				case Funct is
					when "100000" =>
						ALUCtrl	<=	"000"; --ADD
						
					when "100010" =>					
						ALUCtrl	<=	"001"; --SUBTRACT
						
					when "100100" =>						
						ALUCtrl	<=	"010"; --AND
						
					when "100101" =>
						ALUCtrl	<=	"011"; --OR

					when "100110" =>
						ALUCtrl	<=	"100"; --XOR	

					when "100111" =>
						ALUCtrl	<=	"101"; --NOR	

					when "101010" =>						
						ALUCtrl	<=	"110"; --SET LESS THAN
						
					when others =>
						ALUCtrl	<=	"111"; --ALU NOT USED
				end case;			
			when others =>
				ALUCtrl	<=	"111"; --ALU NOT USED
		end case;
	end process;

end behavior;