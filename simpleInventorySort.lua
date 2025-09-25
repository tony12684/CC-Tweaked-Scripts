v1.0
function sortCharcoalChest()
    chest = peripheral.wrap('minecraft:chest_3')    
    for i=1, chest.size(), 1 do
        item = chest.getItemDetail(i)
        if item ~= nil and string.find(item.name, 'stick') ~= nil then
            chest.pushItems('minecraft:chest_6', i, 64)
        end
    end
end

function sortWoodChest()
    chest = peripheral.wrap('minecraft:chest_4')    
    for i=1, chest.size(), 1 do
        item = chest.getItemDetail(i)
        if item ~= nil and string.find(item.name, 'stick') ~= nil then
            chest.pushItems('minecraft:chest_6', i, 64)
        end
    end
end

function sortWheatChest()
    chest = peripheral.wrap('minecraft:chest_0')    
    for i=1, chest.size(), 1 do
        item = chest.getItemDetail(i)
        if item ~= nil and string.find(item.name, 'seed') ~= nil then
            chest.pushItems('minecraft:chest_1', i, 64)
        end
    end
end

function main()
    while true do
        sortCharcoalChest()
        sortWoodChest()
        sortWheatChest()
        os.sleep(1)
    end
end

main()