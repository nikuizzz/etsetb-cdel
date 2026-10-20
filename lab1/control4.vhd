library ieee;
use ieee.std_logic_1164.all;
entity control4 is
    port( clk, nrst : in std_logic;
          netx, ngtx, nltx, bcd, ast, alm, busy : in std_logic;
          less, equal, great, shftl, ecnt, run : out std_logic;
          message : out integer range 0 to 5 );
end control4;
architecture behaviour of control4 is
    type machine is (start, check, show);
    signal state : machine;
    signal msg, last_msg : integer range 0 to 5;
    signal run_i : std_logic;
begin
    -- state transition (same as control.vhd)
    process(clk, nrst)
    begin
        if nrst = '0' then state <= start;
        elsif rising_edge(clk) then
            case state is
                when start => if ast = '1' then state <= check; end if;
                when check => if alm = '1' then state <= show;
                              elsif ast = '1' then state <= start; end if;
                when show  => if ast = '1' then state <= start;
                              elsif bcd = '1' and netx = '0' then state <= check; end if;
            end case;
        end if;
    end process;

    -- outputs (same as control.vhd)
    shftl <= bcd when (state = check) or (state = show and netx = '0') else '0';
    ecnt  <= not ast when state = start else '0';
    less  <= '1' when (state = start) or (state = show and nltx = '1') else '0';
    equal <= '1' when (state = start) or (state = show and netx = '1') else '0';
    great <= '1' when (state = start) or (state = show and ngtx = '1') else '0';

    -- LCD message: function of the state and of the comparison
    msg <= 1 when state = start else   -- Press * to Start
           2 when state = check else   -- Introduce code
           4 when netx = '1'    else   -- You Won!
           3 when nltx = '1'    else   -- num < numx : Go up
           5;                          -- num > numx : Go down

    -- run: 1-clock pulse when the message changes and the LCD is free
    process(clk, nrst)
    begin
        if nrst = '0' then
            last_msg <= 0; run_i <= '0';
        elsif rising_edge(clk) then
            if run_i = '1' then
                run_i <= '0';                       -- falling edge -> LCD starts
            elsif busy = '0' and msg /= last_msg then
                last_msg <= msg; run_i <= '1';
            end if;
        end if;
    end process;
    run     <= run_i;
    message <= last_msg;   -- held stable while run falls
end behaviour;