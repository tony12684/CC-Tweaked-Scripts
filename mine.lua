--local r require "cc.require"

--turtle.getItemDetails(SLOT, true)
--returns WHEN SERIALIZED \/
--name="minecraft:iron_ingot",
--tags={["forge:ingots/iron"]=true,
--["forge:ingots"]=true,
--["appliedenergistics2:metal_ingots"]=true,
--["minecraft:beacon_payment_items"]=true,},
--count=25,
--maxCount=64
--displayName="Iron Ingot",}print
--if obj = turtle.getItemDetails(SLOT,true)
--then obj_tags = obj.tags pulls a table of the item tags

--turtle.inspect(detailed)
--returns bool AND THEN \/
--state,name,tags
--tags include A TON of byg: tags to determine block properties with other blocks



blacklist_blocks = {
    "minecraft:gravel",
    "minecraft:flint",
    "quark:root_item",
    "powah:dry_ice",
    "minecraft:cobweb",
    "quark:deepslate"
}

blacklist_tags = {
    "computercraft:turtle",
    "forge:stone",
    "forge:cobblestone",
    "minecraft:stone_crafting_materials",
    "minecraft:stone_bricks",
    "forge:dirt",
    "forge:marble",
    "minecraft:logs",
    "minecraft:planks",
    "forge:sand",
    "forge:sponge",
    "forge:clay",
    "forge:glass",
    "forge:sandstone",
    "forge:slabs",
    "minecraft:stairs",
    "forge:wool",
    "forge:mushrooms",
    "forge:fences",
    "minecraft:fence_gates",
    "forge:torches",
    "minecraft:walls",
    "minecraft:carpets",
    "minecraft:flowers",
    "forge:glass_panes",
    "minecraft:corals",
    "forge:plants",
    "minecraft:rails",
    "minecraft:doors",
    "forge:netherrack"
}

print("running v1.4")
print("refueling")
turtle.refuel()
print(turtle.getFuelLevel())
return_fuel = 400
continue = true
mine_depth = 124
mine_height = 1
mine_width = 200

--TODO: add sos when errors are thrown

function det_mine_forward()
    while turtle.detect() do
        turtle.dig()
    end
end

function det_mine_up()
    while turtle.detectUp() do
        turtle.digUp()
    end
end

--TODO: func that deletes the byg: tags before passing them to check_block()
--cannot add byg: to blacklist as a blanket. an item may have byg: tags but we might still want it
--also delete alexmobs: tags, and ftbjanitor: tags

function check_block(details)
    --TODO: add check for bedrock. call sos
    --check all items against blacklists
    --if they are in it return true else false
    --get tags from deets
    --print("checking a block")
    if details ~= nil then
        tags = details.tags
        --if air was not given then check to see if the items tags
        --are in blacklist_tags. do this for each tag the item has
        for a,b in pairs(tags) do
            for x,y in pairs(blacklist_tags) do
                if a == y then
                    return true
                end
            end
        end
        --check to see if block name is in blacklist_blocks
        --this is for special exception blocks with none or few tags
        for j,k in pairs(blacklist_blocks) do
            if details.name == k then
                return true
            elseif details.name == "minecraft:bedrock" then
                sos()
            end
        end
        --if we get this far it's not in the blacklist, hooray
        return false
    end
end


function resource_mine_check()
    --look at above, below, left, and right blocks
    --if they don't ret true from check_block then mine them
    --TODO: this shit is disgusting. clean this up
    details = {turtle.inspectUp()}
    if details[1] and not check_block(details[2]) then
        det_mine_up()
    end
    details = {turtle.inspectDown()}
    if details[1] and not check_block(details[2]) then
        turtle.digDown()
    end
    turtle.turnLeft()
    details = {turtle.inspect()}
    if details[1] and not check_block(details[2]) then
        det_mine_forward()
    end
    turtle.turnRight()
    turtle.turnRight()
    details = {turtle.inspect()}
    if details[1] and not check_block(details[2]) then
        det_mine_forward()
    end
    turtle.turnLeft()
end

function mine_tunnel(depth,height)
    for j=1,depth do
        --mine the block ahead and
        --then the block above if height 2
        --be sure to keep checking to dig all gravel and sand
        --only checks for height 1 and 2
        det_mine_forward()
        turtle.forward()
        if height == 2 then
            det_mine_up()
        end
        resource_mine_check()
        if turtle.getItemCount(15)>0 then
            clean_inv()
            if turtle.getItemCount(15)>0 then
                ender_dump_inv()
            end
        end
    end
end

function start_new_tunnel(side, distance, height)
    --side is a bool that represents if we are on the front or back side
    if side then
        turtle.turnLeft()
        mine_tunnel(distance,height)
        turtle.turnLeft()
        clean_inv()
    else 
        turtle.turnRight()
        mine_tunnel(distance,height)
        turtle.turnRight()
        clean_inv()
    end
end

