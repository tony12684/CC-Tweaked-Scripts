--v1.0
--TODO switch to player peripheral oriented gps finding, maybe
--TODO add support for augmented reality
--TODO add help command functionality for usage explanation
--TODO rename variables to something not shit
--TODO reduce use of global variables, maybe

local args = {...}

local location = {}
local destination = {}

local filename = os.date()
local templog = fs.open("logs/" .. filename, "a")
templog.write("log start\n")
templog.write('running program find\n')

term.clear()
term.setCursorPos(1, 1)

function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function log(msg)
    --takes str and saves it to log as new line
    templog.write("\n"..msg)
end

function crash(err)
    --takes str, passes it to logger and closes program
    log(err)
    templog.close()
    print('Fatal error:')
    print(err)
    print('shutting down in 5 seconds')
    os.sleep(5)
    shell.exit()
end

function equip(item)
    log('equipping '..item)
    --requires exact peripheral type
    --use peripheral.getType(thing) to learn
    for i=1, 3, 1 do
        if peripheral.getType('back') == item then
            do return end
        else
            pocket.equipBack()
        end
    end
    crash(item..' not found in 3 tries')
end

function compare(player, block)
    --takes two tables with x y and z location properties
    --loc of target block = loc of player + distance to target blockround
    local target = {}
    target['x'] = player.x + block.x
    target['y'] = player.y + block.y
    target['z'] = player.z + block.z
    target['name'] = block.name
    return target
end

function vectorSub(player, target)
    --function takes absolute player and target coords and returns relative target coords
    --IDK why we had to do this but i guess it's a good idea
    local next = next
    local block = {}
    if next(player) == nil then
        player['x'] = 1000
        player['y'] = 1000
        player['z'] = 1000
        target['name'] = 'gps: error'
    end
    --CANNOT DO LOGGING, WILL FILL UP PC STORAGE FAST
    --subtract the target cords from player to get relative block coords back
    block['x'] = player.x - target.x
    block['y'] = player.y - target.y
    block['z'] = player.z - target.z
    block['name'] = target.name
    return block
end

function direct(ore)
    --CANNOT DO LOGGING, WILL FILL UP PC STORAGE FAST
    if ore == nil then
        print('no ore found')
        do return end
    end
    --takes single block with name, tags, x, y, and z elements
    --uses relative location not absolute location
    --directs players towards ore
    --(-z) = north, (+x) = east, (-y) = up
    print('hold ctrl+t to close')
    print('hold backspace to rescan')
    print(ore.name..' is')
    local x, y, z = ore.x, ore.y, ore.z
    --rounds the printed values to 2 dcm
    x = round(x, 1)
    y = round(y, 1)
    z = round(z, 1)
    if z <= 0 then
        print(math.abs(z)..' blocks North,')
    else
        print(z..' blocks South,')
    end

    if x >= 0 then
        print(x..' blocks East,')
    else
        print(math.abs(x)..' blocks West,')
    end

    if y <= 0 then
        print('and '..math.abs(y)..' blocks Up')
    else
        print('and '..y..' blocks Down')
    end

    print('at')
    print('x = '..destination.x)
    print('y = '..destination.y)
    print('z = '..destination.z)
end

function getLocation()
    --a helper to update our location with the gps
    --the first gps call is just a check to make sure that our modem is setup correctly
    --attempt to update our gps location 3 times, if that fails, then crash
    equip('modem')
    for x=1, 3, 1 do
        if pcall(gps.locate) then    
            repeat
                location['x'], location['y'], location['z'] = gps.locate()
            until location.x ~= nil
            do return end
        else
            pocket.unequipBack()
            equip('modem')
        end
    end
    crash('failed to get gps location in 3 tries')
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
    if closestOre == nil then
        --if no target found then just update it with some garbage to display
        update('No target found in range')
        closestOre = {}
        closestOre['x'] = 9999
        closestOre['y'] = 9999
        closestOre['z'] = 9999
        closestOre['name'] = 'error: target not found'
    else
        --if closestOre not nil
        update('Closest target is '..closestOre.name)
    end
    return closestOre
end

function runScan()
    log('runScan called')
    --get the currently equipped attachment to put back on after the scan
    term.clear()
    term.setCursorPos(1,1)
    print('scanning...')
    --equip geoScanner
    equip('geoScanner')
    --wrap it 
    local geo = peripheral.wrap('back')
    --find only valuable block
    local ores = search(geo.scan(16))
    --report back the clostest valuable block
    local closest = proximity(ores)
    log('closest is:')
    log(textutils.serialize(closest))

    print('scan complete')

    return closest
end

function waitOnUserInput()
    --only to be run on parallel, otherwise will stall computation
    --  i think
    while true do
        local event, key, isHeld = os.pullEvent('key')
        if key == keys.backspace and isHeld then
            initialize()
        end
        --sleep call needed to yield
        os.sleep(0)
    end
end

function drawScreen()
    log('beginning drawScreen')
    while true do
        --use vector subtraction to get the distance form of the target block back
        --we need to do this so that we can use the gps to search for the block instead of the scanner
        getLocation()
        local distance = vectorSub(location, destination)
        term.clear()
        term.setCursorPos(1, 1)
        direct(distance)
        --this is just to not overtax the GPS
        --also keeps the code running light from flashing i think
        os.sleep(0.05)
    end
end

function initialize()
    log('initializing')
    print('scanning...')
    --scan and parse scan
    local closest = runScan()
    --all this shit can be replaced with getLocation()
    getLocation()
    --compare the rounded off location to the closest value
    --round off the decimal here or the program will think the target block is at x 19.87 instead of 19
    --gps returns computer height not player height
    location.x = round(location.x, 0)
    location.y = round(location.y, 0)
    location.z = round(location.z, 0)
    --exchange our relative coords of closest to absolute coords
    destination = compare(location, closest)
end

function main()
    log('main called')
    equip('modem')
    initialize()
    parallel.waitForAll(drawScreen, waitOnUserInput)
    coroutine.resume(waitOnUserInput)
end

searchTargetName = args[1] or nil
scrubbedSearchTargetName = scrub(searchTargetName)

main()