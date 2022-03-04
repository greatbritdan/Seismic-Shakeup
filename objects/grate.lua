Grate = class:new()

function Grate:init(x, y)
    self.x, self.y = x, y
    self.w, self.h = 1, 0.375

    self.static = true
    self.active = true

    self.category = 3
    self.mask = {false, true, false, false}

    self.platformdown = true
    
    self.frame = 1
    self.open = false
    self.timer = 1

    self.quadcenterx = 8
    self.quadcentery = 7.5
    self.quadoffsetx = 0.5
    self.quadoffsety = 0.15625
end

function Grate:update(dt)
    -- did its state change?
    local col = #collidecheck(self, self.x, self.y, self.w, self.h, {"player"})
    if col > 0 and (not self.open) then
        self.open = true
        self.frame = 1
        self.timer = 0
    elseif col == 0 and self.open then
        self.open = false
        self.frame = 3
        self.timer = 0
    end
    
    self.timer = self.timer + dt
    if self.timer <= 0.21 then
        if self.open then
            if self.frame == 1 and self.timer >= 0.1 then self.frame = 2 end
            if self.frame == 2 and self.timer >= 0.2 then self.frame = 3 end
        else
            if self.frame == 3 and self.timer >= 0.1 then self.frame = 4 end
            if self.frame == 4 and self.timer >= 0.2 then self.frame = 1 end
        end
    end
end

function Grate:draw()
    love.graphics.draw(grateimg, gratequads[self.frame], (self.x+self.quadoffsetx-XSCROLL)*16, (self.y+self.quadoffsety)*16, 0, 1, 1, self.quadcenterx, self.quadcentery)
end