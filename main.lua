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
    video = love.graphics.newVideo(chosenVideo)
    video:play()
end

function love.load(gameArgs)
    if not gameArgs[1] then
        error("You must specify a file path to a video file to play as an argument!")
    end
    chosenVideo = gameArgs[1]
    handle.initasync()
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