library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.pexport.all;
use work.pRegisterBus.all;
use work.pBus_savestates.all;

entity LynxTop is
   generic 
   (
      is_simu : std_logic := '0'
   );
   port
   (
      clk                        : in  std_logic; -- 64Mhz -> 1/4 CE
      reset_in                   : in  std_logic;
      pause_in                   : in  std_logic;
      
      -- rom
      rom_addr                   : out std_logic_vector(19 downto 0);
      rom_byte                   : in  std_logic_vector( 7 downto 0);
      rom_req                    : out std_logic;
      rom_ack                    : in  std_logic;
      
      romsize                    : in  std_logic_vector(19 downto 0);
      romwrite_data              : in  std_logic_vector(15 downto 0);
      romwrite_addr              : in  std_logic_vector(19 downto 0);
      romwrite_wren              : in  std_logic;

      -- bios
      bios_wraddr                : in  std_logic_vector(8 downto 0);
      bios_wrdata                : in  std_logic_vector(7 downto 0);
      bios_wr                    : in  std_logic;
      
      -- video
      pixel_out_addr             : out integer range 0 to 16319;       -- address for framebuffer 
      pixel_out_data             : out std_logic_vector(11 downto 0);  -- RGB data for framebuffer 
      pixel_out_we               : out std_logic;                      -- new pixel for framebuffer 
      
      -- audio
      audio_l                    : out std_logic_vector(15 downto 0); -- 16 bit signed
      audio_r                    : out std_logic_vector(15 downto 0); -- 16 bit signed

      --settings
      turbo                      : in  std_logic;
      fpsoverlay_on              : in  std_logic;
   
      -- JOYSTICK
      JoyUP                      : in  std_logic;
      JoyDown                    : in  std_logic;
      JoyLeft                    : in  std_logic;
      JoyRight                   : in  std_logic;
      Option1                    : in  std_logic;
      Option2                    : in  std_logic;
      KeyB                       : in  std_logic;
      KeyA                       : in  std_logic;
      KeyPause                   : in  std_logic;

      -- ComLynx serial
      comm_rx                    : in  std_logic;
      comm_tx                    : out std_logic
   );
end entity;

architecture arch of LynxTop is

   signal pixel_addr             : integer range 0 to 16319 := 0;       
   signal pixel_we               : std_logic := '0';  

   -- clock
   signal ce_counter             : unsigned (1 downto 0) := (others => '0');
   signal ce                     : std_logic := '0';
   
   -- register
   signal RegBus_Din             : std_logic_vector(BUS_buswidth-1 downto 0);
   signal RegBus_Adr             : std_logic_vector(BUS_busadr-1 downto 0);
   signal RegBus_wren            : std_logic;
   signal RegBus_rst             : std_logic;
   signal RegBus_Dout            : std_logic_vector(BUS_buswidth-1 downto 0);
   
   type t_reg_wired_or is array(0 to 8) of std_logic_vector(7 downto 0);
   signal reg_wired_or : t_reg_wired_or;
   
   -- cart
   signal cart_strobe0           : std_logic;
   signal cart_strobe1           : std_logic;
   signal cart_wait              : std_logic;
   signal cart_idle              : std_logic;
   
   -- timer
   signal IRQ_request            : std_logic; 
   signal IRQ_clear              : std_logic; 
   signal countup7               : std_logic; 
   
   -- Display DMA
   signal displayLine            : std_logic;
   signal frameEnd               : std_logic;
   
   signal dma_active             : std_logic;
   signal DMA_RAM_address        : integer range 0 to 65535;
   signal DMAGPU_RAM_dataRead    : std_logic_vector(7 downto 0);
   
   signal pixel_dma_addr         : integer range 0 to 16319;     
   signal pixel_dma_data         : std_logic_vector(11 downto 0);
   signal pixel_dma_we           : std_logic;                    

   signal pixel_x                : integer range 0 to 159;                    
   signal pixel_y                : integer range 0 to 101;                    
   signal HzcountBCD             : unsigned(7 downto 0);
   
   -- memorymux
   signal bus_request            : std_logic := '0';
   signal bus_rnw                : std_logic := '0';
   signal bus_addr               : unsigned(15 downto 0) := (others => '0');
   signal bus_datawrite          : std_logic_vector(7 downto 0) := (others => '0');
   signal bus_dataread           : std_logic_vector(7 downto 0);
   signal bus_done               : std_logic;
   
   -- CPU
   signal cpu_idle               : std_logic;

   signal cpu_bus_request        : std_logic;
   signal cpu_bus_rnw            : std_logic;
   signal cpu_bus_addr           : unsigned(15 downto 0);
   signal cpu_bus_datawrite      : std_logic_vector(7 downto 0);
   signal cpu_bus_dataread       : std_logic_vector(7 downto 0);
   signal cpu_bus_done           : std_logic;

   signal irqdisabled            : std_logic;
   signal irqpending             : std_logic;
   signal irqfinish              : std_logic;
   
   -- serial
   signal serdat_read            : std_logic;
   signal serialNewTx            : std_logic;
   signal irq_serial             : std_logic;
   
   -- gpu
   signal GPU_RAM_address        : integer range 0 to 65535;
   signal GPURAM_dataWrite       : std_logic_vector(7 downto 0);     
   signal GPURAM_wren            : std_logic;
   
   signal cpu_sleep              : std_logic;  
   signal gpu_idle               : std_logic;  
   
   signal fpscountBCD            : unsigned(7 downto 0);
   
   -- header
   signal bank0size              : std_logic_vector(15 downto 0);
   signal hasHeader              : std_logic;
   
   signal custom_PCAddr          : std_logic_vector(15 downto 0);
   signal custom_PCuse           : std_logic;
   
   signal bs93_addr              : integer range 0 to 65535;
   signal bs93_data              : std_logic_vector(7 downto 0);     
   signal bs93_wren              : std_logic;

   -- state capture bus
   signal reset                  : std_logic;
   
   signal SSBUS_Din              : std_logic_vector(SSBUS_buswidth-1 downto 0);
   signal SSBUS_Adr              : std_logic_vector(SSBUS_busadr-1 downto 0);
   signal SSBUS_wren             : std_logic := '0';
   signal SSBUS_rst              : std_logic := '0';

   -- export
