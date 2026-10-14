library ieee;
use ieee.std_logic_1164.all;

entity control is
    port( clk, nrst                        : in  std_logic;
          netx, ngtx, nltx, bcd, ast, alm  : in  std_logic;
          less, equal, great, shftl, ecnt  : out std_logic );
end control;

architecture behaviour of control is
    type machine is (start, check, show);
    signal state : machine;
begin
    -- states transition
    process(clk, nrst)
    begin
        if nrst='0' then state <= start;
        elsif (clk'event and clk='1') then
            case state is
                when start => if ast = '1' then state <= check;
                              end if;
                when check => if alm = '1' then state <= show;
                              elsif ast = '1' then state <= start;
                              end if;
                when show  => if ast = '1' then state <= start;
                              elsif bcd = '1' and netx = '0' then state <= check;
                              end if;
            end case;
        end if;
    end process;
    -- end of state transition / beginning of output generation
    shftl <= bcd when (state = check) or (state = show and netx = '0') else '0';
    ecnt  <= not ast when state = start else '0';
    less  <= '1' when (state = start) or (state = show and nltx = '1') else '0';
    equal <= '1' when (state = start) or (state = show and netx = '1') else '0';
    great <= '1' when (state = start) or (state = show and ngtx = '1') else '0';
    -- end of output generation
end behaviour;