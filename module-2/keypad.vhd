library ieee;
use ieee.std_logic_1164.all;

entity keypad is
  port ( clk, nrst : in  std_logic;
         col       : in  std_logic_vector(3 downto 0);
         row       : out std_logic_vector(3 downto 0);
         key       : out std_logic;
         keycode   : out std_logic_vector(3 downto 0);
         good, bad1, bad2, bad3, shift : out std_logic );
end keypad;

architecture arc of keypad is
  component part1
    port ( clk, nrst    : in  std_logic;
           col          : in  std_logic_vector(3 downto 0);
           key          : out std_logic;
           keycode, row : out std_logic_vector(3 downto 0));
  end component;

  component part2
    port ( clk, nrst, key         : in  std_logic;
           keycode                : in  std_logic_vector(3 downto 0);
           good, bad1, bad2, bad3 : out std_logic;
           shift                  : out std_logic );
  end component;

  signal key_s     : std_logic;
  signal keycode_s : std_logic_vector(3 downto 0);
begin
  p1 : part1 port map ( clk => clk, nrst => nrst, col => col,
                        key => key_s, keycode => keycode_s, row => row );

  p2 : part2 port map ( clk => clk, nrst => nrst, key => key_s, keycode => keycode_s,
                        good => good, bad1 => bad1, bad2 => bad2, bad3 => bad3,
                        shift => shift );

  key     <= key_s;
  keycode <= keycode_s;
end arc;