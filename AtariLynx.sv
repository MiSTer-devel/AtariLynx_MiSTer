//============================================================================
//  AtariLynx
//  Copyright (c) 2021 Robert Peip
//
//  MiSTer Framework
//  Copyright (C) 2021 Sorgelig
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
	output        VGA_DISABLE, // analog out is off

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,
	output        HDMI_BLACKOUT,
	output        HDMI_BOB_DEINT,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

assign ADC_BUS  = 'Z;
assign VGA_F1 = 0;

assign {UART_RTS, UART_TXD, UART_DTR} = 0;

assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;

assign LED_USER  = ioctl_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;
assign BUTTONS   = 0;
assign VGA_SCALER= 0;
assign VGA_DISABLE = 0;
assign HDMI_FREEZE = 0;
assign HDMI_BLACKOUT = 0;
assign HDMI_BOB_DEINT = 0;

assign AUDIO_MIX = status[8:7];

// Status Bit Map: (0..31 => "O", 32..63 => "o")
// 0         1         2         3          4         5         6
// 01234567890123456789012345678901 23456789012345678901234567890123
// 0123456789ABCDEFGHIJKLMNOPQRSTUV 0123456789ABCDEFGHIJKLMNOPQRSTUV
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx xxxxxxxx      xx

`include "build_id.v" 
localparam CONF_STR = {
	"AtariLynx2P;SS3E000000:20000;",
	"FS1,LNXLYX,Load ROM;",
	"-;",
	"O[49:48],Lynx instances,2,3,4;",
	"O[50],External ComLynx,Off,On;",
	"-;",
	"OQ,Pause when OSD is open,Off,On;",
	"O9,CPU GPU Turbo,Off,On;",
	"-;",
	"P1,Audio & Video;",
	"P1-;",
	"P1OAB,Orientation,Horz,Vert,Vert180;",
	"P1O6,Separator Line,Off,On;",
	"P1-;",
	"P1OGJ,CRT H-Sync Adjust,0,1,2,3,4,5,6,7,-8,-7,-6,-5,-4,-3,-2,-1;",
	"P1OKN,CRT V-Sync Adjust,0,1,2,3,4,5,6,7,-8,-7,-6,-5,-4,-3,-2,-1;",
	"P1-;",
	"P1OO,Sync core to 60 Hz,Off,On;",
	"P1oD,Video Timing for YC,Off,On;",
	"P1OC,FPS Overlay,Off,On;",
	"P1-;",
	"P1O78,Stereo mix,none,25%,50%,100%;",
	"P1O[47:46],Audioselect,Lynx 1,Lynx 2,Mixed,Split odd/even;",
	"-;",
	"R0,Reset;",
	"J1,A,B,Option1,Option2,Pause;",
	"V,v",`BUILD_DATE
};

////////////////////   CLOCKS   ///////////////////

wire clk_sys;
wire clk_ram;
wire pll_locked;

assign CLK_VIDEO = clk_sys;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_sys),// 64Mhz
	.outclk_1(clk_ram),// 64Mhz
	.locked(pll_locked)
);

///////////////////////////////////////////////////

wire [63:0] status;
wire  [1:0] buttons;
wire        forced_scandoubler;
wire        direct_video;
wire [21:0] gamma_bus;

wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire [15:0] ioctl_dout;
reg         ioctl_wait = 0;

wire [15:0] joystick_0, joy0_unmod, joystick_1, joystick_2, joystick_3;
wire [10:0] ps2_key;

