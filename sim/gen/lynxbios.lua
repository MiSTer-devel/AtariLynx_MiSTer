local filecontent = {}
local input = io.open("lynxboot.img", "rb")

for i = 1, 512 do
   filecontent[i] = 0
end

local i = 0;
while true do
   local byte = input:read(1)
   if not byte then 
      break 
   end
   i = i + 1
   filecontent[i] = string.byte(byte)
end
input:close()

print(filecontent[1])
print(filecontent[2])

local outfile=io.open("lynxboot.vhd","w")
io.output(outfile)

io.write("library IEEE;\n")
io.write("use IEEE.std_logic_1164.all;\n") 
io.write("use IEEE.numeric_std.all;\n")
io.write("\n")
io.write("entity lynxboot is\n")
io.write("   port\n")
io.write("   (\n")
io.write("      clk     : in std_logic;\n")
io.write("      address : in std_logic_vector(8 downto 0);\n")
io.write("      data    : out std_logic_vector(7 downto 0)\n")
io.write("   );\n")
io.write("end entity;\n")
io.write("\n")
io.write("architecture arch of lynxboot is\n")
io.write("\n")
io.write("   type t_rom is array(0 to 511) of std_logic_vector(7 downto 0);\n")
io.write("   signal rom : t_rom := ( \n")

for i = 1, 512 do
   io.write("      x\"")
   io.write(string.format("%02X", filecontent[i]))
   io.write("\"")
   if (i < 512) then
      io.write(",")
   end
   io.write("\n")
end

io.write("   );\n")
io.write("\n")
io.write("begin\n")
io.write("\n")
io.write("   process (clk) \n")
io.write("   begin\n")
io.write("      if rising_edge(clk) then\n")
io.write("         data <= rom(to_integer(unsigned(address)));\n")
io.write("      end if;\n")
io.write("   end process;\n")
io.write("\n")
io.write("end architecture;\n")

io.close(outfile)





