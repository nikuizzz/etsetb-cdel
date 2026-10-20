library IEEE;
use ieee.std_logic_1164.all;

entity cmp3x4 is
    port ( a, b             : in  std_logic_vector(11 downto 0);
           netx, ngtx, nltx : out std_logic);
end cmp3x4;

architecture arch of cmp3x4 is
begin
    netx <= '1' when a=b else '0';
    ngtx <= '1' when a>b else '0';
    nltx <= '1' when a<b else '0';
end arch;