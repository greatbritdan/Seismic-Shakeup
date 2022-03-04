-- box my beloved

Box = class:new()

function Box:init(x, y, b)
    self.x, self.y = x, y
    self.w, self.h = 1, 1

    self.startx, self.starty = self.x, self.y

    self.static = false
    self.active = true

    self.category = 2
    self.mask = {false, false, true, false}

    self.horfriction = 8
    
    self.respawning = false

    self.quadcenterx = 8
    self.quadcentery = 8
    self.quadoffsetx = 0.5
    self.quadoffsety = 0.5

    self.frame = 1
    if b then
        self.gravity = 40
        self.metal = true
        self.frame = 2
    end
end

function Box:update(dt)
    if (self.respawning or self.y > MAPHEIGHT) and #collidecheck(self,self.startx,self.starty,self.w,self.h,{"player"}) == 0 then
        self.x, self.y = self.startx, self.starty
        self.respawning = false
        newparticle(self.x+0.5, self.y+0.5, "appear")
    end
end

function Box:draw()
    if self.respawning then return end
    love.graphics.draw(boximg, boxquads[self.frame], (self.x+self.quadoffsetx-XSCROLL)*16, (self.y+self.quadoffsety)*16, 0, 1, 1, self.quadcenterx, self.quadcentery)
end

function Box:floorcollide(a,b)
    if a == "enemy" then
        return false
    end
    if a == "ground" and self.metal and b.breakable then
        settile(true, b.tx, b.ty, 1, 1)
        local i, pass = 0, true
        while pass == true do
            i = i + 1
            pass = false
            if gettile(STATE, b.tx+i, b.ty, "breakable") then
                settile(true, b.tx+i, b.ty, 1, 1)
                pass = true
            end
            if gettile(STATE, b.tx-i, b.ty, "breakable") then
                settile(true, b.tx-i, b.ty, 1, 1)
                pass = true
            end
        end
        generatespritebatch(1)
        generatespritebatch(2)
        playsound(hitsound)
    end
    if math.abs(self.speedy) > 1 then
        newparticle(self.x+0.25, self.y+self.h, "landl")
        newparticle(self.x+0.75, self.y+self.h, "landr")
        playsound(landsound)
    end
    return true
end