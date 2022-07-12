library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gpio_tb is
end;

architecture bench of gpio_tb is

  component gpio
    generic (
      largura_registradores : natural;
      ADDR_PERIPH_WIDTH     : natural;
      DATA_WIDTH            : natural
    );
    port (
      clk           : in std_logic;
      reset         : in std_logic;
      
      addr          : in std_logic_vector(ADDR_PERIPH_WIDTH - 1 downto 0);
      data_in       : in std_logic_vector(31 downto 0);
      data_out      : out std_logic_vector(31 downto 0);
      
      portA_ie      : in std_logic;
      portB_ie      : in std_logic;
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
  signal clk : std_logic;
  signal reset : std_logic;
  signal addr : std_logic_vector(ADDR_PERIPH_WIDTH - 1 downto 0);
  signal data_in : std_logic_vector(31 downto 0);
  signal data_out : std_logic_vector(31 downto 0);
  signal portA_ie : std_logic;
  signal portB_ie : std_logic;
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
        clk           => clk,
        reset         => reset,
        addr          => addr,
        data_in       => data_in,
        data_out      => data_out,
        portA_ie      => portA_ie,
        portB_ie      => portB_ie,
        pin_PORT_A    => pin_PORT_A,
        pin_PORT_B    => pin_PORT_B
    );

    input_process : process
    begin
        wait until (reset = '0');
        --              DIR_A     DIR_B                       IE_A                         IE_B                       DATAOUT_A                    DATAOUT_B
        addr        <= "000000", "000001" after clk_period, "000110" after 2*clk_period, "000111" after 3*clk_period, "000100" after 4*clk_period, "000101" after 5*clk_period, "000000" after 6*clk_period;
        --             Out Out Out Out In In In In            In0 - Interrupt
        data_in     <= x"0000000F",                         x"00000001" after 2*clk_period;
    
        portA_ie    <= '0', '1' after 10*clk_period; --Habilita interrupção para PORT_A
        pin_PORT_A  <= ;
    
        portB_ie    <= '0', '1' after 10*clk_period; --Habilita interrupção para PORT_B
        pin_PORT_B  <= ;
    end process input_process;

    gera_reset : process
	begin
		reset <= '1';
		for i in 1 to 2 loop
			wait until rising_edge(clk);
		end loop;
		reset <= '0';
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
