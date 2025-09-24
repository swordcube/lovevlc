local jit = require("jit")
local ffi = require("ffi")

local libdir = _G.LOVEVLC_LIB_DIRECTORY or "lib"
local plugindir = _G.LOVEVLC_PLUGIN_DIRECTORY or "plugins"

local osm = os
local os = jit and jit.os or ffi.os

-- add os.setenv for plugin folder!
if os == "Windows" then
    ffi.cdef[[
        int _putenv(const char *envstring);
    ]]
    --- Sets an environment variable in the current process
    --- @param name string
    --- @param value string
    osm.setenv = function(name, value)
        ffi.C._putenv(name .. "=" .. value)
    end
else
    ffi.cdef[[
      int setenv(const char *name, const char *value, int overwrite);
    ]]
    --- Sets an environment variable in the current process
    --- @param name string
    --- @param value string
    osm.setenv = function(name, value)
        ffi.C.setenv(name, value, 1)
    end
end
print(love.filesystem.getExecutablePath())
if os == "Windows" or os == "OSX" then
    -- make sure to set plugin path or else it won't work on windows !   lol!
    local pp = love.filesystem.getExecutablePath() .. "/" .. plugindir .. "/" .. os -- hehe
    os.setenv("VLC_PLUGIN_PATH", pp)
end

local extension = os == "Windows" and "dll" or os == "Linux" and "so" or os == "OSX" and "dylib"
package.cpath = string.format("%s;%s/?.%s", package.cpath, libdir, extension)

-- this isn't technically used, but needs to be loaded for libvlc to load on windows!
local vlccore = os == "Windows" and ffi.load(assert(package.searchpath("win64/libvlccore", package.cpath)):gsub("/", "\\")) or ffi.load("libvlccore")

-- this IS used though
local vlc = os == "Windows" and ffi.load(assert(package.searchpath("win64/libvlc", package.cpath)):gsub("/", "\\")) or ffi.load("libvlc")
local vlcWrapper = nil

if os == "Windows" then
    -- windows (load dll from win64 folder)
    vlcWrapper = ffi.load(assert(package.searchpath("win64/libvlc_wrapper", package.cpath)))
    
elseif os == "Linux" then
    -- linux (load so from linux folder)
    vlcWrapper = ffi.load(assert(package.searchpath("linux/libvlc_wrapper", package.cpath)))
    
elseif os == "OSX" then
    -- macos (load dylib from mac folder)
    vlcWrapper = ffi.load(assert(package.searchpath("mac/libvlc_wrapper", package.cpath)))
else
    error(("Unsupported OS: %s"):format(os))
end
require("libvlc_h")
ffi.cdef [[\
    typedef struct {
        unsigned char* pixelBuffer;
        unsigned int width;
        unsigned int height;
    } LuaVLC_Video;

    LuaVLC_Video luavlc_new(void);
    LuaVLC_Video luavlc_free(LuaVLC_Video video);

    unsigned char* luavlc_new_pixel_buffer(unsigned int width, unsigned int height);
    unsigned char* luavlc_free_pixel_buffer(unsigned char* pixelBuffer);
    
    void video_use_unlock_callback(libvlc_media_player_t *mp, void *opaque);
    void video_use_all_callbacks(libvlc_media_player_t *mp, void *opaque);
    bool can_update_texture(void);
]]

local vlcData = {
    inst = nil,
    mediaPlayer = nil
}
local renderedVideo = false
local luaVlcVideo = nil

local loveImageData = nil --- @type love.ImageData
local loveImage = nil --- @type love.Image

