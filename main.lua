TEXTURE_SIZE = 16

require("blocking")
require("maps")
require("game")

-- local emptyRoom = Room.new("emptyRoom")
-- emptyRoom:resize(20, 20)

-- local roomList = Stage.progression[1][1].rooms
-- for j = roomList:len(), 1, -1 do
    -- roomList:remove(roomList[j])
-- end
-- roomList:add(emptyRoom)

-- Stage.progression[1][2].disabled = true

registercallback("onGameStart", function()
    graphics.bindDepth(-10000000, gameEngine)
end, 1234567890)