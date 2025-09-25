local jit = require("jit")
local ffi = require("ffi")

_G.LOVEVLC_LIB_DIRECTORY = os.getenv("LOVEVLC_LIB_DIRECTORY")
_G.LOVEVLC_PLUGIN_DIRECTORY = os.getenv("LOVEVLC_PLUGIN_DIRECTORY")

local libdir = _G.LOVEVLC_LIB_DIRECTORY or "" -- default to current executable directory
local plugindir = _G.LOVEVLC_PLUGIN_DIRECTORY or "plugins" -- default to "plugins" in current executable directory

local osm = os
local os = jit and jit.os or ffi.os

function string.lastIndexOf(self, sub)
    local subStringLength = #sub
    local lastIndex = -1

    for i = 1, #self - subStringLength + 1 do
        local currentSubstring = self:sub(i, i + subStringLength - 1)
        if currentSubstring == sub then
            lastIndex = i
        end
    end

    return lastIndex
end

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
if os == "Windows" or os == "OSX" then
    -- make sure to set plugin path or else it won't work on windows !   lol!
    local execPath = love.filesystem.getExecutablePath():gsub("\\", "/")
    local pp = execPath:sub(1, execPath:lastIndexOf("/") - 1) .. "/" .. plugindir .. "/" .. os -- hehe
    osm.setenv("VLC_PLUGIN_PATH", pp:gsub("/", "\\"))
end

local extension = os == "Windows" and "dll" or os == "Linux" and "so" or os == "OSX" and "dylib"
package.cpath = string.format("%s;%s/?.%s", package.cpath, libdir, extension)

-- this isn't technically used, but needs to be loaded for libvlc to load on windows!
local vlccore = os == "Windows" and ffi.load(assert(package.searchpath("libvlccore", package.cpath)):gsub("/", "\\")) or ffi.load("libvlccore")

-- this IS used though
local vlc = os == "Windows" and ffi.load(assert(package.searchpath("libvlc", package.cpath)):gsub("/", "\\")) or ffi.load("libvlc")
local vlcWrapper = nil

if os == "Windows" then
    -- windows (load dll from win64 folder)
    vlcWrapper = ffi.load(assert(package.searchpath("libvlc_wrapper", package.cpath)))
    
elseif os == "Linux" then
    -- linux (load so from linux folder)
    vlcWrapper = ffi.load(assert(package.searchpath("libvlc_wrapper", package.cpath)))
    
elseif os == "OSX" then
    -- macos (load dylib from mac folder)
    vlcWrapper = ffi.load(assert(package.searchpath("libvlc_wrapper", package.cpath)))
else
    error(("Unsupported OS: %s"):format(os))
end
local openal = os == "Windows" and ffi.load(assert(package.searchpath("OpenAL32", package.cpath))) or ffi.C

require("libvlc_h")
require("al_h")
require("alc_h")

ffi.cdef [[\
    void free(void* a);
    void* malloc(size_t size);

    typedef struct {
        unsigned char* pixelBuffer;
        unsigned int width;
        unsigned int height;
    } LuaVLC_Video;

    typedef struct {
        ALuint *source;
        ALuint *buffers;
        ALenum format;
        unsigned sampleRate;
        unsigned int frameSize;
    } LuaVLC_Audio;

    LuaVLC_Video luavlc_new(void);
    LuaVLC_Audio luavlc_audio_new(void);
    LuaVLC_Audio* luavlc_audio_new_ptr(void);

    void luavlc_audio_free_ptr(void* audio);
    
    void video_setup_format(libvlc_media_player_t *mp, unsigned int width, unsigned int height);
    void video_use_unlock_callback(libvlc_media_player_t *mp, void *opaque);
    void video_use_all_callbacks(libvlc_media_player_t *mp, void *opaque);
    void video_setup_audio(void* video, libvlc_media_player_t *mp);

    bool can_update_texture(void);
]]

local vlcData = {
    inst = nil,
    mediaPlayer = nil
}
local renderedVideo = false
local luaVlcVideo = nil
local luaVlcAudio = nil

local loveImageData = nil --- @type love.ImageData
local loveImage = nil --- @type love.Image

local oldnewvid = love.graphics.newVideo

--- 
--- Creates a new drawable Video. Supports most video formats thru LibVLC.
--- 
--- `.ogv` video files will use the default Love2D video implementation.
--- 
--- You cannot provide any `VideoStream`, only file names are accepted.
--- 
--- [Open in Browser](https://love2d.org/wiki/love.graphics.newVideo)
--- 
--- @overload fun(filename: string, settings?: table):love.Video
--- @overload fun(filename: string, loadaudio?: boolean):love.Video
love.graphics.newVideo = function(filename, settings)
    local ext = filename:match("^.+(%..+)$")
    if ext == ".ogv" then
        return oldnewvid(filename, settings)
    end
    if type(settings) == "boolean" then
        settings = {audio = settings, dpiscale = 1}
    end
    if not settings then
        settings = {audio = false, dpiscale = 1}
    end
    if settings.audio == nil then
        settings.audio = false
    end
    if settings.dpiscale == nil then
        settings.dpiscale = 1
    end
    error("love.graphics.newVideo not implemented for VLC!")
    print("NOTE: settings.dpiscale is currently ignored!")
end

function love.load(gameArgs)
    love.audio.setVolume(0.05)

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

    luaVlcAudio = vlcWrapper.luavlc_audio_new_ptr()
    ffi.gc(luaVlcAudio, nil) -- NO GC FOR YOU x2

    vlcWrapper.video_use_unlock_callback(vlcData.mediaPlayer, ffi.cast("void*", luaVlcVideo.pixelBuffer))
    vlcWrapper.video_setup_audio(luaVlcAudio, vlcData.mediaPlayer)
    vlc.libvlc_media_player_play(vlcData.mediaPlayer)
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

                vlc.libvlc_video_set_format(vlcData.mediaPlayer, "RGBA", w, h, w * 4)
                -- luaVlcVideo.pixelBuffer = vlcWrapper.luavlc_new_pixel_buffer(w, h)

                loveImageData = love.image.newImageData(w, h, "rgba8")
                luaVlcVideo.pixelBuffer = loveImageData:getFFIPointer()

                vlcWrapper.video_use_all_callbacks(vlcData.mediaPlayer, ffi.cast("void*", luaVlcVideo.pixelBuffer))
                
                loveImage = love.graphics.newImage(loveImageData)
                renderedVideo = true
            end
        end
    else
        local state = vlc.libvlc_media_player_get_state(vlcData.mediaPlayer)
        if state == 3 and vlcWrapper.can_update_texture() and loveImageData then
            -- we don't need to update the pixels here since
            -- we passed the ffi pointer to them directly to vlc
            loveImage:replacePixels(loveImageData)
        end
    end
end

function love.draw()
    if loveImage then
        love.graphics.draw(loveImage, 0, 0, 0, love.graphics.getWidth() / loveImageData:getWidth(), love.graphics.getHeight() / loveImageData:getHeight())
    end
    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", 0, 0, 100, 30)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(love.timer.getFPS() .. " FPS", 10, 3)
end

function love.quit()
    -- kill the media player
    vlc.libvlc_media_player_stop(vlcData.mediaPlayer)
    vlc.libvlc_media_player_release(vlcData.mediaPlayer)
    
    -- kill the vlc instance
    vlc.libvlc_release(vlcData.inst)

    -- free lauvlc audio struct stuff
    vlcWrapper.luavlc_audio_free_ptr(luaVlcAudio)
    
    -- free any love2d resources
    if loveImageData then
        loveImageData:release()
    end
    if loveImage then
        loveImage:release()
    end
end