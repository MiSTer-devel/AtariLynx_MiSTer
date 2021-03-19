--space.name = {address, upper, lower, size, default}
lynx = {}
lynx.Reg_Lynx_on = {1056768,0,0,1,0,"lynx.Reg_Lynx_on"} -- on = 1
lynx.Reg_Lynx_lockspeed = {1056769,0,0,1,0,"lynx.Reg_Lynx_lockspeed"} -- 1 = 100% speed
lynx.Reg_Lynx_TestDone = {1056770,0,0,1,0,"lynx.Reg_Lynx_TestDone"}
lynx.Reg_Lynx_TestOk   = {1056770,1,1,1,0,"lynx.Reg_Lynx_TestOk"}
lynx.Reg_Lynx_CyclePrecalc = {1056771,15,0,1,100,"lynx.Reg_Lynx_CyclePrecalc"}
lynx.Reg_Lynx_CyclesMissing = {1056772,31,0,1,0,"lynx.Reg_Lynx_CyclesMissing"}
lynx.Reg_Lynx_BusAddr = {1056773,27,0,1,0,"lynx.Reg_Lynx_BusAddr"}
lynx.Reg_Lynx_BusRnW = {1056773,28,28,1,0,"lynx.Reg_Lynx_BusRnW"}
lynx.Reg_Lynx_BusACC = {1056773,30,29,1,0,"lynx.Reg_Lynx_BusACC"}
lynx.Reg_Lynx_BusWriteData = {1056774,31,0,1,0,"lynx.Reg_Lynx_BusWriteData"}
lynx.Reg_Lynx_BusReadData = {1056775,31,0,1,0,"lynx.Reg_Lynx_BusReadData"}
lynx.Reg_Lynx_MaxPakAddr = {1056776,24,0,1,0,"lynx.Reg_Lynx_MaxPakAddr"}
lynx.Reg_Lynx_VsyncSpeed = {1056777,31,0,1,0,"lynx.Reg_Lynx_VsyncSpeed"}
lynx.Reg_Lynx_KeyUp = {1056778,0,0,1,0,"lynx.Reg_Lynx_KeyUp"}
lynx.Reg_Lynx_KeyDown = {1056778,1,1,1,0,"lynx.Reg_Lynx_KeyDown"}
lynx.Reg_Lynx_KeyLeft = {1056778,2,2,1,0,"lynx.Reg_Lynx_KeyLeft"}
lynx.Reg_Lynx_KeyRight = {1056778,3,3,1,0,"lynx.Reg_Lynx_KeyRight"}
lynx.Reg_Lynx_KeyA = {1056778,4,4,1,0,"lynx.Reg_Lynx_KeyA"}
lynx.Reg_Lynx_KeyB = {1056778,5,5,1,0,"lynx.Reg_Lynx_KeyB"}
lynx.Reg_Lynx_KeyL = {1056778,6,6,1,0,"lynx.Reg_Lynx_KeyL"}
lynx.Reg_Lynx_KeyR = {1056778,7,7,1,0,"lynx.Reg_Lynx_KeyR"}
lynx.Reg_Lynx_KeyStart = {1056778,8,8,1,0,"lynx.Reg_Lynx_KeyStart"}
lynx.Reg_Lynx_KeySelect = {1056778,9,9,1,0,"lynx.Reg_Lynx_KeySelect"}
lynx.Reg_Lynx_cputurbo = {1056780,0,0,1,0,"lynx.Reg_Lynx_cputurbo"} -- 1 = cpu free running, all other 16 mhz
lynx.Reg_Lynx_SramFlashEna = {1056781,0,0,1,0,"lynx.Reg_Lynx_SramFlashEna"} -- 1 = enabled, 0 = disable (disable for copy protection in some games)
lynx.Reg_Lynx_MemoryRemap = {1056782,0,0,1,0,"lynx.Reg_Lynx_MemoryRemap"} -- 1 = enabled, 0 = disable (enable for copy protection in some games)
lynx.Reg_Lynx_SaveState = {1056783,0,0,1,0,"lynx.Reg_Lynx_SaveState"}
lynx.Reg_Lynx_LoadState = {1056784,0,0,1,0,"lynx.Reg_Lynx_LoadState"}
lynx.Reg_Lynx_FrameBlend = {1056785,0,0,1,0,"lynx.Reg_Lynx_FrameBlend"} -- mix last and current frame
lynx.Reg_Lynx_Pixelshade = {1056786,2,0,1,0,"lynx.Reg_Lynx_Pixelshade"} -- pixel shade 1..4, 0 = off
lynx.Reg_Lynx_SaveStateAddr = {1056787,25,0,1,0,"lynx.Reg_Lynx_SaveStateAddr"} -- address to save/load savestate
lynx.Reg_Lynx_Rewind_on = {1056788,0,0,1,0,"lynx.Reg_Lynx_Rewind_on"}
lynx.Reg_Lynx_Rewind_active = {1056789,0,0,1,0,"lynx.Reg_Lynx_Rewind_active"}
lynx.Reg_Lynx_DEBUG_CPU_PC = {1056800,31,0,1,0,"lynx.Reg_Lynx_DEBUG_CPU_PC"}
lynx.Reg_Lynx_DEBUG_CPU_MIX = {1056801,31,0,1,0,"lynx.Reg_Lynx_DEBUG_CPU_MIX"}
lynx.Reg_Lynx_DEBUG_IRQ = {1056802,31,0,1,0,"lynx.Reg_Lynx_DEBUG_IRQ"}
lynx.Reg_Lynx_DEBUG_DMA = {1056803,31,0,1,0,"lynx.Reg_Lynx_DEBUG_DMA"}
lynx.Reg_Lynx_DEBUG_MEM = {1056804,31,0,1,0,"lynx.Reg_Lynx_DEBUG_MEM"}
lynx.Reg_Lynx_CHEAT_FLAGS = {1056810,31,0,1,0,"lynx.Reg_Lynx_CHEAT_FLAGS"}
lynx.Reg_Lynx_CHEAT_ADDRESS = {1056811,31,0,1,0,"lynx.Reg_Lynx_CHEAT_ADDRESS"}
lynx.Reg_Lynx_CHEAT_COMPARE = {1056812,31,0,1,0,"lynx.Reg_Lynx_CHEAT_COMPARE"}
lynx.Reg_Lynx_CHEAT_REPLACE = {1056813,31,0,1,0,"lynx.Reg_Lynx_CHEAT_REPLACE"}
lynx.Reg_Lynx_CHEAT_RESET = {1056814,0,0,1,0,"lynx.Reg_Lynx_CHEAT_RESET"}