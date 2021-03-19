require("vsim_comm")
require("luareg")

wait_ns(10000)

reg_set(0, lynx.Reg_Lynx_on)

--reg_set_file("empty.lnx", 0, 0, 0)

print("Game transfered")

--reg_set_file("empty.sst", 58720256 + 0xC000000, 0, 0)

print("Savestate transfered")

wait_ns(10000)
reg_set(1, lynx.Reg_Lynx_on)

--wait_ns(26000000)

reg_set(1, lynx.Reg_Lynx_LoadState)

print("Lynx ON")

brk()