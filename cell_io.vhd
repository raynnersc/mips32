library ieee;
use ieee.std_logic_1164.all;

entity cell_io is
    generic
    (
        DATA_WIDTH	: natural 
    );
    port
    (
        dir         : in    std_logic_vector(DATA_WIDTH-1 downto 0);
        data        : in    std_logic_vector(DATA_WIDTH-1 downto 0);
        pin         : inout std_logic_vector(DATA_WIDTH-1 downto 0);
        read_buffer : out   std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end cell_io;

architecture rtl of cell_io is
begin
	-- If we are using the inout as an output, assign it an output value, 
	-- otherwise assign it high-impedence
	tristate : for i in 0 to DATA_WIDTH-1 generate
    begin
        pin(i) <= data(i) when dir(i) = '0' else 'Z';
    end generate tristate;
    
	-- Read in the current value of the bidir port, which comes either 
	-- from the input or from the previous assignment
	read_buffer <= pin;
end rtl;
