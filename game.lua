require("render")

local ANGLE_TURN = 1.5

function gameEngine(self, frames)
    local gameData = self:getData()
    local _, screenH = graphics.getGameResolution()
    if frames == 1 then
        prepMapTextures()
    
        misc.hud:set("show_time", 0):set("show_gold", 0)
                :set("show_skills", 0):set("show_level_name", 0)
                :set("objective_text", "")
        
        gameData.level = mapList[1]
        
        for _, p in ipairs(misc.players) do
            local pData = p:getData()
            pData.coords = gameData.level.spawn
            pData.orientation = 270
            pData.plane = {x = math.cos(math.rad(0)), y = -math.sin(math.rad(0))}
            pData.speed = 0.05
            pData.bobbing, pData.bobbingDir = 0, 1
            pData.height = -1
            pData.width = 0.5
        end
    end
    
    gameRender(gameData, frames)
    
    local pData = misc.players[1]:getData()
    for i, ctrl in ipairs({"left", "right"}) do
        if input.checkControl(ctrl) == input.HELD then
            local angle = i == 1 and -ANGLE_TURN or ANGLE_TURN
            pData.orientation = (pData.orientation + angle) % 360
            pData.plane.x, pData.plane.y = math.cos(math.rad((pData.orientation + 90) % 360)),
              -math.sin(math.rad((pData.orientation + 90) % 360))
            break
        end
    end
    for i, ctrl in ipairs({"up", "down"}) do
        if input.checkControl(ctrl) == input.HELD then
            local vec = {x = math.cos(math.rad(pData.orientation)), y = -math.sin(math.rad(pData.orientation))}
            local mult = i == 1 and 1 or -1
            for j, dir in ipairs({"x", "y"}) do
                local newDir = pData.coords[dir] + vec[dir] * pData.speed * mult
                local col = newDir + vec[dir]/math.abs(vec[dir]) * pData.width * mult
                if j == 1 and col - (col % 1) >= 1 and col - (col % 1) <= gameData.level.width
                  and gameData.level.map[pData.coords.y - (pData.coords.y % 1)][col - (col % 1)] == 0
                  or j == 2 and col - (col % 1) >= 1 and col - (col % 1) <= gameData.level.height
                  and gameData.level.map[col - (col % 1)][pData.coords.x - (pData.coords.x % 1)] == 0 then
                    pData.coords[dir] = newDir
                end
            end
            break
        end
    end
end