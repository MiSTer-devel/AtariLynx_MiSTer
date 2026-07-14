library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     

use work.pRegisterBus.all;
use work.pReg_mikey.all;
use work.pBus_savestates.all;
use work.pReg_savestates.all; 

entity serial is
   port 
   (
      clk            : in  std_logic;
      ce             : in  std_logic;
      reset          : in  std_logic;
                     
      RegBus_Din     : in  std_logic_vector(BUS_buswidth-1 downto 0);
      RegBus_Adr     : in  std_logic_vector(BUS_busadr-1 downto 0);
      RegBus_wren    : in  std_logic;
      RegBus_rst     : in  std_logic;
      RegBus_Dout    : out std_logic_vector(BUS_buswidth-1 downto 0);   
      
      serdat_read    : in  std_logic;
      serialNewTx    : in  std_logic;
      comm_rx        : in  std_logic;
      comm_tx        : out std_logic := '1';
      comm_tx_drive  : out std_logic := '1';

      irq_serial     : out std_logic := '0';
         
      -- savestates        
      SSBUS_Din      : in  std_logic_vector(SSBUS_buswidth-1 downto 0);
      SSBUS_Adr      : in  std_logic_vector(SSBUS_busadr-1 downto 0);
      SSBUS_wren     : in  std_logic;
      SSBUS_rst      : in  std_logic;
      SSBUS_Dout     : out std_logic_vector(SSBUS_buswidth-1 downto 0)
   );
end entity;

architecture arch of serial is

   constant UART_TICK_DIVISOR : natural := 8;

   function frame_parity(data : std_logic_vector(7 downto 0); paren : std_logic; pareven : std_logic) return std_logic is
      variable parity : std_logic := '0';
   begin
      for i in 0 to 7 loop
         parity := parity xor data(i);
      end loop;

      if (paren = '1') then
         if (pareven = '1') then
            return parity;
         else
            return not parity;
         end if;
      end if;

      return pareven;
   end function;

   function rx_parity_error(data : std_logic_vector(7 downto 0); parbit : std_logic; pareven : std_logic) return std_logic is
      variable odd_parity : std_logic := parbit;
   begin
      for i in 0 to 7 loop
         odd_parity := odd_parity xor data(i);
      end loop;

      if ((not odd_parity) /= pareven) then
         return '1';
      end if;

      return '0';
   end function;

   -- register
   signal Reg_SERCTL : std_logic_vector(SERCTL.upper downto SERCTL.lower) := (others => '0');
   signal Reg_SERDAT : std_logic_vector(SERDAT.upper downto SERDAT.lower) := (others => '0');

   type t_reg_wired_or is array(0 to 1) of std_logic_vector(7 downto 0);
   signal reg_wired_or : t_reg_wired_or;   
   
   signal Reg_SERCTL_BACK    : std_logic_vector(7 downto 0);
   signal Reg_SERDAT_BACK    : std_logic_vector(7 downto 0);

   signal Reg_SERCTL_written : std_logic;
   signal Reg_SERDAT_written : std_logic;
   signal Reg_SERDAT_write_armed : std_logic := '1';

   -- register details
   signal TXINTEN  : std_logic;
   signal RXINTEN  : std_logic;
   signal PAREN    : std_logic;
   signal TXOPEN   : std_logic;
   signal TXBRK    : std_logic;
   signal PAREVEN  : std_logic;

   -- internal and readback
   signal TXRDY    : std_logic;
   signal RXRDY    : std_logic := '0';
   signal TXEMPTY  : std_logic;
   signal PARERR   : std_logic;
   signal OVERRUN  : std_logic;
   signal FRAMERR  : std_logic;
   signal RXBRK    : std_logic;
   signal PARBIT   : std_logic := '0';

   signal serialNewTx_1 : std_logic := '0';
   signal serial_divider : unsigned(3 downto 0) := (others => '0');

   signal comm_rx_meta  : std_logic := '1';
   signal comm_rx_sync  : std_logic := '1';
   signal comm_rx_last  : std_logic := '1';

   signal tx_hold_full  : std_logic := '0';
   signal tx_hold_data  : std_logic_vector(7 downto 0) := (others => '1');
   signal tx_shift_data : std_logic_vector(7 downto 0) := (others => '1');
   signal tx_busy       : std_logic := '0';
   signal tx_bit_count  : integer range 0 to 10 := 0;
   signal tx_parity_bit : std_logic := '1';
   signal tx_line       : std_logic := '1';

   signal rx_data       : std_logic_vector(7 downto 0) := (others => '1');
   signal rx_hold_pending : std_logic := '0';
   signal rx_shift_data : std_logic_vector(7 downto 0) := (others => '0');
   signal rx_busy       : std_logic := '0';
   signal rx_check_start: std_logic := '0';
   signal rx_bit_count  : integer range 0 to 9 := 0;
   signal rx_wait       : unsigned(24 downto 0) := (others => '0');
   signal rx_parity_bit : std_logic := '0';

   signal baud_counter  : unsigned(23 downto 0) := (others => '0');
   signal baud_period   : unsigned(23 downto 0) := to_unsigned(1024, 24);
   signal break_count   : integer range 0 to 24 := 0;

   -- savestates
   signal SS_SERIAL          : std_logic_vector(REG_SAVESTATE_SERIAL.upper downto REG_SAVESTATE_SERIAL.lower);
   signal SS_SERIAL_BACK     : std_logic_vector(REG_SAVESTATE_SERIAL.upper downto REG_SAVESTATE_SERIAL.lower);

