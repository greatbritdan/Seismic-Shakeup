local intro = {}

intro.introtexts = {""}

function intro.load(last)
    love.graphics.setBackgroundColor(0,0,0)

    intro.titleimage = love.graphics.newImage("images/titleimage.png")
    intro.titlequads = {
        love.graphics.newQuad(0, 0, 24, 24, 150, 32),
        love.graphics.newQuad(25, 0, 24, 24, 150, 32),
        love.graphics.newQuad(50, 0, 24, 24, 150, 32),
        love.graphics.newQuad(75, 0, 24, 24, 150, 32),
        love.graphics.newQuad(100, 0, 24, 24, 150, 32),
        love.graphics.newQuad(125, 0, 24, 24, 150, 32),
        love.graphics.newQuad(0, 25, 142, 2, 150, 32)
    }
    intro.titletimer = 0

    local far = (WIDTH/2)-71
    intro.titleletters = {
        {q=2, x=far, y=-24, speed=0.1, bounce=false},
        {q=3, x=far+24, y=-24, speed=0.1, bounce=false},
        {q=4, x=far+48, y=-24, speed=0.1, bounce=false},
        {q=5, x=far+72, y=-24, speed=0.1, bounce=false},
        {q=6, x=far+96, y=-24, speed=0.1, bounce=false},
        {q=1, x=far+120, y=-24, speed=0.1, bounce=false},
        {q=7, x=far, y=(HEIGHT/2)+13}
    }

    local introtexti = math.random(#intro.introtexts)
    intro.introtext = intro.introtexts[introtexti]
end

function intro.update(dt)
    if intro.titletimer > 3 then return end
    
    intro.titletimer = intro.titletimer + dt
    local timer = intro.titletimer
    if timer > 0.25 and timer <= 2.5 then
        for i = 1, math.floor(timer*4) do
            if i > 6 then break end
            local v = intro.titleletters[i]
            if v.y < (HEIGHT/2)-13 then
                v.y = math.min(v.y + v.speed, (HEIGHT/2)-13)
                v.speed = v.speed + dt*1.5
            elseif not v.bounce then
                v.bounce = true
                v.speed = -0.15
                v.y = math.min(v.y + v.speed, (HEIGHT/2)-13)
            end
        end
    elseif intro.titletimer > 3 then
        Screen:fadeTo("title", {"fade", 0.6})
    end
end

function intro.draw()
    love.graphics.setColor(255,255,255)
    for i, v in pairs(intro.titleletters) do
        love.graphics.draw(intro.titleimage, intro.titlequads[v.q], v.x, v.y, 0)
    end
    love.graphics.printf(intro.introtext, 0, HEIGHT-18, WIDTH, "center")
end

function intro.keypressed()
    Screen:fadeTo("title", {"fade", 0.6})
end
function intro.mousepressed()
    Screen:fadeTo("title", {"fade", 0.6})
end

return intro