-- weird hack required for this demo
-- you shouldn't have to do anything like this when using the lib yourself

require("init")
_G.LOVEVLC_PARENT = ""

-- demo

local handle = require("util.handle")

local initVid = false
local chosenVideo = ""

local video = nil --- @type love.Video
local function playVideo()
    video = love.graphics.newVideo(chosenVideo, {audio = true})
    video:play()
end

function love.load(gameArgs)
    if not gameArgs[1] then
        error("You must specify a file path to a video file to play as an argument!")
    end
    chosenVideo = gameArgs[1]
    handle.initasync()
end

function love.run()
    if love.load then love.load(love.parsedGameArguments, love.rawGameArguments) end

    -- We don't want the first frame's dt to include time taken by love.load.
    if love.timer then love.timer.step() end

    -- Main loop time.
    return function()
        -- Process events.
        if love.event then
            love.event.pump()
            for name, a,b,c,d,e,f,g,h in love.event.poll() do
                if name == "quit" then
                    if c or not love.quit or not love.quit() then
                        return a or 0, b
                    end
                end
                love.handlers[name](a,b,c,d,e,f,g,h)
            end
        end

        -- Update dt, as we'll be passing it to update
        local dt = love.timer and love.timer.step() or 0

        -- Call update and draw
        if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled

        if love.graphics and love.graphics.isActive() then
            love.graphics.origin()
            love.graphics.clear(love.graphics.getBackgroundColor())

            if love.draw then love.draw() end

            love.graphics.present()
        end
    end
end

function love.update()
    if handle.instance and not initVid then
        initVid = true
        playVideo()
    end
end

function love.draw()
    if video then
        love.graphics.draw(video, 0, 0, 0, love.graphics.getWidth() / video:getWidth(), love.graphics.getHeight() / video:getHeight())
    else
        love.graphics.print("Loading...", love.graphics.getWidth() / 2 - 50, love.graphics.getHeight() / 2 - 10)
    end
    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", 0, 0, 100, 30)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(love.timer.getFPS() .. " FPS", 10, 3)
end

function love.keypressed(k)
    if k == "space" then
        if video:isPlaying() then
            video:pause()
        else
            video:play()
        end
    end
end

function love.quit()
    video:release()
    handle.quit()
end