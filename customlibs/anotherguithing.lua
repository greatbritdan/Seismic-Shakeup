-- i gotta stop making GUI stuff

GuiElement = class:new()

function GuiElement:init(...)
    local args = {...}
    self.t, self.x, self.y = args[1], args[2], args[3]
    if self.t == "button" then
        self.text = args[4]
        self.w = round(font:getWidth(self.text)/2)*2
        self.func = args[5]
    elseif self.t == "checkbox" then
        self.value = false
        self.w = 10
        self.func = args[4]
    elseif self.t == "slider" then
        self.w = args[4]
        self.func = args[5]
        self.value = 0.5
        self.grabbed = false
    elseif self.t == "text" then
        self.text = args[4]
        self.w = font:getWidth(self.text)
    end
    if self.x == "center" then
        self.x = (_env.width/2)-((self.w+8)/2)
    end
end

function GuiElement:update(dt)
    if self.t == "slider" and self.grabbed then
        local x = getX()
        self.value = math.min(1, math.max(self.ogvalue+((x-self.grabbed)/100), 0))
    end
end

function GuiElement:draw()
    local a = 175
    if self.t ~= "text" and self:inhighlight(getXY()) then
        a = 225
    elseif self.t == "text" then
        a = 255
    end
    love.graphics.setColor(255,255,255,a)
    if self.t == "button" then
        love.graphics.draw(guiimg, guiquad["buttonl"], self.x, self.y)
        love.graphics.draw(guiimg, guiquad["buttonm"], self.x+4, self.y, 0, self.w, 1)
        love.graphics.draw(guiimg, guiquad["buttonr"], self.x+self.w+4, self.y)

        love.graphics.setColor(155,155,155,a)
        drawtext(self.text, self.x+4, self.y+4)
        love.graphics.setColor(255,255,255,a)
        drawtext(self.text, self.x+4, self.y+3)
    elseif self.t == "checkbox" then
        love.graphics.draw(guiimg, guiquad["buttonl"], self.x, self.y)
        love.graphics.draw(guiimg, guiquad["buttonm"], self.x+4, self.y, 0, 10, 1)
        love.graphics.draw(guiimg, guiquad["buttonr"], self.x+14, self.y)
        if self.value then
            love.graphics.setColor(155,155,155,a)
            drawtext("*", self.x+5, self.y+4)
            love.graphics.setColor(255,255,255,a)
            drawtext("*", self.x+5, self.y+3)
        end
    elseif self.t == "slider" then
        love.graphics.setColor(155,155,255,a)
        love.graphics.rectangle("fill",self.x+4,self.y+4,self.w*self.value,8)
        love.graphics.setColor(255,255,255,a)
        love.graphics.draw(guiimg, guiquad["sliderl"], self.x, self.y)
        love.graphics.draw(guiimg, guiquad["sliderm"], self.x+4, self.y, 0, self.w, 1)
        love.graphics.draw(guiimg, guiquad["sliderr"], self.x+self.w+4, self.y)
    elseif self.t == "text" then
        love.graphics.setColor(155,155,155,a)
        drawtext(self.text, self.x+4, self.y)
        love.graphics.setColor(255,255,255,a)
        drawtext(self.text, self.x+4, self.y-1)
    end
end

function GuiElement:inhighlight(x,y)
    if self.t == "button" or self.t == "slider" then
        if aabb(x,y,1,1,self.x,self.y,self.w+8,18) then
            return true
        end
    elseif self.t == "checkbox" then
        if aabb(x,y,1,1,self.x,self.y,18,18) then
            return true
        end
    end
end

function GuiElement:mousepressed(x, y, button)
    if self.t == "text" or button ~= 1 then return end

    if self:inhighlight(x, y) then
        if self.t == "button" then
            playsound(blipsound)
            if self.func then
                self:func()
            end
        elseif self.t == "checkbox" then
            self.value = not self.value
            playsound(blipsound)
            if self.func then
                self:func()
            end
        elseif self.t == "slider" then
            self.grabbed = x
            self.ogvalue = self.value
        end
    end
end

function GuiElement:mousereleased(x, y, button)
    if self.t == "slider" and self.grabbed then
        playsound(blipsound)
        if self.func then
            self:func()
        end
        self.grabbed = false
    end
end