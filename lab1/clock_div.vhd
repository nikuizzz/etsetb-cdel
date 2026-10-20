library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clock_div is
    port( clk, nrst : in  std_logic;
          q         : out std_logic_vector(15 downto 0) );
end clock_div;

architecture behaviour of clock_div is
    signal count : unsigned(15 downto 0);
begin
    process(clk, nrst)
    begin
        if nrst = '0' then
            count <= (others => '0');
        elsif rising_edge(clk) then
            count <= count + 1;
        end if;
    end process;
    q <= std_logic_vector(count);
end behaviour;