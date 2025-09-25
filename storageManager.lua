--v0.8

--for auto complete > textutils.slowPrint(textutils.serialize())
--[[function round(num, numDecimalPlaces)
    --turns out this rounds up and down
    --not currently needed in the program
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end--]]

function setColorPallete()
    --color1 = background default
    --color2 = background alternate
    --color3 = text color
    --color4 = header background
    --color5 = scroll bar color
    term.setBackgroundColor(color1)
    term.setTextColor(color3)
    term.clear()
end

function retrievePeripherals(kind)
    --takes a kind of peripheral you are searching for
    --returns the names of all peripherals containing that type
    --check all the peripherals available
    local allPeripherals = peripheral.getNames()
    local names = {}
    for key, value in pairs(allPeripherals) do
        if string.find(value, kind) ~= nil then
            --store all found peripherals of the desired type as a table and return it
            --TODO TAKE CARE weird glitch where getNames can return the same name more than once
            names[#names+1] = value
        end
    end
    return names
end

function emptyUserChest(user, chests)
    --takes a string exactly matching a user chest, supply 'all' to empty them all
    --  and takes a list of the names of all the chests
    for key, value in pairs(userChests) do
        for x = 1, #chests, 1 do
            if chests[x] == value then
                --setting element to nil might do weird things to #chests
                chests[x] = nil
                dumpChest(value, chests)

            end
        end
    end
end

function dumpChest(chest, dumpLocations)
    --takes the name of a specific chest to empty
    --  and a list of names of acceptable chests to empty to
    
end

function buildItemList(names)
    --takes a list of attached chest names to look through
    local items = {}
    --TODO streamline this process
    --we should be able to build a table that can be sorted right off the bat
    --there should be no reason we have to build a table of all our items then rebuild that table identically without keyed references
    --structure \/
    --[[items{
        minecraft:cobblestone = {--one table for each specific TYPE of item
            totalCount = num,
            locations = {
                1 = {--one table for each specific instance of an item stack
                    chest = 'minecraft:chest_4' --peripheral name of containing chest
                    index = '11' --which slot it's in in that chest
                    count = num  --the num of items in that exact slot
                }
                ... --continues for all stack instances
            }
            displayName = "Cobblestone",
            itemGroups = {
                {--one table for each group
                    displayName = "Building Blocks",
                    id = "buildingBlocks"
                }
            },
            maxCount = 64,
            name = 'minecraft:cobblestone',
            tags = {
                ['forge:cobblestone'], = true
                ... --continues for all tags
            }
        }
        ... --continues for each type of item
    } --]]
    for x=1, #names, 1 do
        local chest = peripheral.wrap(names[x])
        --retieve list of all items in current chest
        local chestItems = chest.list()
        for key, value in pairs(chestItems) do
            --key is the slot index of an item
            local chestItemDetails = chest.getItemDetail(key)
            --this just makes it a little easier to write
            local chestItemName = chestItemDetails.name
            local chestItemLocation = {}
            chestItemLocation['chest'] = names[x] --the name of the chest we are looking in right now
            chestItemLocation['index'] = key --the slot the item is in in that chest
            chestItemLocation['count'] = chestItemDetails.count --the num of items in that slot
            if items[chestItemName] == nil then
                --if we do not have an entry of our specific item yet then make one
                --our item entry is just a list of item details
                --   with the index being the back end name of the item
                --the item details are appended with a locations table
                --   containing the index of each item stack
                chestItemDetails['locations'] = {}
                --set total count to count of current stack
                chestItemDetails['totalCount'] = chestItemDetails.count
                --then delete the count, this is just to rename the index to reduce confusion
                chestItemDetails['count'] = nil
                --set the first location to be the only one we have so far
                chestItemDetails.locations[1] = chestItemLocation
                --then update the entry with everything we've done
                items[chestItemName] = chestItemDetails
            else
                --if we do already have an entry then add our new item location to it
                local existingItemLocations = items[chestItemName].locations
                existingItemLocations[#existingItemLocations+1] = chestItemLocation
                --and the count of this stack to the running total
                items[chestItemName].totalCount = items[chestItemName].totalCount + chestItemDetails.count
            end
        end
    end
    return items
end

function buildSortedItems(items, method)
    --builds a list with various properties we can sort by
    --returns alphabetically sorted by default
    local sortedItems = {}
    
    for n in pairs(items) do
        local t = {}
        --inserts the entire entry minus the key
        t = items[n]
        --the mod containing the item is the beginning part of the item name
        --take the beginning of the item name until just before the index of the ':'
        t['mod'] = string.sub(n, 1, string.find(n, ':') - 1)
        table.insert(sortedItems, t)
    end
    sortedItems = sortItems(sortedItems, method)
    return sortedItems
end

function sortItems(sortedItems, method)
    --sorts our sort list by the provided method
    --defaults to count
    --TODO add multi layer sorting. EX: count first then alphabetically for tied counts 
    --TODO deal with unique NBT data items
    --   EX enchanted items will currently be grouped, fix that
    method = method or 'count'
    if method == 'alphabetical' then
        table.sort(sortedItems, function (k1, k2) return k1.displayName < k2.displayName end)
    elseif method == 'count' then
        table.sort(sortedItems, function (k1, k2) return k1.totalCount > k2.totalCount end)
    elseif method == 'mod' then
        table.sort(sortedItems, function (k1, k2) return k1.mod < k2.mod end)
    end
    return sortedItems
end

function updateDisplay(sortedItems, lowerIndex, upperIndex, displayStartHeight)
    --needs to be rubust, update every pixel every time to account for scrolling
    --takes our sorted list of all our items,
    --  the first index of the first item we want to display,
    --  the index of the last item we want to display,
    --  and the height at which to begin displaying downwards from
    --computer terminals are working with 51 by 19 resolution
    --pocket terminals are working with a 26 by 20 resolution
    --for now reserve two pixels vertically for search bar and buttons
    --expect one less than the termWidth of display room
    --  one pixel reserved for scroll bar
    --TODO make more dynamic, currently only works with lowerIndex = 1
    --  if you go higher it will not display at the start height
    local termWidth, termHeight = term.getSize()
    --if these values are unspecified each item on the page will be updated
    lowerIndex = lowerIndex or 1
    upperIndex = upperIndex or termHeight - headerHeight
    displayStartHeight = displayStartHeight or headerHeight + 1

    term.setBackgroundColor(color1)
    term.clear()
    local maxPageNum = #sortedItems / (termHeight - headerHeight)

    --cut off the decimal point
    maxPageNum = math.floor(maxPageNum)
    --TODO FIX THIS, does not do terminating rounding, does rounding up or
    if pageNum < 0 then
        --prevents scrolling above item list
        pageNum = 0
    elseif pageNum > maxPageNum then
        --prevents scrolling below item list
        pageNum = maxPageNum
    end

    --if we are on the second page and our available vertical pixels = 17,
    --  then y is = 17, this makes it so that when we are retieving the items,
    --  for the second page we begin indexing them where the last page left off
    local y = pageNum * (termHeight-headerHeight)
    for x = lowerIndex, upperIndex, 1 do
        --minus 1 since lowerIndex starts at one
        if sortedItems[x+y] ~= nil then
            --useful to call this early for the clearLine call
            term.setCursorPos(1, displayStartHeight + x - 1)
            local count = tostring(sortedItems[x+y].totalCount)
            if x%2 == 0 then
                term.setBackgroundColor(color2)
                term.clearLine()
            end
            --write the item display name
            term.write(sortedItems[x+y].displayName)
            --write the item count
            term.setCursorPos(termWidth-string.len(count), displayStartHeight + x - 1)
            term.write(count)
            term.setBackgroundColor(color1)
        end
    end

    updateHeader(termHeight, termWidth)
    updateScrollBar(termHeight, termWidth)
    term.setCursorPos(1,1)
end

function updateHeader(termHeight, termWidth)
    term.setBackgroundColor(color4)
    for x = 1, headerHeight, 1 do
        term.setCursorPos(1,x)
        term.clearLine()
    end
    term.write('Name')
    term.setCursorPos(termWidth - 5, headerHeight)
    term.write('Count')
    term.setBackgroundColor(color1)
    updateButtons(termHeight, termWidth)
end

function updateButtons(termHeight, termWidth)
    --TODO sort by buttons alphabetical, count
    --  multiple toggles reverses sort order
    --TODO filter buttons item groups?, NBT data
    --i think we can leave the rest to advanced search functionality, like parsing tags via #
    --add dividers between each for user clarity
    --create alphabetical sort button
    term.setBackgroundColor(color1)
    term.setCursorPos(termWidth-7, 1)
    term.write('A')
    term.setBackgroundColor(color5)
    term.setCursorPos(termWidth-6, 1)
    term.write(' ')
    --create count sort button
    term.setBackgroundColor(color1)
    term.setCursorPos(termWidth-5, 1)
    term.write('#')
    term.setBackgroundColor(color5)
    term.setCursorPos(termWidth-4, 1)
    term.write('|')
    --build item groups button
    term.setBackgroundColor(color1)
    term.setCursorPos(termWidth-3, 1)
    term.write('G')
    term.setBackgroundColor(color5)
    term.setCursorPos(termWidth-2, 1)
    term.write(' ')
    --build NBT data button
    term.setBackgroundColor(color1)
    term.setCursorPos(termWidth-1, 1)
    term.write('N')
    
end

function updateScrollBar(termHeight, termWidth)
    --TODO update with awareness of how many of the sortedItems we are currently looking at
    --TODO make scroll bar robust, if we simply set a single pixel highlighted by how far we are through our items
    --  we will only have 17 vert pixels on a PC to work with that represent 17 pages of items
    --  17x17 is ONLY 289 unique items
    --  we can get around this by either expanding the scroll bar with a gradient
    --    OR overlay a letter onto the scroll bar
    --for now just update the furthest right side of the screen with a black line
    for x=1, termHeight, 1 do
        --set up the background for the scroll bar's area
        term.setBackgroundColor(color5)
        term.setCursorPos(termWidth, x)
        term.write(' ')
    end
    term.setCursorPos(termWidth, 1)
    term.write('^')
    term.setCursorPos(termWidth, termHeight)
    term.write('v')
    term.setBackgroundColor(color1)
end

function buildInventory()
    local names = retrievePeripherals('chest')
    emptyUserChest('all', names)
    local items = buildItemList(names)
    local sortedItems = buildSortedItems(items)
    updateDisplay(sortedItems)
    return sortedItems
    --TODO add functionality to actually add or withdraw items from player inventory
end

function retrieveItem(sortedItems, targetIndex, count)
    --takes our sortedItems list, the index of the items we want to pull and the num to pull
    -- -1 count means one maxStack
    local names = retrievePeripherals('inventoryManager')
    for x = 1, #names, 1 do
        local invMan = peripheral.wrap(names[x])
        if invMan.getOwner == username then
            --look i know you want to be smart about how it initializes and identifies the
            --  intermediate chests but, just hard code it when setting up each user. It's easier

        end
    end
end

function getClickedItem(sortedItems, button, x, y)
    --determine what item was clicked on and what to do with it
    --takes a mouse button 1,2, or 3, x and y coords of click and our sorted items list to parse
    local termWidth, termHeight = term.getSize()
    -- y - header gives the relative index for the page of items we are on
    local targetIndex = (y - headerHeight) * (pageNum * (termHeight - headerHeight))
    if targetIndex > #sortedItems then
        --if we clicked on a blank space at the end of the list do nothing
        do return end
    end
    if button == 1 then
        --if left click
        retrieveItem(sortedItems, targetIndex, -1)
    elseif button == 2 then
        retrieveItem(sortedItems, targetIndex, 1)
    end
end

function clickManager(sortedItems, button, x, y)
    local termWidth, termHeight = term.getSize()
    if x < termWidth and y > headerHeight then
        --if we are not clicking on the right pixel of the screen or the header
        --  then we must be clicking on an item, let's find out which
        getClickedItem(sortedItems, button, x, y)
    end
end

function waitForUserInput(sortedItems)
    while true do
        --this will trigger for every possible event
        --  be very careful to only do things when the exact event we want happens
        --x, y, and z are abstract to not confuse their purpose
        local event, x, y, z = os.pullEvent()
        if event == 'mouse_scroll' then
            --just updated these for clarity
            -- -1 for up +1 for down
            local dir = x
            --where the mouse is positioned during scroll
            --  not really useful right now
            local x = y
            local z = z
            --subtract pagenum if mousescroll up opposite if down
            pageNum = pageNum + dir
            updateDisplay(sortedItems)
        elseif event == 'mouse_click' then
            --TODO add shift and control and alt click functionality
            clickManager(sortedItems, x, y, z)
        end
    end
end

function main()
    setColorPallete()
    local sortedItems = buildInventory()
    waitForUserInput(sortedItems)
end

typableChars = {
    'a', 'b', 'c', 'd', 'e', 
    'f', 'g', 'h', 'i', 'j', 
    'k', 'l', 'm', 'n', 'o', 
    'p', 'q', 'r', 's', 't', 
    'u', 'v', 'w', 'x', 'y', 
    'z', '@', '$', '#', '_',
    '0', '1', '2', '3', '4',
    '5', '6', '7', '8', '9'
}

--index of what page of items we are looking at
--STARTS AT 0
pageNum = 0
username = 'tony12684'
userChests = {}
userChests['tony12684'] = 'minecraft:chest_7'
headerHeight = 2
--TODO enchance graphics with custom chosen colors via term.setPalleteColor
--color1 = background default
--color2 = background alternate
--color3 = text color
--color4 = header background
--color5 = scroll bar color
color1 = colors.gray
color2 = colors.lightGray
color3 = colors.orange
color4 = colors.black
color5 = colors.black
main()