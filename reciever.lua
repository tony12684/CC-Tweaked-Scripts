print("running v1.1")
rednet.open("left")
print("network is opened")
print("waiting for broadcasts")
speaker = peripheral.find("speaker")
while true do
    event = {os.pullEvent()}
	--debug print
	--print(textutils.serialized(event, {compact = true})
    if event[1] == "rednet_message" then
        msg = event[3]
        print(msg)
        speaker.playNote("bell")
        turtle.up()
        turtle.down()
        turtle.up()
        turtle.down()
		print("waiting for more messages")
        --to run messeges as code
        --func = loadstring(msg)
        --result = {pcall(func)}
    end
end