
vcom -93 -quiet -work  sim/tb ^
src/tb/globals.vhd

vcom -93 -quiet -work  sim/mem ^
src/mem/SyncRamDualByteEnable.vhd ^
src/mem/SyncFifo.vhd 

vcom -quiet -work  sim/rs232 ^
src/rs232/rs232_receiver.vhd ^
src/rs232/rs232_transmitter.vhd ^
src/rs232/tbrs232_receiver.vhd ^
src/rs232/tbrs232_transmitter.vhd

vcom -quiet -work sim/procbus ^
src/procbus/proc_bus.vhd ^
src/procbus/testprocessor.vhd

vcom -quiet -work sim/reg_map ^
src/reg_map/reg_lynx.vhd

vcom -O5 -2008 -vopt -quiet -work sim/lynx ^
../rtl/export.vhd

vcom -O5 -2008 -quiet -work sim/lynx ^
../rtl/lynxboot_sim.vhd ^
../rtl/dpram.vhd ^
../rtl/registerpackage.vhd ^
../rtl/reg_mikey.vhd ^
../rtl/reg_suzy.vhd ^
../rtl/SyncRamDual.vhd ^
../rtl/SyncFifoFallThrough.vhd ^
../rtl/bus_savestates.vhd ^
../rtl/reg_savestates.vhd ^
../rtl/statemanager.vhd ^
../rtl/savestates.vhd ^
../rtl/dummyregs.vhd ^
../rtl/timer_module.vhd ^
../rtl/timer.vhd ^
../rtl/sound_module.vhd ^
../rtl/sound.vhd ^
../rtl/display_dma.vhd ^
../rtl/cart.vhd ^
../rtl/math.vhd ^
../rtl/joypad.vhd ^
../rtl/serial.vhd ^
../rtl/gpu.vhd ^
../rtl/cpu.vhd ^
../rtl/memorymux.vhd ^
../rtl/overlay.vhd ^
../rtl/fpsoverlay.vhd ^
../rtl/header.vhd ^
../rtl/lynx_cheats.vhd ^
../rtl/LynxTop.vhd

vlog -sv -quiet -work sim/tb ^
../rtl/ddram.sv

vcom -quiet -work sim/tb ^
src/tb/stringprocessor.vhd ^
src/tb/tb_interpreter.vhd ^
src/tb/framebuffer.vhd ^
src/tb/sdram_model.vhd ^
src/tb/ddrram_model.vhd ^
src/tb/tb.vhd