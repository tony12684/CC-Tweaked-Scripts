--v1.0
--create place block function that utilizes findblock, just call it every single time we place a block
local filename = os.date()
local templog = fs.open("logs/" .. filename, "a")
templog.write("log start")

function crash(err)
    templog.write(err)
    templog.close()
    print('crashing:'..err)
    shell.exit()
end

function log(msg)
    templog.write("\n"..msg)
end

function findBlock()
    log("searching for building block")
    --search for any block in inventory and select it
    for i=1,16,1 do
        local item = turtle.getItemDetail(i)
        if item ~= nil and not string.find(item.name, "ancient") ~= nil then
            log("found block")
            turtle.select(i)
            do return end
        end
    end
    crash("no blocks found")
end

function placeBlock(dir)
    os.sleep(0.2)
    findBlock()
    if dir == "u" and turtle.inspectUp() then
        log("placing a block up")
        turtle.placeUp()
    elseif dir == "d" then
        log("placing a block down")
        turtle.placeDown()
    elseif turtle.inspect() then
        log("placing a block forward")
        turtle.place()
    end
end

function digLayer(dir)
    log("digging "..dir.." half")
    --place blocks in every direction except back
    --if dir up also don't place down
    turtle.dig()
    placeBlock()
    turtle.turnLeft()
    turtle.dig()
    placeBlock()
    turtle.turnRight()
    turtle.turnRight()
    turtle.dig()
    placeBlock()
    turtle.turnLeft()
    turtle.digUp()
    placeBlock("u")
    if dir == 'd' then
        turtle.digDown()
        placeBlock("d")
    end
end

function main()
    log("main called")
    while true do
        log("loop start")
        digLayer('d')
        turtle.digUp()
        turtle.up()
        digLayer('u')
        turtle.down()
        turtle.dig()
        turtle.forward()
    end
end

main()