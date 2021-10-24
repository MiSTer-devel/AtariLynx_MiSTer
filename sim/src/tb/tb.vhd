library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     

library tb;
library lynx;

library procbus;
use procbus.pProc_bus.all;
use procbus.pRegmap.all;

library reg_map;
use reg_map.pReg_lynx.all;

entity etb  is
end entity;

architecture arch of etb is

   constant clk_speed : integer := 100000000;
   constant baud      : integer := 10000000;
 
   signal reset       : std_logic := '1';
   signal clksys      : std_logic := '1';
   
   signal command_in  : std_logic;
   signal command_out : std_logic;
   signal command_out_filter : std_logic;
   
   signal proc_bus_in : proc_bus_type;
   
   signal cart_addr : std_logic_vector(15 downto 0);
   signal cart_rd   : std_logic;
   signal cart_wr   : std_logic;
   signal cart_act  : std_logic;
   signal cart_do   : std_logic_vector(7 downto 0);
   signal cart_di   : std_logic_vector(7 downto 0);
   
   signal pixel_out_addr : integer range 0 to 16319;
   signal pixel_out_data : std_logic_vector(11 downto 0);  
   signal pixel_out_we   : std_logic := '0';       
   
   -- rom read
   signal rom_addr         : std_logic_vector(19 downto 0);
   signal rom_byte         : std_logic_vector( 7 downto 0);
   signal rom_req          : std_logic;
   signal rom_ack          : std_logic;
   
   signal romsize          : std_logic_vector(19 downto 0);
   signal romwrite_data    : std_logic_vector(15 downto 0);
   signal romwrite_addr    : std_logic_vector(19 downto 0);
   signal romwrite_wren    : std_logic;
   
   -- ddrram
   signal DDRAM_CLK        : std_logic;
   signal DDRAM_BUSY       : std_logic;
   signal DDRAM_BURSTCNT   : std_logic_vector(7 downto 0);
   signal DDRAM_ADDR       : std_logic_vector(28 downto 0);
   signal DDRAM_DOUT       : std_logic_vector(63 downto 0);
   signal DDRAM_DOUT_READY : std_logic;
   signal DDRAM_RD         : std_logic;
   signal DDRAM_DIN        : std_logic_vector(63 downto 0);
   signal DDRAM_BE         : std_logic_vector(7 downto 0);
   signal DDRAM_WE         : std_logic;
   
   signal ch1_addr         : std_logic_vector(27 downto 1);
   signal ch1_dout         : std_logic_vector(63 downto 0);
   signal ch1_din          : std_logic_vector(63 downto 0);
   signal ch1_be           : std_logic_vector(7 downto 0);
   signal ch1_req          : std_logic;
   signal ch1_rnw          : std_logic;
   signal ch1_ready        : std_logic;
   
   signal SAVE_out_Din     : std_logic_vector(63 downto 0);
   signal SAVE_out_Dout    : std_logic_vector(63 downto 0);
   signal SAVE_out_Adr     : std_logic_vector(25 downto 0);
   signal SAVE_out_be      : std_logic_vector(7 downto 0);
   signal SAVE_out_rnw     : std_logic;                    
   signal SAVE_out_ena     : std_logic;                                    
   signal SAVE_out_done    : std_logic; 
   
   -- settings
   signal Lynx_on            : std_logic_vector(Reg_Lynx_on.upper             downto Reg_Lynx_on.lower)             := (others => '0');
   signal Lynx_SaveState     : std_logic_vector(Reg_Lynx_SaveState.upper      downto Reg_Lynx_SaveState.lower)      := (others => '0');
   signal Lynx_LoadState     : std_logic_vector(Reg_Lynx_LoadState.upper      downto Reg_Lynx_LoadState.lower)      := (others => '0'); 
   signal Lynx_Rewind_on     : std_logic_vector(Reg_Lynx_Rewind_on    .upper  downto Reg_Lynx_Rewind_on    .lower)  := (others => '0'); 
   signal Lynx_Rewind_active : std_logic_vector(Reg_Lynx_Rewind_active.upper  downto Reg_Lynx_Rewind_active.lower)  := (others => '0'); 
   
   signal cheat_on           : std_logic := '0';
   
   
