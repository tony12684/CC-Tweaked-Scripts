while true do
    turtle.digDown()
    if not turtle.down() then
        while turtle.up() do
        end
        error('all done', 0)
    end
end
