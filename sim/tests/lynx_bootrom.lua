require("vsim_comm")
require("luareg")

wait_ns(10000)

reg_set(0, lynx.Reg_Lynx_on)

reg_set_file("P:\\Emu\\Lynx\\empty.lnx", 0, 0, 0)

wait_ns(10000)
reg_set(1, lynx.Reg_Lynx_on)

print("Lynx ON")

brk()