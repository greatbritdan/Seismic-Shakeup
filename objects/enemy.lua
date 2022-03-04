Enemy = class:new()

function Enemy:init(x, y, t)
    self.x, self.y = x, y

    self.static = false
    self.active = true

    self.category = 4
    self.mask = {true, false, false, false}

    self.speedx, self.speedy = 0, 0
    self.dir = 1
    self.ledgedelay = 0

    self.frametimer = 0
    self.frame = 1

    self.t = t
    if t == "car" then
        self.w, self.h = 3.5, 1.5
        self.speedx = -4
        self.damage = 2

        self.quadcenterx = 32
        self.quadcentery = 16
        self.quadoffsetx = 1.75
        self.quadoffsety = 0.5
        self.img, self.quads = carimg, carquads
    elseif t == "rat" or t == "debris" then
        self.w, self.h = 0.75, 0.375
        if t == "rat" then
            self.speedx = -2
            self.damage = 1
        else
            self.damage = 1
            self.frame = 3
            self.static = true
            self.falling = false
        end

        self.quadcenterx = 8
        self.quadcentery = 8
        self.quadoffsetx = 0.375
        self.quadoffsety = -0.125
        self.img, self.quads = enemiesimg, enemiesquads
    end
end

function Enemy:update(dt)
    if self.t ~= "debris" then
        self.frametimer = self.frametimer + dt
        self.frame = math.ceil((self.frametimer*8)%2)
    end

    if self.t ~= "debris" then
        -- turn on cliff
        if self.ledgedelay <= 0 then
            local x, y = round(self.x)+1, round(self.y+self.h)+1
            if MAP[STATE][y] and MAP[STATE][y][x] and (not tilequadsdata[MAP[STATE][y][x][1]].collision) then
                self.speedx = -self.speedx
                self.dir = -self.dir
                self.ledgedelay = 0.1
            end
        else
            self.ledgedelay = self.ledgedelay - self.ledgedelay
        end
    end

    -- hurty
    local p = OBJS["player"][1]
    if (not p.invincible) and (not p.animation) and aabb(self.x,self.y,self.w,self.h,p.x,p.y,p.w,p.h) then
        p.speedy = -10
        p.jumping = true
        p.speedx = 8
        if self.x > p.x then
            p.speedx = -8
        end
        p:hurt(self.damage)
    end
end

function Enemy:draw()
    love.graphics.draw(self.img, self.quads[((STATE-1)*2)+self.frame], (self.x+self.quadoffsetx-XSCROLL)*16, (self.y+self.quadoffsety)*16, 0, self.dir, 1, self.quadcenterx, self.quadcentery)
end

function Enemy:leftcollide(a,b)
    if a == "ground" or a == "box" then
        self.speedx = -self.speedx
        self.dir = -self.dir
    end
    return true
end

function Enemy:rightcollide(a,b)
    if a == "ground" or a == "box" then
        self.speedx = -self.speedx
        self.dir = -self.dir
    end
    return true
end

function Enemy:ceilcollide(a,b)
    if a == "box" then
        if self.t == "rat" then
            newparticle(self.x+(self.w/4), self.y+self.h, "landl")
            newparticle(self.x+((self.w/4)*3), self.y+self.h, "landr")
            playsound(smooshsound)
            self.deletemepls = true
        elseif self.t == "car" then
            b.respawning = true
            return false
        end
    end
    return true
end