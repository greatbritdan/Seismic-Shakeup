local game = {}

function gettileind(x,y,state)
    local all = MAPWIDTH*MAPHEIGHT
    return ((state-1)*all) + ((y-1)*MAPWIDTH) + x
end

local pitchlow = 1
function game.load(last)
    if not LEVEL then
        LEVEL = _env.level or 1
        LEVELSELECT = false
    else
        LEVELSELECT = true
    end
    loadmap("level" .. LEVEL)

    shader = love.graphics.newShader[[
        extern number factor;
        vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
            vec4 pixel = Texel(texture, texture_coords );//This is the current pixel color
            number average = (pixel.r+pixel.b+pixel.g)/3.0;
            pixel.r = pixel.r + (average-pixel.r) * factor;
            pixel.g = pixel.g + (average-pixel.g) * factor;
            pixel.b = pixel.b + (average-pixel.b) * factor;
            return pixel * color;
        }
    ]]

    MENUBUTTON = GuiElement:new("button", "center", (_env.height/2)+10, "return to menu", function() Screen:fadeTo("title", {"fade", 0.6}) end)

    titlemusic:stop()
    music:setPitch(pitchlow)
end

function loadmap(name)
    OBJS = {}
    OBJS["player"] = {}
    OBJS["ground"] = {}
    OBJS["ceilblocker"] = {}

    OBJS["grate"] = {}
    OBJS["box"] = {}
    OBJS["enemy"] = {}

    PARTICLES = {}

    MAP = {{}, {}}

    -- ok now lets make the map!
    mappres = sti("maps/" .. name .. ".lua")
    mappast = sti("maps/" .. name .. "-past.lua")
    MAPWIDTH, MAPHEIGHT = mappres.width, mappres.height
    XSCROLL = 0

    NOTICES = {}
    NOTICETIMER = 0
    NOTICE = false
    NOTICEAWAIT = false

    CHECKPOINTS = {}

    STATE = 1

    tilespritebatch = {}
    backtilespritebatch = {}
    foretilespritebatch = {}

    loadmapdata(1, mappres)
    loadmapdata(2, mappast)

    BACKGROUND = {}
    BACKGROUND[1] = (mappres.properties.background or "city")
    BACKGROUND[2] = (mappast.properties.background or "city")
    BACKGROUNDSCROLLFACTOR = 1.5

    TIMETRAVELON = (mappres.properties.timetravelenabled or false)
    TIMETRAVELING = false
    TIMETRAVELTIMER = 0

    LEVELWON = false
    LEVELWONTIMER = 0

    PAUSED = false
    PAUSEDTIMER = 0

    --dust to dust
    DUST = false
    if LEVEL == 4 then DUST = {x=0, speed=4} end
end

function loadmapdata(state, map)
    -- objs
    local objectlayer = map.layers[3]
    for i, obj in pairs(objectlayer.objects) do
        if obj.visible then
            local objc, objgroup
            if obj.type == "spawn" then
                objc, objgroup = Player:new(obj.x/16, obj.y/16), "player"
            elseif obj.type == "grate" then
                objc, objgroup = Grate:new(obj.x/16, obj.y/16), "grate"
            elseif obj.type == "box" then
                objc, objgroup = Box:new(obj.x/16, obj.y/16, obj.properties.metal), "box"
            elseif obj.type == "enemy" then
                objc, objgroup = Enemy:new(obj.x/16, obj.y/16, obj.properties.type), "enemy"
            elseif obj.type == "notice" then
                NOTICES[obj.x/16] = {obj.properties.text, obj.properties.enabletimetravel}
            elseif obj.type == "checkpoint" then
                CHECKPOINTS[obj.x/16] = obj.y/16
            end
            if objc then
                if obj.properties.global == false then
                    objc.STATE = state
                end
                table.insert(OBJS[objgroup], objc)
            end
        end
    end

    -- tiles
    local tilelayer = map.layers[2].data
    local backtilelayer = map.layers[1].data
    local foretilelayer = map.layers[4].data
    for y = 1, MAPHEIGHT do
        MAP[state][y] = {}
        for x = 1, MAPWIDTH do
            MAP[state][y][x] = {1}
            if tilelayer[y][x] then
                settile(state, x, y, tilelayer[y][x].id+1, 1)
                if y == 1 and tilequadsdata[tilelayer[y][x].id+1].collision then
                    OBJS["ceilblocker"][x] = Ceilblocker:new(x-1, y-1)
                end
            end
            if backtilelayer[y][x] then
                settile(state, x, y, backtilelayer[y][x].id+1, "back")
            end
            if foretilelayer[y][x] then
                settile(state, x, y, foretilelayer[y][x].id+1, "fore")
            end
        end
    end

    -- spritbach
    generatespritebatch(state)