begin 

   iSS_SERIAL : entity work.eReg_SS generic map ( REG_SAVESTATE_SERIAL ) port map (clk, SSBUS_Din, SSBUS_Adr, SSBUS_wren, SSBUS_rst, SSBUS_Dout, SS_SERIAL_BACK, SS_SERIAL);

   iReg_SERCTL  : entity work.eReg generic map ( SERCTL ) port map (clk, RegBus_Din, RegBus_Adr, RegBus_wren, RegBus_rst, reg_wired_or(0), Reg_SERCTL_BACK, Reg_SERCTL, Reg_SERCTL_written);
   iReg_SERDAT  : entity work.eReg generic map ( SERDAT ) port map (clk, RegBus_Din, RegBus_Adr, RegBus_wren, RegBus_rst, reg_wired_or(1), Reg_SERDAT_BACK, Reg_SERDAT, Reg_SERDAT_written);

   process (reg_wired_or)
      variable wired_or : std_logic_vector(7 downto 0);
   begin
      wired_or := reg_wired_or(0);
      for i in 1 to (reg_wired_or'length - 1) loop
         wired_or := wired_or or reg_wired_or(i);
      end loop;
      RegBus_Dout <= wired_or;
   end process;

   TXINTEN <= Reg_SERCTL(7);
   RXINTEN <= Reg_SERCTL(6);
   PAREN   <= Reg_SERCTL(4);
   TXOPEN  <= Reg_SERCTL(2);
   TXBRK   <= Reg_SERCTL(1);
   PAREVEN <= Reg_SERCTL(0);

   TXRDY   <= not tx_hold_full;
   TXEMPTY <= '1' when (tx_hold_full = '0' and tx_busy = '0' and TXBRK = '0') else '0';

   -- TXOPEN selects open-collector vs TTL mode. In open-collector mode a
   -- high bit releases the shared data line; in TTL mode high and low bits
   -- are both actively driven.
   comm_tx       <= tx_line;
   comm_tx_drive <= '1' when (TXOPEN = '0' or tx_line = '0') else '0';

   irq_serial <= '1' when ((TXRDY = '1' and TXINTEN = '1') or (RXRDY = '1' and RXINTEN = '1')) else '0';

   Reg_SERCTL_BACK(7) <= TXRDY;
   Reg_SERCTL_BACK(6) <= RXRDY;
   Reg_SERCTL_BACK(5) <= TXEMPTY;
   Reg_SERCTL_BACK(4) <= PARERR;
   Reg_SERCTL_BACK(3) <= OVERRUN;
   Reg_SERCTL_BACK(2) <= FRAMERR;
   Reg_SERCTL_BACK(1) <= RXBRK;
   Reg_SERCTL_BACK(0) <= PARBIT;

   Reg_SERDAT_BACK <= rx_data;

   SS_SERIAL_BACK( 7 downto  0) <= tx_hold_data;
   SS_SERIAL_BACK(15 downto  8) <= rx_data;
   SS_SERIAL_BACK(19 downto 16) <= std_logic_vector(to_unsigned(tx_bit_count, 4));
   SS_SERIAL_BACK(23 downto 20) <= std_logic_vector(to_unsigned(rx_bit_count, 4));
   SS_SERIAL_BACK(24) <= TXRDY;
   SS_SERIAL_BACK(25) <= RXRDY;
   SS_SERIAL_BACK(26) <= TXEMPTY;
   SS_SERIAL_BACK(27) <= PARERR;
   SS_SERIAL_BACK(28) <= OVERRUN;
   SS_SERIAL_BACK(29) <= FRAMERR;
   SS_SERIAL_BACK(30) <= RXBRK;
   SS_SERIAL_BACK(31) <= PARBIT;

   process (clk)
      variable serial_tick   : std_logic;
      variable uart_bit_tick : std_logic;
      variable sample_period : unsigned(rx_wait'range);
      variable rx_done       : std_logic;
   begin
      if rising_edge(clk) then

         serial_tick := serialNewTx and not serialNewTx_1;
         uart_bit_tick := '0';
         serialNewTx_1 <= serialNewTx;
         rx_done := '0';

         comm_rx_meta <= comm_rx;
         comm_rx_sync <= comm_rx_meta;
         comm_rx_last <= comm_rx_sync;

         if (reset = '1') then

            tx_hold_data  <= SS_SERIAL(7 downto 0);
            tx_hold_full  <= not SS_SERIAL(24);
            tx_shift_data <= (others => '1');
            tx_busy       <= '0';
            tx_bit_count  <= 0;
            tx_parity_bit <= '1';
            tx_line       <= '1';

            PARERR        <= SS_SERIAL(27);
            OVERRUN       <= SS_SERIAL(28);
            FRAMERR       <= SS_SERIAL(29);
            RXBRK         <= SS_SERIAL(30);
            RXRDY         <= SS_SERIAL(25);
            PARBIT        <= SS_SERIAL(31);

            rx_data       <= SS_SERIAL(15 downto 8);
            rx_hold_pending <= '0';
            rx_shift_data <= (others => '0');
            rx_busy       <= '0';
            rx_check_start <= '0';
            rx_bit_count  <= 0;
            rx_wait       <= (others => '0');
            rx_parity_bit <= '0';

            baud_counter  <= (others => '0');
            baud_period   <= to_unsigned(1024, 24);
            serial_divider <= (others => '0');
            break_count   <= 0;
            Reg_SERDAT_write_armed <= '1';

         else

            if (Reg_SERDAT_written = '0') then
               Reg_SERDAT_write_armed <= '1';
            end if;

            if (baud_counter /= x"FFFFFF") then
               baud_counter <= baud_counter + 1;
            end if;

            if (serial_tick = '1') then
               if (baud_counter > 0) then
                  baud_period <= shift_left(baud_counter, 3);
               end if;
               baud_counter <= (others => '0');

               if (serial_divider = to_unsigned(UART_TICK_DIVISOR - 1, serial_divider'length)) then
                  serial_divider <= (others => '0');
                  uart_bit_tick := '1';
               else
                  serial_divider <= serial_divider + 1;
               end if;
            end if;

            if (uart_bit_tick = '1') then
               if (comm_rx_sync = '0') then
                  if (break_count < 24) then
                     break_count <= break_count + 1;
                  end if;
                  if (break_count >= 23) then
                     RXBRK <= '1';
                  end if;
               else
                  break_count <= 0;
                  RXBRK <= '0';
               end if;

               if (TXBRK = '1') then
                  tx_busy       <= '0';
                  tx_bit_count  <= 0;
                  tx_line       <= '0';
               elsif (tx_busy = '0') then
                  if (tx_hold_full = '1') then
                     tx_shift_data <= tx_hold_data;
                     tx_parity_bit <= frame_parity(tx_hold_data, PAREN, PAREVEN);
                     tx_hold_full  <= '0';
                     tx_busy       <= '1';
                     tx_bit_count  <= 0;
                     tx_line       <= '0';
                  else
                     tx_line <= '1';
                  end if;
               else
                  if (tx_bit_count < 10) then
                     tx_bit_count <= tx_bit_count + 1;
                     case tx_bit_count + 1 is
                        when 1 => tx_line <= tx_shift_data(0);
                        when 2 => tx_line <= tx_shift_data(1);
                        when 3 => tx_line <= tx_shift_data(2);
                        when 4 => tx_line <= tx_shift_data(3);
                        when 5 => tx_line <= tx_shift_data(4);
                        when 6 => tx_line <= tx_shift_data(5);
                        when 7 => tx_line <= tx_shift_data(6);
                        when 8 => tx_line <= tx_shift_data(7);
                        when 9 => tx_line <= tx_parity_bit;
                        when others => tx_line <= '1';
                     end case;
                  elsif (tx_hold_full = '1') then
                     tx_shift_data <= tx_hold_data;
                     tx_parity_bit <= frame_parity(tx_hold_data, PAREN, PAREVEN);
                     tx_hold_full  <= '0';
                     tx_bit_count  <= 0;
                     tx_line       <= '0';
                  else
                     tx_busy      <= '0';
                     tx_bit_count <= 0;
                     tx_line      <= '1';
                  end if;
            end if;
         elsif (TXBRK = '1') then
            tx_line <= '0';
         elsif (tx_busy = '0') then
            tx_line <= '1';
         end if;

            if (rx_busy = '0') then
               if (comm_rx_last = '1' and comm_rx_sync = '0') then
                  sample_period := resize(baud_period, rx_wait'length);
                  rx_busy       <= '1';
                  rx_check_start <= '1';
                  rx_bit_count  <= 0;
                  rx_wait       <= shift_right(sample_period, 1);
               end if;
            else
               if (rx_wait > 0) then
                  rx_wait <= rx_wait - 1;
               else
                  sample_period := resize(baud_period, rx_wait'length);
                  rx_wait <= sample_period - 1;

                  if (rx_check_start = '1') then
                     if (comm_rx_sync = '0') then
                        rx_check_start <= '0';
                     else
                        rx_busy        <= '0';
                        rx_check_start <= '0';
                        rx_bit_count   <= 0;
                     end if;
                  elsif (rx_bit_count < 8) then
                     rx_shift_data(rx_bit_count) <= comm_rx_sync;
                     rx_bit_count <= rx_bit_count + 1;
                  elsif (rx_bit_count = 8) then
                     rx_parity_bit <= comm_rx_sync;
                     rx_bit_count <= 9;
                  else
                     if (comm_rx_sync = '0' and rx_shift_data = x"00") then
                        null;
                     else
                        rx_done := '1';
                        if (rx_parity_error(rx_shift_data, rx_parity_bit, PAREVEN) = '1') then
                           PARERR <= '1';
                        end if;

                        if (comm_rx_sync = '0' and rx_shift_data /= x"00") then
                           FRAMERR <= '1';
                        end if;

                        if (RXRDY = '1' and serdat_read = '0') then
                           OVERRUN <= '1';
                        elsif (serdat_read = '1' and ce = '0') then
                           rx_hold_pending <= '1';
                        else
                           rx_data <= rx_shift_data;
                           PARBIT  <= rx_parity_bit;
                           RXRDY   <= '1';
                        end if;
                     end if;

                     rx_busy      <= '0';
                     rx_bit_count <= 0;
                  end if;
               end if;
            end if;

            if (ce = '1') then

               if (Reg_SERCTL_written = '1') then
                  if (Reg_SERCTL(3) = '1') then
                     PARERR  <= '0';
                     OVERRUN <= '0';
                     FRAMERR <= '0';
                     RXBRK   <= '0';
                  end if;
               end if;

               if (serdat_read = '1') then
                  if (rx_hold_pending = '1') then
                     rx_data <= rx_shift_data;
                     PARBIT  <= rx_parity_bit;
                     rx_hold_pending <= '0';
                  elsif (rx_done = '0') then
                     RXRDY <= '0';
                  end if;
               end if;

               if (Reg_SERDAT_written = '1' and Reg_SERDAT_write_armed = '1') then
                  tx_hold_data <= Reg_SERDAT;
                  tx_hold_full <= '1';
                  Reg_SERDAT_write_armed <= '0';
               end if;
            end if;

         end if;
         
      end if;
   end process;
  

end architecture;





