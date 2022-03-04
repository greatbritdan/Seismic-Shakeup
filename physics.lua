-- MADE BY AIDAN --

-- MASKS
-- 1. player
-- 2. ground/box
-- 3. grate
-- 4. enemies

function aabb(ax, ay, aw, ah, bx, by, bwidth, bheight)
	return ax+aw > bx and ax < bx+bwidth and ay+ah > by and ay < by+bheight
end

local collision_check, collision_hor, collision_ver, collision_passive
function physics_update(dt)
    -- run through every object
    for og1, _ in pairs(OBJS) do
        if og1 ~= "ground" then
            for i1, v1 in pairs(OBJS[og1]) do
                if ((not v1.STATE) or v1.STATE == STATE) and (not v1.static) and v1.active then
                    -- gravity
                    v1.speedy = v1.speedy + (v1.gravity or 20)*dt

                    -- check for collisions (objects)
                    local horcol, vercol = false, false
                    for og2, __ in pairs(OBJS) do
                        if og2 ~= "ground" then
                            for i2, v2 in pairs(OBJS[og2]) do
                                -- if not itself and active
                                if ((not v2.STATE) or v2.STATE == STATE) and (i1 ~= i2 or v1 ~= v2) and v2.active and (v1.mask == nil or v1.mask[v2.category] ~= true) and (v2.mask == nil or v2.mask[v1.category] ~= true) then
                                    local horcheck, vercheck = collision_check(og1, i1, v1, og2, i2, v2, dt)
                                end
                                if horcheck then horcol = true end
                                if vercheck then vercol = true end
                            end
                        end
                    end

                    -- check for collisions (tiles)
                    local sx, sy = math.floor(v1.x), math.floor(v1.y)
                    local sw, sh = v1.w+2, v1.h+2
                    for x = sx, sx+sw do
                        for y = sy, sy+sh do
                            og2, i2, v2 = "ground", gettileind(x,y,STATE), OBJS["ground"][gettileind(x,y,STATE)]
                            if v2 then
                                if ((not v2.STATE) or v2.STATE == STATE) and (v1.mask == nil or v1.mask[v2.category] ~= true) and (v2.mask == nil or v2.mask[v1.category] ~= true) then
                                    local horcheck, vercheck = collision_check(og1, i1, v1, og2, i2, v2, dt)
                                end
                                if horcheck then horcol = true end
                                if vercheck then vercol = true end
                            end
                        end
                    end

                    -- x friction
                    if v1.horfriction then
                        if v1.speedx > 0 then
                            v1.speedx = math.max(0, v1.speedx-v1.horfriction*dt)
                        else
                            v1.speedx = math.min(0, v1.speedx+v1.horfriction*dt)
                        end
                    end
                    -- x movement
                    if not horcol then
                        v1.x = v1.x + v1.speedx*dt
                    end
                    
                    -- y friction
                    if v1.verfriction then
                        if v1.speedy > 0 then
                            v1.speedy = math.max(0, v1.speedy-v1.verfriction*dt)
                        else
                            v1.speedy = math.min(0, v1.speedy+v1.verfriction*dt)
                        end
                    end
                    -- y movement
                    if not vercol then
                        v1.y = v1.y + v1.speedy*dt
                        local grav = v1.gravity or 20
                        if v1.speedy == grav*dt and v1.startfall then
                            v1:startfall()
                        end
                    end

                    -- thats all folks
                end
            end
        end
    end
end

function collision_check(og1, i1, v1, og2, i2, v2, dt)
    local horcheck, vercheck = false, false

    -- are they close enough
    if math.abs(v1.x - v2.x) < math.max(v1.w, v2.w)+1 and math.abs(v1.y - v2.y) < math.max(v1.h, v2.h)+1 then
        if aabb(v1.x, v1.y, v1.w, v1.h, v2.x, v2.y, v2.w, v2.h) then
            -- passive collision
            if collision_passive(og1, i1, v1, og2, i2, v2, d) then
                vercheck = true
            end
        end
        if aabb(v1.x + v1.speedx*dt, v1.y + v1.speedy*dt, v1.w, v1.h, v2.x, v2.y, v2.w, v2.h) then
            -- have they just overlapped
            if aabb(v1.x + v1.speedx*dt, v1.y, v1.w, v1.h, v2.x, v2.y, v2.w, v2.h) then
                -- horizontal collison
                if collision_hor(og1, i1, v1, og2, i2, v2, dt) then
                    horcheck = true
                end
            elseif aabb(v1.x, v1.y + v1.speedy*dt, v1.w, v1.h, v2.x, v2.y, v2.w, v2.h) then
                -- vertical collison
                if collision_ver(og1, i1, v1, og2, i2, v2, dt) then
                    vercheck = true
                end
            else 
                -- jank diagonal collision
                local grav = (v1.gravity or 20)
                if math.abs(v1.speedy-grav*dt) < math.abs(v1.speedx) then
                    if collision_ver(og1, i1, v1, og2, i2, v2, dt) then
                        vercheck = true
                    end
                else 
                    if collision_hor(og1, i1, v1, og2, i2, v2, dt) then
                        horcheck = true
                    end
                end
            end
        end
    end

    return horcheck, vercheck
