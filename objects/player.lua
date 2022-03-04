Player = class:new()

function Player:init(x, y)
    self.x, self.y = x+0.25, y-0.75
    self.w, self.h = 0.5, 1.75

    self.spawnx, self.spawny = self.x, self.y

    self.static = false
    self.active = true

    self.category = 1
    self.mask = {false, false, false, false}

    self.gravity = 40

    if LEVEL == 1 then
        self.animation = "intro"
        self.controlsenabled = false
        self.speedy = -20
    else
        self.animation = false
        self.controlsenabled = true
    end
    self.animationtimer = 0

    self.collidetable = {"box","ground"}

    self.maxspeed = 7
    self.acceleration = 10
    self.jumpspeed = 18
    self.duckjumpspeed = 6
    self.friction = 8
    self.walkfriction = 4

    self.jumping = false
    self.falling = false
    self.ducking = false
    self.grabbed = false

    self.frame = 1
    self.dir = 1

    self.idletimer = 0
    self.walktimer = 0

    self.maxhealth = 3
    self.health = self.maxhealth
    self.invincible = false

    self.quadcenterx = 8
    self.quadcentery = 16
    self.quadoffsetx = 0.25
    self.quadoffsety = 0.75
end

function Player:update(dt)
    -- auto move magigy
    if self.animation == "win" then
        if self.static then
            return
        end

        self.animationtimer = self.animationtimer + dt
        if self.animationtimer > 1 then
            self.speedx = self.maxspeed
        end
        if self.x > MAPWIDTH then
            self.static = true
            LEVELWON = true
            NOTICEAWAIT, NOTICE = false
        end
    elseif self.animation == "dead" then
        self.frame = 9
        if self.y > MAPHEIGHT then
            self:respawn()
        end
        return
    end

    -- owwie
    if self.invincible then
        self.invincible = self.invincible - dt
        if self.invincible <= 0 then
            self.invincible = false
        end
    end

    -- falling
    if self.jumping and self.speedy > 0 then
        self.jumping = false
        self.falling = true
    end

    if self.controlsenabled then
        -- duck!!!
        if (not self.jumping) and (not self.falling) and (not self.grabbed) then
            if (not self.ducking) and love.keyboard.isDown(CONTROLS["duck"]) then
                self.ducking = true
                self.h, self.y = 0.875, self.y+0.875
                self.quadoffsety = -0.125
            elseif self.ducking and (not love.keyboard.isDown(CONTROLS["duck"])) then
                if #collidecheck(self,self.x,self.y-0.875,self.w,0.875,{"ground"}) == 0 then
                    self.ducking = false
                    self.h, self.y = 1.75, self.y-0.875
                    self.quadoffsety = 0.75
                end
            end
        end

        if (not self.ducking) or self.jumping then
            -- momentm
            if love.keyboard.isDown(CONTROLS["left"]) and (not love.keyboard.isDown(CONTROLS["right"])) and self.speedx > -self.maxspeed then
                self.speedx = self.speedx - self.acceleration * dt
                if self.speedx < 0 then self.dir = -1 end
            elseif love.keyboard.isDown(CONTROLS["right"]) and (not love.keyboard.isDown(CONTROLS["left"]))  and self.speedx < self.maxspeed then
                self.speedx = self.speedx + self.acceleration * dt
                if self.speedx > 0 then self.dir = 1 end
            end

            -- frick-tion
            if (love.keyboard.isDown(CONTROLS["left"]) and self.speedx < 0) or (love.keyboard.isDown(CONTROLS["right"]) and self.speedx > 0) then
                self.horfriction = self.walkfriction
            else
                self.horfriction = self.friction
            end
        end
    end

    -- grabbbbb
    if self.grabbed then
        self.grabbed.x, self.grabbed.y = self.x-0.25, self.y-1
    end

    -- animation
    if self.ducking then
        self.frame = 8
    elseif self.jumping or self.falling then
        self.frame = 7
    else
        if math.abs(self.speedx) < 0.2 then
            self.walktimer = 0
            self.idletimer = self.idletimer + dt
            self.frame = math.ceil((self.idletimer*2)%2) -- 1 > 2
        else
            self.idletimer = 0
            self.walktimer = self.walktimer + dt
            self.frame = math.ceil((self.walktimer*8)%4)+2 -- 3 > 6
        end
    end

    -- set xscroll
    XSCROLL = math.min(math.max(self.x-(_env.width/32)+(self.w/2), 0),MAPWIDTH-(_env.width/16))
    XSCROLL = round(XSCROLL*16)/16
    if self.y > _env.height/16 then
        self:hurt(self.maxhealth, true)
    end

    -- winnnn
    if self.x > MAPWIDTH-5 and (self.animation ~= "win") then
        self.controlsenabled = false
        self.speedx = 0
        self.animation = "win"
        self.animationtimer = 0
        music:stop()
    end
end

function Player:draw()
    local g = 1
    if self.grabbed then g = 2 end
    if self.invincible and self.invincible%0.1 > 0.05 then return end
    love.graphics.draw(playerimg, playerquads[self.frame][g], (self.x+self.quadoffsetx-XSCROLL)*16, (self.y+self.quadoffsety)*16, 0, self.dir, 1, self.quadcenterx, self.quadcentery)
end