end

function generatespritebatch(state)
    tilespritebatch[state] = love.graphics.newSpriteBatch(tileimg,MAPWIDTH*MAPHEIGHT)
    backtilespritebatch[state] = love.graphics.newSpriteBatch(tileimg,MAPWIDTH*MAPHEIGHT)
    foretilespritebatch[state] = love.graphics.newSpriteBatch(tileimg,MAPWIDTH*MAPHEIGHT)

    for y = 1, MAPHEIGHT do
        for x = 1, MAPWIDTH do
            local i = MAP[state][y][x][1]
            tilespritebatch[state]:add(tilequads[i], (x-1)*16, (y-1)*16)
            if MAP[state][y][x]["back"] then
                local i = MAP[state][y][x]["back"]
                backtilespritebatch[state]:add(tilequads[i], (x-1)*16, (y-1)*16)
            end
            if MAP[state][y][x]["fore"] then
                local i = MAP[state][y][x]["fore"]
                foretilespritebatch[state]:add(tilequads[i], (x-1)*16, (y-1)*16)
            end
        end
    end
end

function game.update(dt)
    if (OBJS["player"][1].animation ~= "win") and (not music:isPlaying()) then
        music:play()
    end

    if PAUSED then
        PAUSEDTIMER = PAUSEDTIMER + dt
        return
    end

    if DUST then
        local p = OBJS["player"][1]
        if p.x > 60 and DUST.speed == 4 then
            DUST.speed = 7
        end
        DUST.x = DUST.x + DUST.speed * dt
        if DUST.x > MAPWIDTH+3 then
            DUST.x = MAPWIDTH+3
            DUST.speed = 0
        end
        if p.x+2 < DUST.x and (not p.animation) then
            p:hurt(3)
        end
    end

    forinupdate(OBJS["player"], dt)
    forinupdate(OBJS["enemy"], dt)
    forinupdate(OBJS["box"], dt)
    forinupdate(OBJS["grate"], dt)
    forinupdate(PARTICLES, dt)

    local p = OBJS["player"][1]
    for i,v in pairs(CHECKPOINTS) do
        if p.x > i then
            p.spawnx, p.spawny = i+0.25, v-0.75
            CHECKPOINTS[i] = nil
        end
    end

    for i,v in pairs(NOTICES) do
        if p.x > i then
            if NOTICE then
                NOTICEAWAIT = deepcopy(v)
            else
                NOTICE = v[1]
                if v[2] then TIMETRAVELON = true end
                NOTICETIMER = 0
            end
            NOTICES[i] = nil
        end
    end
    if NOTICE then
        NOTICETIMER = NOTICETIMER + dt
        if NOTICETIMER > 4 then
            NOTICE = false
            if NOTICEAWAIT then
                NOTICE = NOTICEAWAIT[1]
                if NOTICEAWAIT[2] then TIMETRAVELON = true end
                NOTICEAWAIT = false
            end
            NOTICETIMER = 0
        end
    end
    
    if TIMETRAVELING then
        TIMETRAVELTIMER = TIMETRAVELTIMER + dt
        if TIMETRAVELTIMER >= 0.5 and TIMETRAVELING == true then
            if STATE == 1 then
                STATE = 2
                music:setPitch(1)
            else
                STATE = 1
                music:setPitch(pitchlow)
            end
            if OBJS["player"][1].grabbed and OBJS["player"][1].grabbed.STATE then
                OBJS["player"][1].grabbed.STATE = STATE
            end
            TIMETRAVELING = "anim"
        end
        if TIMETRAVELTIMER >= 1 then
            TIMETRAVELING = false
            TIMETRAVELTIMER = 0
        end
    end

    if LEVELWON then
        LEVELWONTIMER = LEVELWONTIMER + dt
        if LEVELWONTIMER >= 1 then
            local x, y = MAPWIDTH-math.random(1,22), math.random(1,14)
            for i = 1, 12 do
                newparticle(x, y, "yay")
            end
            LEVELWONTIMER = LEVELWONTIMER - 0.5
        end
    end

    physics_update(dt)
