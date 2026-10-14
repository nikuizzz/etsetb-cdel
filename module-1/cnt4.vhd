library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cnt4 is
    port( clock, aclr, sclr, cnt_en : in  std_logic;
          q                         : out std_logic_vector(3 downto 0) );
end cnt4;

architecture behaviour of cnt4 is
    signal count : unsigned(3 downto 0);
begin
    process(clock, aclr)
    begin
        if aclr = '1' then
            count <= (others => '0');
        elsif rising_edge(clock) then
            if sclr = '1' then
                count <= (others => '0');
            elsif cnt_en = '1' then
                count <= count + 1;
            end if;
        end if;
    end process;
    q <= std_logic_vector(count);
end behaviour;