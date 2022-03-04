Ground = class:new()

function Ground:init(x, y, data)
    self.x, self.y = x, y
    self.w, self.h = 1, 1
    self.tx, self.ty = x+1, y+1

    self.static = true
    self.active = true

    self.category = 2
    self.mask = {false, false, true, false}

    if data.half then
        self.h =  0.5
        if data.half == "bottom" then
            self.y = self.y+0.5
        end
    end
    if data.platform then
        self.platformdown = true
    end
    if data.breakable then
        self.breakable = true
    end
end

Ceilblocker = class:new()
-- yes will, i didn't forget them, they're automatic B)

function Ceilblocker:init(x, y, data)
    self.x, self.y = x, y-100
    self.w, self.h = 1, 100

    self.static = true
    self.active = true

    self.category = 2
    self.mask = {false}
end