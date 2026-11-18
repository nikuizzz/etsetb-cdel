library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;

entity LCD_int_i5 is 
   port( clk, nrst			       	: in std_logic;
         DB_LCD 					: inout std_logic_vector (7 downto 0);
    	 LON, LEN, LWRN, LRS, busy 	: out std_logic;
    	 run						: in std_logic;
    	 message 					: in integer range 0 to 9 );
end LCD_int_i5;

architecture behaviour of LCD_int_i5 is

   type lcd_machine is ( delay, set1, set2, onoff1, onoff2, mode1, mode2, 
						waiting, clear1, clear2, char1, char2, read1, read2 );
   signal lcd_st 	: lcd_machine;
   signal lcdctrl 	: std_logic_vector(2 downto 0);
   signal data		: std_logic_vector(7 downto 0);
   signal ch		: character;
   signal add	  	: integer range 144 downto 0;
   signal counter   : integer range 16 downto 0;	
   signal run_d     : std_logic;
   signal go        : std_logic_vector (1 downto 0);

begin

--D-TYPE FLIP FLOP	
FFD:process (clk,nrst)
    begin
    if nrst ='0' then run_d <= '1';
     elsif clk'event and clk='1' then
         run_d <= run;
	 end if;
end process FFD;
go <= run & run_d;

--LCD CONTROL STATE MACHINE 
  LCD_FSM : process (clk, nrst)  
  begin  	
    if nrst='0' then lcd_st <= delay; 
    elsif clk'event and clk='1' then
      case lcd_st is
		--------Setting---------------
        when delay  => lcd_st <= set1; add <= 0; counter <= 0;
        when set1   => lcd_st <= set2;
        when set2   => lcd_st <= onoff1;
        when onoff1 => lcd_st <= onoff2;
        when onoff2 => lcd_st <= mode1;
        when mode1  => lcd_st <= mode2;
        when mode2  => lcd_st <= waiting;
	    when waiting => if go = "01" then  
					       if message = 1  then  
						      lcd_st <= clear1; add <= 0; 	 -- Message 1
	                       elsif message = 2 then  
							  lcd_st <= clear1; add <= 16;   -- Message 2			
					       elsif message = 3 then  
							  lcd_st <= clear1; add <= 32; 	 -- Message 3  
					       elsif message = 4 then
							  lcd_st <= clear1; add <= 48;	 -- Message 4
					       elsif message = 5 then  
							  lcd_st <= clear1; add <= 64; 	 -- Message 5
					       elsif message = 6 then  
							  lcd_st <= clear1; add <= 80; 	 -- Message 6
					       elsif message = 7 then  
							  lcd_st <= clear1; add <= 96; 	 -- Message 7
					       elsif message = 8 then  
							  lcd_st <= clear1; add <= 112;  -- Message 8
					       elsif message = 9 then  
							  lcd_st <= clear1; add <= 128;  -- Message 9
						   else
							  lcd_st <= waiting;
						   end if;	  	
					   else lcd_st <= waiting; 
					   end if;
	    -------- Message Display Routine---------------
        when clear1 => lcd_st <= clear2; 
        when clear2 => lcd_st <= char1;
        when char1  => lcd_st <= char2;
        when char2  => lcd_st <= read1;
        when read1  => if DB_LCD(7)='1' then 
							lcd_st <= read2;
						elsif counter = 16 then 
							lcd_st <= waiting;
							counter <= 0;
						else 
							lcd_st <= char1; 
							counter <= counter+1; 
							add <= add+1; 
						end if;
        when read2  => if DB_LCD(7)='1' then 
							lcd_st <= read1;
						elsif counter = 16 then 
							lcd_st <= waiting;
							counter <= 0; 
						else 
							lcd_st <= char1;
							counter <= counter+1; 
							add <= add+1; 
							end if;
     end case;
    end if;
  end process LCD_FSM;

with lcd_st select
    busy <= '0' when waiting,
		    '1' when others;

---------------LCD CONTROL LINES---------------
LRS  <= lcdctrl(2);
LWRN <= lcdctrl(1);
LEN  <= lcdctrl(0);
LON  <= '1';

