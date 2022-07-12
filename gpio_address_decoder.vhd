library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gpio_address_decoder is
	generic (
		ADDR_PERIPH_WIDTH : natural
	);
    port (
		addr        : in	std_logic_vector(ADDR_PERIPH_WIDTH - 1 downto 0);
        ctrl_reg    : out   std_logic_vector(5 downto 0);
        ctrl_mux    : out   std_logic_vector(1 downto 0)
    );
end gpio_address_decoder;

--Controle do Write Enable dos Registradores
--ctrl_reg(0): DIR_A
--ctrl_reg(1): DIR_B
--ctrl_reg(2): DATAOUT_A
--ctrl_reg(3): DATAOUT_B
--ctrl_reg(4): IE_A
--ctrl_reg(5): IE_B

--ctrl_mux: 00 - DATAIN_A
--          01 - DATAIN_B
--          10 - IF_A
--          11 - IF_B

architecture beh OF gpio_address_decoder IS
begin
	process(addr) is
	begin
		case to_integer(unsigned(addr)) is
			when 0 =>                           --DIR_A
                ctrl_reg <= "000001";
                ctrl_mux <= "00";
            when 1 =>                           --DIR_B
                ctrl_reg <= "000010";
                ctrl_mux <= "00";
            when 2 =>                           --DATAIN_A
                ctrl_reg <= "000000";
                ctrl_mux <= "00";
            when 3 =>                           --DATAIN_B
                ctrl_reg <= "000000";
                ctrl_mux <= "01";
            when 4 =>                           --DATAOUT_A
                ctrl_reg <= "000100";
                ctrl_mux <= "00";
            when 5 =>                           --DATAOUT_B
                ctrl_reg <= "001000";
                ctrl_mux <= "00";
            when 6 =>                           --IE_A
                ctrl_reg <= "010000";
                ctrl_mux <= "00";
            when 7 =>                           --IE_B
                ctrl_reg <= "100000";
                ctrl_mux <= "00";
            when 8 =>                           --IF_A
                ctrl_reg <= "000000";
                ctrl_mux <= "10";
            when 9 =>                           --IF_B
                ctrl_reg <= "000000";
                ctrl_mux <= "11";
			when others =>
                ctrl_reg <= "000000";
                ctrl_mux <= "00";
		end case;

	end process;
	
end beh;