end

function game.draw()
    if STATE == 2 then
        shader:send("factor", -0.2)
    else
        shader:send("factor", 0.4)
    end
    love.graphics.setShader(shader)

    love.graphics.setColor(255,255,255)
    local x = -((XSCROLL*16)%(backgroundsimg[BACKGROUND[STATE]]:getWidth()*BACKGROUNDSCROLLFACTOR))
    love.graphics.draw(backgroundsbatch[BACKGROUND[STATE]], x/BACKGROUNDSCROLLFACTOR, 0)
    
    love.graphics.setColor(155,155,155)
    love.graphics.draw(backtilespritebatch[STATE], -(XSCROLL*16))
    love.graphics.setColor(255,255,255)
    love.graphics.draw(tilespritebatch[STATE], -(XSCROLL*16))
   
    forindraw(OBJS["box"])
    forindraw(OBJS["grate"])
    forindraw(OBJS["enemy"])
    forindraw(OBJS["player"])
    forindraw(PARTICLES)

    if love.keyboard.isDown("0") then
        for j, w in pairs(OBJS) do
            for i, v in pairs(OBJS[j]) do
                if v.w and ((not v.STATE) or v.STATE == STATE) then
                    love.graphics.rectangle("line",(v.x-XSCROLL)*16,v.y*16,v.w*16,v.h*16)
                end
            end
        end
    end

    love.graphics.setColor(255,255,255)
    love.graphics.draw(foretilespritebatch[STATE], -(XSCROLL*16))

    if DUST then
        love.graphics.draw(dustimg, ((DUST.x-XSCROLL)*16)-400, 0)
        forindraw(PARTICLES)
    end

    local p = OBJS["player"][1]
    for i = 1, p.maxhealth do
        local q = 2
        if i <= p.health then q = 1 end
        love.graphics.draw(hudimg, hudquads[q], 4+((i-1)*6), 4)
    end

    if NOTICE then
        local a = 255
        if NOTICETIMER > 3.5 then
            a = 255-((NOTICETIMER-3.5)*510)
        end
        love.graphics.setColor(155,155,155,a)
        love.graphics.printf(NOTICE, 2, 3, _env.width, "center")
        love.graphics.setColor(255,255,255,a)
        love.graphics.printf(NOTICE, 2, 2, _env.width, "center")
    end
    
    if TIMETRAVELING then
        if TIMETRAVELTIMER < 0.5 then
            love.graphics.setColor(255,255,255, TIMETRAVELTIMER*510)
        else
            love.graphics.setColor(255,255,255, 255-((TIMETRAVELTIMER-0.5)*510))
        end
        love.graphics.rectangle("fill", 0, 0, _env.width, _env.height)
    end

    if LEVELWON then
        love.graphics.setColor(155,155,155)
        love.graphics.printf("level cleared!\npress any button to continue", 2, (_env.height/2)-10, _env.width, "center")
        love.graphics.setColor(255,255,255)
        love.graphics.printf("level cleared!\npress any button to continue", 2, (_env.height/2)-11, _env.width, "center")
    end

    if PAUSED then
        love.graphics.setColor(0,0,0,100)
        love.graphics.rectangle("fill", 0, 0, _env.width, _env.height)
        love.graphics.setColor(155,155,155)
        love.graphics.printf("pasued", 2, (_env.height/2)-4, _env.width, "center")
        love.graphics.setColor(255,255,255)
        love.graphics.printf("pasued", 2, (_env.height/2)-5, _env.width, "center")
        MENUBUTTON:draw()
    end

    love.graphics.setShader()
