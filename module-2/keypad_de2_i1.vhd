library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity keypad_de2_i1 is
  port ( OSC_50    : in  std_logic;
         KEY       : in  std_logic_vector(3 downto 0);
         COL       : in  std_logic_vector(3 downto 0);
         ROW       : out std_logic_vector(3 downto 0);
         LED_GREEN : out std_logic_vector(8 downto 0);
         LED_RED   : out std_logic_vector(17 downto 0);
         HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7 : out std_logic_vector(6 downto 0) );
end keypad_de2_i1;

architecture arc of keypad_de2_i1 is
  component keypad
    port ( clk, nrst : in  std_logic;
           col       : in  std_logic_vector(3 downto 0);
           row       : out std_logic_vector(3 downto 0);
           key       : out std_logic;
           keycode   : out std_logic_vector(3 downto 0);
           good, bad1, bad2, bad3, shift : out std_logic );
  end component;

  component hex_disps
    port ( num0, num1, num2, num3, num4, num5, num6, num7 : in std_logic_vector (3 downto 0);
           HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7 : out std_logic_vector (6 downto 0));
  end component;

  component clock_div
    port ( clk, nrst : in  std_logic;
           q         : out std_logic_vector(15 downto 0) );
  end component;
  
  component CLK_LOCK
    port ( inclk  : in  std_logic;
           outclk : out std_logic );
  end component;

  signal nrst, sclk : std_logic;
  signal q      : std_logic_vector(15 downto 0);
  signal blink  : std_logic;
  signal bcnt   : integer range 0 to 24999999;
  signal key_s, good_s, bad1_s, bad2_s, bad3_s, shift_s : std_logic;
  signal keycode_s : std_logic_vector(3 downto 0);
  signal num    : std_logic_vector(15 downto 0);
  signal ndig   : integer range 0 to 4;
begin
  nrst <= KEY(0);

  -- clocks: system = 50 MHz / 2^9 = 97.7 kHz
  cdiv  : clock_div port map ( clk => OSC_50, nrst => nrst, q => q );
  clklk : CLK_LOCK  port map ( inclk => q(8), outclk => sclk );

  -- improvement 1: 1 Hz blink
  -- 50.000.000 / 24999999 = 0.5s to rise / fall => 1s total period
  process (OSC_50, nrst)
  begin
    if nrst = '0' then bcnt <= 0; blink <= '0';
    elsif rising_edge(OSC_50) then
      if bcnt = 24999999 then bcnt <= 0; blink <= not blink;
      else bcnt <= bcnt + 1; end if;
    end if;
  end process;

  -- full system (part1 + part2)
  kp : keypad port map ( clk => sclk, nrst => nrst, col => COL, row => ROW,
                         key => key_s, keycode => keycode_s,
                         good => good_s, bad1 => bad1_s, bad2 => bad2_s,
                         bad3 => bad3_s, shift => shift_s );

  -- LEDs with LED_RED mapped to blink when bad3_s = 1
  LED_GREEN <= (others => good_s);
  gen_led : for i in 0 to 5 generate
    LED_RED(i + 12) <= blink when bad3_s = '1' else bad1_s;
    LED_RED(i + 6)  <= blink when bad3_s = '1' else bad2_s;
    LED_RED(i)      <= blink when bad3_s = '1' else bad3_s;
  end generate;

  -- digits register: newest digit at the right, cleared by '*' (code E)
  process (sclk, nrst)
  begin
    if nrst = '0' then
      num <= x"FFFF"; ndig <= 0;
    elsif rising_edge(sclk) then
      if key_s = '1' and keycode_s = x"E" then
        num <= x"FFFF"; ndig <= 0;
      elsif shift_s = '1' and ndig < 4 then
        num <= num(11 downto 0) & keycode_s;
        ndig <= ndig + 1;
      end if;
    end if;
  end process;

  -- displays
  displays : hex_disps
    port map ( num0 => num(3 downto 0),  num1 => num(7 downto 4),
               num2 => num(11 downto 8), num3 => num(15 downto 12),
               num4 => x"F", num5 => x"F", num6 => x"F", num7 => x"F",
               HEX0 => HEX0, HEX1 => HEX1, HEX2 => HEX2, HEX3 => HEX3,
               HEX4 => HEX4, HEX5 => HEX5, HEX6 => HEX6, HEX7 => HEX7 );
end arc;