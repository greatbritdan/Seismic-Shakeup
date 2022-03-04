-- MADE BY AIDAN, DON'T STEAL OR I DO BE A SAD BOI!!!

function love.load()
    love.graphics.setDefaultFilter("nearest","nearest")

    local logo = love.image.newImageData("images/icon.png")
    love.window.setIcon(logo)

    _env = deepcopy(env)
    require("libs/class")
    JSON = require("libs/JSON")
    sti = require("libs/sti")

    if love.filesystem.exists("save.json") then
        local json = love.filesystem.read("save.json")
        local data = JSON:decode(json)
        for i,v in pairs(data) do
            _env[i] = v
        end
        love.window.setMode(_env.width*_env.scale,_env.height*_env.scale,{vsync=_env.vsync})
    else    
        local data = {scale=3, vsync=false, volumemusic=40, volumesound=40, level=1}
        local json = JSON:encode_pretty(data)
        love.filesystem.write("save.json", json)
    end

    font = love.graphics.newImageFont("images/font.png", "abcdefghijklmnopqrstuvwxyz 0123456789.,:;_-!?/\\<>*", 1)
    love.graphics.setFont(font)

    require("physics")
    require("objects/player")
    require("objects/ground")
    require("objects/grate")
    require("objects/box")
    require("objects/enemy")

    titleimg = love.graphics.newImage("images/title.png")
    hudimg, hudquads = createsprites("hud", 2, nil, 8, 6)

    guiimg = love.graphics.newImage("images/gui.png")
    guiquad = {
        buttonl = love.graphics.newQuad(0, 0,4,18,24,18),
        buttonm = love.graphics.newQuad(5 ,0,1,18,24,18),
        buttonr = love.graphics.newQuad(7, 0,4,18,24,18),
        sliderl = love.graphics.newQuad(12,0,4,18,24,18),
        sliderm = love.graphics.newQuad(17,0,1,18,24,18),
        sliderr = love.graphics.newQuad(19,0,4,18,24,18)
    }

    playerimg, playerquads = createsprites("player", 9, 2, 16, 32)
    enemiesimg, enemiesquads = createsprites("enemies", 4, nil, 16, 16)
    grateimg, gratequads = createsprites("grate", 4, nil, 16, 15)
    carimg, carquads = createsprites("car", 4, nil, 64, 32)
    boximg, boxquads = createsprites("box", 2, nil, 16, 16)

    particleimg, particlequads = createsprites("particles", 10, nil, 8, 8)
    dustimg = love.graphics.newImage("images/dust.png")

    tilequadsdata = {}
    tileimg, tilequads, totaltiles, tilesgrid = createtiles("tiles")

    backgroundsbatch = {}
    backgroundsimg = {}
    for i, v in pairs(love.filesystem.getDirectoryItems("images/backgrounds/")) do
        local name = string.sub(v,1,-5)
        backgroundsimg[name] = love.graphics.newImage("images/backgrounds/" .. v)
        backgroundsbatch[name] = love.graphics.newSpriteBatch(backgroundsimg[name], 16)

        local totwidth = 0
        while totwidth < _env.width*2 do
            backgroundsbatch[name]:add(totwidth, 0)
            totwidth = totwidth + backgroundsimg[name]:getWidth()
        end
    end

    jumpsound = love.audio.newSource("sounds/jump.ogg","static")
    hitsound = love.audio.newSource("sounds/hit.ogg","static")
    smooshsound = love.audio.newSource("sounds/smoosh.ogg","static")
    travelsound = love.audio.newSource("sounds/travel.ogg","static")
    pickupsound = love.audio.newSource("sounds/pickup.ogg","static")
    landsound = love.audio.newSource("sounds/land.ogg","static")
    deadsound = love.audio.newSource("sounds/ded.ogg","static")
    blipsound = love.audio.newSource("sounds/blip.ogg","static")

    music = love.audio.newSource("sounds/music.ogg","stream")
    titlemusic = love.audio.newSource("sounds/titlemusic.ogg","stream")

    updatesounds()

    CONTROLS = {left="a",right="d",jump="space",duck="s",grab="e",travel="r"}

    require("customlibs/screen")
    require("customlibs/anotherguithing")

    Screen:changeTo("intro")
end

function updatesounds()
    jumpsound:setVolume(_env.volumesound/100)
    hitsound:setVolume(_env.volumesound/100)
    smooshsound:setVolume(_env.volumesound/100)
    travelsound:setVolume(_env.volumesound/100)
    pickupsound:setVolume(_env.volumesound/100)
    landsound:setVolume(_env.volumesound/100)
    deadsound:setVolume(_env.volumesound/100)

    music:setVolume(_env.volumemusic/100)
    titlemusic:setVolume(_env.volumemusic/100)