function Player:jump(speed)
    if not speed then
        if self.ducking then
            speed = self.duckjumpspeed
        else
            speed = self.jumpspeed
        end
    end
    -- don't jump if jumping + falling
    if (not self.jumping) and (not self.falling) then
        self.speedy = -speed
        self.jumping = true
        playsound(jumpsound)
    end
end

function Player:stopjump()
    -- holding jump will make you jump higher
    if self.speedy < 0 then
        self.speedy = self.speedy/2
    end
end

function Player:grab()
    if self.ducking then return end
    if self.grabbed then
        local obj = self.grabbed
        if #collidecheck(obj,obj.x,obj.y,obj.w,obj.h,{"ground","box"}) == 0 then
            self.grabbed.active = self.grabbedold.active
            self.grabbed.speedx, self.grabbed.speedy = self.dir*4, -4
            self.grabbed.y = self.grabbed.y -0.125
            self.grabbed.grabbed = nil
            self.grabbed = false
            playsound(pickupsound)
        end
    else
        local col = collidecheck(self,self.x-0.5,self.y-0.5,self.w+1,self.h+0.5,{"box"})
        if #col > 0 then
            local obj = col[1][2]
            self.grabbed = obj
            obj.grabbed = self

            self.grabbedold = {active=obj.active}
            obj.active = false
            obj.x, obj.y = self.x-0.25, self.y-1
            playsound(pickupsound)
        end
    end
end

function Player:hurt(health, instantrespawn)
    self.health = self.health - health
    if self.health <= 0 then
        playsound(deadsound)
        if instantrespawn then
            self:respawn()
            return
        end
        self.mask = {true,true,true,true}
        self.speedx, self.speedy = math.random(-8,8), -12
        self.horfriction = false
        self.animation = "dead"
    else
        playsound(hitsound)
        self.invincible = 1
    end
end

function Player:respawn()
    self.health = self.maxhealth
    self.x, self.y = self.spawnx, self.spawny
    self.h = 1.75
    self.speedx, self.speedy = 0, 0
    self.quadoffsety = 0.75
    self.jumping, self.falling, self.ducking = false, false, false
    self.mask = {false, false, false, false}
    
    self.animation = false

    if self.grabbed then
        self.grabbed.active = self.grabbedold.active
        self.grabbed.respawning = true
        self.grabbed.grabbed = nil
        self.grabbed = false
    end

    if LEVEL == 4 then DUST = {x=0, speed=4} end
end

function Player:startfall()
    self.falling = true
end

function Player:floorcollide(a,b)
    if self.animation == "intro" then
        self.controlsenabled = true
        self.animation = false
    end
    self.jumping = false
    self.falling = false
    if math.abs(self.speedy) > 1 then
        newparticle(self.x+0.125, self.y+self.h, "landl")
        newparticle(self.x+0.375, self.y+self.h, "landr")
        playsound(landsound)
    end
    return true
end

function Player:leftcollide(a,b)
    return self:sidecollide(a,b,"left")
end

function Player:rightcollide(a,b)
    return self:sidecollide(a,b,"right")
end

function Player:sidecollide(a,b,side)
    if a == "ground" and math.abs((self.y+self.h)-(b.y)) <= 0.5 and (not self.ducking) and (not self.jumping) then
        self.y = b.y-self.h-0.01
        self.speedy = 0
        self.falling = false
        return false
    end
    return true
end

-- don't ask whey they are in player lol.
Particle = class:new()

function Particle:init(x, y, t)
    self.x, self.y = x, y

    if t == "landl" or t == "landr" then
        self.speedx = 2
        if t == "landl" then self.speedx = -2 end
        self.frames = {frames={1,2,3}, time=0.1}
        self.lifetime = 0.3
    elseif t == "appear" then
        self.frames = {frames={4,5,6}, time=0.1}
        self.lifetime = 0.3
    elseif t == "yay" then
        self.frames = {frames={7}}
        self.lifetime = 3
        self.gravity = 8

        local time = math.random()*math.pi*2
        self.speedx, self.speedy = math.sin(time)*2, -4+math.cos(time)*2
        self.color = {math.random(0,255),math.random(0,255),math.random(0,255)}
        self.rot = math.random(1,4)*(math.pi/2)
        playsound(hitsound)
    end

    self.frametimer = 0
    self.frame = 1
end

function Particle:update(dt)
    -- fram
    if #self.frames.frames > 1 then
        self.frametimer = self.frametimer + dt
        if self.frametimer >= self.frames.time then
            self.frame = self.frame + 1
            self.frametimer = self.frametimer - self.frames.time
            if self.frame > #self.frames.frames then
                self.frame = 1
            end
        end
    end

    -- time till ded
    self.lifetime = self.lifetime - dt
    if self.lifetime <= 0 then
        self.deletemepls = true
    end

    -- sped
    if self.gravity then
        self.speedy = self.speedy + self.gravity * dt
    end
    if self.speedx then
        self.x = self.x + self.speedx * dt
    end
    if self.speedy then
        self.y = self.y + self.speedy * dt
    end
end

function Particle:draw()
    if self.color then love.graphics.setColor(self.color) end
    love.graphics.draw(particleimg, particlequads[self.frames.frames[self.frame]], (self.x-XSCROLL)*16, self.y*16, self.rot, 1, 1, 4, 4)
    love.graphics.setColor(255,255,255)
end