end

function collision_hor(og1, i1, v1, og2, i2, v2, dt)
    if (v2.platformup or v2.platformdown) and not (v2.platformleft or v2.platformright) then
        return false
    end
    if v1.speedx < 0 then
        -- slide to the left (right for other)
        if (not v2.rightcollide) or v2:rightcollide(og1,v1) then
            if (not v2.dontstop) and v2.speedx > 0 then
                v2.speedx = 0
            end
        end

        if v2.platformleft and (not v2.platformright) then
            return false
        end
        if (not v1.leftcollide) or v1:leftcollide(og2,v2) then
            if (not v1.dontstop) and v1.speedx < 0 then
                v1.speedx = 0
            end
            v1.x = v2.x + v2.w --+ v2.speedx*dt
            return true
        end
    else
        -- slide to the right (left for other)
        if (not v2.leftcollide) or v2:leftcollide(og1,v1) then
            if (not v2.dontstop) and v2.speedx < 0 then
                v2.speedx = 0
            end
        end

        if v2.platformright and (not v2.platformleft) then
            return false
        end
        if (not v1.rightcollide) or v1:rightcollide(og2,v2) then
            if (not v1.dontstop) and v1.speedx > 0 then
                v1.speedx = 0
            end
            v1.x = v2.x - v1.w
            return true
        end
    end

    -- criss cross
    return false
end

function collision_ver(og1, i1, v1, og2, i2, v2, dt)
    if (v2.platformleft or v2.platformright) and not (v2.platformup or v2.platformdown) then
        return false
    end
    if v1.speedy < 0 then
        -- down (up for other)
        if (not v2.floorcollide) or v2:floorcollide(og1,v1) then
            if (not v2.dontstop) and v2.speedy > 0 then
                v2.speedy = 0
            end
        end

        if v2.platformdown and (not v2.platformup) then
            return false
        end
        if (not v1.ceilcollide) or v1:ceilcollide(og2,v2) then
            if (not v1.dontstop) and v1.speedy < 0 then
                v1.speedy = 0
            end
            v1.y = v2.y + v2.h
            return true
        end
    else
        -- up (down for other)
        if (not v2.ceilcollide) or v2:ceilcollide(og1,v1) then
            if (not v2.dontstop) and v2.speedy < 0 then
                v2.speedy = 0
            end
        end

        if v2.platformup and (not v2.platformdown) then
            return false
        end
        if (not v1.floorcollide) or v1:floorcollide(og2,v2) then
            if (not v1.dontstop) and v1.speedy > 0 then
                v1.speedy = 0
            end
            v1.y = v2.y - v1.h
            return true
        end
    end

    return false
end

-- :pacsive:
function collision_passive(og1, i1, v1, og2, i2, v2, dt)
    if v2.platformup or v2.platformdown or v2.platformleft or v2.platformright then
        return false
    end
    if v1.passivecollide then
        v1:passivecollide(og2,v2)
        if v2.passivecollide then
            v2:passivecollide(og1,v1)
        end
    end
    return false
end

-- check for collisons, useful for predicting the future. :mmaker:
function collidecheck(v, x, y, w, h, list, stateignore)
    local out = {}
    
    for og1, ol1 in pairs(OBJS) do
        local contains = false
        if list and list ~= "all" then	
            contains = tablecontains(list, og1)
        end

        if list == "all" or contains then
            for i1, v1 in pairs(ol1) do
                if (v ~= v1) and (stateignore or (not v1.STATE) or v1.STATE == STATE) and v1.active and ((not v1.static) or list ~= "all") then
                    if aabb(x, y, w, h, v1.x, v1.y, v1.w, v1.h) and (not v1.platformdown) then
                        table.insert(out, {og1, v1})
                    end
                end
            end
        end
    end

    return out
end