end

function playsound(sound)
    sound:stop()
    sound:play()
end

function love.update(dt)
    dt = math.min(dt, 1/60)
    gdt = dt
    Screen:update(dt)
end

function love.draw()
    Screen:draw(dt)
    if _env.fps then
        love.graphics.setColor(255,255,255)
        love.graphics.print("fps: " .. love.timer.getFPS(), 3, 3, 0, _env.scale, _env.scale)
    end
end

function love.mousepressed(x, y, button)
    Screen:mousepressed(x, y, button)
end
function love.mousereleased(x, y, button)
    Screen:mousereleased(x, y, button)
end
function love.keypressed(key, scancode)
    Screen:keypressed(key)
end
function love.keyreleased(key)
    Screen:keyreleased(key)
end
function love.textinput(key)
    Screen:textinput(key)
end
function love.wheelmoved(x, y)
    Screen:wheelmoved(x, y)
end
function love.mousemoved(x, y, dx, dy)
    Screen:mousemoved(x, y, dx, dy)
end

function love.resize(w, h)
    WIDTH, HEIGHT = round(w/_env.scale), round(h/_env.scale)
end

function drawtext(text, x, y, back, limit, align)
    limit = limit or 9999
    if back then
        local r,g,b,a = love.graphics.getColor()
        love.graphics.setColor(0,0,0)
        love.graphics.printf(text, x+1, y, limit, align)
        love.graphics.printf(text, x, y+1, limit, align) 
        love.graphics.printf(text, x-1, y, limit, align)
        love.graphics.printf(text, x, y-1, limit, align)
        love.graphics.setColor(r,g,b,a)
    end
    love.graphics.printf(text, x, y, limit, align)
end

function createtiles(name) --create tiles from image
    local img = love.graphics.newImage("images/" .. name .. ".png")
    local imgdata = love.image.newImageData("images/" .. name .. ".png")
    local imgw, imgh, xquads, yquads
    local quads = {}
    imgw, imgh = img:getWidth(), img:getHeight()
    xquads, yquads = imgw/17, imgh/17
    for y = 1, yquads do
        for x = 1, xquads do
            table.insert(quads, love.graphics.newQuad((x-1)*17, (y-1)*17, 16, 16, imgw, imgh))
            getproperties(x, y, imgdata)
        end
    end
    --print("loaded " .. xquads*yquads .. " tiles")
    return img, quads, xquads*yquads, {xquads, yquads}
end

function getproperties(x, y, data)
    local quaddata = {}
    local r,g,b,a

    r,g,b,a = data:getPixel((x*17)-17, (y*17)-1)
    if a > 127 then
        quaddata.collision = true
    end
    r,g,b,a = data:getPixel((x*17)-16, (y*17)-1)
    if a > 127 then
        quaddata.platform = true
    end
    r,g,b,a = data:getPixel((x*17)-15, (y*17)-1)
    if a > 127 then
        if r == 255 and g == 0 and b == 0 then
            quaddata.half = "bottom"
        elseif r == 0 and g == 255 and b == 0 then
            quaddata.half = "top"
        end
    end
    r,g,b,a = data:getPixel((x*17)-14, (y*17)-1)
    if a > 127 then
        quaddata.breakable = true
    end

    table.insert(tilequadsdata, quaddata)
end

function createsprites(name, horquads, verquads, width, height)
    local img = love.graphics.newImage("images/" .. name .. ".png")
    local quads = {}
    if verquads then
        for x = 1, horquads do
            quads[x] = {}
            for y = 1, verquads do
                quads[x][y] = love.graphics.newQuad((x-1)*width, (y-1)*height, width, height, img:getWidth(), img:getHeight())
            end
        end
    else
        for x = 1, horquads do
            quads[x] = love.graphics.newQuad((x-1)*width, 0, width, height, img:getWidth(), img:getHeight())
        end
    end
    return img, quads
end

function round(num)
    return math.floor(num+0.5)
end
function snap(num, by)
    return round(num/by)*by
end
function getX()
    return math.floor(love.mouse.getX()/_env.scale)
end
function getY()
    return math.floor(love.mouse.getY()/_env.scale)
end
function getXY()
    return getX(), getY()
end
-- not made by me \/
function tablecontains(table, name)
    for i = 1, #table do
        if table[i] == name then
            return i
        end
    end
    return false
end
function string:split(d)
	local data = {}
	local from, to = 1, string.find(self, d)
	while to do
		table.insert(data, string.sub(self, from, to-1))
		from = to+d:len()
		to = string.find(self, d, from)
	end
	table.insert(data, string.sub(self, from))
	return data
end
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end