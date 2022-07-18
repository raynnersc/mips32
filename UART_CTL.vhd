--Faz a interface do TX e RX com o processador
--Recebe da CPU configurações e dados a serem enviados e direciona para TX e RX
--Colhe do TX e RX sinais de interrupção e dados recebidos e envia para a CPU

--Faixa de endereços de memória reservados para UART:
--0xA a 0xD, x16 e x17

--Locais de memória necessarios:
-- 0xA - reg_clock_pbit 				- Ler/Escrever configuração de clocks por bit (TX e RX)
-- 0xB - saida o_RX_Byte do RX 		- Ler dado recebido (RX)
--	0xC - reg_tx_setup				 	- Ler/Escrever dado a ser enviado + bit de habilitação de envio (TX)
--	0xD - saída o_TX_Active do TX   - Ler bit de status de transimissão (para saber se o TX ainda esta ocupado) (TX)
-- 0x16- Ack Tx
-- 0x17- Ack Rx

--Operações de escrita:
--0xA e 0xC	- será necessária a geração de WE para esses dois resgitradores

--Operações de leitura:
--Todos os 4 endereços - será necessário um mux41 para selecionar o dado de saída e dois bits de seleção

--Interrupções:
--Termino de envio (Tx), Byte recebido (Rx)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity UART_CTL is
	generic(
		clocks_pbit_width : natural; --Min standard baud rate is 110 and max clock em DE10 is 50MHz, which yields 454545 clocks per bit. 19 bits is enough for this.
		tx_setup_width		: natural; --8 bits de dado e 1 bit de configuração (MSB)
		DATA_WIDTH			: natural
	);
	port(
		clock				: in std_logic;
		reset				: in std_logic;
		
		tx					: out std_logic;
		rx					: in std_logic;
		
		reg_addr			: in std_logic_vector(5 downto 0);
		data_in			: in std_logic_vector(DATA_WIDTH-1 downto 0);
		write_enable	: in std_logic;
		data_out			: out std_logic_vector(DATA_WIDTH-1 downto 0);
		inter_out		: out std_logic_vector(1 downto 0)
		
	);
end UART_CTL;
 
 
architecture RTL of UART_CTL is

	component mux41 is
		 generic (
			  largura_dado : natural
		 );
		 port (
			  dado_ent_0, dado_ent_1, dado_ent_2, dado_ent_3 : in std_logic_vector((largura_dado - 1) downto 0);
			  sele_ent                                       : in std_logic_vector(1 downto 0);
			  dado_sai                                       : out std_logic_vector((largura_dado - 1) downto 0)
		 );
	end component;

component UART_TX is
  generic (
    g_CLKS_PER_BIT_width : natural     -- Needs to be set correctly
    );
  port (
    i_Clk       : in  std_logic;
    i_TX_DV     : in  std_logic;
	 Ack			 : in  std_logic;
    i_TX_Byte   : in  std_logic_vector(7 downto 0);
    o_TX_Active : out std_logic;
    o_TX_Serial : out std_logic;
    o_TX_Done   : out std_logic;
	 clocks_pbit : in  std_logic_vector(g_CLKS_PER_BIT_width-1 downto 0)
    );
end component;

component UART_RX is
  generic (
    g_CLKS_PER_BIT_width : natural     -- Needs to be set correctly
    );
  port (
    i_Clk       : in  std_logic;
    i_RX_Serial : in  std_logic;
	 Ack			 : in  std_logic;
    o_RX_DV     : out std_logic;
    o_RX_Byte   : out std_logic_vector(7 downto 0);
	 clocks_pbit : in  std_logic_vector(g_CLKS_PER_BIT_width-1 downto 0)
    );
end component;

	component registrador is
		 generic (
			  largura_dado : natural
		 );
		 port (
			  entrada_dados  : in std_logic_vector((largura_dado - 1) downto 0);
			  WE, clk, reset : in std_logic;
			  saida_dados    : out std_logic_vector((largura_dado - 1) downto 0)
		 );
	end component;

	-----------------------------------
	
	signal aux_clocks_pbit 			: std_logic_vector(clocks_pbit_width-1 downto 0);
	signal aux_tx_setup	  			: std_logic_vector(tx_setup_width-1 downto 0);
	signal aux_o_rx_byte				: std_logic_vector(7 downto 0);
	signal aux_o_tx_active			: std_logic;
	
	signal aux_sel_data_out			: std_logic_vector(1 downto 0);
	signal aux_we_reg_clock_pbit	: std_logic;
	signal aux_we_reg_tx_setup		: std_logic;
	
	signal reset_tx_setup			: std_logic;
	signal aux_tx_done				: std_logic;
	
	signal aux_dado_ent_0, aux_dado_ent_1, aux_dado_ent_2, aux_dado_ent_3	: std_logic_vector(DATA_WIDTH-1 downto 0);
	
	signal aux_Ack_tx					: std_logic;
	signal aux_Ack_rx					: std_logic;
	
