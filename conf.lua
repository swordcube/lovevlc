function love.conf(t)
    t.identity = "LoveVLCTest"
    t.version = "12.0"
    t.console = false

    t.graphics.gammacorrect = false

    t.highdpi = false
    t.usedpiscale = false

    t.window.title = "LÖVE VLC"

    t.window.width = 1280
    t.window.height = 720

    t.window.minwidth = 200
    t.window.minheight = 0

    t.window.resizable = true
    t.window.vsync = false
end
