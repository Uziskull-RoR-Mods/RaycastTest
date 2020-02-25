local PX_PER_COL = 2

local DIST_RENDER = 32
local DIST_FOG = DIST_RENDER - 4

function getScreenCorners(player)
    local cameraWidth, cameraHeight = graphics.getGameResolution()
    local stageWidth, stageHeight = Stage.getDimensions()
    local drawX = 0
    if player.x > cameraWidth / 2 then
        drawX = player.x - cameraWidth / 2
        if drawX + cameraWidth > stageWidth then
            drawX = stageWidth - cameraWidth
        end
    end
    local drawY = 0
    if player.y > cameraHeight / 2 then
        drawY = player.y - cameraHeight / 2
        if drawY + cameraHeight > stageHeight then
            drawY = stageHeight - cameraHeight
        end
    end
    
    return drawX, drawY, drawX + cameraWidth, drawY + cameraHeight
end

function castRay(ray, data, pData, screenW, screenH, wallList, ceilList, floorList, sprList)
    local pAngle = pData.orientation
    local rayAngle = pAngle - (45-1) / 2 + (45 / screenW) * (ray - 1)
    local theta = math.rad(pAngle)

    local cameraX = 2 * ray / screenW - 1
	local rayPosX, rayPosY = pData.coords.x, pData.coords.y
	local rayDirX, rayDirY = math.cos(theta) + pData.plane.x * cameraX,
        -math.sin(theta) + pData.plane.y * cameraX
    -- local rayDirX, rayDirY = math.cos(theta), -math.sin(theta)
	
	local mapX, mapY = rayPosX - (rayPosX % 1), rayPosY - (rayPosY % 1)
	
	local sideDistX, sideDistY = nil, nil
	
	local deltaDistX, deltaDistY = math.abs(1 / rayDirX), math.abs(1 / rayDirY)
	local perWallDist = nil
	
	local stepX, stepY = nil, nil
	
	local hit, side = 0, 0
	
	if rayDirX < 0 then
	  	stepX = -1
	  	sideDistX = (rayPosX - mapX) * deltaDistX
	else
	  	stepX = 1
	  	sideDistX = (mapX + 1.0 - rayPosX) * deltaDistX
	end
	if rayDirY < 0 then
	  	stepY = -1
	  	sideDistY = (rayPosY - mapY) * deltaDistY
	else
	  	stepY = 1
	  	sideDistY = (mapY + 1.0 - rayPosY) * deltaDistY
	end

    local transparentCount = {0, 0}
	local numSteps = 0
	while hit == 0 and numSteps < DIST_RENDER do
		local coords = {x = mapX, y = mapY}
        local found = false
		for i = 1, #floorList do
			found = floorList[i].x == coords.x and floorList[i].y == coords.y
            if found then break end
		end
        if not found then
            table.insert(floorList, coords)
        end
		found = false
		for i = 1, #ceilList do
			found = ceilList[i].x == coords.x and ceilList[i].y == coords.y
            if found then break end
		end
        if not found then
            table.insert(ceilList, coords)
        end

	  	if sideDistX < sideDistY then
			sideDistX = sideDistX + deltaDistX
			mapX = mapX + stepX
			side = 0
	  	else
			sideDistY = sideDistY + deltaDistY
			mapY = mapY + stepY
			side = 1
	  	end
	  	
	  	if mapX > 0 and mapX <= data.level.width and mapY > 0 and mapY <= data.level.height then
		  	if data.level.map[mapY][mapX] ~= 0 then
		  		-- transparent or door
		  		if data.level.map[mapY][mapX] < 0 then
                    if side == 0 then
                        perpWallDist = (mapX - rayPosX + (1 - stepX) / 2) / rayDirX
                    else
                        perpWallDist = (mapY - rayPosY + (1 - stepY) / 2) / rayDirY
                    end
                    -- perpWallDist = math.abs(perpWallDist * math.cos(theta) * math.cos(math.rad(pAngle))
                        -- + perpWallDist * math.sin(theta) * math.sin(math.rad(pAngle)))
                    perpWallDist = math.abs(perpWallDist)
                    
                    if transparentCount[1] == 0 or perpWallDist - transparentCount[2] > TEXTURE_SIZE / 2 then
                        local lineHeight = (screenH + pData.height*screenH) / perpWallDist
                        local normalLineHeight = (screenH - pData.height*screenH) / perpWallDist
                        
                        drawStart = -lineHeight / 2 + ((screenH / 2) + pData.bobbing)
                        drawEnd = normalLineHeight / 2 + ((screenH / 2) + pData.bobbing)
                        
                        local spr = data.level.map[mapY][mapX]
                        
                        local wallX = nil
                        if side == 1 then
                            wallX = rayPosX + ((mapY - rayPosY + (1 - stepY) / 2) / rayDirY) * rayDirX
                        else
                            wallX = rayPosY + ((mapX - rayPosX + (1 - stepX) / 2) / rayDirX) * rayDirY
                        end
                        wallX = wallX % 1
                        
                        local sprX = math.floor(wallX * TEXTURE_SIZE)
                        if side == 0 and rayDirX > 0 or side == 1 and rayDirY < 0 then
                            sprX = TEXTURE_SIZE - sprX - 1
                        end

                        local color = side == 1 and Color.GREY or Color.WHITE
                        if perpWallDist > DIST_FOG * 2/3 then
                            local mix = (perpWallDist - DIST_FOG * 2/3) / (DIST_FOG * 1/3)
                            if mix > 1 then mix = 1 end
                            color = Color.mix(color, data.level.fog, mix)
                        end

                        table.insert(wallList, 1 + #wallList - transparentCount[1], {
                            x = ray,
                            sprX = sprX,
                            start = drawStart,
                            scale = (drawEnd - drawStart) / TEXTURE_SIZE / 2,
                            spr = spr,
                            color = color,
                            depth = perpWallDist,
                            --type = "wall",
                            --onlyTop = data.level.map[mapY][mapX] < 0,
                        })
                    
                        transparentCount[1] = transparentCount[1] + 1
                        transparentCount[2] = perpWallDist
                    end
		  		else
					hit = 1

					local coords = {x = mapX, y = mapY}
                    local found = false
                    for i = 1, #floorList do
                        found = floorList[i].x == coords.x and floorList[i].y == coords.y
                        if found then break end
                    end
                    if not found then
                        table.insert(floorList, coords)
                    end
                    found = false
                    for i = 1, #ceilList do
                        found = ceilList[i].x == coords.x and ceilList[i].y == coords.y
                        if found then break end
                    end
                    if not found then
                        table.insert(ceilList, coords)
                    end
				end
		  	end
        else
            break
		end

		numSteps = numSteps + 1
	end
	
    if mapX > 0 and mapX <= data.level.width and mapY > 0 and mapY <= data.level.height then
        if side == 0 then
            perpWallDist = (mapX - rayPosX + (1 - stepX) / 2) / rayDirX
        else
            perpWallDist = (mapY - rayPosY + (1 - stepY) / 2) / rayDirY
        end
        -- perpWallDist = math.abs(perpWallDist * math.cos(theta) * math.cos(math.rad(pAngle))
            -- + perpWallDist * math.sin(theta) * math.sin(math.rad(pAngle)))
        perpWallDist = math.abs(perpWallDist)
          
        local lineHeight = (screenH + pData.height*screenH) / perpWallDist
        local normalLineHeight = (screenH - pData.height*screenH) / perpWallDist
        
        drawStart = -lineHeight / 2 + ((screenH / 2) + pData.bobbing)
        drawEnd = normalLineHeight / 2 + ((screenH / 2) + pData.bobbing)
        
        local spr = data.level.map[mapY][mapX]
        
        local wallX = nil
        if side == 1 then
            wallX = rayPosX + ((mapY - rayPosY + (1 - stepY) / 2) / rayDirY) * rayDirX
        else
            wallX = rayPosY + ((mapX - rayPosX + (1 - stepX) / 2) / rayDirX) * rayDirY
        end
        wallX = wallX % 1
        
        local sprX = math.floor(wallX * TEXTURE_SIZE)
        if side == 0 and rayDirX > 0 or side == 1 and rayDirY < 0 then
            sprX = TEXTURE_SIZE - sprX - 1
        end

        local color = side == 1 and Color.GREY or Color.WHITE
        if perpWallDist > DIST_FOG * 2/3 then
            local mix = (perpWallDist - DIST_FOG * 2/3) / (DIST_FOG * 1/3)
            if mix > 1 then mix = 1 end
            color = Color.mix(color, data.level.fog, mix)
        end

        local wall = {
            x = ray,
            sprX = sprX,
            start = drawStart,
            scale = (drawEnd - drawStart) / TEXTURE_SIZE / 2,
            spr = spr,
            color = color,
            depth = perpWallDist,
            --type = "wall",
            --onlyTop = false,
        }

        --table.insert(sprList, wall)
        table.insert(wallList, 1 + #wallList - transparentCount[1], wall)

        --zBuffer[ray] = perpWallDist
    end
end

function gameRender(data, frames)
    local p = misc.players[1]
    local pData = p:getData()
    
    local x1, y1, x2, y2 = getScreenCorners(p)
    local screenW, screenH = graphics.getGameResolution()

    if frames < 30 then
        graphics.color(Color.BLACK)
        local stageWidth, stageHeight = Stage.getDimensions()
        graphics.rectangle(0, 0, stageWidth, stageHeight)
        return
    end

    -- bg
    graphics.color(data.level.bg)
    graphics.rectangle(x1, y1, x2, y2)
    
    -- raycasting
    local rayMult = PX_PER_COL
    
    local wallList, ceilList, floorList, sprList = {}, {}, {}, {}
    local pX, pY = pData.coords.x, pData.coords.y
    local pAngle = pData.orientation
    local mX, mY = pData.coords.x - (pData.coords.x % 1), pData.coords.y - (pData.coords.y % 1)
    for ray = 0, screenW - 1, rayMult do
        castRay(
            ray, data, pData,
            screenW, screenH,
            wallList, ceilList, floorList, sprList
        )
    end
    
    local logEnabled = input.checkKeyboard("numpad5") == input.PRESSED
    
    -- fog
    -- local lineHeight = (screenH + pData.height*screenH) / DIST_FOG
    -- local normalLineHeight = (screenH - pData.height*screenH) / DIST_FOG
    -- fogStart = -lineHeight / 2 + ((screenH / 2) + pData.bobbing)
    -- fogEnd = normalLineHeight / 2 + ((screenH / 2) + pData.bobbing)
    -- fogScale = (fogEnd - fogStart) / TEXTURE_SIZE
    -- graphics.color(data.level.fog)
    
    -- -- -- for i = 1, 10 do
        -- -- -- graphics.alpha(i/10)
        -- -- -- graphics.rectangle(
            -- -- -- x1, y1 + drawStart - (data.level.levels - 1) * (drawEnd - drawStart) + i * TEXTURE_SIZE / 4,
            -- -- -- x2, y1 + drawEnd - i * TEXTURE_SIZE / 4
        -- -- -- )
    -- -- -- end
    
    -- floors
    local dirX, dirY = math.cos(math.rad(pAngle)), -math.sin(math.rad(pAngle))
    local invDet = 1.0 / (pData.plane.x * dirY - dirX * pData.plane.y)
	local additive = 1.0
	for _, floor in ipairs(floorList) do
		if floor.x > 0 and floor.x <= data.level.width and floor.y > 0 and floor.y <= data.level.height then
            
            local spriteX = floor.x - pX
            local spriteY = floor.y - pY
            local canDraw = true
            local draw = {{},{},{},{}}

            tx = invDet * (dirY * spriteX - dirX * spriteY)
            ty = invDet * (-pData.plane.y * spriteX + pData.plane.x * spriteY)
            if ty <= 0 then canDraw = false end

            draw[1].x = (screenW / 2) * (1 + tx / ty)
            draw[1].y = ((screenH - pData.height) / ty) / 2 + (screenH / 2) + pData.bobbing

            tx = invDet * (dirY * (spriteX + additive) - dirX * spriteY)
            ty = invDet * (-pData.plane.y * (spriteX + additive) + pData.plane.x * spriteY)
            if ty <= 0 then canDraw = false end

            draw[2].x = (screenW / 2) * (1 + tx / ty)
            draw[2].y = ((screenH - pData.height) / ty) / 2 + (screenH / 2) + pData.bobbing

            tx = invDet * (dirY * (spriteX + additive) - dirX * (spriteY + additive))
            ty = invDet * (-pData.plane.y * (spriteX + additive) + pData.plane.x * (spriteY + additive))
            if ty <= 0 then canDraw = false end

            draw[3].x = (screenW / 2) * (1 + tx / ty)
            draw[3].y = ((screenH - pData.height) / ty) / 2 + (screenH / 2) + pData.bobbing

            tx = invDet * (dirY * spriteX - dirX * (spriteY + additive))
            ty = invDet * (-pData.plane.y * spriteX + pData.plane.x * (spriteY + additive))
            if ty <= 0 then canDraw = false end

            draw[4].x = (screenW / 2) * (1 + tx / ty)
            draw[4].y = ((screenH - pData.height) / ty) / 2 + (screenH / 2) + pData.bobbing

            if logEnabled then
                log(spriteX .. ", " .. spriteY)
                log(draw)
            end

            if canDraw then
                local color = data.level.palette.floor[data.level.floor[floor.y][floor.x]]
                if color ~= nil then
                    graphics.color(color)
                    graphics.triangle(x1+draw[1].x, y1+draw[1].y, x1+draw[2].x, y1+draw[2].y, x1+draw[3].x, y1+draw[3].y)
                    graphics.triangle(x1+draw[3].x, y1+draw[3].y, x1+draw[4].x, y1+draw[4].y, x1+draw[1].x, y1+draw[1].y)
                end
            end
        end
    end
    
    -- walls
    for _, wall in ipairs(wallList) do
        if wall.spr ~= 0 then
            local spr = data.level.palette[wall.spr]
            for l = 1, data.level.levels do
                local sprPalette = spr[data.level.levels - l + 1]
                if sprPalette ~= nil then
                    for j = 0, rayMult - 1 do
                        graphics.drawImage{
                            sprPalette[wall.sprX + 1],
                            x1 + wall.x + j, y1 + wall.start - (l-1) * (TEXTURE_SIZE * wall.scale),
                            yscale = wall.scale,
                            color = wall.color
                        }
                    end
                end
            end
        end
	end
    
    graphics.color(Color.WHITE)
    graphics.print("X: " .. pData.coords.x .. "; Y: " .. pData.coords.y, x1 + 10, y1 + 10, graphics.FONT_LARGE)
end