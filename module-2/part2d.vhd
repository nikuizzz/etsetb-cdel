--part2 with LCD message selection (improvement 2, 4, 5)
library ieee;
use ieee.std_logic_1164.all;

entity part2d is
  port ( clk, nrst, key          : in  std_logic;
         keycode                 : in  std_logic_vector(3 downto 0);
         good, bad1, bad2, bad3  : out std_logic;
         shift                   : out std_logic;
         trick                   : out std_logic;
         correct_code            : out std_logic_vector(15 downto 0);
         msg                     : out integer range 0 to 9 );
end part2d;

architecture arc of part2d is
type     errcnt_mach is (err0, err1, err2, err3);
type     seqdet_mach is (waiting, start, now1ok, now1ko, now2ok, now2ko,
                         now3ok, now3ko, now4ok, now4ko, seqok, seqko,
                         config_start, config_apply, config1, config2, config3, config4, config_failed);
signal   errcnt : errcnt_mach;
signal   seqdet : seqdet_mach;

constant default_code1  : std_logic_vector(3 downto 0) := x"1";
constant default_code2  : std_logic_vector(3 downto 0) := x"2";
constant default_code3  : std_logic_vector(3 downto 0) := x"4";
constant default_code4  : std_logic_vector(3 downto 0) := x"8";

signal code1  : std_logic_vector(3 downto 0);
signal code2  : std_logic_vector(3 downto 0);
signal code3  : std_logic_vector(3 downto 0);
signal code4  : std_logic_vector(3 downto 0);

signal new_code1  : std_logic_vector(3 downto 0);
signal new_code2  : std_logic_vector(3 downto 0);
signal new_code3  : std_logic_vector(3 downto 0);
signal new_code4  : std_logic_vector(3 downto 0);

signal   code   : std_logic_vector(3 downto 0);
signal   bcdind, astind, almind, aind, cind  : std_logic;
signal   detecok, detecko, bcd_ok, bcd_ko, conf_ok : std_logic;
signal   good_i, wrong                    : std_logic;
signal   trick_i, key_eff        : std_logic;
begin

-- improvement 4: toggle trick on A
aind <= '1' when key = '1' and (keycode = x"a") else '0';

trick_reg : process (clk, nrst)
begin
  if nrst = '0' then trick_i <= '0';
  elsif clk'event and clk = '1' then
    if aind = '1' then trick_i <= not trick_i; end if;
  end if;
end process trick_reg;

key_eff <= key and not trick_i;
trick   <= trick_i;

--key type detection
bcdind <= key_eff and (not keycode(3) or ((not keycode(2) and not keycode(1)))); -- any digit
astind <= '1' when (key_eff = '1' and keycode = x"e") else '0'; -- *
almind <= '1' when (key_eff = '1' and keycode = x"f") else '0'; -- #
cind <= '1' when (key_eff = '1' and keycode = x"c") else '0'; -- c

