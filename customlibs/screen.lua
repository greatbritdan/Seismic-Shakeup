-- Made by Aidan
-- handles screen states, transitions, etc

Screen = {}
Screens = {}
for i, v in pairs(love.filesystem.getDirectoryItems("screens")) do
    local name = v:sub(1,-5)
    Screens[name] = require("screens/" .. name)
end

function Screen:init()
    self.state = false
    self.laststate = false
    self.nextstate = false

    self.transition, self.transtimer = false, 0 -- transition = {type, time}
    self.translock = {"mousepressed", "mousereleased", "keypressed", "textinput", "keyreleased", "wheelmoved"}
end

function Screen:update(dt)
    self:runFunc("update", {dt})
    if self.transition then
        self:updateTransition(dt)
    end
end

function Screen:draw()
    love.graphics.push()
    love.graphics.scale(_env.scale,_env.scale)
    self:runFunc("draw")
    if self.transition then
        self:drawTransition()
    end
    love.graphics.pop()
end

function Screen:mousepressed(x, y, button)
    x, y = math.floor(x/_env.scale), math.floor(y/_env.scale)
    self:runFunc("mousepressed", {x, y, button})
end
function Screen:mousereleased(x, y, button)
    x, y = math.floor(x/_env.scale), math.floor(y/_env.scale)
    self:runFunc("mousereleased", {x, y, button})
end
function Screen:keypressed(key)
    self:runFunc("keypressed", {key})
end
function Screen:keyreleased(key)
    self:runFunc("keyreleased", {key})
end
function Screen:textinput(key)
    self:runFunc("textinput", {key})
end
function Screen:wheelmoved(x, y)
    self:runFunc("wheelmoved", {x, y})
end
function Screen:mousemoved(x, y, dx, dy)
    self:runFunc("mousemoved", {x, y, dx, dy})
end

function Screen:changeTo(state)
    self.laststate = self.state
    self.state = (state or false)
    if self.state then
        self:runFunc("load", {self.laststate})
    end
end

function Screen:runFunc(func, args, state)
    args = (args or {})
    state = (state or self.state)
    if (not Screens[state]) or (self.transition and tablecontains(self.translock,func)) then
        return false
    end
    if Screens[state][func] then
        return Screens[state][func](unpack(args))
    end
end

function Screen:fadeTo(state, typ)
    self.nextstate = state
    if type(typ) ~= "table" then
        typ = {typ, 1}
    end
    self.transition = typ
    self.transtimer = 0
end

function Screen:updateTransition(dt)
    self.transtimer = self.transtimer + dt
    if self.transtimer >= self.transition[2] then
        self.transition, self.transtimer = false, 0
        return
    end
    if self.transition[1] == "fade" and self.transtimer >= self.transition[2]/2 and self.nextstate then
        self:changeTo(self.nextstate)
        self.nextstate = false
    end
end

function Screen:drawTransition()
    local time, timer = self.transition[2], self.transtimer
    if self.transition[1] == "fade" then
        if timer >= time/2 then
            love.graphics.setColor(0,0,0,255-((timer-(time/2))*(510/time)))
        else
            love.graphics.setColor(0,0,0,timer*(510/time))
        end
        love.graphics.rectangle("fill",0,0,WIDTH,HEIGHT)
    end
    love.graphics.setColor(255,255,255)
end

Screen:init()