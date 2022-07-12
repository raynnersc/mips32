library ieee;
use ieee.std_logic_1164.all;

entity gpio is
    generic
    (
        largura_registradores : natural; --tamanho dos registradores (grupo de portas com 8 I/Os)
        ADDR_PERIPH_WIDTH     : natural;
        DATA_WIDTH	          : natural
    );
    port
    (
        clk           : in  std_logic;
        reset         : in  std_logic;
        --
        addr          : in  std_logic_vector(ADDR_PERIPH_WIDTH - 1 downto 0);
        data_in       : in  std_logic_vector(31 downto 0);
        data_out      : out std_logic_vector(31 downto 0);
        --
        portA_ie      : in std_logic;
        portB_ie      : in std_logic;
        pin_PORT_A    : inout std_logic_vector(DATA_WIDTH-1 downto 0);
        pin_PORT_B    : inout std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end gpio;

architecture beh of gpio is

    -- Ports
    signal aux_portA_in : std_logic_vector(7 downto 0);
    signal aux_portA_out : std_logic_vector(7 downto 0);
    signal aux_portA_dir : std_logic_vector(7 downto 0);
    
    signal aux_portB_in : std_logic_vector(7 downto 0);
    signal aux_portB_out : std_logic_vector(7 downto 0);
    signal aux_portB_dir : std_logic_vector(7 downto 0);

    component cell_io
        generic
        (
            DATA_WIDTH	: integer 
        );
        port
        (
            dir         : in    std_logic_vector(DATA_WIDTH-1 downto 0);
            data        : in    std_logic_vector(DATA_WIDTH-1 downto 0);
            pin         : inout std_logic_vector(DATA_WIDTH-1 downto 0);
            read_buffer : out   std_logic_vector(DATA_WIDTH-1 downto 0)
        );
    end component;

    component gpio_mod
        generic (
          largura_registradores : natural;
          ADDR_PERIPH_WIDTH : natural
        );
        port (
          clk : in std_logic;
          reset : in std_logic;
          
          addr : in std_logic_vector(ADDR_PERIPH_WIDTH - 1 downto 0);
          data_in : in std_logic_vector(31 downto 0);
          data_out : out std_logic_vector(31 downto 0);
          
          portA_ie : in std_logic;
          portA_in : in std_logic_vector(7 downto 0);
          portA_out : out std_logic_vector(7 downto 0);
          portA_dir : out std_logic_vector(7 downto 0);
          
          portB_ie : in std_logic;
          portB_in : in std_logic_vector(7 downto 0);
          portB_out : out std_logic_vector(7 downto 0);
          portB_dir : out std_logic_vector(7 downto 0)
        );
    end component;

begin

    gpio_module : gpio_mod
        generic map(
            largura_registradores => largura_registradores,
            ADDR_PERIPH_WIDTH     => ADDR_PERIPH_WIDTH
        )
        port map (
            clk => clk,
            reset => reset,
            addr => addr,
            data_in => data_in,
            data_out => data_out,
            portA_ie => portA_ie,
            portA_in => aux_portA_in,
            portA_out => aux_portA_out,
            portA_dir => aux_portA_dir,
            portB_ie => portB_ie,
            portB_in => aux_portB_in,
            portB_out => aux_portB_out,
            portB_dir => aux_portB_dir
        );

    PORT_A : cell_io
        generic map
        (
            DATA_WIDTH => DATA_WIDTH
        )
        port map
        (
            dir         => aux_portA_dir,
            data        => aux_portA_out,
            pin         => pin_PORT_A,
            read_buffer => aux_portA_in
        );

    PORT_B : cell_io
        generic map
        (
            DATA_WIDTH => DATA_WIDTH
        )
        port map
        (
            dir         => aux_portB_dir,
            data        => aux_portB_out,
            pin         => pin_PORT_B,
            read_buffer => aux_portB_in
        );
end beh;