-- synthesis translate_off
   signal new_export             : std_logic;   
   signal cpu_done               : std_logic; 
   signal cpu_export             : cpu_export_type;
   signal dma_done               : std_logic;
   signal export_timer           : t_exporttimer;
   signal export_16              : std_logic_vector(15 downto 0);
-- synthesis translate_on

begin
   
   -- CE Generation
   process (clk)
   begin
      if rising_edge(clk) then
         if (reset = '1') then
            ce         <= '0';
            ce_counter <= (others => '0');
         elsif (pause_in = '0' or ce = '1') then
            ce_counter <= ce_counter + 1;
            ce <= '0'; 
            if (turbo = '1' or ce_counter = "11" ) then
               ce <= '1';
            end if;
         end if;
         
      end if;
   end process;
   
   
   -- register
   process (reg_wired_or)
      variable wired_or : std_logic_vector(7 downto 0);
   begin
      wired_or := reg_wired_or(0);
      for i in 1 to (reg_wired_or'length - 1) loop
         wired_or := wired_or or reg_wired_or(i);
      end loop;
      RegBus_Dout <= wired_or;
   end process;
   
   idummyregs : entity work.dummyregs
   port map
   (
      clk          => clk,
      ce           => ce,
      reset        => reset,
                                 
      RegBus_Din   => RegBus_Din,
      RegBus_Adr   => RegBus_Adr,
      RegBus_wren  => RegBus_wren,
      RegBus_rst   => RegBus_rst,
      RegBus_Dout  => reg_wired_or(0)
   );
   
   -- cart
   icart : entity work.cart
   port map
   (
      clk            => clk,
      ce             => ce,
      reset          => reset,
      
      hasHeader      => hasHeader,
      bank0size      => bank0size,
      bank1size      => x"0000",
                        
      RegBus_Din     => RegBus_Din,
      RegBus_Adr     => RegBus_Adr,
      RegBus_wren    => RegBus_wren,
      RegBus_rst     => RegBus_rst,
      RegBus_Dout    => reg_wired_or(1),
      
      cart_strobe0   => cart_strobe0,
      cart_strobe1   => cart_strobe1,
      cart_wait      => cart_wait,
      cart_idle      => cart_idle,
      
      rom_addr       => rom_addr,
      rom_byte       => rom_byte,
      rom_req        => rom_req, 
      rom_ack        => rom_ack, 

      SSBUS_Din      => SSBUS_Din, 
      SSBUS_Adr      => SSBUS_Adr, 
      SSBUS_wren     => SSBUS_wren,
      SSBUS_rst      => SSBUS_rst, 
      SSBUS_Dout     => open
   );
   
   -- timer
   itimer : entity work.timer
   port map
   (
      clk               => clk,        
      ce                => ce,         
      reset             => reset,      
      fastforward       => '0',
      turbo             => turbo,
                                
      RegBus_Din        => RegBus_Din, 
      RegBus_Adr        => RegBus_Adr, 
      RegBus_wren       => RegBus_wren,
      RegBus_rst        => RegBus_rst, 
      RegBus_Dout       => reg_wired_or(2),
                        
      irq_serial        => irq_serial,
      IRQ_out           => IRQ_request,
      IRQ_clr           => IRQ_clear,
      
      displayLine       => displayLine,
      frameEnd          => frameEnd,    
      serialNewTx       => serialNewTx,
      countup7          => countup7,
      
-- synthesis translate_off
      debugout          => export_timer,
      debugout16        => export_16,
-- synthesis translate_on

      SSBUS_Din         => SSBUS_Din, 
      SSBUS_Adr         => SSBUS_Adr, 
      SSBUS_wren        => SSBUS_wren,
      SSBUS_rst         => SSBUS_rst, 
      SSBUS_Dout        => open
   );
   
   -- Display DMA
   idisplay_dma : entity work.display_dma
   port map
   (
      clk               => clk,        
      ce                => ce,         
      reset             => reset,      
                                
      RegBus_Din        => RegBus_Din, 
      RegBus_Adr        => RegBus_Adr, 
      RegBus_wren       => RegBus_wren,
      RegBus_rst        => RegBus_rst, 
      RegBus_Dout       => reg_wired_or(3),
      
      cpu_idle          => cpu_idle,
      displayLine       => displayLine,     
      frameEnd          => frameEnd,        
                           
      dma_active        => dma_active,  
      
-- synthesis translate_off
      dma_done          => dma_done,     
-- synthesis translate_on

      RAM_address       => DMA_RAM_address, 
      RAM_dataRead      => DMAGPU_RAM_dataRead,
                        
      pixel_out_addr    => pixel_dma_addr,
      pixel_out_data    => pixel_dma_data,
      pixel_out_we      => pixel_dma_we,  
      
      pixel_out_x       => pixel_x,  
      pixel_out_y       => pixel_y,  
      HzcountBCDout     => HzcountBCD,

      SSBUS_Din         => SSBUS_Din, 
      SSBUS_Adr         => SSBUS_Adr, 
      SSBUS_wren        => SSBUS_wren,
      SSBUS_rst         => SSBUS_rst, 
      SSBUS_Dout        => open
   );
   
   -- Memory Mux
   bus_request   <= cpu_bus_request;
   bus_rnw       <= cpu_bus_rnw;     
   bus_addr      <= cpu_bus_addr;     
   bus_datawrite <= cpu_bus_datawrite;
   
   cpu_bus_dataread <= bus_dataread; 
   cpu_bus_done     <= bus_done;     
   
   imemorymux : entity work.memorymux
   port map
   (
      clk                  => clk,          
      ce                   => ce,           
      reset                => reset,        
                     
      bus_request          => bus_request,  
      bus_rnw              => bus_rnw,      
      bus_addr             => bus_addr,     
      bus_datawrite        => bus_datawrite,
      bus_dataread         => bus_dataread, 
      bus_done             => bus_done,
      
      RegBus_Din           => RegBus_Din,
      RegBus_Adr           => RegBus_Adr,
      RegBus_wren          => RegBus_wren,
      RegBus_Dout          => RegBus_Dout,
   
      cpu_idle             => cpu_idle,
      dma_active           => dma_active,
      DMA_RAM_address      => DMA_RAM_address,
      GPU_RAM_address      => GPU_RAM_address,
      GPURAM_dataWrite     => GPURAM_dataWrite,  
      GPURAM_wren          => GPURAM_wren,     
      DMAGPURAM_dataRead   => DMAGPU_RAM_dataRead,
         
      cart_strobe0         => cart_strobe0,
      cart_strobe1         => cart_strobe1,
      cart_wait            => cart_wait,
      serdat_read          => serdat_read,
      
      bios_wraddr          => bios_wraddr,
      bios_wrdata          => bios_wrdata,
      bios_wr              => bios_wr, 

      bs93_addr            => bs93_addr,
      bs93_data            => bs93_data,
      bs93_wren            => bs93_wren,
         
      SSBUS_Din            => SSBUS_Din, 
      SSBUS_Adr            => SSBUS_Adr, 
      SSBUS_wren           => SSBUS_wren,
      SSBUS_rst            => SSBUS_rst, 
      SSBUS_Dout           => open,
      
      SSMEM_Addr           => x"0000",
      SSMEM_WrEn           => "00",
      SSMEM_WriteData      => x"00",
      SSMEM_ReadData_REG   => open,
      SSMEM_ReadData_RAM   => open
   );
   
   -- cpu
   icpu : entity work.cpu
   port map
   (
      clk               => clk,  
      ce                => ce,   
      reset             => reset,
   
      cpu_idle          => cpu_idle,
      dma_active        => dma_active,  
      cpu_sleep         => cpu_sleep,       
   
      bus_request       => cpu_bus_request,  
      bus_rnw           => cpu_bus_rnw,     
      bus_addr          => cpu_bus_addr,     
      bus_datawrite     => cpu_bus_datawrite,
      bus_dataread      => cpu_bus_dataread,
      bus_done          => cpu_bus_done,     
   
      irqrequest_in     => IRQ_request,    
      irqclear_in       => IRQ_clear,   
      irqdisabled       => irqdisabled,  
      irqpending        => irqpending,  
      irqfinish         => irqfinish, 

      load_savestate    => '0',
      custom_PCAddr     => custom_PCAddr,
      custom_PCuse      => custom_PCuse,       
            
-- synthesis translate_off
      cpu_done          => cpu_done,         
      cpu_export        => cpu_export,
-- synthesis translate_on

      SSBUS_Din         => SSBUS_Din, 
      SSBUS_Adr         => SSBUS_Adr, 
      SSBUS_wren        => SSBUS_wren,
      SSBUS_rst         => SSBUS_rst, 
      SSBUS_Dout        => open
   );
   
   -- math
   imath : entity work.math
   port map
   (
      clk            => clk,  
      ce             => ce,   
      reset          => reset,
                     
      RegBus_Din     => RegBus_Din, 
      RegBus_Adr     => RegBus_Adr, 
      RegBus_wren    => RegBus_wren,
      RegBus_rst     => RegBus_rst, 
      RegBus_Dout    => reg_wired_or(4),
        
      SSBUS_Din      => SSBUS_Din,  
      SSBUS_Adr      => SSBUS_Adr,  
      SSBUS_wren     => SSBUS_wren, 
      SSBUS_rst      => SSBUS_rst,  
      SSBUS_Dout     => open
   );
   
   -- joystick
   ijoypad: entity work.joypad
   port map
   (     
      clk            => clk,     
                                
      JoyUP          => JoyUP,   
      JoyDown        => JoyDown, 
      JoyLeft        => JoyLeft,
      JoyRight       => JoyRight,
      Option1        => Option1, 
      Option2        => Option2, 
      KeyB           => KeyB,    
      KeyA           => KeyA,    
      KeyPause       => KeyPause,
   
      RegBus_Din     => RegBus_Din, 
      RegBus_Adr     => RegBus_Adr, 
      RegBus_wren    => RegBus_wren,
      RegBus_rst     => RegBus_rst, 
      RegBus_Dout    => reg_wired_or(5)
   );
   
   -- serial
   iserial : entity work.serial
   port map
   (
      clk            => clk,  
      ce             => ce,   
      reset          => reset,
                     
      RegBus_Din     => RegBus_Din, 
      RegBus_Adr     => RegBus_Adr, 
      RegBus_wren    => RegBus_wren,
      RegBus_rst     => RegBus_rst, 
      RegBus_Dout    => reg_wired_or(6),  
      
      serdat_read    => serdat_read,
      serialNewTx    => serialNewTx,
      comm_rx        => comm_rx,
      comm_tx        => comm_tx,
      
      irq_serial     => irq_serial,
         
      -- savestates        
      SSBUS_Din      => SSBUS_Din,  
      SSBUS_Adr      => SSBUS_Adr,  
      SSBUS_wren     => SSBUS_wren, 
      SSBUS_rst      => SSBUS_rst,  
      SSBUS_Dout     => open
   );
   
   -- gpu
   igpu : entity work.gpu
   generic map
   (
      is_simu => is_simu
   )
   port map
   (
      clk            => clk,  
      ce             => ce,   
      reset          => reset,
                     
      RegBus_Din     => RegBus_Din, 
      RegBus_Adr     => RegBus_Adr, 
      RegBus_wren    => RegBus_wren,
      RegBus_rst     => RegBus_rst, 
      RegBus_Dout    => reg_wired_or(7), 
      
      cpu_idle       => cpu_idle,  
      dma_active     => dma_active,
      cpu_sleep      => cpu_sleep, 
      load_savestate => '0',
      gpu_idle       => gpu_idle,
      
      irqrequest_in  => IRQ_request,
      irqdisabled    => irqdisabled,  
      irqpending     => irqpending,  
      irqfinish      => irqfinish,    

      RAM_address    => GPU_RAM_address,
      RAM_dataWrite  => GPURAM_dataWrite,
      RAM_wren       => GPURAM_wren,
      RAM_dataRead   => DMAGPU_RAM_dataRead,
      
      fpscountBCDout => fpscountBCD,
                 
      -- savestates        
      SSBUS_Din      => SSBUS_Din,  
      SSBUS_Adr      => SSBUS_Adr,  
      SSBUS_wren     => SSBUS_wren, 
      SSBUS_rst      => SSBUS_rst,  
      SSBUS_Dout     => open
   );
   
   --sound
   isound : entity work.sound
   port map
   (
      clk            => clk,        
      ce             => ce,         
      reset          => reset,      
      turbo          => turbo,
                     
      RegBus_Din     => RegBus_Din, 
      RegBus_Adr     => RegBus_Adr, 
      RegBus_wren    => RegBus_wren,
      RegBus_rst     => RegBus_rst, 
      RegBus_Dout    => reg_wired_or(8), 
                     
      countup7       => countup7,
                     
      audio_l        => audio_l,
      audio_r        => audio_r,
         
      -- savestates        
      SSBUS_Din      => SSBUS_Din,  
      SSBUS_Adr      => SSBUS_Adr,  
      SSBUS_wren     => SSBUS_wren, 
      SSBUS_rst      => SSBUS_rst,  
      SSBUS_Dout     => open
   );
   
   -- fps overlay
   ifpsoverlay : entity work.fpsoverlay
   port map
   (
      clk            => clk,           
                                      
      overlay_on     => fpsoverlay_on,    
                                      
      pixel_out_addr => pixel_out_addr,
      pixel_out_data => pixel_out_data,
      pixel_out_we   => pixel_out_we,  
                                      
      pixel_in_addr  => pixel_dma_addr, 
      pixel_in_data  => pixel_dma_data, 
      pixel_in_we    => pixel_dma_we,   
                                      
      pixel_x        => pixel_x,       
      pixel_y        => pixel_y,       
      HzcountBCD     => HzcountBCD,    
      FPScountBCD    => FPScountBCD  
   );
   
   -- header
   iheader : entity work.header
   port map
   (
      clk            => clk,          
                                     
      romsize        => romsize,      
      romwrite_data  => romwrite_data,
      romwrite_addr  => romwrite_addr,
      romwrite_wren  => romwrite_wren,
                                     
      bank0size      => bank0size,    
      hasHeader      => hasHeader,
      
      custom_PCAddr  => custom_PCAddr,
      custom_PCuse   => custom_PCuse,
      
      bs93_addr      => bs93_addr,
      bs93_data      => bs93_data,
      bs93_wren      => bs93_wren
   );      
   
   -- State capture logic is disabled in Lynx2P to keep the multi-core build within MiSTer RAM.
   reset            <= reset_in;
   RegBus_rst       <= reset_in;

   SSBUS_Din        <= (others => '0');
   SSBUS_Adr        <= (others => '0');
   SSBUS_wren       <= '0';
   SSBUS_rst        <= reset_in;
   
   -- export
-- synthesis translate_off
   gexport : if is_simu = '1' generate
   begin
   
      new_export <= (cpu_done and not dma_active) or dma_done;
      
      iexport : entity work.export
      port map
      (
         clk            => clk,
         ce             => ce,
         reset          => reset,
         
         new_export     => new_export,
         export_cpu     => cpu_export,
         export_timer   => export_timer,
         
         export_8       => x"00",
         export_16      => x"0000", --export_16,
         export_32      => x"00000000"
      );
   
   
   end generate;
-- synthesis translate_on
   

end architecture;