with lcd_st select
	lcdctrl <= "001" when set1|onoff1|mode1|clear1,
			"000" when set2|onoff2|mode2|clear2, 
			"101" when char1,
			"100" when char2,
			"010" when read1,
			"011" when read2,
			"000" when others;

----------------DATA BUS CONTROL---------------
with lcd_st select
	DB_LCD <= data when char1|char2,
		"ZZZZZZZZ" when read1|read2,
		"001111XX" when set1|set2,
 		"00001111" when onoff1|onoff2,
		"00000001" when clear1|clear2,
		"00000110" when mode1|mode2,
		"00000010" when others;
data  <=  conv_std_logic_vector(character'pos(ch),8);

---------------LCD MESSAGES---------------
with add select
 ch <=	'P' when 0,  ------MESSAGE 1 "Press * to start"
		'r' when 1,
		'e' when 2,
		's' when 3,
		's' when 4,
		' ' when 5,
		'*' when 6,
		' ' when 7,
		't' when 8,
		'o' when 9,
		' ' when 10,
		's' when 11,
		't' when 12,
		'a' when 13,
		'r' when 14,
		't' when 15,
		'E' when 16,  -----MESSAGE 2 "Enter PIN Code"
		'n' when 17,
		't' when 18,
		'e' when 19,
		'r' when 20,
		' ' when 21,
		'P' when 22,
		'I' when 23,
		'N' when 24,
		' ' when 25,
		'C' when 26,
		'o' when 27,
		'd' when 28,
		'e' when 29,
		' ' when 30 to 31,
		'R' when 32,  -----MESSAGE 3 "Right Code!"
		'i' when 33,
		'g' when 34,
		'h' when 35,
		't' when 36,
		' ' when 37,
		'C' when 38,
		'o' when 39,
		'd' when 40,
		'e' when 41,
		'!' when 42,
		' ' when 43 to 47,
		'W' when 48,  -----MESSAGE 4 "Wrong Code!"
		'r' when 49,
		'o' when 50,
		'n' when 51,
		'g' when 52,
		' ' when 53,
		'C' when 54,
		'o' when 55,
		'd' when 56,
		'e' when 57,
		'!' when 58,
		' ' when 59 to 63,
		'S' when 64,  -----MESSAGE 5 "System Locked"
		'y' when 65,
		's' when 66,
		't' when 67,
		'e' when 68,
		'm' when 69,
		' ' when 70,
		'L' when 71,
		'o' when 72,
		'c' when 73,
		'k' when 74,
		'e' when 75,
		'd' when 76,
		' ' when 77 to 79,
		'M' when 80,  -----MESSAGE 6 "Must be 4 digits"
		'u' when 81,
		's' when 82,
		't' when 83,
		' ' when 84,
		'b' when 85,
		'e' when 86,
		' ' when 87,
		'4' when 88,
		' ' when 89,
		'd' when 90,
		'i' when 91,
		'g' when 92,
		'i' when 93,
		't' when 94,
		's' when 95,
		'C' when 96,  -----MESSAGE 7 "Config. applied"
		'o' when 97,
		'n' when 98,
		'f' when 99,
		'i' when 100,
		'g' when 101,
		'.' when 102,
		' ' when 103,
		'a' when 104,
		'p' when 105,
		'p' when 106,
		'l' when 107,
		'i' when 108,
		'e' when 109,
		'd' when 110,
		' ' when 111,
		'C' when 112,  -----MESSAGE 8 "Configuration on"
		'o' when 113,
		'n' when 114,
		'f' when 115,
		'i' when 116,
		'g' when 117,
		'u' when 118,
		'r' when 119,
		'a' when 120,
		't' when 121,
		'i' when 122,
		'o' when 123,
		'n' when 124,
		' ' when 125,
		'o' when 126,
		'n' when 127,
		'T' when 128,  -----MESSAGE 9 "Trick mode on"
		'r' when 129,
		'i' when 130,
		'c' when 131,
		'k' when 132,
		' ' when 133,
		'm' when 134,
		'o' when 135,
		'd' when 136,
		'e' when 137,
		' ' when 138,
		'o' when 139,
		'n' when 140,
		' ' when 141,
		' ' when 142,
		' ' when 143,
	    ' ' when others;
end behaviour;