--sequence detector FSM
seq_detector : process (clk, nrst)
begin
    if nrst = '0' then 
        seqdet <= waiting; 
        good_i <= '0'; 
        code1 <= default_code1;
        code2 <= default_code2;
        code3 <= default_code3;
        code4 <= default_code4;
        new_code1 <= x"0";
        new_code2 <= x"0";
        new_code3 <= x"0";
        new_code4 <= x"0";
    elsif clk'event and clk = '1' then
      case seqdet is
        when waiting => if cind = '1' and good_i = '1' then seqdet <= config_start; -- we can enter config mode only after 
                                                                                    -- entering the correct  code
                        elsif astind = '1' then seqdet <= start; 
                        end if;
        when config_start => 
                        if conf_ok = '1' then seqdet <= config1; new_code1 <= keycode;
                        elsif astind = '1' then seqdet <= start;
                        elsif almind = '1' then seqdet <= config_failed;
                        end if;
        when config1 => if conf_ok = '1' then seqdet <= config2; new_code2 <= keycode;
                        elsif almind = '1' then seqdet <= config_failed;
                        elsif astind = '1' then seqdet <= start;
                        end if;
        when config2 => if conf_ok = '1' then seqdet <= config3; new_code3 <= keycode;
                        elsif almind = '1' then seqdet <= config_failed;
                        elsif astind = '1' then seqdet <= start;
                        end if;
        when config3 => if conf_ok = '1' then seqdet <= config4; new_code4 <= keycode;
                        elsif almind = '1' then seqdet <= config_failed;
                        elsif astind = '1' then seqdet <= start;
                        end if;
        when config4 => if conf_ok = '1' then seqdet <= config_failed;
                        elsif almind = '1' then seqdet <= config_apply;
                        elsif astind = '1' then seqdet <= start;
                        end if;
        when config_apply =>
                        code1 <= new_code1; code2 <= new_code2;
                        code3 <= new_code3; code4 <= new_code4;
                        if astind = '1' or almind = '1' then seqdet <= start; end if;
        when config_failed => 
                        if cind = '1' then seqdet <= config_start;
                        elsif astind = '1' then seqdet <= start; 
                        end if;
        when start  =>  good_i <= '0';
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
        when seqok =>   seqdet <= waiting; good_i <= '1';
        when seqko =>   if errcnt /= err3 then seqdet <= waiting; end if;
        when others =>  null;
      end case;
    end if;
end process seq_detector;
-- good is driven from internal signal bcs we couldn't use good (out) on line 135 otherwise
good <= good_i;

--code selection and detection
code_sel : with seqdet select
  code <= code1 when start,
          code2 when now1ok | now1ko,
          code3 when now2ok | now2ko,
          code4 when others;

bcd_ok  <= '1' when bcdind = '1' and code = keycode  else '0';
bcd_ko  <= '1' when bcdind = '1' and code /= keycode else '0';

detecok <= '1' when seqdet = now4ok and almind = '1' else '0';
detecko <= '1' when seqdet = now4ko and almind = '1' else '0';

--improvement 5: code configuration
conf_ok <= '1' when bcdind = '1' and (seqdet = config_start or 
                                     seqdet = config1 or 
                                     seqdet = config2 or 
                                     seqdet = config3 or 
                                     seqdet = config4)
                                     else '0';

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

-- the wrong flag is set to 0 on start, set to 1 when seqko
wrong_reg : process (clk, nrst)
begin
    if nrst = '0' then wrong <= '0';
    elsif clk'event and clk = '1' then
      if    seqdet = seqko  then wrong <= '1';
      elsif seqdet = start  then wrong <= '0';
      end if;
    end if;
end process wrong_reg;

--output generation
bad1   <= '1' when errcnt /= err0 else '0';
bad2   <= '1' when errcnt = err2 or errcnt = err3 else '0';
bad3   <= '1' when errcnt = err3 else '0';
shift  <= '0' when (seqdet = waiting or seqdet = seqko) else bcdind;
correct_code <= code1 & code2 & code3 & code4; -- 16 bit array where every quadruple is 1 digit of the actual code

--LCD message
msg <= 9 when trick_i = '1' else                                                               -- Trick mode on
       8 when seqdet = config_start or seqdet = config1 or seqdet = config2 or
              seqdet = config3 or seqdet = config4 else                                        -- Conf. mode on       
       7 when seqdet = config_apply else                                                       -- Conf. applied
       6 when seqdet = config_failed else                                                      -- Must be 4 digits
	   5 when errcnt = err3 else                                                               -- System Locked
       3 when seqdet = seqok or (seqdet = waiting and good_i = '1') else                       -- Right code
       4 when seqdet = seqko or (seqdet = waiting and wrong = '1') else                        -- Wrong code
       1 when seqdet = waiting else                                                            -- Press * to start
       2;                                                                                      -- Enter PIN code

end arc;