--v1.0
local args = {...}
local pulseLength = args[1] or 0.5
local pulseDelay = args[2] or 5

term.clear()
term.setCursorPos(1, 1)
print('Redstone clock online.')
print('Pulse length is '..pulseLength..' seconds.')
print('Pulse delay is '..pulseDelay..' seconds.')
print('Pulsing in all directions.')
print('To edit the pulse length or delay...')
print('hold ctrl t to terminate program,')
print('type "edit startup.lua",')
print('edit the two numbers after rsClock to change pulse length and delay respectively,')
print('then save the program and restart')
print('To edit pulse directions... ask Tony.')

function rsSwitch(state)
    rs.setOutput('front',state)
    rs.setOutput('back',state)
    rs.setOutput('left',state)
    rs.setOutput('right',state)
    rs.setOutput('top',state)
    rs.setOutput('bottom',state)
end

function main()
    while true do
        rsSwitch(true)
        os.sleep(pulseLength)
        rsSwitch(false)
        os.sleep(pulseDelay)
    end
end

main()