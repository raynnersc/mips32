library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_gpio is
end;

architecture bench of tb_gpio is

  component gpio
    generic
    (
        largura_registradores : natural := 8; --tamanho dos registradores (grupo de portas com 8 I/Os)
        ADDR_PERIPH_WIDTH     : natural := 6;
        DATA_WIDTH	         : natural := 8
    );
    port
    (
		  we				 : in  std_logic;
        clk           : in  std_logic;
        reset         : in  std_logic;
        --
        addr          : in  std_logic_vector(ADDR_PERIPH_WIDTH - 1 downto 0);
        data_in       : in  std_logic_vector(31 downto 0);
        data_out      : out std_logic_vector(31 downto 0);
        --
        portA_ie      : in std_logic;
        portB_ie      : in std_logic;
		  portA_if		 : out std_logic;
		  portB_if		 : out std_logic;
        pin_PORT_A    : inout std_logic_vector(DATA_WIDTH-1 downto 0);
        pin_PORT_B    : inout std_logic_vector(DATA_WIDTH-1 downto 0)
    );
  end component;

  -- Clock period
  constant clk_period : time := 10 ns;
  -- Generics
  constant largura_registradores    : natural := 8;
  constant ADDR_PERIPH_WIDTH        : natural := 6;
  constant DATA_WIDTH               : natural := 8;

  -- Ports
  signal we : std_logic;
  signal clk : std_logic;
  signal reset : std_logic;
  signal addr : std_logic_vector(ADDR_PERIPH_WIDTH - 1 downto 0);
  signal data_in : std_logic_vector(31 downto 0);
  signal data_out : std_logic_vector(31 downto 0);
  signal portA_ie : std_logic;
  signal portB_ie : std_logic;
  signal portA_if : std_logic;
  signal portB_if : std_logic;
  signal pin_PORT_A : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal pin_PORT_B : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

  gpio_inst : gpio
    generic map (
        largura_registradores => largura_registradores,
        ADDR_PERIPH_WIDTH     => ADDR_PERIPH_WIDTH,
        DATA_WIDTH            => DATA_WIDTH
    )
    port map (
		  we				 => we,
        clk           => clk,
        reset         => reset,
        addr          => addr,
        data_in       => data_in,
        data_out      => data_out,
        portA_ie      => portA_ie,
        portB_ie      => portB_ie,
		  portA_if      => portA_if,
		  portB_if      => portB_if,
        pin_PORT_A    => pin_PORT_A,
        pin_PORT_B    => pin_PORT_B
    );

    input_process : process
    begin
        wait until (reset = '0'); 
		  we <= '1', '0' after 5.5*clk_period;
		  
		  portA_ie    				  <= '0', '1' after 9*clk_period; --Habilita interrupção para PORT_A
        pin_PORT_A(3 downto 0)  <= x"A", x"B" after 5*clk_period, x"A" after 10.5*clk_period;
    
        portB_ie    				  <= '0', '1' after 9*clk_period; --Habilita interrupção para PORT_B
        pin_PORT_B(3 downto 0)  <= x"E", x"F" after 5*clk_period, x"E" after 10.5*clk_period;
		  
		  wait until falling_edge(clk);
        --              DIR_A     DIR_B                       IE_A                         IE_B                       DATAOUT_A                    DATAOUT_B                    DATAIN_A                      DATAIN_B                      IF_A                           IF_B
        addr        <= "000000", "000001" after clk_period, "000110" after 2*clk_period, "000111" after 3*clk_period, "000100" after 4*clk_period, "000101" after 5*clk_period, "000010" after 7*clk_period, "000011" after 8*clk_period, "001000" after 11*clk_period, "001001" after 12*clk_period;
        --             Out Out Out Out In In In In            In0 - Interrupt                    All Outs = 1                    All Outs = 0
        data_in     <= x"0000000F",                         x"00000001" after 2*clk_period, x"000000F0" after 4*clk_period, x"00000000" after 6*clk_period;
    

    end process input_process;

    gera_reset : process
	begin
		reset <= '1', '0' after 1.5*clk_period;
--		for i in 1 to 2 loop
--			wait until rising_edge(clk);
--		end loop;
--		reset <= '0';
		wait;
	end process gera_reset;

    clk_process : process
    begin
        clk <= '1';
        wait for clk_period/2;
        clk <= '0';
        wait for clk_period/2;
    end process clk_process;

end;
