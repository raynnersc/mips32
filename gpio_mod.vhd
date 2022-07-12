library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity gpio_mod is
    generic(
        largura_registradores : natural; --tamanho dos registradores (grupo de portas com 8 I/Os)
        ADDR_PERIPH_WIDTH     : natural
    );
    port(
        clk       : in  std_logic;
        reset     : in  std_logic;
        --
        --we        : in  std_logic;
        addr      : in  std_logic_vector(ADDR_PERIPH_WIDTH - 1 downto 0);
        data_in   : in  std_logic_vector(31 downto 0);
        data_out  : out std_logic_vector(31 downto 0);
        -- PORT A
        portA_ie  : in std_logic;
        portA_in  : in  std_logic_vector(7 downto 0);
        portA_out : out std_logic_vector(7 downto 0);
        portA_dir : out std_logic_vector(7 downto 0);
        -- PORT B
        portB_ie  : in std_logic;
        portB_in  : in  std_logic_vector(7 downto 0);
        portB_out : out std_logic_vector(7 downto 0);
        portB_dir : out std_logic_vector(7 downto 0)
    );
end entity gpio_mod;

architecture rtl of gpio_mod is

    --signal aux_we       : std_logic;
    signal aux_addr     : std_logic_vector(ADDR_PERIPH_WIDTH - 1 downto 0);
    signal aux_data_in  : std_logic_vector(7 downto 0);
    signal aux_data_out : std_logic_vector(7 downto 0);

    signal aux_ctrl_reg : std_logic_vector(5 downto 0);
    signal aux_ctrl_mux : std_logic_vector(1 downto 0);

    signal aux_datain_A : std_logic_vector(7 downto 0);
    signal aux_datain_B : std_logic_vector(7 downto 0);
    signal aux_ie_A     : std_logic_vector(7 downto 0);
    signal aux_ie_B     : std_logic_vector(7 downto 0);
    signal aux_if_A     : std_logic_vector(7 downto 0);
    signal aux_if_B     : std_logic_vector(7 downto 0);

    signal old_datain_A : std_logic_vector(7 downto 0);
    signal old_datain_B : std_logic_vector(7 downto 0);
    signal detect_if_A  : std_logic_vector(7 downto 0);
    signal detect_if_B  : std_logic_vector(7 downto 0);

    component gpio_address_decoder is
        generic (
            ADDR_PERIPH_WIDTH : natural
        );
        port (
            --we          : in    std_logic;
            addr        : in	std_logic_vector(ADDR_PERIPH_WIDTH - 1 downto 0);
            ctrl_reg    : out   std_logic_vector(5 downto 0);
            ctrl_mux    : out   std_logic_vector(1 downto 0)
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

begin

    --Interligando os sinais auxiliares com os pinos do módulo GPIO
    --aux_we <= we;
    aux_addr <= addr;
    aux_data_in <= data_in(7 downto 0);
    data_out <= x"000000" & aux_data_out(7 downto 0);

    GPIO_CONTROL : gpio_address_decoder
        generic map(ADDR_PERIPH_WIDTH => ADDR_PERIPH_WIDTH)
        port map(
            --we      => aux_we,
            addr    => aux_addr, 
            ctrl_reg => aux_ctrl_reg,
            ctrl_mux => aux_ctrl_mux
        );

    SEL_DATA_OUT : mux41
        generic map(largura_dado => largura_registradores)
        port map(
            dado_ent_0 => aux_datain_A,
            dado_ent_1 => aux_datain_B,
            dado_ent_2 => aux_if_A,
            dado_ent_3 => aux_if_B,
            sele_ent => aux_ctrl_mux,
            dado_sai => aux_data_out
        );

    --Declaração dos registradores do GPIO 
    DIR_A : registrador
        generic map(largura_dado => largura_registradores)
        port map(
            clk => clk,
            reset => reset,
            WE  => aux_ctrl_reg(0),
            entrada_dados => aux_data_in,
            saida_dados => portA_dir
        );
    DIR_B : registrador
        generic map(largura_dado => largura_registradores)
        port map(
            clk => clk,
            reset => reset,
            WE  => aux_ctrl_reg(1),
            entrada_dados => aux_data_in,
            saida_dados => portB_dir
        );
    DATAIN_A : registrador
        generic map(largura_dado => largura_registradores)
        port map(
            clk => clk,
            reset => reset,
            WE  => '1',
            entrada_dados => portA_in,
            saida_dados => aux_datain_A
        );
    DATAIN_B : registrador
        generic map(largura_dado => largura_registradores)
        port map(
            clk => clk,
            reset => reset,
            WE  => '1',
            entrada_dados => portB_in,
            saida_dados => aux_datain_B
        );
    DATAOUT_A : registrador
        generic map(largura_dado => largura_registradores)
        port map(
            clk => clk,
            reset => reset,
            WE  => aux_ctrl_reg(2),
            entrada_dados => aux_data_in,
            saida_dados => portA_out
        );
    DATAOUT_B : registrador
        generic map(largura_dado => largura_registradores)
        port map(
            clk => clk,
            reset => reset,
            WE  => aux_ctrl_reg(3),
            entrada_dados => aux_data_in,
            saida_dados => portB_out
        );
    IE_A : registrador
        generic map(largura_dado => largura_registradores)
        port map(
            clk => clk,
            reset => reset,
            WE  => aux_ctrl_reg(4),
            entrada_dados => aux_data_in,
            saida_dados => aux_ie_A
        );
    IE_B : registrador
        generic map(largura_dado => largura_registradores)
        port map(
            clk => clk,
            reset => reset,
            WE  => aux_ctrl_reg(5),
            entrada_dados => aux_data_in,
            saida_dados => aux_ie_B
        );
    IF_A : registrador
        generic map(largura_dado => largura_registradores)
        port map(
            clk => clk,
            reset => reset,
            WE  => '1',
            entrada_dados => detect_if_A,
            saida_dados => aux_if_A
        );
    IF_B : registrador
        generic map(largura_dado => largura_registradores)
        port map(
            clk => clk,
            reset => reset,
            WE  => '1',
            entrada_dados => detect_if_B,
            saida_dados => aux_if_B
        );
    
    --Gerando a interrupção
    process(clk) is
    begin
        if(rising_edge (clk)) then
            if(portA_ie = '1') then                                                 --Interrupção geral do PORT_A
                if(old_datain_A /= aux_datain_A) then
                    detect_if_A <= aux_ie_A and (aux_datain_A xor old_datain_A);    --Interrupção de cada pino do PORT_A: se a interrupção do pino estiver ativa e detectar que a entrada é diferente da entrada do ciclo anterior
                end if;
            else
                detect_if_A <= x"00";
            end if;
            if(portB_ie = '1') then                                                 --Interrupção geral do PORT_B  
                if(old_datain_B /= aux_datain_B) then
                    detect_if_B <= aux_ie_B and (aux_datain_B xor old_datain_B);    --Interrupção de cada pino do PORT_B: se a interrupção do pino estiver ativa e detectar que a entrada é diferente da entrada do ciclo anterior
                end if;
            else
                detect_if_B <= x"00";
            end if;
            old_datain_A <= aux_datain_A;
            old_datain_B <= aux_datain_B;
        end if;
    end process;
end architecture rtl;