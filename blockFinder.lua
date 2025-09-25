--v1.0
--this is a separate program for scanning with the geoScanner
--  that's because bad things seem to happen when you scan with a geo scanner
--    then try to connect to rednet after in the same program

--logging inits
local filename = os.date()
local templog = fs.open("logs/" .. filename, "a")
templog.write("log start\n")
templog.write("running program blockFinder\n")

--clearscreen and ready typing at topleft

function log(msg)
    --takes str and saves it to log as new line
    templog.write("\n"..msg)
end

function crash(err)
    --takes str, passes it to logger and closes program
    log(err)
    templog.close()
    shell.exit()
end

function scrub(blockName)
    log('scrubbing arg')
    --makes uppercase letters lower case and spaces underscores
    --same way minecraft seems to set block names on the back end
    if blockName ~= nil then
        blockName = string.lower(blockName)
        blockName = string.gsub(blockName, ' ', '_')
    end
    return blockName
end

function checkGeo()
    log('checking geo wrap')
    --crash if we don't have a geoScanner peripheral wrapped
    if peripheral.getType(geo) ~= 'geoScanner' then
        crash('geo scanner not equiped at required time')
    end
end

function update(str)
    --takes string
    --updates the display for prints
    --usefull to render things in the way i want
    str = str or ''
    term.clear()
    term.setCursorPos(1,1)
    print('Please remain still during scanning...')
    print('Please do not switch tabs')
    print(str)
end

--textutils.slowPrint(textutils.serialize(valuables))

function equip(item)
    --requires exact peripheral type
    --use peripheral.getType(thing) to learn
    for i=1, 3, 1 do
        if peripheral.getType('back') == item then
            do return end
        end
        pocket.equipBack()
    end
    print('make sure you have a modem and geo scanner ready')
    crash(item..' not found in 3 tries')
end

function whitelist(block)
    --only return true if we are trying to find the suplied block
    if block == nil then
        --if nil bad shit has happened
        crash('nil block... wtf')
    elseif searchTargetName ~= nil and string.find(block.name, scrubbedSearchTargetName) ~= nil then
        --if arg was supplied and the block name contains our search term
        return true
    elseif searchTargetName == nil and string.find(block.name, 'ore') ~= nil then
        --only succeeds if no args supplied and block name contains 'ore'
        return true
    elseif searchTargetName == nil and string.find(block.name, 'debris') ~= nil then
        --only succeeds if no args supplied and block name contains 'debris'
        return true
    else
        return false
    end
end

function search(scan)
    log('searching')
    --takes table
    --elements contain .name, .tags, .x, .y, .z
    local valuables = {}
    --loop for the length of the scan table
    for i=1, #scan, 1 do
        --if scan element i is in the whitelist
        if whitelist(scan[i]) then
            --#valuables+1 = make last item in table
            valuables[#valuables+1] = scan[i]
        end
    end
    log(#valuables..' valueables found')
    return valuables
end

function proximity(ores)
    log('finding closest ore')
    --takes table of ores after parsed by search()
    local closestDist = 3000
    local closestOre = nil
    for i=1, #ores, 1 do
        local x, y, z = ores[i].x, ores[i].y, ores[i].z
        local dist = math.abs(x) + math.abs(y) + math.abs(z)
        if dist < closestDist then
            closestOre = ores[i]
            closestDist = dist
        end
    end
    if closestOre ~= nil then
        --if closestOre not nil
        update('Closest target is '..closestOre.name)
    else
        update('No target found in range')
    end
    return closestOre
end

function saveOres(ore)
    --just saves relative ore direction and name for now
    if ore == nil then
        ore['x'] = 9999
        ore['y'] = 9999
        ore['z'] = 9999
        ore['name'] = 'error: item not found'
    local file = fs.open('ore', 'w')
    file.write(ore.x)
    file.write('\n'..ore.y)
    file.write('\n'..ore.z)
    file.write('\n'..ore.name)
    file.close()
end

function main()
    --ensure we have the scanner on
    --equip geoScanner
    equip('geoScanner')
    --wrap it every time just in case the reference table changes
    local geo = peripheral.wrap('back')
    --return only valuable items scanned
    local ores = search(geo.scan(16))
    local closest = proximity(ores)
    saveOres(closest)
    --TODO detect player look direction to update graphics
    --save old finds

end

--get args, needs to be down here due to function declaration
local args = {...}
--if argument suplied will search for the closest block containing argument
--scrub call formats supplied string to match minecraft naming convention
--uses two lines so we can just keep the supplied string to present to players
--if these are not global we have to pass them all the way down through like 4 functions
searchTargetName = args[1] or nil
scrubbedSearchTargetName = scrub(searchTargetName)

main()