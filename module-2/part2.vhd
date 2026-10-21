--sequence detector and errors counter subsystem
library ieee;
use ieee.std_logic_1164.all;

entity part2 is
  port ( clk, nrst, key          : in  std_logic;
         keycode                 : in  std_logic_vector(3 downto 0);
         good, bad1, bad2, bad3  : out std_logic;
         shift                   : out std_logic );
end part2;

architecture arc_part2 of part2 is
type     errcnt_mach is (err0, err1, err2, err3);
type     seqdet_mach   is (waiting, start, now1ok, now1ko, now2ok, now2ko, 
                           now3ok, now3ko, now4ok, now4ko, seqok, seqko);
signal   errcnt : errcnt_mach;
signal   seqdet   : seqdet_mach;
constant code1    : std_logic_vector(3 downto 0) := x"1";
constant code2    : std_logic_vector(3 downto 0) := x"2";
constant code3    : std_logic_vector(3 downto 0) := x"4";
constant code4    : std_logic_vector(3 downto 0) := x"8";
signal   code     : std_logic_vector(3 downto 0);
signal   bcdind, astind, almind           : std_logic;
signal   detecok, detecko, bcd_ok, bcd_ko : std_logic;

begin

--key type detection
bcdind <= key and (not keycode(3) or ((not keycode(2) and not keycode(1))));
astind <= '1' when (key = '1' and keycode = x"e") else '0';
almind <= '1' when (key = '1' and keycode = x"f") else '0';

--sequence detector FSM 
seq_detector : process (clk, nrst) 
begin
    if nrst = '0' then seqdet <= waiting; good <= '0';
    elsif clk'event and clk = '1' then
      case seqdet is
        when waiting => if astind = '1' then seqdet <= start; end if;
        when start  =>  good  <= '0'; 
                        if    astind = '1' then seqdet <= start;
                        elsif bcd_ok = '1' then seqdet <= now1ok;
                        elsif bcd_ko = '1' then seqdet <= now1ko;
                        end if;
        when now1ok =>  if    astind = '1' then seqdet <= start;
                        elsif bcd_ok = '1' then seqdet <= now2ok;
                        elsif bcd_ko = '1' then seqdet <= now2ko;
                        end if;
        when now1ko =>  if    astind = '1' then seqdet <= start;
                        elsif bcdind = '1' then seqdet <= now2ko;
                        end if;
        when now2ok =>  if    astind = '1' then seqdet <= start;
                        elsif bcd_ok = '1' then seqdet <= now3ok;
                        elsif bcd_ko = '1' then seqdet <= now3ko;
                        end if;
        when now2ko =>  if    astind = '1' then seqdet <= start;
                        elsif bcdind = '1' then seqdet <= now3ko;
                        end if;
        when now3ok =>  if    astind = '1' then seqdet <= start;
                        elsif bcd_ok = '1' then seqdet <= now4ok;
                        elsif bcd_ko = '1' then seqdet <= now4ko;
                        end if;
        when now3ko =>  if    astind = '1' then seqdet <= start;
                        elsif bcdind = '1' then seqdet <= now4ko;
                        end if;
        when now4ok =>  if    astind = '1' then seqdet <= start;
                        elsif almind = '1' then seqdet <= seqok;
                        end if;
        when now4ko =>  if    astind = '1' then seqdet <= start;
                        elsif almind = '1' then seqdet <= seqko;
                        end if;
        when seqok =>   seqdet  <= waiting; good <= '1';
        when seqko =>   if errcnt /= err3 then seqdet <= waiting; end if;
        when others =>  null;
      end case;
    end if;
end process seq_detector;

--code selection and detection
code_sel : with seqdet select
  code <= code1 when start,
          code2 when now1ok | now1ko,
          code3 when now2ok | now2ko,
          code4 when others;

bcd_ok  <= '1' when bcdind = '1' and code = keycode  else '0';
bcd_ko  <= '1' when bcdind = '1' and code /= keycode  else '0';

detecok <= '1' when seqdet = now4ok and almind = '1' else '0';
detecko <= '1' when seqdet = now4ko and almind = '1' else '0';

--errors counter FSM 
err_counter : process (clk, nrst) 
begin
    if nrst = '0' then errcnt <= err0;
    elsif clk'event and clk = '1' then
      case errcnt is
        when err0 => if    detecko = '1' then errcnt <= err1;
                     elsif detecok = '1' then errcnt <= err0;
                     end if;
        when err1 => if    detecok = '1' then errcnt <= err0;
                     elsif detecko = '1' then errcnt <= err2;
                     end if;
        when err2 => if    detecok = '1' then errcnt <= err0;
                     elsif detecko = '1' then errcnt <= err3;
                     end if;
        when err3 => errcnt <= err3;
      end case;
    end if;
end process err_counter;

--output generation
bad1   <= '1' when errcnt /= err0 else '0';
bad2   <= '1' when errcnt = err2 or errcnt=err3 else '0';
bad3   <= '1' when errcnt = err3 else '0';
shift  <= '0' when (seqdet = waiting or seqdet = seqko) else bcdind;

end arc_part2;
