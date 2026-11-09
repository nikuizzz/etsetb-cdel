--4x4 keypad analyser
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity part1 is
  port (
    clk, nrst    : in  std_logic;
    col          : in  std_logic_vector(3 downto 0);
    key          : out std_logic;
    keycode, row : out std_logic_vector(3 downto 0));
end part1;

architecture arc_keypad of part1 is
  component count10b
    port ( clk, nrst : in  std_logic;
           output    : out integer range 0 to 1023);
  end component;
  type   states is (wait0, check0, kra0, kra1, kra2, kra3, wait1, check1);
  signal curr_st, next_st : states;
  signal comp                      : integer range 0 to 1023;
  signal rowq, colq                : std_logic_vector(3 downto 0);
  signal look, kpressed            : std_logic;
  signal key_i                     : std_logic;
  signal keycode_i                 : std_logic_vector(3 downto 0);
begin  -- arc_keypad

--look generation
  counter : count10b port map ( clk => clk, nrst => nrst, output => comp);
  look <= '1' when comp = 1023 else '0';

--columns register and kpressed generation
  reg4 : process (clk, nrst)
  begin  -- process reg4
    if nrst = '0' then colq <= "0000";
    elsif clk'event and clk = '0' then colq <= col;
    end if;
  end process reg4;
  kpressed <= not (colq(3) and colq(2) and colq(1) and colq(0));

--whatkey FSM: a synchronous state register, plus two combinational blocs
-- describing either next state and output functions
  --state register
  whatkey : process (clk, nrst) 
  begin
    if nrst = '0' then curr_st <= wait0;
    elsif clk'event and clk = '1' then curr_st <= next_st;
    end if;
  end process whatkey;

  --next state function
  next_st <=   check0 when (curr_st = wait0 and look = '1')
         else  wait0  when (((curr_st = wait0 or curr_st = kra3 or 
                         curr_st = check1) and kpressed = '0') or 
                         (curr_st = wait0 and look = '0'))
         else  kra0   when (curr_st = check0 and kpressed = '1')
         else  kra1   when (curr_st = kra0 and kpressed = '0')
         else  kra2   when (curr_st = kra1 and kpressed = '0')
         else  kra3   when (curr_st = kra2 and kpressed = '0')
         else  wait1  when (((curr_st = kra0 or curr_st = kra1 or 
                         curr_st = kra2 or curr_st = kra3 or 
                         curr_st = check1) and kpressed = '1') or 
                         (curr_st = wait1 and look = '0'))
         else  check1 when (curr_st = wait1 and look = '1')
         else  wait0;

  --output functions
  with curr_st select
    rowq <= "1111" when wait0  | wait1,
            "0000" when check0 | check1,
            "1110" when kra0,
            "1101" when kra1,
            "1011" when kra2,
            "0111" when kra3,
            "1111" when others;

  key_i <= '0' when (curr_st = wait0 or curr_st = check0 or curr_st = wait1 or
                     curr_st = check1 or colq = "1111") else '1';

  keycode_i <= x"1" when (curr_st = kra0 and colq(0) = '0')
       else  x"2" when (curr_st = kra0 and colq(1) = '0')
       else  x"3" when (curr_st = kra0 and colq(2) = '0')
       else  x"a" when (curr_st = kra0 and colq(3) = '0')
       else  x"4" when (curr_st = kra1 and colq(0) = '0')
       else  x"5" when (curr_st = kra1 and colq(1) = '0')
       else  x"6" when (curr_st = kra1 and colq(2) = '0')
       else  x"b" when (curr_st = kra1 and colq(3) = '0')
       else  x"7" when (curr_st = kra2 and colq(0) = '0')
       else  x"8" when (curr_st = kra2 and colq(1) = '0')
       else  x"9" when (curr_st = kra2 and colq(2) = '0')
       else  x"c" when (curr_st = kra2 and colq(3) = '0')
       else  x"e" when (curr_st = kra3 and colq(0) = '0')
       else  x"0" when (curr_st = kra3 and colq(1) = '0')
       else  x"f" when (curr_st = kra3 and colq(2) = '0')
       else  x"d" when (curr_st = kra3 and colq(3) = '0')
       else  x"0";
  --whatkey end

  --output register: key and keycode only change on the rising edge of clk,
  -- so the glitches of the combinational functions never reach the outputs
  outreg : process (clk, nrst)
  begin
    if nrst = '0' then
      key     <= '0';
      keycode <= x"0";
    elsif clk'event and clk = '1' then
      key     <= key_i;
      keycode <= keycode_i;
    end if;
  end process outreg;

  --tristate buffers
  tribuf: for i in 0 to 3 generate
    row(i) <= '0' when rowq(i) = '0' else 'Z';
  end generate tribuf;

end arc_keypad; 
