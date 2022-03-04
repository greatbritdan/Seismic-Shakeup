function love.conf(t)
    env = require("env")

    t.window.width = env.width*env.scale
    t.window.height = env.height*env.scale
    t.window.vsync = env.vsync
    
    WIDTH, HEIGHT = env.width, env.height

    t.version = "0.10.2"
    t.identity = "seismic shake up"
    t.window.title = "Seismic Shake-Up"
end