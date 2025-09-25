--v1.0
--INITS
local length = 48
local width = 48
local tunnelDistance = 5
local direction = "right"
local filename = os.date()
local templog = fs.open("logs/" .. filename, "a")
templog.write("log start\n")

--TODO
-- FIX water causes mining hangup
-- do not go to next tunnel start if it's too far
-- constant log updating to read on VSC
-- logging of what block is mined
-- add optional height parameter
-- mine if name contains ore
-- ascend / lower to next tunnel level
-- expand to allow vert mining

function crashLog(err)
    templog.write(err)
    templog.close()
    shell.exit()
end

function checkNil(x)
    --turns nil to ""
    if x == nil then
        return ""
    else
        return x
    end
end

function checkAll(d)
    --TODO make this shit good and not shit
    templog.write("check "..d.."\n")
    local notAir, block
    if d == "Up" then
        notAir, block = turtle.inspectUp()
    elseif d == "Down" then
        notAir, block = turtle.inspectDown()
    elseif d == "" then
        notAir, block = turtle.inspect()
    else
        crashLog("Bad direction in checkAll()\n")
    end
    if notAir and string.find(checkNil(block.name), "ore") ~= nil then
        if d == "Up" then
            turtle.digUp()
        elseif d == "Down" then
            turtle.digDown()
        elseif d == "" then
            turtle.dig()
        else
            crashLog("Bad direction in checkAll()\n")
        end
        templog.write("dig "..d.."\n")
    end
end

function safeDig()
    -- block name contains water or lava just go through it dummy
    local notAir, block = turtle.inspect()
    while notAir do
        if string.find(checkNil(block.name), "water") ~= nil or string.find(checkNil(block.name), "lava")  then
            do return end
        end
        turtle.dig()
        notAir, block = turtle.inspect()
    end
end

function spinCheck()
    templog.write("spin check\n")
    checkAll("Up")
    checkAll("Down")
    turtle.turnLeft()
    checkAll("")
    turtle.turnRight()
    turtle.turnRight()
    checkAll("")
    turtle.turnLeft()
end

function tunnel(l)
    templog.write("tunnel length "..l.."\n")
    for n=1, l, 1 do
        spinCheck()
        safeDig()
        templog.write("dig forward\n")
        turtle.forward()
        templog.write("go forward\n")
        templog.write(turtle.getFuelLevel().." fuel remaining\n")
        templog.write(l-n .." blocks remaining in tunnel\n")
    end
    --refuel if low
    local fuel = turtle.getFuelLevel()
    if fuel < 1000 then
        templog.write("refueling\n")
        shell.run("refuel 50")
    end
end

function turnDirection(d, reflect)
    --if nil gives false
    reflect = reflect or false
    templog.write("turn direction "..d.."\n")
    templog.write("reflect is "..tostring(reflect).."\n")
    if d == "left" and not reflect then
        turtle.turnLeft()
    elseif d == "right" and not reflect then
        turtle.turnRight()
    elseif d == "left" and reflect then
        turtle.turnRight()
    elseif d == "right" and reflect then
        turtle.turnLeft()
    else
        print("Error: Invalid Direction Provided to turnDirection()")
        crashLog("turnDirection failed")
    end
end

function turnBack(l, d)
    templog.write("turn back\n")
    turnDirection(d)
    --HARDCODED
    tunnel(tunnelDistance)
    turnDirection(d)
    tunnel(l)
end

--place chest to left or right side of turtle start
function deposit(d)
    templog.write("deposit\n")
    turnDirection(d)
    local distance = 0
    while true do
        local _, block = turtle.inspect()
        local tags = block.tags
        if tags ~= nil then
            for value in pairs(tags) do
                if value == "forge:chests" then
                    templog.write("chest found\n")
                    dropAll()
                    print("I made it home!")
                    distance = distance + tunnelDistance
                    return distance
                end
            end
        end
        safeDig()
        templog.write("dig forward\n")
        turtle.forward()
        templog.write("go forward\n")
        distance = distance + 1
    end
    templog.write("chest not found\n")
end

function dropAll()
    templog.write("drop all\n")
    for i=1, 16, 1 do
        turtle.select(i)
        turtle.drop()
    end
end
--while width is not reached do the thing
function main(l, d)
    templog.write("main called\n")
    local backDistance = 0
    while backDistance < width do
        tunnel(l)
        turnBack(l, d)
        backDistance = deposit(d)
        templog.write("backDistance is "..backDistance.."\n")
        turtle.turnLeft()
        turtle.turnLeft()
        if backDistance > width then
            turnDirection(d, true)
            do return end
        end
        for i=1, backDistance, 1 do
            safeDig()
            turtle.forward()
            templog.write("go forward\n")
            templog.write(backDistance-i .." blocks remaining in return trip\n")
        end
        turnDirection(d, true)
    end
end

print("Mining!")
main(length, direction)
print("All Done!\n")
templog.write("log closed\n")
templog.close()
