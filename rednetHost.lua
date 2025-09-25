--v1.0
local modem = peripheral.find("modem", rednet.open)
local speaker = peripheral.find("speaker")
print('waiting for messages')
while true do
    local sender, message = rednet.receive()
    speaker.playSound("entity.generic.explode", 3, 0.5)
    print(message)
end