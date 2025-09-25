--sapSuck v1.0
homeBlock = 'polished_diorite'

function nonNegative(num)
    log("num is "..num)
    if num < 0 then
        return 0
    end
    return num
end

function safeSuck()
    if not turtle.inspect() then
        turtle.suck()
    end
end

function safeMove()
    obstructed, block = turtle.inspect()
    if not obstructed then
        --do nothing
    elseif block ~= nil and string.find(block.name, 'leaves') ~= nil then
        --if we are looking at leaves then wait for them to be gone before you move
        while obstructed do
            os.sleep(10)
            obstructed = turtle.inspect()
        end
    else
        --if we are blocked but not by leaves then turn and get ready for the next line
        -- it should be fine that this movement isn't safeMove
        turtle.back()
        turtle.turnRight()
    end

    turtle.forward()
end

function depositSaps()
    for i = 1, 16 , 1 do
        local item = turtle.getItemDetail(i, true)
        if item ~= nil then
            turtle.select(i)
            turtle.drop()
            do return end
        end
    end
end

function collectFuel()
    chest = peripheral.wrap('front')
    for i=1, chest.size(), 1 do
        item = chest.getItemDetail(i)
        if item ~= nil and string.find(item.name, 'coal') ~= nil then
            chest.pullItems('front', i, 64, 1)
            turtle.suck()
            do return end
        end
    end
end

function refuelSelf()
    for i = 1, 16 , 1 do
        local item = turtle.getItemDetail(i, true)
        if item ~= nil and string.find(item.name, "coal") ~= nil then
            turtle.select(i)
            turtle.refuel(64)
            do return end
        end
    end
end

function main(args)
    while true do
        turtle.turnLeft()
        safeSuck()
        turtle.turnRight()
        safeSuck()
        turtle.turnRight()
        safeSuck()
        _, block = turtle.inspectDown()
        if block.name ~= nil and string.find(block.name, homeBlock) ~= nil then
            --if we are at homeBlock AND
            _, block = turtle.inspect()
            if block.name ~= nil and string.find(block.name, 'chest') ~= nil then
                --if we are looking at a chest then we can exchange
                if turtle.getFuelLevel()<500 then
                    --take some charcoal and refuel
                    collectFuel()
                    refuelSelf()
                end
                depositSaps()
                os.sleep(120)
                --if we did a run of saps sleep
            end
        end
        turtle.turnLeft()
        safeMove()
    end
end

main()
