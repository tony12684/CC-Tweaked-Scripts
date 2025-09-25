--v1.1
local big = false
local sapling = "birch_sapling"

--TODO add args handling for cleaner implimentation
-- resolve sequence breaking bug that keeps breaking the wood chest

local notAir, block
local filename = os.date()
local templog = fs.open("logs/" .. filename, "a")
templog.write("log start")
turtle.select(1)
--DOES NOT DEAL WITH BRANCHES
--WE DON'T WANT THAT SHIT ANYWHERE NEAR HERE
--just use create for that shit

--expects looking at left side of big trees
--DEAL WITH STICKS?
--BETTER SAPLINGS
--BONE MEAL?

function log(msg)
    --takes msg string writes it in new line
    templog.write("\n"..msg)
end

function crash(msg)
    log("crashing")
    log(msg)
    templog.close()
    shell.exit()
end

function waitForGrowth()
    notAir, block = turtle.inspect()
    while notAir and string.find(block.name, "sapling") do
        log("waiting for tree growth")
        print("waiting for tree growth")
        os.sleep(10)
        notAir, block = turtle.inspect()
    end
    log("sapling gone")
end

function fell(dir)
    notAir, block = turtle.inspect()
    if dir == 'down' and not big then
        -- if we are felling down for a small tree then just go all the way down
        --  we already cut down all the wood
        while turtle.down do
            -- if we get to this point we already moved down so just log it
            log('went down')
        end
        --if we get here we went all the way down so break out of fell()
        do return end
    end

    while notAir and string.find(block.name, "log") do
        --loop breaks when observing air or a block that is not a log
        log("digging "..block.name)
        turtle.dig()
        if dir == "up" then
            log("going up")
            turtle.digUp()
            turtle.up()
        elseif dir == "down" then
            log("going down")
            turtle.down()
        else
            crash("bad dir in fell()")
        end
        notAir, block = turtle.inspect()
    end
    log("digging")
    if dir == "up" then
        log("going down")
        turtle.down()
    end
end

function cutLayer()
    log("cutting a layer")
    turtle.dig()
    turtle.turnRight()
    turtle.dig()
    turtle.forward()
    turtle.turnLeft()
    turtle.dig()
    turtle.turnLeft()
    turtle.forward()
    turtle.turnRight()
end

function shaveTop()
    log("a little off the top")
    turtle.up()
    turtle.digUp()
    turtle.up()
    turtle.digUp()
    turtle.up()
    cutLayer()
    turtle.down()
    cutLayer()
    turtle.down()
    cutLayer()
    turtle.down()
    cutLayer()
    turtle.down()
end

function findSapling()
    log("searching for saps")
    for i=1,16,1 do
        local item = turtle.getItemDetail(i, true)
        if item ~= nil and string.find(item.name, sapling) ~= nil then
            log("found sap at pos "..i)
            log("we have "..item.count.."saps")
            turtle.select(i)
            if big and item.count >= 4 then
                do return end
            elseif not big and item.count >= 1 then
                do return end
            else
                crash("not enough saps")
            end
        end
    end
    crash("no saps in inventory")
end

function plantSapling(big)
    --takes boolean of if tree is 2x2 or not
    findSapling()
    if big then
        log("planting big tree")
        --redundant but robust
        turtle.forward()
        turtle.forward()
        turtle.turnRight()
        turtle.place()
        turtle.turnLeft()
        turtle.back()
        turtle.place()
        turtle.turnRight()
        turtle.place()
        turtle.turnLeft()
        turtle.back()
    else
        log("planting small tree")
    end
    findSapling()
    turtle.place()
end

function chopTree(big)
    --takes boolean of if tree is 2x2 or not
    fell("up")
    if big then
        log("chopping big tree")
        turtle.forward()
        shaveTop()
        fell("down")
        turtle.turnRight()
        fell("up")
        turtle.forward()
        turtle.turnLeft()
        fell("down")
        turtle.turnLeft()
        turtle.forward()
        turtle.turnRight()
        turtle.back()
    else
        log("chopping small tree")
        fell("down")
    end
end

function makeCharcoal()
    log("making charcoal")
    for i = 1, 16 , 1 do
        local item = turtle.getItemDetail(i, true)
        if item ~= nil and string.find(item.name, "log") ~= nil then
            log("dropping "..item.count.." "..item.name)
            turtle.select(i)
            turtle.dropDown()
            do return end
        end
    end
    crash("no logs found")
end

function takeCharcoal()
    log("taking cooked charcoal")
    turtle.forward()
    turtle.down()
    turtle.down()
    turtle.back()
    turtle.suckUp()
end

function nonNegative(num)
    log("num is "..num)
    if num < 0 then
        return 0
    end
    return num
end

function refuelSelf()
    log("refueling myself")
    log("fuel is "..turtle.getFuelLevel())
    for i = 1, 16 , 1 do
        local item = turtle.getItemDetail(i, true)
        if item ~= nil and string.find(item.name, "charcoal") ~= nil then
            turtle.select(i)
            turtle.refuel(nonNegative(1000-turtle.getFuelLevel())/60)
            log("I've fueled up")
            do return end
        end
    end
end

function depositCharcoal()
    log("depositing extra charcoal")
    for i = 1, 16 , 1 do
        local item = turtle.getItemDetail(i, true)
        if item ~= nil and string.find(item.name, "charcoal") ~= nil then
            turtle.select(i)
            turtle.drop()
            log(item.count.." charcoal deposited")
        end
    end
end

function depositWood()
    log("depositing extra extra wood")
    for i = 1, 16 , 1 do
        local item = turtle.getItemDetail(i, true)
        if item ~= nil and string.find(item.name, sapling) ~= nil then
            --do nothing
            log("keeping "..item.count.." saplings")
        elseif item ~= nil then
            log("dropping "..item.count.." of "..item.name)
            turtle.select(i)
            turtle.drop()
        end
    end
end

function main()
    log("main called")
    while true do
        waitForGrowth()
        chopTree(big)
        plantSapling(big)
        turtle.turnLeft()
        turtle.up()
        turtle.forward()
        makeCharcoal()
        takeCharcoal()
        turtle.back()
        turtle.up()
        refuelSelf()
        depositCharcoal()
        turtle.turnLeft()
        depositCharcoal()
        turtle.turnLeft()
        depositWood()
        turtle.turnLeft()
    end
end

main()