wire [2:0] lynx_count = (status[49:48] == 2'd0) ? 3'd2 :
                        (status[49:48] == 2'd1) ? 3'd3 :
                        3'd4;
wire       lynx3_active = (lynx_count >= 3);
wire       lynx4_active = (lynx_count >= 4);

wire [7:0]  filetype;

reg  [31:0] sd_lba = 0;
reg         sd_rd = 0;
reg         sd_wr = 0;
wire        sd_ack;
wire  [7:0] sd_buff_addr;
wire [15:0] sd_buff_dout;
wire [15:0] sd_buff_din = 0;
wire        sd_buff_wr;
wire        img_mounted;
wire        img_readonly;
wire [63:0] img_size;

wire [32:0] RTC_time;

hps_io #(.CONF_STR(CONF_STR), .WIDE(1)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),
	.EXT_BUS(),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_wait(ioctl_wait),
	.ioctl_index(filetype),
	
	.status(status),
	.status_menumask(1'b0),
	.status_in(status),
	.status_set(1'b0),
	
	.sd_lba('{sd_lba}),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din('{sd_buff_din}),
	.sd_buff_wr(sd_buff_wr),
	.img_mounted(img_mounted),
	.img_readonly(img_readonly),
	.img_size(img_size),

	.buttons(buttons),
	.direct_video(direct_video),
	.gamma_bus(gamma_bus),
	.forced_scandoubler(forced_scandoubler),
    .new_vmode(new_vmode),

	.joystick_0(joy0_unmod),
	.joystick_1(joystick_1),
	.joystick_2(joystick_2),
	.joystick_3(joystick_3),
	
	.ps2_key(ps2_key),
	
	.info_req(1'b0),
	.info(8'd0),
	
	.TIMESTAMP(RTC_time)
);

assign joystick_0 = joy0_unmod[10] ? 16'b0 : joy0_unmod;

///////////////////////////////////////////////////

reg cart_ready = 0;

wire cart_download = ioctl_download && (filetype == 8'h01 || filetype == 8'h41 || filetype == 8'h80);
wire bios_download = ioctl_download && (filetype == 8'h00);

wire sdram_ack;
wire sdram_ch1_ready;
wire [15:0] sdram_ch1_dout;

wire [19:0] rom_addr1;
wire [19:0] rom_addr2;
wire [19:0] rom_addr3;
wire [19:0] rom_addr4;
wire [15:0] rom_din = 0;
wire [15:0] rom_dout1;
wire [15:0] rom_dout2;
wire [15:0] rom_dout3;
wire [15:0] rom_dout4;
wire  [7:0] rom_byte1 = rom_addr1[0] ? rom_dout1[15:8] : rom_dout1[7:0];
wire  [7:0] rom_byte2 = rom_addr2[0] ? rom_dout2[15:8] : rom_dout2[7:0];
wire  [7:0] rom_byte3 = rom_addr3[0] ? rom_dout3[15:8] : rom_dout3[7:0];
wire  [7:0] rom_byte4 = rom_addr4[0] ? rom_dout4[15:8] : rom_dout4[7:0];
wire rom_req1;
wire rom_req2;
wire rom_req3;
wire rom_req4;
wire rom_ack1;
wire rom_ack2;
wire rom_ack3;
wire rom_ack4;

reg old_download = 0;
wire [26:1] sdram_ch1_addr = cart_download ? {7'd0, ioctl_addr[19:1]} :
                                              {7'd0, rom_addr2[19:1]};
wire        sdram_ch1_req  = cart_download ? ioctl_wr : rom_req2;
wire        sdram_ch1_rnw  = ~cart_download;
wire        sdram_ch4_ready;
wire        sdram_ch5_ready;

assign sdram_ack = cart_download & sdram_ch1_ready;
assign rom_dout2 = sdram_ch1_dout;
assign rom_ack2  = ~cart_download & sdram_ch1_ready;
assign rom_ack3  = ~cart_download & lynx3_active & sdram_ch4_ready;
assign rom_ack4  = ~cart_download & lynx4_active & sdram_ch5_ready;

sdram sdram
(
	.*,
	.init(~pll_locked),
	.clk(clk_sys),

	.ch1_addr(sdram_ch1_addr),
	.ch1_din(ioctl_dout),
	.ch1_req(sdram_ch1_req),
	.ch1_rnw(sdram_ch1_rnw),
	.ch1_ready(sdram_ch1_ready),
   .ch1_dout(sdram_ch1_dout),

   // 32bit
	.ch2_addr(0),
	.ch2_din(0),
   .ch2_rnw(1),
	.ch2_req(0),
   .ch2_dout(),
   .ch2_ready(),

   // 16 bit
	.ch3_addr({7'd0, rom_addr1[19:1]}),
	.ch3_din(rom_din),
	.ch3_dout(rom_dout1),
	.ch3_req(~cart_download & rom_req1),
	.ch3_rnw(1),
	.ch3_ready(rom_ack1),

   // 16 bit
	.ch4_addr({7'd0, rom_addr3[19:1]}),
	.ch4_din(rom_din),
	.ch4_dout(rom_dout3),
	.ch4_req(~cart_download & lynx3_active & rom_req3),
	.ch4_rnw(1),
	.ch4_ready(sdram_ch4_ready),

   // 16 bit
	.ch5_addr({7'd0, rom_addr4[19:1]}),
	.ch5_din(rom_din),
	.ch5_dout(rom_dout4),
	.ch5_req(~cart_download & lynx4_active & rom_req4),
	.ch5_rnw(1),
	.ch5_ready(sdram_ch5_ready)
);

always @(posedge clk_sys) begin
	if(cart_download) begin
		if(ioctl_wr)  ioctl_wait <= 1;
		if(sdram_ack) ioctl_wait <= 0;
	end
	else ioctl_wait <= 0;
end

reg [19:0] max_addr1 = 0;
reg [19:0] max_addr2 = 0;
reg [19:0] max_addr3 = 0;
reg [19:0] max_addr4 = 0;
always @(posedge clk_sys) begin
	old_download <= cart_download;
	if (old_download & ~cart_download) begin
      max_addr1  <= ioctl_addr[19:0];
      max_addr2  <= ioctl_addr[19:0];
      max_addr3  <= ioctl_addr[19:0];
      max_addr4  <= ioctl_addr[19:0];
      cart_ready <= 1;
   end
end

wire [15:0] Lynx1_AUDIO_L;
wire [15:0] Lynx1_AUDIO_R;
wire [15:0] Lynx2_AUDIO_L;
wire [15:0] Lynx2_AUDIO_R;
wire [15:0] Lynx3_AUDIO_L;
wire [15:0] Lynx3_AUDIO_R;
wire [15:0] Lynx4_AUDIO_L;
wire [15:0] Lynx4_AUDIO_R;

reg [1:0] lynx_count_sel_d = 0;
reg [7:0] lynx_count_reset = 0;
always_ff @(posedge clk_sys) begin
   lynx_count_sel_d <= status[49:48];
   if (status[49:48] != lynx_count_sel_d) begin
      lynx_count_reset <= 8'hFF;
   end else if (lynx_count_reset != 0) begin
      lynx_count_reset <= lynx_count_reset - 8'd1;
   end
end

wire base_reset = (RESET | status[0] | buttons[1] | cart_download | (lynx_count_reset != 0));

localparam [19:0] LYNX_RESET_DELAY2 = 20'd131072;
localparam [19:0] LYNX_RESET_DELAY3 = 20'd262144;
localparam [19:0] LYNX_RESET_DELAY4 = 20'd393216;

reg [19:0] lynx_reset_hold2 = 0;
reg [19:0] lynx_reset_hold3 = 0;
reg [19:0] lynx_reset_hold4 = 0;

always_ff @(posedge clk_sys) begin
   if (base_reset) begin
      lynx_reset_hold2 <= LYNX_RESET_DELAY2;
      lynx_reset_hold3 <= LYNX_RESET_DELAY3;
      lynx_reset_hold4 <= LYNX_RESET_DELAY4;
   end else begin
      if (lynx_reset_hold2 != 0) lynx_reset_hold2 <= lynx_reset_hold2 - 20'd1;
      if (lynx_reset_hold3 != 0) lynx_reset_hold3 <= lynx_reset_hold3 - 20'd1;
      if (lynx_reset_hold4 != 0) lynx_reset_hold4 <= lynx_reset_hold4 - 20'd1;
   end
end

wire reset1 = base_reset;
wire reset2 = base_reset | (lynx_reset_hold2 != 0);
wire reset3 = base_reset | (lynx_reset_hold3 != 0) | ~lynx3_active;
wire reset4 = base_reset | (lynx_reset_hold4 != 0) | ~lynx4_active;

wire comlynx_tx1;
wire comlynx_tx2;
wire comlynx_tx3;
wire comlynx_tx4;
// ComLynx is an open-drain shared bus between all active internal Lynx instances.
wire comlynx_drive = comlynx_tx1 & comlynx_tx2 &
                     (lynx3_active ? comlynx_tx3 : 1'b1) &
                     (lynx4_active ? comlynx_tx4 : 1'b1);
wire external_comlynx = status[50];

// Deglitch the external ComLynx input. The USER port line is open-drain and
// rises only through the weak FPGA pull-ups, so rising edges are slow and can
// chatter across the input threshold; the UART receivers are edge-sensitive
// and would take each glitch as a false start bit. Require the synchronized
// level to be stable for 16 clk (~0.25us at 64MHz, under 2% of a bit even at
// 62500 baud) before it reaches the bus. The internal multi-core path is not
// filtered.
reg [1:0] comlynx_ext_sync = 2'b11;
reg [3:0] comlynx_ext_cnt  = 4'd0;
reg       comlynx_ext_filt = 1'b1;
always_ff @(posedge clk_sys) begin
   comlynx_ext_sync <= {comlynx_ext_sync[0], USER_IN[0]};
   if (comlynx_ext_sync[1] == comlynx_ext_filt) begin
      comlynx_ext_cnt <= 4'd0;
   end else if (comlynx_ext_cnt == 4'd15) begin
      comlynx_ext_filt <= comlynx_ext_sync[1];
      comlynx_ext_cnt  <= 4'd0;
   end else begin
      comlynx_ext_cnt <= comlynx_ext_cnt + 1'd1;
   end
end

wire comlynx_bus = external_comlynx ? (comlynx_ext_filt & comlynx_drive) : comlynx_drive;

assign USER_OUT = {6'b111111, external_comlynx ? comlynx_drive : 1'b1};

reg paused;
always_ff @(posedge clk_sys) begin
   paused <= syncpaused || (status[26] && OSD_STATUS);
end

reg [8:0]  bios_wraddr;
reg [7:0]  bios_wrdata;
reg [7:0]  bios_wrdata_next;
reg        bios_wr;
reg        bios_wr_next;
always @(posedge clk_sys) begin
	bios_wr      <= 0;
	bios_wr_next <= 0;
	if(bios_download & ioctl_wr) begin
		bios_wrdata       <= ioctl_dout[7:0];
		bios_wrdata_next  <= ioctl_dout[15:8];
      bios_wraddr       <= ioctl_addr[8:0];
      bios_wr           <= 1;
      bios_wr_next      <= 1;
	end else if (bios_wr_next) begin
      bios_wrdata       <= bios_wrdata_next;
      bios_wraddr       <= bios_wraddr + 1'd1;
      bios_wr           <= 1;
	end
end

LynxTop LynxTop1 (
	.clk              ( clk_sys),
	.reset_in	      ( reset1 ),
	.pause_in	      ( paused ),
   
   // rom
   .rom_addr         ( rom_addr1 ),
   .rom_byte         ( rom_byte1 ),
   .rom_req          ( rom_req1  ),
   .rom_ack          ( rom_ack1  ),

   .romsize          (max_addr1),
   .romwrite_data    (ioctl_dout),
   .romwrite_addr    (ioctl_addr[19:0]),
   .romwrite_wren    (cart_download & ioctl_wr),
   
   // bios
   .bios_wraddr      (bios_wraddr),
   .bios_wrdata      (bios_wrdata),
   .bios_wr          (bios_wr    ),
   
   // Video 
   .pixel_out_addr   (pixel_addr),        // integer range 0 to 16319; -- address for framebuffer
	.pixel_out_data   (pixel_data),        // RGB data for framebuffer
	.pixel_out_we     (pixel_we),          // new pixel for framebuffer
      
	// audio 
	.audio_l 	      (Lynx1_AUDIO_L),
	.audio_r 	      (Lynx1_AUDIO_R),
	
   //settings
   .turbo            ( status[9]    ),
   .fpsoverlay_on    ( status[12]   ),
   
   // joystick
   .JoyUP            ((orientation == 2) ? joystick_0[1] : (orientation == 1) ? joystick_0[0] : joystick_0[3]),
   .JoyDown          ((orientation == 2) ? joystick_0[0] : (orientation == 1) ? joystick_0[1] : joystick_0[2]),
   .JoyLeft          ((orientation == 2) ? joystick_0[2] : (orientation == 1) ? joystick_0[3] : joystick_0[1]),
   .JoyRight         ((orientation == 2) ? joystick_0[3] : (orientation == 1) ? joystick_0[2] : joystick_0[0]),
   .Option1          (joystick_0[6]),
   .Option2          (joystick_0[7]),
   .KeyB             (joystick_0[5]),
   .KeyA             (joystick_0[4]),
   .KeyPause         (joystick_0[8]),
   .comm_rx          (comlynx_bus),
   .comm_tx          (comlynx_tx1)
);

LynxTop LynxTop2 (
	.clk              ( clk_sys),
	.reset_in	      ( reset2 ),
	.pause_in	      ( paused ),

   // rom
   .rom_addr         ( rom_addr2 ),
   .rom_byte         ( rom_byte2 ),
   .rom_req          ( rom_req2  ),
   .rom_ack          ( rom_ack2  ),

   .romsize          (max_addr2),
   .romwrite_data    (ioctl_dout),
   .romwrite_addr    (ioctl_addr[19:0]),
   .romwrite_wren    (cart_download & ioctl_wr),

   // bios
   .bios_wraddr      (bios_wraddr),
   .bios_wrdata      (bios_wrdata),
   .bios_wr          (bios_wr    ),

   // Video
   .pixel_out_addr   (pixel_addr2),
	.pixel_out_data   (pixel_data2),
	.pixel_out_we     (pixel_we2),

	// audio
	.audio_l 	      (Lynx2_AUDIO_L),
	.audio_r 	      (Lynx2_AUDIO_R),

   //settings
   .turbo            ( status[9]    ),
   .fpsoverlay_on    ( status[12]   ),

   // joystick
   .JoyUP            ((orientation == 2) ? joystick_1[1] : (orientation == 1) ? joystick_1[0] : joystick_1[3]),
   .JoyDown          ((orientation == 2) ? joystick_1[0] : (orientation == 1) ? joystick_1[1] : joystick_1[2]),
   .JoyLeft          ((orientation == 2) ? joystick_1[2] : (orientation == 1) ? joystick_1[3] : joystick_1[1]),
   .JoyRight         ((orientation == 2) ? joystick_1[3] : (orientation == 1) ? joystick_1[2] : joystick_1[0]),
   .Option1          (joystick_1[6]),
   .Option2          (joystick_1[7]),
   .KeyB             (joystick_1[5]),
   .KeyA             (joystick_1[4]),
   .KeyPause         (joystick_1[8]),
   .comm_rx          (comlynx_bus),
   .comm_tx          (comlynx_tx2)
);

LynxTop LynxTop3 (
	.clk              ( clk_sys),
	.reset_in	      ( reset3 ),
	.pause_in	      ( paused ),

   // rom
   .rom_addr         ( rom_addr3 ),
   .rom_byte         ( rom_byte3 ),
   .rom_req          ( rom_req3  ),
   .rom_ack          ( rom_ack3  ),

   .romsize          (max_addr3),
   .romwrite_data    (ioctl_dout),
   .romwrite_addr    (ioctl_addr[19:0]),
   .romwrite_wren    (cart_download & ioctl_wr),

   // bios
   .bios_wraddr      (bios_wraddr),
   .bios_wrdata      (bios_wrdata),
   .bios_wr          (bios_wr    ),

   // Video
   .pixel_out_addr   (pixel_addr3),
	.pixel_out_data   (pixel_data3),
	.pixel_out_we     (pixel_we3),

	// audio
	.audio_l 	      (Lynx3_AUDIO_L),
	.audio_r 	      (Lynx3_AUDIO_R),

   //settings
   .turbo            ( status[9]    ),
   .fpsoverlay_on    ( status[12]   ),

   // joystick
   .JoyUP            ((orientation == 2) ? joystick_2[1] : (orientation == 1) ? joystick_2[0] : joystick_2[3]),
   .JoyDown          ((orientation == 2) ? joystick_2[0] : (orientation == 1) ? joystick_2[1] : joystick_2[2]),
   .JoyLeft          ((orientation == 2) ? joystick_2[2] : (orientation == 1) ? joystick_2[3] : joystick_2[1]),
   .JoyRight         ((orientation == 2) ? joystick_2[3] : (orientation == 1) ? joystick_2[2] : joystick_2[0]),
   .Option1          (joystick_2[6]),
   .Option2          (joystick_2[7]),
   .KeyB             (joystick_2[5]),
   .KeyA             (joystick_2[4]),
   .KeyPause         (joystick_2[8]),
   .comm_rx          (comlynx_bus),
   .comm_tx          (comlynx_tx3)
);

LynxTop LynxTop4 (
	.clk              ( clk_sys),
	.reset_in	      ( reset4 ),
	.pause_in	      ( paused ),

   // rom
   .rom_addr         ( rom_addr4 ),
   .rom_byte         ( rom_byte4 ),
   .rom_req          ( rom_req4  ),
   .rom_ack          ( rom_ack4  ),

   .romsize          (max_addr4),
   .romwrite_data    (ioctl_dout),
   .romwrite_addr    (ioctl_addr[19:0]),
   .romwrite_wren    (cart_download & ioctl_wr),

   // bios
   .bios_wraddr      (bios_wraddr),
   .bios_wrdata      (bios_wrdata),
   .bios_wr          (bios_wr    ),

   // Video
   .pixel_out_addr   (pixel_addr4),
	.pixel_out_data   (pixel_data4),
	.pixel_out_we     (pixel_we4),

	// audio
	.audio_l 	      (Lynx4_AUDIO_L),
	.audio_r 	      (Lynx4_AUDIO_R),

   //settings
   .turbo            ( status[9]    ),
   .fpsoverlay_on    ( status[12]   ),

   // joystick
   .JoyUP            ((orientation == 2) ? joystick_3[1] : (orientation == 1) ? joystick_3[0] : joystick_3[3]),
   .JoyDown          ((orientation == 2) ? joystick_3[0] : (orientation == 1) ? joystick_3[1] : joystick_3[2]),
   .JoyLeft          ((orientation == 2) ? joystick_3[2] : (orientation == 1) ? joystick_3[3] : joystick_3[1]),
   .JoyRight         ((orientation == 2) ? joystick_3[3] : (orientation == 1) ? joystick_3[2] : joystick_3[0]),
   .Option1          (joystick_3[6]),
   .Option2          (joystick_3[7]),
   .KeyB             (joystick_3[5]),
   .KeyA             (joystick_3[4]),
   .KeyPause         (joystick_3[8]),
   .comm_rx          (comlynx_bus),
   .comm_tx          (comlynx_tx4)
);

wire signed [15:0] audio_mix_l_2 = $signed(Lynx1_AUDIO_L[15:1]) + $signed(Lynx2_AUDIO_L[15:1]);
wire signed [15:0] audio_mix_r_2 = $signed(Lynx1_AUDIO_R[15:1]) + $signed(Lynx2_AUDIO_R[15:1]);
wire signed [15:0] audio_mix_l_4 = $signed(Lynx1_AUDIO_L[15:2]) + $signed(Lynx2_AUDIO_L[15:2]) +
                                   (lynx3_active ? $signed(Lynx3_AUDIO_L[15:2]) : 16'sd0) +
                                   (lynx4_active ? $signed(Lynx4_AUDIO_L[15:2]) : 16'sd0);
wire signed [15:0] audio_mix_r_4 = $signed(Lynx1_AUDIO_R[15:2]) + $signed(Lynx2_AUDIO_R[15:2]) +
                                   (lynx3_active ? $signed(Lynx3_AUDIO_R[15:2]) : 16'sd0) +
                                   (lynx4_active ? $signed(Lynx4_AUDIO_R[15:2]) : 16'sd0);

wire signed [15:0] audio_mono1 = $signed(Lynx1_AUDIO_L[15:1]) + $signed(Lynx1_AUDIO_R[15:1]);
wire signed [15:0] audio_mono2 = $signed(Lynx2_AUDIO_L[15:1]) + $signed(Lynx2_AUDIO_R[15:1]);
wire signed [15:0] audio_mono3 = $signed(Lynx3_AUDIO_L[15:1]) + $signed(Lynx3_AUDIO_R[15:1]);
wire signed [15:0] audio_mono4 = $signed(Lynx4_AUDIO_L[15:1]) + $signed(Lynx4_AUDIO_R[15:1]);
wire signed [15:0] audio_split_l = lynx3_active ? $signed(audio_mono1[15:1]) + $signed(audio_mono3[15:1]) : audio_mono1;
wire signed [15:0] audio_split_r = lynx4_active ? $signed(audio_mono2[15:1]) + $signed(audio_mono4[15:1]) : audio_mono2;

wire signed [15:0] audio_l_out =
   (status[47:46] == 2'd0) ? $signed(Lynx1_AUDIO_L) :
   (status[47:46] == 2'd1) ? $signed(Lynx2_AUDIO_L) :
   (status[47:46] == 2'd2) ? (lynx3_active ? audio_mix_l_4 : audio_mix_l_2) :
                              audio_split_l;

wire signed [15:0] audio_r_out =
   (status[47:46] == 2'd0) ? $signed(Lynx1_AUDIO_R) :
   (status[47:46] == 2'd1) ? $signed(Lynx2_AUDIO_R) :
   (status[47:46] == 2'd2) ? (lynx3_active ? audio_mix_r_4 : audio_mix_r_2) :
                              audio_split_r;

assign AUDIO_L = audio_l_out;
assign AUDIO_R = audio_r_out;
assign AUDIO_S = 1;

////////////////////////////  VIDEO  ////////////////////////////////////

wire [13:0] pixel_addr;
wire [11:0] pixel_data;
wire        pixel_we;
wire [13:0] pixel_addr2;
wire [11:0] pixel_data2;
wire        pixel_we2;
wire [13:0] pixel_addr3;
wire [11:0] pixel_data3;
wire        pixel_we3;
wire [13:0] pixel_addr4;
wire [11:0] pixel_data4;
wire        pixel_we4;

reg [11:0] vram1[16320];
reg [11:0] vram2[16320];
reg [11:0] vram3[16320];
reg [11:0] vram4[16320];
reg        syncpaused = 0;

always @(posedge clk_sys) begin
   if(pixel_we)  vram1[pixel_addr]   <= pixel_data;
   if(pixel_we2) vram2[pixel_addr2]  <= pixel_data2;
   if(pixel_we3) vram3[pixel_addr3]  <= pixel_data3;
   if(pixel_we4) vram4[pixel_addr4]  <= pixel_data4;
   
   if (y > 150) begin
      syncpaused <= 0;
   end else if (status[24] && pixel_we && pixel_addr == 16319) begin
      syncpaused <= 1;
   end

end

reg  [11:0] rgb1;
reg  [11:0] rgb2;
reg  [11:0] rgb3;
reg  [11:0] rgb4;
reg  [1:0]  rgb_core;
reg         rgb_blank;

always @(posedge CLK_VIDEO) begin
   rgb1 <= vram1[px_addr1];
   rgb2 <= vram2[px_addr2];
   rgb3 <= vram3[px_addr3];
   rgb4 <= vram4[px_addr4];
   rgb_core <= px_core;
   rgb_blank <= px_blank;
end 

reg [13:0] px_addr1 = 0;
reg [13:0] px_addr2 = 0;
reg [13:0] px_addr3 = 0;
reg [13:0] px_addr4 = 0;
reg [1:0]  px_core = 0;
reg        px_blank = 0;

wire [11:0] rgb_now_sel = (rgb_core == 2'd0) ? rgb1 :
                          (rgb_core == 2'd1) ? rgb2 :
                          (rgb_core == 2'd2) ? rgb3 :
                          rgb4;
wire [11:0] rgb_now = rgb_blank ? 12'd0 : rgb_now_sel;
                  
reg hs, vs, hbl, vbl, ce_pix;
reg [7:0] r,g,b;
reg [1:0] orientation;
reg [2:0] videomode;
reg [2:0] active_lynx_video = 3'd2;
reg [8:0] x,y;
reg [3:0] div;
reg signed [3:0] HShift;
reg signed [3:0] VShift; 
reg [9:0] HDisplayHFreqMode; 
reg [8:0] VDisplayHFreqMode;
reg signed [3:0] HShiftHFreqMode;
reg signed [3:0] VShiftHFreqMode;  
function automatic [13:0] lynx_pix_addr(input [8:0] sx, input [8:0] sy);
   reg [13:0] sy_ext;
   begin
      sy_ext = {6'd0, sy[7:0]};
      lynx_pix_addr = (sy_ext << 7) + (sy_ext << 5) + {6'd0, sx[7:0]};
   end
endfunction

// If video timing changes, force mode update
reg [4:0] video_status;
wire [4:0] video_status_now = {status[49:48], status[45], status[11:10]};
reg new_vmode = 0;
always @(posedge clk_sys) begin
    if (video_status != video_status_now) begin
        video_status <= video_status_now;
        new_vmode <= ~new_vmode;
    end
end

wire wide_vertical_video = (videomode == 3'd1 || videomode == 3'd2) && (active_lynx_video > 3'd2);
wire signed [10:0] hsync_start_signed = wide_vertical_video ? 11'sd410 : (11'sd350 + $signed(HShift));
wire [9:0] hsync_start = hsync_start_signed[9:0];
wire [9:0] hsync_end   = hsync_start + 10'd32;

wire separator_line = status[6];

always @(posedge CLK_VIDEO) begin
   integer src_x;
   integer src_y;
   integer local_x;
   integer local_y;
   integer screen_idx;
   integer map_valid;
   logic draw_separator;

   if (div < 8) div <= div + 1'd1; else div <= 0; // 64mhz / 9 => 7,11Mhz Pixelclock

	ce_pix <= 0;
	if(!div) begin
		ce_pix <= 1;

      // Optional black separator lines along the seams between adjacent Lynx
      // screens. Boundaries mirror the compositor's own screen mapping for
      // each videomode and active screen count.
      draw_separator = separator_line && !hbl && !vbl &&
         (((videomode == 0) && (x == 9'd159 || x == 9'd160)) ||
          ((videomode == 4) && ((x == 9'd159 || x == 9'd160) ||
                                (y == 40+101+$signed(VShift)) ||
                                (y == 40+102+$signed(VShift)))) ||
          (((videomode == 1) || (videomode == 2)) &&
             ((x == 9'd101 || x == 9'd102) ||
              ((active_lynx_video > 3'd2) && (x == 9'd203 || x == 9'd204)) ||
              ((active_lynx_video > 3'd3) && (x == 9'd305 || x == 9'd306)))));

      if (draw_separator) begin
         r <= 8'd0;
         g <= 8'd0;
         b <= 8'd0;
      end else begin
         r <= {rgb_now[11:8], rgb_now[11:8]};
         g <= {rgb_now[7:4] , rgb_now[7:4] };
         b <= {rgb_now[3:0] , rgb_now[3:0] };
      end

      if (videomode == 0) begin
         if(x == 320)     hbl <= 1;
         if(y == 120)     vbl <= 0;
         if(y >= 120+102) vbl <= 1;
      end else if (videomode == 1 || videomode == 2) begin
         if(x == (wide_vertical_video ? 408 : 204)) hbl <= 1;
         if(y == 62)      vbl <= 0;
         if(y >= 62+160)  vbl <= 1;
      end else if (videomode == 4) begin
         if(x == 320)                     hbl <= 1;
         if(y == 40+$signed(VShift))      vbl <= 0;
         if(y >= 40+204+$signed(VShift))  vbl <= 1;
      end
      
		if(x == 000) begin 
         hbl <= 0;
      end  
       
		if(x == hsync_start) begin
			hs <= 1;
			if(y == 1)   vs <= 1;
			if(y == 4)   vs <= 0;
		end

		if(x == hsync_end) hs  <= 0;

	end

   if(ce_pix) begin
   
      px_core <= 2'd0;
      px_blank <= 1'b1;
      px_addr1 <= 14'd0;
      px_addr2 <= 14'd0;
      px_addr3 <= 14'd0;
      px_addr4 <= 14'd0;
      map_valid = 0;
      screen_idx = 0;
      src_x = 0;
      src_y = 0;

      if (videomode == 0 && !hbl && !vbl && x < 320) begin
         src_y = y - 120;
         if (src_y < 0) src_y = 0;
         if (src_y > 101) src_y = 101;
         if (x < 160) begin
            src_x = x;
            px_addr1 <= lynx_pix_addr(src_x[8:0], src_y[8:0]);
         end else begin
            src_x = x - 160;
            if (src_x > 159) src_x = 159;
            screen_idx = 1;
         end
         map_valid = 1;
      end else if (videomode == 1 && !hbl && !vbl && x < (wide_vertical_video ? 408 : 204)) begin
         if (x < 102) begin
            local_x = x;
            screen_idx = 0;
         end else if (x < 204) begin
            local_x = x - 102;
            screen_idx = 1;
         end else if (x < 306) begin
            local_x = x - 204;
            screen_idx = 2;
         end else begin
            local_x = x - 306;
            screen_idx = 3;
         end
         src_x = y - 62;
         if (src_x < 0) src_x = 0;
         if (src_x > 159) src_x = 159;
         src_y = 101 - local_x;
         if (src_y < 0) src_y = 0;
         map_valid = 1;
      end else if (videomode == 2 && !hbl && !vbl && x < (wide_vertical_video ? 408 : 204)) begin
         if (x < 102) begin
            local_x = x;
            screen_idx = 0;
         end else if (x < 204) begin
            local_x = x - 102;
            screen_idx = 1;
         end else if (x < 306) begin
            local_x = x - 204;
            screen_idx = 2;
         end else begin
            local_x = x - 306;
            screen_idx = 3;
         end
         src_x = 221 - y;
         if (src_x < 0) src_x = 0;
         if (src_x > 159) src_x = 159;
         src_y = local_x;
         if (src_y > 101) src_y = 101;
         map_valid = 1;
      end else if (videomode == 4 && !hbl && !vbl && x < 320) begin
         local_y = y - (40 + $signed(VShift));
         if (local_y < 0) local_y = 0;
         if (local_y > 203) local_y = 203;
         if (x < 160) begin
            src_x = x;
            screen_idx = (local_y < 102) ? 0 : 2;
         end else begin
            src_x = x - 160;
            if (src_x > 159) src_x = 159;
            screen_idx = (local_y < 102) ? 1 : 3;
         end
         src_y = (local_y < 102) ? local_y : (local_y - 102);
         map_valid = 1;
      end

      if (map_valid && screen_idx < active_lynx_video) begin
         px_blank <= 1'b0;
         if (screen_idx == 0) begin
            px_core <= 2'd0;
            px_addr1 <= lynx_pix_addr(src_x[8:0], src_y[8:0]);
         end else if (screen_idx == 1) begin
            px_core <= 2'd1;
            px_addr2 <= lynx_pix_addr(src_x[8:0], src_y[8:0]);
         end else if (screen_idx == 2) begin
            px_core <= 2'd2;
            px_addr3 <= lynx_pix_addr(src_x[8:0], src_y[8:0]);
         end else begin
            px_core <= 2'd3;
            px_addr4 <= lynx_pix_addr(src_x[8:0], src_y[8:0]);
         end
      end

		x <= x + 1'd1;
		if(x == HDisplayHFreqMode) begin  // (445x270 for standard video, 452x265 for improved Analog Timing for Composite)
			x <= 0;
			if (~&y) y <= y + 1'd1;
			if (y >= VDisplayHFreqMode) begin
            y              <= 0;
            
            orientation <= status[11:10];
            active_lynx_video <= lynx_count;
            HShift      <= status[19:16] + HShiftHFreqMode;
            VShift      <= status[23:20] - VShiftHFreqMode;
			HShiftHFreqMode <= (status[45] ? 4'd7 : 4'd0); // Screen Adjust when Y/C Selected
			VShiftHFreqMode <= (status[45] ? 4'd5 : 4'd0); // Screen Adjust when Y/C Selected
			HDisplayHFreqMode <= (status[45] ? 10'd451 : 10'd444); // Change Video Timing for for Y/C Composite Video 
            VDisplayHFreqMode <= (status[45] ? 9'd264 : 9'd269); // Change Video Timing for for Y/C Composite Video
            if (status[11:10] == 0) begin
               if (lynx_count > 2) begin
                  videomode = 4; // 320*204 four-screen 2x2 grid, 60Hz
               end else begin
                  videomode = 0; // 320*102 dual-screen, 60Hz
               end
            end else begin
               if (status[11:10] == 1) videomode = 1; // 204/408*160 vertical strip, 60Hz
               if (status[11:10] == 2) videomode = 2; // 204/408*160 vertical strip, 180 degree rotated
            end
            
         end
		end

	end

end

assign VGA_SL = 2'b00;
assign CE_PIXEL = ce_pix;
assign VGA_R = r;
assign VGA_G = g;
assign VGA_B = b;
assign VGA_HS = hs;
assign VGA_VS = vs;
assign VGA_DE = ~(hbl | vbl);

wire [11:0] native_arx = (orientation > 0) ? ((active_lynx_video > 2) ? 12'd408 : 12'd204) : 12'd320;
wire [11:0] native_ary = (orientation > 0) ? 12'd160 :
                          ((active_lynx_video > 2) ? 12'd204 : 12'd102);
assign VIDEO_ARX = {1'b0, native_arx};
assign VIDEO_ARY = {1'b0, native_ary};

///////////////////////////// Unused DDRAM Interface /////////////////////////////////

assign DDRAM_CLK = clk_sys;
assign DDRAM_BURSTCNT = 8'd0;
assign DDRAM_ADDR = 29'd0;
assign DDRAM_RD = 1'b0;
assign DDRAM_DIN = 64'd0;
assign DDRAM_BE = 8'd0;
assign DDRAM_WE = 1'b0;

endmodule
