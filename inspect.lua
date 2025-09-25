--v1.0
local not_air, block = turtle.inspect()
print(notAir)
textutils.slowPrint(textutils.serialize(block))
local item = turtle.getItemDetail(1)
textutils.slowPrint(textutils.serialize(item))