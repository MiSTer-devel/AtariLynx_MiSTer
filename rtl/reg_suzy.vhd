library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     

use work.pRegisterBus.all;

package pReg_suzy is

   -- range 0xFC00 .. 0xFCFF
   --   (                                 adr    upper    lower    size   default   accesstype)                                     
   --constant TMPADR      : regmap_type := (16#00#,   7,      0,        1,        0,   readwrite);
   constant TMPADRL     : regmap_type := (16#00#,   7,      0,        1,        0,   readwrite);
   constant TMPADRH     : regmap_type := (16#01#,   7,      0,        1,        0,   readwrite);
   --constant TILTACUM    : regmap_type := (16#02#,   7,      0,        1,        0,   readwrite);
   constant TILTACUML   : regmap_type := (16#02#,   7,      0,        1,        0,   readwrite);
   constant TILTACUMH   : regmap_type := (16#03#,   7,      0,        1,        0,   readwrite);
   --constant HOFF        : regmap_type := (16#04#,   7,      0,        1,        0,   readwrite);
   constant HOFFL       : regmap_type := (16#04#,   7,      0,        1,        0,   readwrite);
   constant HOFFH       : regmap_type := (16#05#,   7,      0,        1,        0,   readwrite);
   --constant VOFF        : regmap_type := (16#06#,   7,      0,        1,        0,   readwrite);
   constant VOFFL       : regmap_type := (16#06#,   7,      0,        1,        0,   readwrite);
   constant VOFFH       : regmap_type := (16#07#,   7,      0,        1,        0,   readwrite);
   --constant VIDBAS      : regmap_type := (16#08#,   7,      0,        1,        0,   readwrite);
   constant VIDBASL     : regmap_type := (16#08#,   7,      0,        1,        0,   readwrite);
   constant VIDBASH     : regmap_type := (16#09#,   7,      0,        1,        0,   readwrite);
   --constant COLLBAS     : regmap_type := (16#0a#,   7,      0,        1,        0,   readwrite);
   constant COLLBASL    : regmap_type := (16#0a#,   7,      0,        1,        0,   readwrite);
   constant COLLBASH    : regmap_type := (16#0b#,   7,      0,        1,        0,   readwrite);
   --constant VIDADR      : regmap_type := (16#0c#,   7,      0,        1,        0,   readwrite);
   constant VIDADRL     : regmap_type := (16#0c#,   7,      0,        1,        0,   readwrite);
   constant VIDADRH     : regmap_type := (16#0d#,   7,      0,        1,        0,   readwrite);
   --constant COLLADR     : regmap_type := (16#0e#,   7,      0,        1,        0,   readwrite);
   constant COLLADRL    : regmap_type := (16#0e#,   7,      0,        1,        0,   readwrite);
   constant COLLADRH    : regmap_type := (16#0f#,   7,      0,        1,        0,   readwrite);
   --constant SCBNEXT     : regmap_type := (16#10#,   7,      0,        1,        0,   readwrite);
   constant SCBNEXTL    : regmap_type := (16#10#,   7,      0,        1,        0,   readwrite);
   constant SCBNEXTH    : regmap_type := (16#11#,   7,      0,        1,        0,   readwrite);
   --constant SPRDLINE    : regmap_type := (16#16#,   7,      0,        1,        0,   readwrite);
   constant SPRDLINEL   : regmap_type := (16#16#,   7,      0,        1,        0,   readwrite);
   constant SPRDLINEH   : regmap_type := (16#13#,   7,      0,        1,        0,   readwrite);
   --constant HPOSSTRT    : regmap_type := (16#14#,   7,      0,        1,        0,   readwrite);
   constant HPOSSTRTL   : regmap_type := (16#14#,   7,      0,        1,        0,   readwrite);
   constant HPOSSTRTH   : regmap_type := (16#15#,   7,      0,        1,        0,   readwrite);
   --constant VPOSSTRT    : regmap_type := (16#16#,   7,      0,        1,        0,   readwrite);
   constant VPOSSTRTL   : regmap_type := (16#16#,   7,      0,        1,        0,   readwrite);
   constant VPOSSTRTH   : regmap_type := (16#17#,   7,      0,        1,        0,   readwrite);
   --constant SPRHSIZ     : regmap_type := (16#18#,   7,      0,        1,        0,   readwrite);
   constant SPRHSIZL    : regmap_type := (16#18#,   7,      0,        1,        0,   readwrite);
   constant SPRHSIZH    : regmap_type := (16#19#,   7,      0,        1,        0,   readwrite);
   --constant SPRVSIZ     : regmap_type := (16#1a#,   7,      0,        1,        0,   readwrite);
   constant SPRVSIZL    : regmap_type := (16#1a#,   7,      0,        1,        0,   readwrite);
   constant SPRVSIZH    : regmap_type := (16#1b#,   7,      0,        1,        0,   readwrite);
   --constant STRETCH     : regmap_type := (16#1c#,   7,      0,        1,        0,   readwrite);
   constant STRETCHL    : regmap_type := (16#1c#,   7,      0,        1,        0,   readwrite);
   constant STRETCHH    : regmap_type := (16#1d#,   7,      0,        1,        0,   readwrite);
   --constant TILT        : regmap_type := (16#1e#,   7,      0,        1,        0,   readwrite);
   constant TILTL       : regmap_type := (16#1e#,   7,      0,        1,        0,   readwrite);
   constant TILTH       : regmap_type := (16#1f#,   7,      0,        1,        0,   readwrite);
   --constant SPRDOFF     : regmap_type := (16#20#,   7,      0,        1,        0,   readwrite);
   constant SPRDOFFL    : regmap_type := (16#20#,   7,      0,        1,        0,   readwrite);
   constant SPRDOFFH    : regmap_type := (16#21#,   7,      0,        1,        0,   readwrite);
   --constant SPRVPOS     : regmap_type := (16#22#,   7,      0,        1,        0,   readwrite);
   constant SPRVPOSL    : regmap_type := (16#22#,   7,      0,        1,        0,   readwrite);
   constant SPRVPOSH    : regmap_type := (16#23#,   7,      0,        1,        0,   readwrite);
   --constant COLLOFF     : regmap_type := (16#24#,   7,      0,        1,        0,   readwrite);
   constant COLLOFFL    : regmap_type := (16#24#,   7,      0,        1,        0,   readwrite);
   constant COLLOFFH    : regmap_type := (16#25#,   7,      0,        1,        0,   readwrite);
   --constant VSIZACUM    : regmap_type := (16#26#,   7,      0,        1,        0,   readwrite);
   constant VSIZACUML   : regmap_type := (16#26#,   7,      0,        1,        0,   readwrite);
   constant VSIZACUMH   : regmap_type := (16#27#,   7,      0,        1,        0,   readwrite);
   --constant HSIZOFF     : regmap_type := (16#28#,   7,      0,        1,        0,   readwrite);
   constant HSIZOFFL    : regmap_type := (16#28#,   7,      0,        1,        0,   readwrite);
   constant HSIZOFFH    : regmap_type := (16#29#,   7,      0,        1,        0,   readwrite);
   --constant VSIZOFF     : regmap_type := (16#2a#,   7,      0,        1,        0,   readwrite);
   constant VSIZOFFL    : regmap_type := (16#2a#,   7,      0,        1,        0,   readwrite);
   constant VSIZOFFH    : regmap_type := (16#2b#,   7,      0,        1,        0,   readwrite);
   --constant SCBADR      : regmap_type := (16#2c#,   7,      0,        1,        0,   readwrite);
   constant SCBADRL     : regmap_type := (16#2c#,   7,      0,        1,        0,   readwrite);
   constant SCBADRH     : regmap_type := (16#2d#,   7,      0,        1,        0,   readwrite);
   --constant PROCADR     : regmap_type := (16#2e#,   7,      0,        1,        0,   readwrite);
   constant PROCADRL    : regmap_type := (16#2e#,   7,      0,        1,        0,   readwrite);
   constant PROCADRH    : regmap_type := (16#2f#,   7,      0,        1,        0,   readwrite);
   constant MATHD       : regmap_type := (16#52#,   7,      0,        1,        0,   readwrite);
   constant MATHC       : regmap_type := (16#53#,   7,      0,        1,        0,   readwrite);
   constant MATHB       : regmap_type := (16#54#,   7,      0,        1,        0,   readwrite);
   constant MATHA       : regmap_type := (16#55#,   7,      0,        1,        0,   readwrite);
   constant MATHP       : regmap_type := (16#56#,   7,      0,        1,        0,   readwrite);
   constant MATHN       : regmap_type := (16#57#,   7,      0,        1,        0,   readwrite);
   constant MATHH       : regmap_type := (16#60#,   7,      0,        1,        0,   readwrite);
   constant MATHG       : regmap_type := (16#61#,   7,      0,        1,        0,   readwrite);
   constant MATHF       : regmap_type := (16#62#,   7,      0,        1,        0,   readwrite);
   constant MATHE       : regmap_type := (16#63#,   7,      0,        1,        0,   readwrite);
   constant MATHM       : regmap_type := (16#6c#,   7,      0,        1,        0,   readwrite);
   constant MATHL       : regmap_type := (16#6d#,   7,      0,        1,        0,   readwrite);
   constant MATHK       : regmap_type := (16#6e#,   7,      0,        1,        0,   readwrite);
   constant MATHJ       : regmap_type := (16#6f#,   7,      0,        1,        0,   readwrite);
   constant SPRCTL0     : regmap_type := (16#80#,   7,      0,        1,        0,   writeonly);
   constant SPRCTL1     : regmap_type := (16#81#,   7,      0,        1,        0,   writeonly);
   constant SPRCOLL     : regmap_type := (16#82#,   7,      0,        1,        0,   writeonly);
   constant SPRINIT     : regmap_type := (16#83#,   7,      0,        1,        0,   writeonly);
   constant SUZYHREV    : regmap_type := (16#88#,   7,      0,        1,        1,   readonly );
   constant SUZYSREV    : regmap_type := (16#89#,   7,      0,        1,        0,   readwrite);
   constant SUZYBUSEN   : regmap_type := (16#90#,   7,      0,        1,        0,   writeonly);
   constant SPRGO       : regmap_type := (16#91#,   7,      0,        1,        0,   writeonly);
   constant SPRSYS      : regmap_type := (16#92#,   7,      0,        1,        0,   readwrite);
   constant JOYSTICK    : regmap_type := (16#b0#,   7,      0,        1,        0,   readwrite);
   constant SWITCHES    : regmap_type := (16#b1#,   7,      0,        1,        0,   readwrite);
   constant RCART0      : regmap_type := (16#b2#,   7,      0,        1,        0,   readwrite);
   constant RCART1      : regmap_type := (16#b3#,   7,      0,        1,        0,   readwrite);
   constant LEDS        : regmap_type := (16#c0#,   7,      0,        1,        0,   readwrite);
   constant PPORTSTAT   : regmap_type := (16#c2#,   7,      0,        1,        0,   readwrite);
   constant PPORTDATA   : regmap_type := (16#c3#,   7,      0,        1,        0,   readwrite);
   constant HOWIE       : regmap_type := (16#c4#,   7,      0,        1,        0,   readwrite);
   
end package;
