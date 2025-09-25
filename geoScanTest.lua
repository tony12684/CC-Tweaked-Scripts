--v1.0
local geo = peripheral.wrap('right')
local scan = geo.chunkAnalyze()
local filename = os.date()
local templog = fs.open("logs/" .. filename, "a")
templog.write("log start")
for value in pairs(scan) do
    templog.write("\n"..value..": "..scan[value])
end

for i=1,#scan,1 do
    local block = scan[i]
    print(block)
    templog.write("\n"..block.name.. " at " .. block.x ..", ".. block.y ..", ".. block.z)
end