end

function game.mousepressed(x,y,b)
    if PAUSED then
        MENUBUTTON:mousepressed(x,y,b)
    end
end

function game.keypressed(key)
    if key == "escape" and (not OBJS["player"][1].animation) and (not LEVELWON) then
        PAUSED = not PAUSED
        return
        --love.event.push("quit")
    end
    if PAUSED then return end

    if LEVELWON then
        if LEVEL == 4 or LEVELSELECT then
            Screen:fadeTo("title", {"fade", 0.6})
        else
            LEVEL = LEVEL + 1
            _env.level = LEVEL
            loadmap("level" .. LEVEL)
        end
        return
    end
    
    local p = OBJS["player"][1]
    if love.keyboard.isDown("lshift") then
        if key == "1" then
            p.y = p.y - 1
            table.insert(OBJS["box"], Box:new(p.x-0.25, p.y+p.h))
        end
        if key == "2" then
            p.y = p.y - 1
            table.insert(OBJS["box"], Box:new(p.x-0.25, p.y+p.h, true))
        end
    end

    if p.controlsenabled then
        if key == CONTROLS["jump"] then
            p:jump()
        end
        if key == CONTROLS["grab"] then
            p:grab()
        end
        if key == CONTROLS["travel"] and TIMETRAVELON and (not TIMETRAVELING) then
            local oldstate = STATE
            if #collidecheck(p, p.x, p.y, p.w, p.h, {"box","ground"}, true) == 0 then
                TIMETRAVELING = true
                TIMETRAVELTIMER = 0
                playsound(travelsound)
            end
        end
    end
end

function game.keyreleased(key)
    local p = OBJS["player"][1]
    if p.controlsenabled then
        if key == CONTROLS["jump"] then
            p:stopjump()
        end
    end
end

function newparticle(x, y, t)
    table.insert(PARTICLES, Particle:new(x, y, t))
end

---

function settile(state, x, y, id, layer)
    if state == true then
        settilereal(1, x, y, id, layer)
        settilereal(2, x, y, id, layer)
    else
        settilereal(state, x, y, id, layer)
    end
end
function settilereal(state, x, y, id, layer)
    state = state
    MAP[state][y][x][layer] = id
    if layer == 1 then
        OBJS["ground"][gettileind(x,y,state)] = nil
        if tilequadsdata[id].collision then
            OBJS["ground"][gettileind(x,y,state)] = Ground:new(x-1,y-1,tilequadsdata[id])
            OBJS["ground"][gettileind(x,y,state)].STATE = state
        end
    end
end

function gettile(state, x, y, prop)
    local obj = OBJS["ground"][gettileind(x,y,state)]
    if prop then
        return (obj and obj[prop])
    else
        return obj
    end
end

---

function forinupdate(obj, dt)
    local delet
    for i, v in pairs(obj) do
        if (not v.STATE) or v.STATE == STATE then
            v:update(dt)
            if v.deletemepls then
                if not delet then delet = {} end
                table.insert(delet, i)
            end
        end
    end
    if delet then
        table.sort(delet, function(a,b) return a>b end)
        for i, v in pairs(delet) do
            table.remove(obj, v)
        end
    end
end

function forindraw(obj)
    for i, v in pairs(obj) do
        if (not v.STATE) or v.STATE == STATE then
            v:draw()
        end
    end
end

return game