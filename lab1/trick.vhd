library ieee;
use ieee.std_logic_1164.all;

entity trick is
    port( clk, nrst, key : in  std_logic;
          keycode        : in  std_logic_vector(3 downto 0);
          num, numx      : in  std_logic_vector(11 downto 0);
          disp           : out std_logic_vector(11 downto 0) );
end trick;

architecture behaviour of trick is
    signal show_x : std_logic;   -- '1' = trick mode
begin
    process(clk, nrst)
    begin
        if nrst = '0' then
            show_x <= '0';
        elsif rising_edge(clk) then
            if key = '1' and (keycode = x"A" or keycode = x"B" or
                              keycode = x"C" or keycode = x"D") then
                show_x <= not show_x;
            end if;
        end if;
    end process;

    disp <= numx when show_x = '1' else num;
end behaviour;