begin

   reset  <= not Lynx_on(0);
   clksys <= not clksys after 5 ns;
   
   -- registers
   iReg_Lynx_on             : entity procbus.eProcReg generic map (Reg_Lynx_on           ) port map (clksys, proc_bus_in, Lynx_on           , Lynx_on       );      
   iReg_Lynx_SaveState      : entity procbus.eProcReg generic map (Reg_Lynx_SaveState    ) port map (clksys, proc_bus_in, Lynx_SaveState    , Lynx_SaveState);      
   iReg_Lynx_LoadState      : entity procbus.eProcReg generic map (Reg_Lynx_LoadState    ) port map (clksys, proc_bus_in, Lynx_LoadState    , Lynx_LoadState);
   iReg_Lynx_Rewind_on      : entity procbus.eProcReg generic map (Reg_Lynx_Rewind_on    ) port map (clksys, proc_bus_in, Lynx_Rewind_on    , Lynx_Rewind_on    );
   iReg_Lynx_Rewind_active  : entity procbus.eProcReg generic map (Reg_Lynx_Rewind_active) port map (clksys, proc_bus_in, Lynx_Rewind_active, Lynx_Rewind_active);
   
   iLynxTop : entity Lynx.LynxTop
   generic map
   (
      is_simu => '1'
   )
   port map
   (
      clk                        => clksys,  
      reset_in	                  => reset,
      pause_in	                  => '0',
      
      -- rom
      rom_addr                   => rom_addr,
      rom_byte                   => rom_byte,
      rom_req                    => rom_req, 
      rom_ack                    => rom_ack,
      
      romsize                    => romsize,      
      romwrite_data              => romwrite_data,
      romwrite_addr              => romwrite_addr,
      romwrite_wren              => romwrite_wren,
      
      -- bios
      bios_wraddr                => (others => '0'),
      bios_wrdata                => (others => '0'),
      bios_wr                    => '0',
                    
      -- video                   
      pixel_out_addr             => pixel_out_addr,
      pixel_out_data             => pixel_out_data,
      pixel_out_we               => pixel_out_we,  
                                 
      -- audio                   
      audio_l 	                  => open,
      audio_r 	                  => open,
      
      -- settings
      fastforward                => '0',
      turbo                      => '0',
      speedselect                => "00",
      fpsoverlay_on              => '0',
      
      -- JOYSTICK
      JoyUP                      => '0',
      JoyDown                    => '0',
      JoyLeft                    => '0',
      JoyRight                   => '0',
      Option1                    => '0',
      Option2                    => '0',
      KeyB                       => '0',
      KeyA                       => '0',
      KeyPause                   => '0',
                                 
      -- savestates              
      increaseSSHeaderCount      => '0',
      save_state                 => Lynx_SaveState(0),
      load_state                 => Lynx_LoadState(0),
      savestate_number           => 0,
      state_loaded               => open,
                    
      SAVE_out_Din               => SAVE_out_Din,                 
      SAVE_out_Dout              => SAVE_out_Dout,         
      SAVE_out_Adr               => SAVE_out_Adr, 
      SAVE_out_rnw               => SAVE_out_rnw, 
      SAVE_out_ena               => SAVE_out_ena, 
      SAVE_out_be                => SAVE_out_be, 
      SAVE_out_done              => SAVE_out_done,
                       
      rewind_on                  => Lynx_Rewind_on(0),
      rewind_active              => Lynx_Rewind_active(0),
      
      cheat_clear                => '0',
      cheats_enabled             => '1',
      cheat_on                   => cheat_on,
      cheat_in                   => x"00000000" & x"0000000B" & x"00000000" & x"00000059",
      cheats_active              => open
      
   );
   
   --cheat_on <= '1' after 30 us;
   
   isdram_model : entity tb.sdram_model 
   port map
   (
      clk               => clksys,
      cart_addr         => rom_addr,
      cart_rd           => rom_req,
      cart_do           => rom_byte,
      cart_ack          => rom_ack,
      romsize           => romsize,      
      romwrite_data     => romwrite_data,
      romwrite_addr     => romwrite_addr,
      romwrite_wren     => romwrite_wren
   );
   
   
   ch1_addr <= SAVE_out_Adr(25 downto 0) & "0";
   ch1_din  <= SAVE_out_Din;
   ch1_req  <= SAVE_out_ena;
   ch1_be   <= SAVE_out_be;
   ch1_rnw  <= SAVE_out_rnw;
   SAVE_out_Dout <= ch1_dout;
   SAVE_out_done <= ch1_ready;
   
   iddrram : entity tb.ddram
   port map (
      DDRAM_CLK        => clksys,      
      DDRAM_BUSY       => DDRAM_BUSY,      
      DDRAM_BURSTCNT   => DDRAM_BURSTCNT,  
      DDRAM_ADDR       => DDRAM_ADDR,      
      DDRAM_DOUT       => DDRAM_DOUT,      
      DDRAM_DOUT_READY => DDRAM_DOUT_READY,
      DDRAM_RD         => DDRAM_RD,        
      DDRAM_DIN        => DDRAM_DIN,       
      DDRAM_BE         => DDRAM_BE,        
      DDRAM_WE         => DDRAM_WE,                
                                   
      ch1_addr         => ch1_addr,        
      ch1_dout         => ch1_dout,        
      ch1_din          => ch1_din,         
      ch1_req          => ch1_req,         
      ch1_be           => ch1_be,         
      ch1_rnw          => ch1_rnw,         
      ch1_ready        => ch1_ready
   );
   
   iddrram_model : entity tb.ddrram_model
   port map
   (
      DDRAM_CLK        => clksys,      
      DDRAM_BUSY       => DDRAM_BUSY,      
      DDRAM_BURSTCNT   => DDRAM_BURSTCNT,  
      DDRAM_ADDR       => DDRAM_ADDR,      
      DDRAM_DOUT       => DDRAM_DOUT,      
      DDRAM_DOUT_READY => DDRAM_DOUT_READY,
      DDRAM_RD         => DDRAM_RD,        
      DDRAM_DIN        => DDRAM_DIN,       
      DDRAM_BE         => DDRAM_BE,        
      DDRAM_WE         => DDRAM_WE        
   );

   
   iframebuffer : entity work.framebuffer
   generic map
   (
      FRAMESIZE_X => 160,
      FRAMESIZE_Y => 102
   )
   port map
   (
      clk                => clksys,
                          
      pixel_in_addr      => pixel_out_addr,
      pixel_in_data      => pixel_out_data,
      pixel_in_we        => pixel_out_we
   );
   
   iTestprocessor : entity procbus.eTestprocessor
   generic map
   (
      clk_speed => clk_speed,
      baud      => baud,
      is_simu   => '1'
   )
   port map 
   (
      clk               => clksys,
      bootloader        => '0',
      debugaccess       => '1',
      command_in        => command_in,
      command_out       => command_out,
            
      proc_bus          => proc_bus_in,
      
      fifo_full_error   => open,
      timeout_error     => open
   );
   
   command_out_filter <= '0' when command_out = 'Z' else command_out;
   
   itb_interpreter : entity tb.etb_interpreter
   generic map
   (
      clk_speed => clk_speed,
      baud      => baud
   )
   port map
   (
      clk         => clksys,
      command_in  => command_in, 
      command_out => command_out_filter
   );
   
end architecture;