begin

	reset_tx_setup <= reset OR aux_tx_done;
	inter_out(1) <= aux_tx_done;
	
	
  aux_dado_ent_0 <= "0000000000000" & aux_clocks_pbit;
  aux_dado_ent_1 <= x"000000" & aux_o_rx_byte;
  aux_dado_ent_2 <= "00000000000000000000000" & aux_tx_setup;
  aux_dado_ent_3 <= "0000000000000000000000000000000" & aux_o_tx_active;


  -- Instantiate UART transmitter
  UART_TX_INST : uart_tx
    generic map (
      g_CLKS_PER_BIT_width => clocks_pbit_width
      )
    port map (
      i_clk       => clock,
      i_tx_dv     => aux_tx_setup(tx_setup_width-1),
		Ack			=>	aux_Ack_tx,
      i_tx_byte   => aux_tx_setup(tx_setup_width-2 downto 0),
      o_tx_active => aux_o_tx_active,
      o_tx_serial => tx,
      o_tx_done   => aux_tx_done,
		clocks_pbit => aux_clocks_pbit
      );
 
  -- Instantiate UART Receiver
  UART_RX_INST : uart_rx
    generic map (
      g_CLKS_PER_BIT_width => clocks_pbit_width
      )
    port map (
      i_clk       => clock,
      i_rx_serial => rx,
		Ack			=>	aux_Ack_rx,
      o_rx_dv     => inter_out(0),
      o_rx_byte   => aux_o_rx_byte,
		clocks_pbit => aux_clocks_pbit
      );
		
	instancia_mux41_out : mux41
      generic map(
        largura_dado => DATA_WIDTH
      )
      port map (
        dado_ent_0 => aux_dado_ent_0,
        dado_ent_1 => aux_dado_ent_1,
        dado_ent_2 => aux_dado_ent_2,
        dado_ent_3 => aux_dado_ent_3,
        sele_ent => aux_sel_data_out,
        dado_sai => data_out
      );
		
		
    instancia_reg_clock_pbit : registrador
      generic map(
        largura_dado => clocks_pbit_width	
      )
      port map (
        entrada_dados => data_in(clocks_pbit_width-1 downto 0),
        WE => aux_we_reg_clock_pbit,
        clk => clock,
        reset => reset,
        saida_dados => aux_clocks_pbit
      );
		
	 instancia_reg_tx_setup : registrador
      generic map(
        largura_dado => tx_setup_width 
      )
      port map (
        entrada_dados => data_in(tx_setup_width-1 downto 0),
        WE => aux_we_reg_tx_setup,
        clk => clock,
        reset => reset_tx_setup,
        saida_dados => aux_tx_setup
      );

		
		process(reg_addr, write_enable) is	--Gera sinais de WE e seleção do mux de saída
		begin
	
			aux_we_reg_clock_pbit <= '0';
			aux_we_reg_tx_setup	<= '0';
		
			case reg_addr is
			
				when "00" & x"A" =>
					aux_we_reg_clock_pbit <= write_enable;
					aux_sel_data_out <= "00";
				when "00" & x"B" =>
					aux_sel_data_out <= "01";
				when "00" & x"C" =>
					aux_we_reg_tx_setup	<= write_enable;
					aux_sel_data_out <= "10";
				when "00" & x"D" =>
					aux_sel_data_out <= "11";
				when others =>
					aux_we_reg_clock_pbit <= '0';
					aux_we_reg_tx_setup	<= '0';
					aux_sel_data_out <= "00";
			
			end case;
		
		end process;
		
		process(reg_addr,write_enable,data_in)
			begin
				if (reg_addr="001110" AND write_enable='1' AND data_in=x"00000001") then
					aux_Ack_tx <= '1';
				else
					aux_Ack_tx <= '0';
				end if;
				
				if (reg_addr="001111" AND write_enable='1' AND data_in=x"00000001") then
					aux_Ack_rx <= '1';
				else
					aux_Ack_rx <= '0';
				end if;
		end process;

end RTL;