--synchronous 10-bit counter 
library ieee; 
use ieee.std_logic_1164.all;

entity count10b is
  port ( clk, nrst : in  std_logic;
         output    : out integer range 0 to 1023 );
end count10b;

architecture arc_count10b of count10b is
  signal count : integer range 0 to 1023;
begin

  process (clk, nrst)
  begin
    if nrst = '0' then  count <= 0;
    elsif clk'event and clk = '1' then  count <= count + 1;
    end if;
  end process;

  output <= count;

end arc_count10b;
