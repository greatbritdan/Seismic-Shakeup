local title = {}

function title.load()
    love.graphics.setBackgroundColor(35,35,35)
    titletext = "made by aidan for the love game jam!"
    titletimer = 0
    titlestate = "menu"

    titlegui = {}
    titlegui["play"] =     GuiElement:new("button", "center", 112, " play ", function() LEVEL = false; Screen:fadeTo("game", {"fade", 0.6}) end)
    titlegui["level"] =    GuiElement:new("button", "center", 132, " level select ", function() titlestate = "levels" end)
    titlegui["settings"] = GuiElement:new("button", "center", 152, " settings ", function() titlestate = "settings" end)

    levelgui = {}
    levelgui["text"] =   GuiElement:new("text", "center", 16, "settings")
    levelgui["level1"] = GuiElement:new("button", "center", 74, " level 1 ", function() LEVEL = 1; Screen:fadeTo("game", {"fade", 0.6}) end)
    levelgui["level2"] = GuiElement:new("button", "center", 94, " level 2 ", function() LEVEL = 2; Screen:fadeTo("game", {"fade", 0.6}) end)
    levelgui["level3"] = GuiElement:new("button", "center", 114, " level 3 ", function() LEVEL = 3; Screen:fadeTo("game", {"fade", 0.6}) end)
    levelgui["level4"] = GuiElement:new("button", "center", 134, " level 4 ", function() LEVEL = 4; Screen:fadeTo("game", {"fade", 0.6}) end)
    levelgui["exit"] =   GuiElement:new("button", "center", 192, "    exit    ", function() titlestate = "menu" end)

    settingsgui = {}
    settingsgui["text"] =      GuiElement:new("text", "center", 16, "settings")
    settingsgui["scale"] =     GuiElement:new("button", "center", 36, "scale: 0", function() updatevar("scale") end)
    settingsgui["vsync"] =     GuiElement:new("button", "center", 56, "vsync: false", function() updatevar("vsync") end)
    settingsgui["musictext"] = GuiElement:new("text", "center", 86, "music volume")
    settingsgui["music"] =     GuiElement:new("slider", "center", 101, 100, function() updatevar("music") end)
    settingsgui["musicv"] =    GuiElement:new("text", 230, 105, "(100)")
    settingsgui["soundtext"] = GuiElement:new("text", "center", 126, "sfx volume")
    settingsgui["sound"] =     GuiElement:new("slider", "center", 141, 100, function() updatevar("sound") end)
    settingsgui["soundv"] =    GuiElement:new("text", 230, 145, "(100)")
    settingsgui["exit"] =      GuiElement:new("button", "center", 192, "    exit    ", function() titlestate = "menu" end)

    settingsgui["music"].value = _env.volumemusic/100
    settingsgui["sound"].value = _env.volumesound/100

    music:stop()
end

function title.update(dt)
    if not titlemusic:isPlaying() then
        titlemusic:play()
    end

    titletimer = titletimer + dt
    if titlestate == "settings" then
        for i, v in pairs(settingsgui) do
            v:update(dt)
        end
    end

    settingsgui["scale"].text = "scale: " .. _env.scale
    settingsgui["vsync"].text = "vsync: " .. tostring(_env.vsync)
    settingsgui["musicv"].text = "(" .. settingsgui["music"].value*100 --[[_env.volumemusic]] .. ")"
    settingsgui["soundv"].text = "(" .. settingsgui["sound"].value*100 --[[_env.volumesound]] .. ")"
end

function updatevar(name)
    if name == "scale" then
        _env.scale = _env.scale + 1
        if _env.scale > 4 then _env.scale = 1 end
    elseif name == "vsync" then
        _env.vsync = not _env.vsync
    elseif name == "music" then
        _env.volumemusic = settingsgui["music"].value*100
        updatesounds()
    elseif name == "sound" then
        _env.volumesound = settingsgui["sound"].value*100
        updatesounds()
    end
    if name == "scale" or name == "vsync" then
        love.window.setMode(_env.width*_env.scale,_env.height*_env.scale,{vsync=_env.vsync})
    end

    local data = {scale=_env.scale, vsync=_env.vsync, volumemusic=_env.volumemusic, volumesound=_env.volumesound}
    local json = JSON:encode_pretty(data)
    love.filesystem.write("save.json", json)
end

function title.draw()
    love.graphics.setColor(255,255,255)
    local x = -((titletimer*32)%(backgroundsimg["cityblur"]:getWidth()))
    love.graphics.draw(backgroundsbatch["cityblur"], x, 0)

    if titlestate == "menu" then
        love.graphics.setColor(0,0,0,100)
        love.graphics.draw(titleimg, (_env.width/2)-(titleimg:getWidth()/2)+4, 28+math.sin(titletimer*2)*12)
        love.graphics.setColor(255,255,255)
        love.graphics.draw(titleimg, (_env.width/2)-(titleimg:getWidth()/2), 24+math.sin(titletimer*2)*12)

        for i, v in pairs(titlegui) do
            v:draw()
        end
        
        love.graphics.setColor(255,255,255)
        if math.floor(titletimer*12) > #titletext then
            drawtext(titletext, 0, _env.height-18, true, _env.width, "center")
        else
            drawtext(string.sub(titletext, 1, math.floor(titletimer*12)) .. "_", 0, _env.height-18, true, _env.width, "center")
        end
    elseif titlestate == "levels" then
        love.graphics.setColor(0,0,0,155)
        love.graphics.rectangle("fill",8,8,_env.width-16,_env.height-16)
        love.graphics.setColor(255,255,255)

        for i, v in pairs(levelgui) do
            v:draw()
        end
    elseif titlestate == "settings" then
        love.graphics.setColor(0,0,0,155)
        love.graphics.rectangle("fill",8,8,_env.width-16,_env.height-16)
        love.graphics.setColor(255,255,255)

        for i, v in pairs(settingsgui) do
            v:draw()
        end
    end
end

function title.mousepressed(x, y, button)
    if titlestate == "menu" then
        for i, v in pairs(titlegui) do
            v:mousepressed(x, y, button)
        end
    elseif titlestate == "levels" then
        for i, v in pairs(levelgui) do
            v:mousepressed(x, y, button)
        end
    elseif titlestate == "settings" then
        for i, v in pairs(settingsgui) do
            v:mousepressed(x, y, button)
        end
    end
end

function title.mousereleased(x, y, button)
    if titlestate == "settings" then
        for i, v in pairs(settingsgui) do
            v:mousereleased(x, y, button)
        end
    end
end

return title