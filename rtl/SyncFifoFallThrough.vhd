library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all; 
use ieee.math_real.all;   

entity SyncFifoFallThrough is
   generic 
   (
      SIZE             : integer;
      DATAWIDTH        : integer;
      NEARFULLDISTANCE : integer
   );
   port 
   ( 
      clk      : in  std_logic;
      ce       : in  std_logic;
      reset    : in  std_logic;
               
      Din      : in  std_logic_vector(DATAWIDTH - 1 downto 0);
      Wr       : in  std_logic; 
      Full     : out std_logic;
      NearFull : out std_logic;
      
      Dout     : out std_logic_vector(DATAWIDTH - 1 downto 0);
      Rd       : in  std_logic;
      Empty    : out std_logic
   );
end entity;

architecture arch of SyncFifoFallThrough is

   constant SIZEBITS : integer := integer(ceil(log2(real(SIZE))));

   type t_memory is array(0 to SIZE - 1) of std_logic_vector(DATAWIDTH - 1 downto 0);
   signal memory : t_memory;  
   attribute ramstyle : string;
   attribute ramstyle of memory : signal is "logic";

   signal wrcnt   : unsigned(SIZEBITS - 1 downto 0) := (others => '0');
   signal rdcnt   : unsigned(SIZEBITS - 1 downto 0) := (others => '0');
 
   signal fifocnt : unsigned(SIZEBITS - 1 downto 0) := (others => '0');
 
   signal full_wire     : std_logic;
   signal empty_wire    : std_logic;

begin

   full_wire      <= '1' when rdcnt = wrcnt+1 else '0';
   empty_wire     <= '1' when rdcnt = wrcnt   else '0';

   process(clk)
   begin
      if rising_edge(clk) then
         if (reset = '1') then
            wrcnt   <= (others => '0');
            rdcnt   <= (others => '0');
            fifocnt <= (others => '0');
         elsif (ce = '1') then
            if (Wr = '1' and full_wire = '0') then
               if (Rd = '0' or empty_wire = '1') then
                  fifocnt <= fifocnt + 1;
               end if;
            elsif (Rd = '1' and empty_wire = '0') then
               fifocnt <= fifocnt - 1;
            end if;
            
            if (fifocnt < NEARFULLDISTANCE) then
               NearFull <= '0';
            else
               NearFull <= '1';
            end if;
         
            if (Wr = '1' and full_wire = '0') then
               memory(to_integer(wrcnt)) <= Din;
               wrcnt <= wrcnt+1;
            end if;
            
            if (Rd = '1' and empty_wire = '0') then
               rdcnt <= rdcnt+1;
            end if;
         end if;
      end if;
   end process;
   
   Dout      <= memory(to_integer(rdcnt)); 
  
   Full      <= full_wire;
   Empty     <= empty_wire;

end architecture;