function love.load(gameArgs)
    if not gameArgs[1] then
        error("You must specify a file path to a video file to play as an argument!")
    end
    local args = {
        "--ignore-config",
        "--drop-late-frames",
        "--aout=none",
        "--intf=none",
        "--vout=none",
        "--no-interact",
        "--no-keyboard-events",
        "--no-mouse-events",
        "--no-lua",
        "--no-snapshot-preview",
        "--no-sub-autodetect-file",
        "--no-video-title-show",
        "--no-volume-save",
        "--no-xlib",
        "--verbose=-1"
    }
    local argsPtr = ffi.new("const char *[?]", #args)
    for i = 1, #args do
        argsPtr[i - 1] = ffi.cast("const char *", args[i])
    end
    vlcData.inst = vlc.libvlc_new(#args, argsPtr)

    local media = vlc.libvlc_media_new_path(vlcData.inst, gameArgs[1])
    vlcData.mediaPlayer = vlc.libvlc_media_player_new_from_media(media)
    vlc.libvlc_media_release(media)

    renderedVideo = false

    luaVlcVideo = vlcWrapper.luavlc_new()
    ffi.gc(luaVlcVideo, nil) -- NO GC FOR YOU

    vlcWrapper.video_use_unlock_callback(vlcData.mediaPlayer, ffi.cast("void*", luaVlcVideo.pixelBuffer))
    vlc.libvlc_media_player_play(vlcData.mediaPlayer)
end

local function updatePixel(x, y, r, g, b, a)
    local idx = (x + (y * loveImageData:getWidth())) * 3
    r = tonumber(luaVlcVideo.pixelBuffer[idx + 0]) / 255.0
    g = tonumber(luaVlcVideo.pixelBuffer[idx + 1]) / 255.0
    b = tonumber(luaVlcVideo.pixelBuffer[idx + 2]) / 255.0
    a = 1.0 -- the pixel buffer is rgb8 only so we just have to force an alpha value of 1!
    return r, g, b, a
end

function love.update(dt)
    if not renderedVideo then
        local state = vlc.libvlc_media_player_get_state(vlcData.mediaPlayer)
        if state == 3 then -- 3 = playing
            local cw, ch = ffi.new("unsigned int[1]"), ffi.new("unsigned int[1]")
            vlc.libvlc_video_get_size(vlcData.mediaPlayer, 0, cw, ch)
            
            local w, h = tonumber(cw[0]), tonumber(ch[0])
            if w > 0 and h > 0 then
                luaVlcVideo.width = cw[0]
                luaVlcVideo.height = ch[0]

                vlc.libvlc_video_set_format(vlcData.mediaPlayer, "RV24", w, h, w * 3)
                luaVlcVideo.pixelBuffer = vlcWrapper.luavlc_new_pixel_buffer(w, h)
                vlcWrapper.video_use_all_callbacks(vlcData.mediaPlayer, ffi.cast("void*", luaVlcVideo.pixelBuffer))
                
                loveImageData = love.image.newImageData(w, h, "rgba8")
                loveImage = love.graphics.newImage(loveImageData)
                
                renderedVideo = true
            end
        end
    else
        local state = vlc.libvlc_media_player_get_state(vlcData.mediaPlayer)
        if state == 3 and vlcWrapper.can_update_texture() and loveImageData then
            -- method 1 (slow)
            -- for x = 1, loveImageData:getWidth() do
            --     for y = 1, loveImageData:getHeight() do
            --         local idx = ((x - 1) + ((y - 1) * loveImageData:getWidth())) * 3
            --         loveImageData:setPixel(x - 1, y - 1, tonumber(luaVlcVideo.pixelBuffer[idx + 0]) / 255, tonumber(luaVlcVideo.pixelBuffer[idx + 1]) / 255, tonumber(luaVlcVideo.pixelBuffer[idx + 2]) / 255, 1)
            --     end
            -- end

            -- method 2 (faster, but still quite slow)
            -- loveImageData:mapPixel(updatePixel)

            -- method 3 (ffi way, Might be faster)
            -- local ptr = ffi.cast("unsigned char*", loveImageData:getFFIPointer())
            -- ffi.copy(ptr, luaVlcVideo.pixelBuffer, loveImageData:getWidth() * loveImageData:getHeight() * 3)

            local w, h = loveImageData:getWidth(), loveImageData:getHeight()
            local src = ffi.cast("unsigned char*", luaVlcVideo.pixelBuffer) -- RGB8 source
            local dst = ffi.cast("unsigned char*", loveImageData:getFFIPointer())  -- RGBA8 destination

            local srcIndex, dstIndex = 0, 0
            local numPixels = w * h

            for _ = 0, numPixels - 1 do
                -- Copy R,G,B
                dst[dstIndex] = src[srcIndex] -- R
                dst[dstIndex + 1] = src[srcIndex + 1] -- G
                dst[dstIndex + 2] = src[srcIndex + 2] -- B
                dst[dstIndex + 3] = 255              -- A (fully opaque)

                srcIndex = srcIndex + 3
                dstIndex = dstIndex + 4
            end
            loveImage:replacePixels(loveImageData)
        end
    end
end

function love.draw()
    if loveImage then
        love.graphics.draw(loveImage, 0, 0, 0, love.graphics.getWidth() / loveImageData:getWidth(), love.graphics.getHeight() / loveImageData:getHeight())
    end
    love.graphics.print(love.timer.getFPS() .. " FPS", 10, 3)
end

function love.quit()
    -- free the luavlc pixel buffer
    vlcWrapper.luavlc_free_pixel_buffer(luaVlcVideo.pixelBuffer)

    -- kill the media player
    vlc.libvlc_media_player_stop(vlcData.mediaPlayer)
    vlc.libvlc_media_player_release(vlcData.mediaPlayer)

    -- kill the vlc instance
    vlc.libvlc_release(vlcData.inst)
end