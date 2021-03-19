library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     

library tb;
use tb.globals.all;

entity sdram_model is
   port 
   (
      clk               : in  std_logic;
      cart_addr         : in  std_logic_vector(19 downto 0);
      cart_rd           : in  std_logic;
      cart_do           : out std_logic_vector(7 downto 0);
      cart_ack          : out std_logic := '0';
      romsize           : out std_logic_vector(19 downto 0) := (others => '0');
      romwrite_data     : out std_logic_vector(15 downto 0) := (others => '0');
      romwrite_addr     : out std_logic_vector(19 downto 0) := (others => '0');
      romwrite_wren     : out std_logic := '0'
   );
end entity;

architecture arch of sdram_model is

   -- not full size, because of memory required
   type t_data is array(0 to (2**20)-1) of integer;
   type bit_vector_file is file of bit_vector;
   
begin

   process
   
      variable data           : t_data := (others => 0);
      variable bs93           : std_logic;
      
      file infile             : bit_vector_file;
      variable f_status       : FILE_OPEN_STATUS;
      variable read_byte      : std_logic_vector(7 downto 0);
      variable next_vector    : bit_vector (0 downto 0);
      variable actual_len     : natural;
      variable targetpos      : integer;
      
      -- copy from std_logic_arith, not used here because numeric std is also included
      function CONV_STD_LOGIC_VECTOR(ARG: INTEGER; SIZE: INTEGER) return STD_LOGIC_VECTOR is
        variable result: STD_LOGIC_VECTOR (SIZE-1 downto 0);
        variable temp: integer;
      begin
 
         temp := ARG;
         for i in 0 to SIZE-1 loop
 
         if (temp mod 2) = 1 then
            result(i) := '1';
         else 
            result(i) := '0';
         end if;
 
         if temp > 0 then
            temp := temp / 2;
         elsif (temp > integer'low) then
            temp := (temp - 1) / 2; -- simulate ASR
         else
            temp := temp / 2; -- simulate ASR
         end if;
        end loop;
 
        return result;  
      end;
   
   begin
      wait until rising_edge(clk);
      
      if (cart_rd = '1') then 
         wait until rising_edge(clk);
         wait until rising_edge(clk);
         wait until rising_edge(clk);
         wait until rising_edge(clk);
         wait until rising_edge(clk);
         wait until rising_edge(clk);         
         cart_do       <= std_logic_vector(to_unsigned(data(to_integer(unsigned(cart_addr))), 8));
         cart_ack      <= '1';
         wait until rising_edge(clk);
         cart_ack      <= '0';
      end if; 

      COMMAND_FILE_ACK_1 <= '0';
      if COMMAND_FILE_START_1 = '1' then
         
         assert false report "received" severity note;
         assert false report COMMAND_FILE_NAME(1 to COMMAND_FILE_NAMELEN) severity note;
      
         file_open(f_status, infile, COMMAND_FILE_NAME(1 to COMMAND_FILE_NAMELEN), read_mode);
      
         targetpos := COMMAND_FILE_TARGET;
         
         romwrite_wren   <= '0';
         wait until rising_edge(clk);
         
         bs93 := '1';
     
         while (not endfile(infile)) loop
            
            read(infile, next_vector, actual_len);  
             
            read_byte := CONV_STD_LOGIC_VECTOR(bit'pos(next_vector(0)), 8);
            
            --report "read_byte=" & integer'image(to_integer(unsigned(read_byte)));
            
            data(targetpos) := to_integer(unsigned(read_byte));
            romsize         <= std_logic_vector(to_unsigned(targetpos, 20));
            
            if (targetpos = 4 and read_byte /= x"42") then bs93 := '0'; end if;
            if (targetpos = 5 and read_byte /= x"53") then bs93 := '0'; end if;
            if (targetpos = 6 and read_byte /= x"39") then bs93 := '0'; end if;
            if (targetpos = 7 and read_byte /= x"33") then bs93 := '0'; end if;
            
            if ((bs93 = '1' or targetpos < 10) and targetpos mod 2 = 1) then
               romwrite_data   <= read_byte & std_logic_vector(to_unsigned(data(targetpos - 1), 8));
               romwrite_addr   <= std_logic_vector(to_unsigned(targetpos - 1, 20));
               romwrite_wren   <= '1';
               wait until rising_edge(clk);
               romwrite_wren   <= '0';
               wait until rising_edge(clk);
            end if;
            
            targetpos       := targetpos + 1;
            
         end loop;
         
         romwrite_wren   <= '0';
         wait until rising_edge(clk);
      
         file_close(infile);
      
         COMMAND_FILE_ACK_1 <= '1';
      
      end if;

   
   
   end process;
   
end architecture;