function ender_check()
    turtle.select(16)
    details = turtle.getItemDetail(x, true)
    if details == nil or details.name ~= "enderstorage:ender_chest" then
        print("don't forget the ender chest!")
    end
    turtle.select(1)
end

function stripmine()
    --TODO: make stripmine called with params. current way has little abstraction
    --distance between tunnels is hard coded for now
    ender_check()
    --side is bool representing if we are on the front or back side
    side = true
    width_traveled = 0
    --dist between tunnels
    while turtle.getFuelLevel() > return_fuel and turtle.getItemCount(15) == 0 and continue do 
        mine_tunnel(mine_depth, mine_height)
        --if digging a new tunnel would exceed desired mine width
        --flip flop side on each loop
        tun_dist = 4
        side = not side 
        if width_traveled + 4 > mine_width and width_traveled + 2 < mine_width then
            --if we can continue our direction with a tunnel 2 blocks away but not 4
            --then start the new row in the same direction we are going
            --go down one layer and continue the tunnel direction pattern but not next time
            turtle.digDown()
            turtle.down()
            tun_dist = 2
            start_new_tunnel(side, tun_dist, mine_height)
            side = not side
            width_traveled = 0
        elseif width_traveled + 4 > mine_width then
            --if we don't have room to make a new tunnel before we hit the boundary
            --then make our next tunnel in our new row in the opposite direction we are going
            --go down one layer and repeat the last tunnel direction but not after
            turtle.digDown()
            turtle.down()
            tun_dist = 2
            start_new_tunnel(not side, tun_dist, mine_height)
            width_traveled = 2
            side = not side
        else
            start_new_tunnel(side, tun_dist, mine_height)
            width_traveled = width_traveled + tun_dist
        end
        --since we've traveled in width add to counter based
        fuel_up()
    end
    if continue then
        sos()
    else
        --requires modem on left
        rednet.open("left")
        location = find_me()
        rednet.broadcast("I'm stopped and ready at xyz "..location)
    end
end

function fuel_up()
    for x=1,15 do
        turtle.select(x)
        details = turtle.getItemDetail(x, true)
        if details ~= nil and details.name == "minecraft:coal" then
            while turtle.getFuelLevel() > (return_fuel*3) and turtle.refuel(x) do
                print("refueling")
            end
        end
    end
    turtle.select(1)
end

function find_me()
    --returns "x,y,z" location
    return table.concat({gps.locate()},",")
end

function stop_mine()
    continue = false
    print("stopping soon due to rednet request")
end

function reciever()
    --requires modem on left
    --do NOT call without running as coroutine through parallel
    rednet.open("left")
    while true do
        event = {os.pullEvent("rednet_message")}
        if event[3] == "Locate Jeff" then
            location = find_me()
            rednet.broadcast("Jeff is at x,y,z "..location)
        elseif event[3] == "Stop mining" then
            stop_mine()
            rednet.broadcast("Jeff will stop soon. Please wait a few minutes.")
        end
    end
end

function clean_inv()
    --for each item check if it's in blacklists
    --if it is drop it on the ground
    --TODO: find a way to destroy blocks outright to reduce entities
    for x=1,15 do
        turtle.select(x)
        details = turtle.getItemDetail(x, true)
        if check_block(details) then
            turtle.drop()
        end
    end
    turtle.select(1)
    --sort the inventory
    sort_inv()
end

function sort_inv()
    --compare back to front
    --move back items to front
    for x=15,1,-1 do
        turtle.select(x)
        for y=1,x-1 do
            x_count = turtle.getItemCount(x)
            y_count = turtle.getItemCount(y)
            --if x and y are same and their positions are not the same and x is not empty and y is not full
            if turtle.compareTo(y) and x ~= y and x_count>0 and y_count<64 then
                print(x.." goes to "..y)
                turtle.transferTo(y)
                break
            end
        end
    end
    --bring items all the way up
    left_just_inv()
end

function left_just_inv()
    --start in the bottom right
    --if top left is empty move item
    for x=15,1,-1 do
        turtle.select(x)
        for y=1,x-1 do
            x_count = turtle.getItemCount(x)
            y_count = turtle.getItemCount(y)
            if x_count>0 and y_count==0 then
                print(x.." goes to "..y)
                turtle.transferTo(y)
                break
            end
        end
    end
end

function ender_dump_inv()
    --mine a space, place the chest, drop the whole inv in it
    --works without having a block under or behind chest
    det_mine_forward()
    turtle.select(16)
    turtle.place()
    for x=1,16 do
        turtle.select(x)
        turtle.drop()
    end
    --dig goes to selected slot (16)
    turtle.dig()
    turtle.select(1)
end

function sos()
    --emergency SOS call
    while true do
        rednet.open("left")
        location = find_me()
        --TODO: add timestamp
        rednet.broadcast("SOS jeff is stuck at x,y,z "..location)
        print("I'm calling for help...")
        sleep(20)
    end
end

parallel.waitForAll(reciever,stripmine)