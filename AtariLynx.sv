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
	inout  [45:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output [11:0] VIDEO_ARX,
	output [11:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler

`ifdef USE_FB
	// Use framebuffer in DDRAM (USE_FB=1 in qsf)
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

	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
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

`ifdef USE_DDRAM
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
`endif

`ifdef USE_SDRAM
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
`endif

`ifdef DUAL_SDRAM
	//Secondary SDRAM
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
assign USER_OUT = '1;

assign {UART_RTS, UART_TXD, UART_DTR} = 0;

assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;

reg  sav_pending     = 0;

assign LED_USER  = ioctl_download | sav_pending;
assign LED_DISK  = 0;
assign LED_POWER = 0;
assign BUTTONS   = 0;
assign VGA_SCALER= 0;

wire [1:0] ar = status[14:13];

assign VIDEO_ARX = (!ar) ? (orientation > 0 && !status[15]) ? 12'd102 : 12'd160 : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? (orientation > 0 && !status[15]) ? 12'd160 : 12'd102 : 12'd0;

assign AUDIO_MIX = status[8:7];

// Status Bit Map:
// 0         1         2         3 
// 01234567890123456789012345678901
// 0123456789ABCDEFGHIJKLMNOPQRSTUV
// xxxxxxxxxxxxxxxx         xxx

`include "build_id.v" 
localparam CONF_STR = {
	"AtariLynx;SS3E000000:100000;",
	"FS,LNX;",
	"-;",
	"h0RS,Save state (Alt-F1);",
	"h0RT,Restore state (F1);",
	"-;",
	"OAB,Orientation,Horz,Vert,Vert180;",
	"OF,240p Mode,Off,On;",
	"ODE,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"O24,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"O5,Buffer video,Off,On;",
   "-;",
	"O78,Stereo mix,none,25%,50%,100%;",
   "OP,FastForward Sound,On,Off;",
	"-;",
   "O9,CPU GPU Turbo,Off,On;",
	"OQ,Pause when OSD is open,Off,On;",
	"OR,Rewind Capture,Off,On;",
	//"OC,FPS Overlay,Off,On;",
	"-;",
	"R0,Reset;",
	"J1,A,B,Option1,Option2,Pause,FastForward,SaveState,LoadState,Rewind;",
	"I,",
	"Save to state 1,",
	"Restore state 1,",
	"Save to state 2,",
	"Restore state 2,",
	"Save to state 3,",
	"Restore state 3,",
	"Save to state 4,",
	"Restore state 4,",
	"Rewinding...;",
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

wire [31:0] status;
wire  [1:0] buttons;
wire        forced_scandoubler;
wire        direct_video;
wire [21:0] gamma_bus;

wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire [15:0] ioctl_dout;
reg         ioctl_wait = 0;

wire [15:0] joystick_0, joystick_1, joystick_2, joystick_3;
wire [10:0] ps2_key;

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

hps_io #(.STRLEN($size(CONF_STR)>>3), .WIDE(1)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),
	.EXT_BUS(),

	.conf_str(CONF_STR),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_wait(ioctl_wait),
	.ioctl_index(filetype),
	
	.sd_lba(sd_lba),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din),
	.sd_buff_wr(sd_buff_wr),
	.img_mounted(img_mounted),
	.img_readonly(img_readonly),
	.img_size(img_size),

	.buttons(buttons),
	.status(status),
	.status_menumask(cart_ready),
	.direct_video(direct_video),
	.gamma_bus(gamma_bus),
	.forced_scandoubler(forced_scandoubler),

	.joystick_0(joystick_0),
	.joystick_1(joystick_1),
	.joystick_2(joystick_2),
	.joystick_3(joystick_3),
	
	.ps2_key(ps2_key),
	
	.info_req(ss_info_req),
	.info(ss_info),
	
	.TIMESTAMP(RTC_time)
);

///////////////////////////////////////////////////

wire [15:0] cart_addr;
wire cart_rd;
wire cart_wr;
reg cart_ready = 0;

wire cart_download = ioctl_download && (filetype == 8'h01 || filetype == 8'h41 || filetype == 8'h80);
wire bios_download = ioctl_download && (filetype == 8'h00);

wire sdram_ack;

wire [19:0] rom_addr;
wire [15:0] rom_din = 0;
wire [15:0] rom_dout;
wire  [7:0] rom_byte = rom_addr[0] ? rom_dout[15:8] : rom_dout[7:0];
wire rom_req;
wire rom_ack;

sdram sdram
(
	.*,
	.init(~pll_locked),
	.clk(clk_sys),

	.ch1_addr(ioctl_addr[24:1]),
	.ch1_din(ioctl_dout),
	.ch1_req(ioctl_wr),
	.ch1_rnw(cart_download ? 1'b0 : 1'b1),
	.ch1_ready(sdram_ack),
   .ch1_dout(),

   // 32bit
	.ch2_addr(0),
	.ch2_din(0),
   .ch2_rnw(1),
	.ch2_req(0),
   .ch2_dout(),
   .ch2_ready(),

   // 16 bit
	.ch3_addr(rom_addr[19:1]),
	.ch3_din(rom_din),
	.ch3_dout(rom_dout),
	.ch3_req(~cart_download & rom_req),
	.ch3_rnw(1),
	.ch3_ready(rom_ack)
);

always @(posedge clk_sys) begin
	if(cart_download) begin
		if(ioctl_wr)  ioctl_wait <= 1;
		if(sdram_ack) ioctl_wait <= 0;
	end
	else ioctl_wait <= 0;
end

reg old_download;
reg [19:0] max_addr;
always @(posedge clk_sys) begin
	old_download <= cart_download;
	if (old_download & ~cart_download) begin
      max_addr   <= ioctl_addr[19:0];
      cart_ready <= 1;
   end
end

wire [15:0] Lynx_AUDIO_L;
wire [15:0] Lynx_AUDIO_R;

wire reset = (RESET | status[0] | buttons[1] | cart_download);

reg paused;
always_ff @(posedge clk_sys) begin
   paused <= status[26] && OSD_STATUS && ~status[27]; // no pause when rewind capture is on
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

LynxTop LynxTop (
	.clk              ( clk_sys),
	.reset_in	      ( reset  ),
	.pause_in	      ( paused ),
   
   // rom
   .rom_addr         ( rom_addr ),
   .rom_byte         ( rom_byte ),
   .rom_req          ( rom_req  ),
   .rom_ack          ( rom_ack  ),  
   
   .romsize          (max_addr),
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
	.audio_l 	      (Lynx_AUDIO_L),
	.audio_r 	      (Lynx_AUDIO_R),
	
   //settings
   .fastforward      ( fast_forward ),
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
   
	// savestates
	.save_state       (ss_save),
	.load_state       (ss_load),
	.savestate_number (ss_base),
	.state_loaded     (ss_loaded),
	
	.SAVE_out_Din     (ss_din),            // data read from savestate
	.SAVE_out_Dout    (ss_dout),           // data written to savestate
	.SAVE_out_Adr     (ss_addr),           // all addresses are DWORD addresses!
	.SAVE_out_rnw     (ss_rnw),            // read = 1, write = 0
	.SAVE_out_ena     (ss_req),            // one cycle high for each action
	.SAVE_out_done    (ss_ack),            // should be one cycle high when write is done or read value is valid
	
	.rewind_on        (status[27]),
	.rewind_active    (status[27] & joystick_0[12])
);

assign AUDIO_L = (fast_forward && status[25]) ? 16'd0 : Lynx_AUDIO_L;
assign AUDIO_R = (fast_forward && status[25]) ? 16'd0 : Lynx_AUDIO_R;
assign AUDIO_S = 1;

////////////////////////////  VIDEO  ////////////////////////////////////

wire [13:0] pixel_addr;
wire [11:0] pixel_data;
wire        pixel_we;

wire sync_core = status[5];

reg [11:0] vram1[16320];
reg [11:0] vram2[16320];
reg [11:0] vram3[16320];
reg [1:0] buffercnt_write    = 0;
reg [1:0] buffercnt_readnext = 0;
reg [1:0] buffercnt_read     = 0;

always @(posedge clk_sys) begin
   if (sync_core) begin
      if(pixel_we && pixel_addr == 16319) begin
         buffercnt_readnext <= buffercnt_write;
         if (buffercnt_write < 2) begin
            buffercnt_write <= buffercnt_write + 1'd1;
         end else begin
            buffercnt_write <= 0;
         end
      end
   end else begin
      buffercnt_write    <= 0;
      buffercnt_readnext <= 0;
   end
   
   if(pixel_we) begin
      if (buffercnt_write == 0) vram1[pixel_addr] <= pixel_data;
      if (buffercnt_write == 1) vram2[pixel_addr] <= pixel_data;
      if (buffercnt_write == 2) vram3[pixel_addr] <= pixel_data;
   end
end

always @(posedge CLK_VIDEO) begin
   if (buffercnt_read == 0) rgb <= vram1[px_addr];
   if (buffercnt_read == 1) rgb <= vram2[px_addr];
   if (buffercnt_read == 2) rgb <= vram3[px_addr];
end 

wire [13:0] px_addr;
reg  [11:0] rgb;


reg hs, vs, hbl, vbl, ce_pix;
reg [3:0] r,g,b;
reg [1:0] orientation;
reg [1:0] videomode; 

always @(posedge CLK_VIDEO) begin
	reg [8:0] x,y;
	reg [3:0] div;

	
   if (div < 8) div <= div + 1'd1; else div <= 0; // 64mhz / 9 => 7,11Mhz Pixelclock

	ce_pix <= 0;
	if(!div) begin
		ce_pix <= 1;

		{r,g,b} <= rgb;

      if (videomode == 0) begin
         if(x == 160)     hbl <= 1;
         if(y == 120)     vbl <= 0;
         if(y >= 120+102) vbl <= 1;
      end else if (videomode == 1 || videomode == 2) begin
         if(x == 102)     hbl <= 1;
         if(y == 62)      vbl <= 0;
         if(y >= 62+160)  vbl <= 1;
      end else if (videomode == 3) begin
         if(x == 320)     hbl <= 1;
         if(y == 40)      vbl <= 0;
         if(y >= 40+204)  vbl <= 1;
      end
      
		if(x == 000) begin 
         hbl         <= 0;
         orientation <= status[11:10];
         if (status[15]) begin
            videomode = 3; // 320*204, 60Hz
         end else begin
            if (status[11:10] == 0) videomode = 0; // 160*102, 60Hz
            if (status[11:10] == 1) videomode = 1; // 102*160, 60Hz
            if (status[11:10] == 2) videomode = 2; // 102*160, 60Hz, 180 degree rotated
         end
      end  
       
		if(x == 350) begin
			hs <= 1;
			if(y == 1)   vs <= 1;
			if(y == 4)   vs <= 0;
		end

		if(x == 350+32) hs  <= 0;

	end

	if(ce_pix) begin

      if (videomode == 0) begin
         if(vbl) px_addr <= 0;
         else begin 
            if(!hbl) px_addr <= px_addr + 1'd1;
         end
      end else if (videomode == 1) begin
         if(!hbl) begin 
            px_addr <= px_addr - 8'd160;
         end else begin
            px_addr <= (8'd101 * 8'd160) + (y - 6'd61);
         end
      end else if (videomode == 2) begin
         if(!hbl) begin 
            px_addr <= px_addr + 8'd160;
         end else begin
            px_addr <= 8'd220 - y;
         end
      end else if (videomode == 3) begin
         if(vbl) begin
            px_addr <= 0;
         end else if(!hbl) begin 
            if (x[0] == 1'b1) begin
               px_addr <= px_addr + 1'd1;
            end
         end else begin
            px_addr <= 8'd160 * ((y - 6'd40) / 2'd2);
         end
      end

		x <= x + 1'd1;
		if(x == 444) begin
			x <= 0;
			if (~&y) y <= y + 1'd1;
			if (y >= 269) begin
            y              <= 0;
            buffercnt_read <= buffercnt_readnext;
         end
		end

	end

end

assign VGA_F1 = 0;
assign VGA_SL = sl[1:0];

wire [2:0] scale = status[4:2];
wire [2:0] sl = scale ? scale - 1'd1 : 3'd0;
wire       scandoubler = (scale || forced_scandoubler);

wire [7:0] r_in = {r,r};
wire [7:0] g_in = {g,g};
wire [7:0] b_in = {b,b};

video_mixer #(.LINE_LENGTH(520), .GAMMA(1)) video_mixer
(
	.*,

	.clk_vid(CLK_VIDEO),
	.ce_pix_out(CE_PIXEL),

	.scanlines(0),
	.hq2x(scale==1),
	.mono(0),

	.HSync(hs),
	.VSync(vs),
	.HBlank(hbl),
	.VBlank(vbl),
	.R(r_in),
	.G(g_in),
	.B(b_in)
);

///////////////////////////// Fast Forward Latch /////////////////////////////////

reg fast_forward;
reg ff_latch;

wire fastforward = joystick_0[9] && !ioctl_download && !OSD_STATUS;
wire ff_on;

always @(posedge clk_sys) begin : ffwd
	reg last_ffw;
	reg ff_was_held;
	longint ff_count;

	last_ffw <= fastforward;

	if (fastforward)
		ff_count <= ff_count + 1;

	if (~last_ffw & fastforward) begin
		ff_latch <= 0;
		ff_count <= 0;
	end

	if ((last_ffw & ~fastforward)) begin // 64mhz clock, 0.2 seconds
		ff_was_held <= 0;

		if (ff_count < 6400000 && ~ff_was_held) begin
			ff_was_held <= 1;
			ff_latch <= 1;
		end
	end

	fast_forward <= (fastforward | ff_latch);
end

///////////////////////////// savestates /////////////////////////////////

wire [63:0] SaveStateBus_Din; 
wire [9:0]  SaveStateBus_Adr; 
wire        SaveStateBus_wren;
wire        SaveStateBus_rst; 
wire [63:0] SaveStateBus_Dout;
wire        savestate_load;
	
wire [63:0] ss_dout, ss_din;
wire [27:2] ss_addr;
wire        ss_rnw, ss_req, ss_ack;

assign DDRAM_CLK = clk_sys;
ddram ddram
(
	.*,

	.ch1_addr({ss_addr, 1'b0}),
	.ch1_din(ss_din),
	.ch1_dout(ss_dout),
	.ch1_req(ss_req),
	.ch1_rnw(ss_rnw),
	.ch1_ready(ss_ack)
);

// saving with keyboard/OSD/gamepad
wire       pressed = ps2_key[9];
wire [7:0] code    = ps2_key[7:0];

reg [1:0] ss_base = 0;
reg [7:0] ss_info;
reg reset_1;
reg ss_save, ss_load, ss_info_req;
wire ss_loaded;
always @(posedge clk_sys) begin
	reg old_state;
	reg alt = 0;
	reg [1:0] old_st;
	reg [1:0] old_st_joy;

	old_state <= ps2_key[10];

	if(cart_ready) begin
		if(old_state != ps2_key[10]) begin
			case(code)
				'h11: alt <= pressed;
				'h05: begin ss_save <= pressed & alt; ss_load <= pressed & ~alt; ss_base <= 0; end // F1
				'h06: begin ss_save <= pressed & alt; ss_load <= pressed & ~alt; ss_base <= 1; end // F2
				'h04: begin ss_save <= pressed & alt; ss_load <= pressed & ~alt; ss_base <= 2; end // F3
				'h0C: begin ss_save <= pressed & alt; ss_load <= pressed & ~alt; ss_base <= 3; end // F4
			endcase
		end

      old_st_joy <= joystick_0[11:10];
		if(old_st_joy[0] ^ joystick_0[10])  ss_save <= joystick_0[10];
		if(old_st_joy[1] ^ joystick_0[11]) ss_load <= joystick_0[11];
      if(joystick_0[11:10]) ss_base <= 0;

		old_st <= status[29:28];
		if(old_st[0] ^ status[28]) ss_save <= status[28];
		if(old_st[1] ^ status[29]) ss_load <= status[29];
		if(status[29:28])    ss_base <= 0;

		if(ss_load | ss_save) ss_info <= 7'd1 + {ss_base, ss_load};
		ss_info_req <= (ss_loaded | ss_save);

		// rewind info
		if (status[27] & joystick_0[12]) begin
			ss_info_req <= 1'b1;
			ss_info     <= 7'd9;
		end

	end
end

endmodule
