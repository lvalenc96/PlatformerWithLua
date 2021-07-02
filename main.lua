function love.load()
    love.window.setMode (1000, 768)

    anim8 = require 'libraries/anim8/anim8'
    sti = require 'libraries/Simple-Tiled-Implementation/sti'
    cameraFile = require 'libraries/hump/camera'

    cam = cameraFile()

    sounds = {}
    sounds.jump = love.audio.newSource("audio/jump.wav", "static")
    sounds.jump:setVolume(0.5)
    sounds.music = love.audio.newSource("audio/music.mp3", "stream")
    sounds.music:setLooping(true)
    sounds.music:setVolume(0.3)

    sounds.music2 = love.audio.newSource("audio/music2.mp3", "stream")


    sprites = {}
    sprites.playerSheet = love.graphics.newImage('sprites/playerSheet.png')
    sprites.enemySheet = love.graphics.newImage('sprites/enemySheet.png')
    sprites.background = love.graphics.newImage('sprites/background.png')
    sprites.background2 = love.graphics.newImage('sprites/background2.png')
    sprites.background3 = love.graphics.newImage('sprites/background3.png')
    sprites.background4 = love.graphics.newImage('sprites/background4.png')
    sprites.background5 = love.graphics.newImage('sprites/background5.png')

    local grid = anim8.newGrid(614, 564, sprites.playerSheet:getWidth(), sprites.playerSheet:getHeight())
    local enemyGrid = anim8.newGrid(100, 79, sprites.enemySheet:getWidth(), sprites.enemySheet:getHeight())
    
    animations = {}
    animations.idle = anim8.newAnimation(grid('1-1',1), 0.2)
    animations.jump = anim8.newAnimation(grid('1-1',2), 0.05)
    animations.run = anim8.newAnimation(grid('1-15',3), 0.04)
    animations.enemy = anim8.newAnimation(enemyGrid('1-2', 1), 0.03)

    wf = require 'libraries/windfield/windfield'

    world = wf.newWorld(0, 800, false)
    world:setQueryDebugDrawing(true)

    world:addCollisionClass('Platform')
    world:addCollisionClass('Player')--, {ignores = {'Platform'}})
    world:addCollisionClass('Danger')

    require('player')
    require('enemy')
    
    
    

    --dangerZone = world:newRectangleCollider(-500, 800, 5000, 50, {collision_class = "Danger"})
    --dangerZone: setType('static')

    platforms = {}

    flagX = 0
    flagY = 0

    
    currentLevel = 'level1'

    loadMap(currentLevel)

end

function love.update(dt)
    world:update(dt)
    gameMap:update(dt)
    playerUpdate(dt)
    updateEnemies(dt)

    local px, py = player:getPosition()
    cam:lookAt(px, py)

    local colliders = world:queryCircleArea(flagX, flagY, 10, {'Player'})
    if #colliders > 0 then
        if currentLevel == "level1" then
            loadMap("level2")
        elseif currentLevel == "level2" then
            loadMap("level3")
        elseif currentLevel == "level3" then
            loadMap("level2")
        end
    end
    if currentLevel == "level1" then
        sounds.music:play()
        sounds.music:setLooping(true)
        sounds.music:setVolume(0.3)

    elseif currentLevel == "level2" then
        sounds.music:setLooping(false)
        sounds.music:setVolume(0.0)
     --   sounds.music2:play()

    elseif currentLevel == "level3" then
        sounds.music:play()
        sounds.music:setLooping(true)
        sounds.music:setVolume(0.3)
        
        
    end
end

function love.draw()
    if currentLevel == "level1" then
        love.graphics.draw(sprites.background, 0, 0)
        
    end
    if currentLevel == "level2" then
        love.graphics.draw(sprites.background, 0, 0)
        
    end
    if currentLevel == "level3" then
        love.graphics.draw(sprites.background3, 0, 0)
        
    end
    
    cam:attach()
        if currentLevel == "level1" then
            love.graphics.draw(sprites.background2, 0, 0)
        end
        
        if currentLevel == "level2" then
            love.graphics.draw(sprites.background5, 0, 0)
        end
        if currentLevel == "level3" then
            love.graphics.draw(sprites.background4, 0, 0)
        end
        gameMap:drawLayer(gameMap.layers["Tile Layer 1"])
        --world:draw()
        drawPlayer()
        drawEnemies()
    cam:detach()
end

function love.keypressed(key)
    if key == 'up' then
        if player.grounded then
            player:applyLinearImpulse(0, -3800)
            sounds.jump:play()
        end
    end
    if key == 'r' then
        loadMap("level2")
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
            local colliders  = world:queryCircleArea(x, y, 200, {'Platform', 'Danger'})
            for i,c in ipairs(colliders) do
                c:destroy()
            end
    end
end

function spawnPlatform(x, y, width, height)
    print("1")
    print(width)
    print(height)
    local platform = world:newRectangleCollider(x, y, width, height, {collision_class = "Platform"})
    print("2")
    platform:setType('static')
    table.insert(platforms, platform)
end

function destroyAll()
    local i = #platforms
    while i > -1 do
        if platforms[i] ~= nil then
            platforms[i]:destroy()
        end
        table.remove(platforms, i)
        i = i -1
    end

    local i = #enemies
    while i > -1 do
        if enemies[i] ~= nil then
            enemies[i]:destroy()
        end
        table.remove(enemies, i)
        i = i -1
    end
end

function loadMap(mapName)
    currentLevel = mapName
    destroyAll()
    
    gameMap =sti("maps/".. mapName.. ".lua")
    for i, obj in pairs(gameMap.layers["Start"].objects) do
        playerStartX = obj.x 
        playerStartY = obj.y 
    end
    player:setPosition(playerStartX, playerStartY)
    for i, obj in pairs(gameMap.layers["Platforms"].objects) do
        spawnPlatform(obj.x, obj.y, obj.width, obj.height) 
    end
    for i, obj in pairs(gameMap.layers["Enemies"].objects) do
        spawnEnemy(obj.x, obj.y)
    end
    for i, obj in pairs(gameMap.layers["Flag"].objects) do
        flagX = obj.x 
        flagY = obj.y
    end
end