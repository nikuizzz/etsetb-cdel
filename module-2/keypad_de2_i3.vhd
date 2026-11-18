library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity keypad_de2_i3 is
  port ( OSC_50    : in    std_logic;
         KEY       : in    std_logic_vector(3 downto 0);
         COL       : in    std_logic_vector(3 downto 0);
         ROW       : out   std_logic_vector(3 downto 0);
         LED_GREEN : out   std_logic_vector(8 downto 0);
         LED_RED   : out   std_logic_vector(17 downto 0);
         HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7 : out std_logic_vector(6 downto 0);
         LCD_DATA  : inout std_logic_vector(7 downto 0);
         LCD_ON, LCD_BLON, LCD_EN, LCD_RW, LCD_RS : out std_logic );
end keypad_de2_i3;

architecture arc of keypad_de2_i3 is
  component part1
    port ( clk, nrst    : in  std_logic;
           col          : in  std_logic_vector(3 downto 0);
           key          : out std_logic;
           keycode, row : out std_logic_vector(3 downto 0));
  end component;

  component part2b
    port ( clk, nrst, key         : in  std_logic;
           keycode                : in  std_logic_vector(3 downto 0);
           good, bad1, bad2, bad3 : out std_logic;
           shift                  : out std_logic;
           msg                    : out integer range 0 to 5 );
  end component;

  component hex_disps
    port ( num0, num1, num2, num3, num4, num5, num6, num7 : in std_logic_vector (3 downto 0);
           HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7 : out std_logic_vector (6 downto 0));
  end component;

  component LCD_int
    port ( clk, nrst                 : in    std_logic;
           DB_LCD                    : inout std_logic_vector (7 downto 0);
           LON, LEN, LWRN, LRS, busy : out   std_logic;
           run                       : in    std_logic;
           message                   : in    integer range 0 to 5 );
  end component;

  component clock_div
    port ( clk, nrst : in  std_logic;
           q         : out std_logic_vector(15 downto 0) );
  end component;

  component CLK_LOCK
    port ( inclk  : in  std_logic;
           outclk : out std_logic );
  end component;

  signal nrst, sclk, lclk : std_logic;
  signal q       : std_logic_vector(15 downto 0);
  signal blink   : std_logic;
  signal bcnt    : integer range 0 to 24999999;
  signal key_s, key_eff, good_s, bad1_s, bad2_s, bad3_s, shift_s : std_logic;
  signal keycode_s : std_logic_vector(3 downto 0);
  signal num, display : std_logic_vector(15 downto 0);
  signal ndig    : integer range 0 to 4;
  signal msg, shown_msg : integer range 0 to 5;
  signal run, busy  : std_logic;
  signal trick, abcdind : std_logic;
begin
  nrst <= KEY(0);

  -- clocks: keypad/system = 50MHz/2^11 = 24.4 kHz, LCD = 50MHz/2^16 = 763 Hz
  cdiv   : clock_div port map ( clk => OSC_50, nrst => nrst, q => q );
  clklk  : CLK_LOCK  port map ( inclk => q(10),  outclk => sclk );
  clklk2 : CLK_LOCK  port map ( inclk => q(15), outclk => lclk );

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

  -- improvement 3: toggle trick on A, B, C or D
  abcdind <= '1' when key_s = '1' and (keycode_s = x"A" or keycode_s = x"B" or
                                       keycode_s = x"C" or keycode_s = x"D") else '0';
  process (sclk, nrst)
  begin
    if nrst = '0' then trick <= '0';
    elsif rising_edge(sclk) then
      if abcdind = '1' then trick <= not trick; end if;
    end if;
  end process;

  -- ignore other keys when tick
  key_eff <= key_s and not trick;   

  -- part1 and part2b (part2 + LCD message output)
  p1 : part1  port map ( clk => sclk, nrst => nrst, col => COL, key => key_s,
                         keycode => keycode_s, row => ROW );
  p2 : part2b port map ( clk => sclk, nrst => nrst, key => key_eff, keycode => keycode_s,
                         good => good_s, bad1 => bad1_s, bad2 => bad2_s, bad3 => bad3_s,
                         shift => shift_s, msg => msg );

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
      if key_eff = '1' and keycode_s = x"E" then
        num <= x"FFFF"; ndig <= 0;
      elsif shift_s = '1' and ndig < 4 then
        num <= num(11 downto 0) & keycode_s;
        ndig <= ndig + 1;
      end if;
    end if;
  end process;

  -- display mapping: show 1248 if trick is active, else show the number
  display <= x"1248" when trick = '1' else num;
  displays : hex_disps
    port map ( num0 => display(3 downto 0),  num1 => display(7 downto 4),
               num2 => display(11 downto 8), num3 => display(15 downto 12),
               num4 => x"F", num5 => x"F", num6 => x"F", num7 => x"F",
               HEX0 => HEX0, HEX1 => HEX1, HEX2 => HEX2, HEX3 => HEX3,
               HEX4 => HEX4, HEX5 => HEX5, HEX6 => HEX6, HEX7 => HEX7 );

  -- improvement 2: LCD request. run falls (and stays low) until the LCD answers busy = '1'
  -- to acknowledge that it changes the message
  process (sclk, nrst)
  begin
    if nrst = '0' then
      shown_msg <= 0; run <= '1';
    elsif rising_edge(sclk) then
      if run = '1' then
        if shown_msg /= msg and busy = '0' then run <= '0'; shown_msg <= msg; end if;
      elsif busy = '1' then
        run <= '1';
      end if;
    end if;
  end process;

  lcd : LCD_int
    port map ( clk => lclk, nrst => nrst, DB_LCD => LCD_DATA,
               LON => LCD_ON, LEN => LCD_EN, LWRN => LCD_RW, LRS => LCD_RS,
               busy => busy, run => run, message => msg );
  LCD_BLON <= '1';
end arc;