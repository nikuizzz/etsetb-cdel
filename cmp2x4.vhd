library IEEE;
use ieee.std_logic_1164.all;

entity cmp2x4 is
    port ( a, b             : in  std_logic_vector(7 downto 0);
           netx, ngtx, nltx : out std_logic);
end cmp2x4;

architecture arch of cmp2x4 is
begin
    netx <= '1' when a=b else '0';
    ngtx <= '1' when a>b else '0';
    nltx <= '1' when a<b else '0';
end arch;