library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gpio_address_decoder is
	generic (
		ADDR_PERIPH_WIDTH : natural
	);
    port (
		  we			  : in	std_logic;
		  addr        : in	std_logic_vector(ADDR_PERIPH_WIDTH - 1 downto 0);
        ctrl_reg    : out  std_logic_vector(5 downto 0);
        ctrl_mux    : out  std_logic_vector(1 downto 0);
		  ctrl_if_A	  : out	std_logic;
		  ctrl_if_B	  : out	std_logic
    );
end gpio_address_decoder;

--Controle do Write Enable dos Registradores
--ctrl_reg(0): DIR_A
--ctrl_reg(1): DIR_B
--ctrl_reg(2): DATAOUT_A
--ctrl_reg(3): DATAOUT_B
--ctrl_reg(4): IE_A
--ctrl_reg(5): IE_B
--ctrl_reg(6): IF_A
--ctrl_reg(7): IF_B

--ctrl_mux: 00 - DATAIN_A
--          01 - DATAIN_B
--          10 - IF_A
--          11 - IF_B

--ctrl_if_A/B: 0 - operação normal
--         		1 - reset do bit de flag

architecture beh OF gpio_address_decoder IS
begin
	process(addr,we) is
	begin
		ctrl_reg <= "000000";
		ctrl_if_A <= '0';
		ctrl_if_B <= '0';
		case to_integer(unsigned(addr)) is
			when 0 =>                           --DIR_A
                ctrl_reg(0) <= we;
                ctrl_mux 	 <= "00";
            when 1 =>                           --DIR_B
                ctrl_reg(1) <= we;
                ctrl_mux 	 <= "00";
            when 2 =>                           --DATAIN_A
                ctrl_reg <= "000000";
                ctrl_mux <= "00";
            when 3 =>                           --DATAIN_B
                ctrl_reg <= "000000";
                ctrl_mux <= "01";
            when 4 =>                           --DATAOUT_A
                ctrl_reg(2) <= we;
                ctrl_mux 	 <= "00";
            when 5 =>                           --DATAOUT_B
                ctrl_reg(3) <= we;
                ctrl_mux 	 <= "00";
            when 6 =>                           --IE_A
                ctrl_reg(4) <= we;
                ctrl_mux 	 <= "00";
            when 7 =>                           --IE_B
                ctrl_reg(5) <= we;
                ctrl_mux 	 <= "00";
            when 8 =>                           --IF_A
						if(we = '1') then
							ctrl_if_A 	 <= '1';
						else
							ctrl_if_A 	 <= '0';
						end if;
						ctrl_reg <= "000000";
						ctrl_mux <= "10";
            when 9 =>                           --IF_B
						if(we = '1') then
							ctrl_if_B 	 <= '1';
						else
							ctrl_if_B 	 <= '0';
						end if;
						ctrl_reg <= "000000";
						ctrl_mux <= "11";
			when others =>
                ctrl_reg <= "000000";
                ctrl_mux <= "00";
					 ctrl_if_A  <= '0';
					 ctrl_if_B  <= '0';
		end case;

	end process;
	
end beh;