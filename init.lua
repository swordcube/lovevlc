local parent = ...
if not parent or #parent == 0 or parent == "init" then
    parent = nil
end
_G.LOVEVLC_PARENT = parent

local jit = require("jit")
local ffi = require("ffi")

_G.LOVEVLC_LIB_DIRECTORY = _G.LOVEVLC_LIB_DIRECTORY or os.getenv("LOVEVLC_LIB_DIRECTORY")
_G.LOVEVLC_PLUGIN_DIRECTORY = _G.LOVEVLC_PLUGIN_DIRECTORY or os.getenv("LOVEVLC_PLUGIN_DIRECTORY")

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
function table.indexOf(table, element)
    for i = 1, #table do
        if table[i] == element then
            return i
        end
    end
    return -1
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
    local execPath = love.filesystem.getExecutablePath()
    if os == "Windows" then
        execPath = execPath:gsub("\\", "/")
    end
    local pp = execPath:sub(1, execPath:lastIndexOf("/") - 1) .. "/" .. plugindir .. "/" .. os -- hehe
    osm.setenv("VLC_PLUGIN_PATH", os == "Windows" and pp:gsub("/", "\\") or pp)
end

local extension = os == "Windows" and "dll" or os == "Linux" and "so" or os == "OSX" and "dylib"
package.cpath = string.format("%s;%s/?.%s", package.cpath, libdir, extension)

-- this isn't technically used, but needs to be loaded for libvlc to load on windows!
local _ = os == "Windows" and ffi.load(assert(package.searchpath("libvlccore", package.cpath)):gsub("/", "\\")) or ffi.load("libvlccore")

-- this IS used though
_G.libvlc = os == "Windows" and ffi.load(assert(package.searchpath("libvlc", package.cpath)):gsub("/", "\\")) or ffi.load("libvlc")
_G.libvlcWrapper = ffi.load(assert(package.searchpath("libvlc_wrapper", package.cpath)))

-- similarly to libvlccore, variable not used, but needed to load openal
_G.libopenal = os == "Windows" and ffi.load(assert(package.searchpath("OpenAL32", package.cpath))) or ffi.C

require((parent and (parent .. ".") or "") .. "libvlc_h")
require((parent and (parent .. ".") or "") .. "al_h")
require((parent and (parent .. ".") or "") .. "alc_h")

ffi.cdef [[\
    void free(void* a);
    void* malloc(size_t size);

    typedef struct {
        unsigned char* pixelBuffer;
        unsigned int width;
        unsigned int height;
    } LuaVLC_Video;

    typedef struct LuaVLC_Audio LuaVLC_Audio;

    LuaVLC_Video luavlc_new(void);

    void luavlc_init_vlc(int argc, const char *const *argv);
    libvlc_instance_t* luavlc_get_vlc_instance(void);
    void luavlc_free_vlc(void);

    LuaVLC_Audio luavlc_audio_new(void);
    LuaVLC_Audio* luavlc_audio_new_ptr(void);

    void luavlc_audio_free_ptr(void* audio);
    
    void video_setup_format(libvlc_media_player_t *mp, unsigned int width, unsigned int height);
    void video_use_unlock_callback(libvlc_media_player_t *mp, void *opaque);
    void video_use_all_callbacks(libvlc_media_player_t *mp, void *opaque);
    void video_setup_audio(void* video, libvlc_media_player_t *mp);

    bool can_update_texture(void);
]]

if not love.graphics then
    return -- this file gets required for handle.initasync
end
local oldnewvid = love.graphics.newVideo
local vids = {}

--- 
--- Creates a new drawable Video. Supports most video formats thru LibVLC.
--- 
--- `.ogv` video files will use the default Love2D video implementation.
--- 
--- You can provide a `VideoStream`, but only Theora video streams
--- are supported, to play other formats you need to use a file name.
--- 
--- NOTE: `settings.dpiscale` is currently ignored!
--- 
--- [Open in Browser](https://love2d.org/wiki/love.graphics.newVideo)
--- 
--- @overload fun(videostream: love.VideoStream):love.Video
--- @overload fun(filename: string, settings?: table):love.Video
--- @overload fun(filename: string, loadaudio?: boolean):love.Video
--- @overload fun(videostream: love.VideoStream, loadaudio?: boolean):love.Video
love.graphics.newVideo = function(filename, settings)
    if type(filename) == "table" or type(filename) == "userdata" then
        -- assume video stream
        return oldnewvid(filename, settings)
    end
    -- otherwise assume file name
    local ext = filename:match("^.+(%..+)$")
    if ext == ".ogv" then
        return oldnewvid(filename, settings)
    end
    if type(settings) == "boolean" then
        settings = {audio = settings, dpiscale = love.graphics.getDPIScale()}
    end
    if not settings then
        settings = {audio = false, dpiscale = love.graphics.getDPIScale()}
    end
    if settings.audio == nil then
        settings.audio = false
    end
    if settings.dpiscale == nil then
        settings.dpiscale = love.graphics.getDPIScale( )
    end
    if settings.options == nil then
        settings.options = {}
    end
    if not settings.audio then
        table.insert(settings.options, ":no-audio")
    end
    local handle = require((_G.LOVEVLC_PARENT and (_G.LOVEVLC_PARENT .. ".") or "") .. "util.handle")
    if not handle.instance then
        handle.init()
    end
    local videoCl = {
        _type = "LoveVLCVideo",

        image = nil, --- @type love.Image
        imageData = nil, --- @type love.ImageData

        _mediaPlayer = nil, --- @protected
        _rendered = false, --- @protected

        _luaVlcVideo = nil, --- @protected
        _luaVlcAudio = nil, --- @protected

        _volume = 1.0 --- @protected
    } --- @class lovevlc.Video

    local video = videoCl --- @type lovevlc.Video
    video._fakeSource = setmetatable({
        getVolume = function(_)
            return video._volume
        end,
        setVolume = function(_, vol)
            video._volume = vol
            libvlc.libvlc_audio_set_volume(video._mediaPlayer, vol * 100)
        end
    }, {
        __index = function(t, k)
            local v = t[k]
            if v then
                return v
            end
            error("You can't access the " .. k .. " property from VLC audio source!", 2)
        end
    })
    table.insert(vids, video)

    local media = libvlc.libvlc_media_new_path(libvlcWrapper.luavlc_get_vlc_instance(), filename)
    for i = 1, #settings.options do
        libvlc.libvlc_media_add_option(media, settings.options[i])
    end
    video._mediaPlayer = libvlc.libvlc_media_player_new_from_media(media)
    libvlc.libvlc_media_release(media)

    video._luaVlcVideo = libvlcWrapper.luavlc_new()
    ffi.gc(video._luaVlcVideo, nil) -- NO GC FOR YOU

    video._luaVlcAudio = libvlcWrapper.luavlc_audio_new_ptr()
    ffi.gc(video._luaVlcAudio, nil) -- NO GC FOR YOU x2

    libvlcWrapper.video_use_unlock_callback(video._mediaPlayer, ffi.cast("void*", video._luaVlcVideo.pixelBuffer))
    libvlcWrapper.video_setup_audio(video._luaVlcAudio, video._mediaPlayer)

    video.play = function(v)
        libvlc.libvlc_media_player_play(v._mediaPlayer)
    end
    video.pause = function(v)
        libvlc.libvlc_media_player_pause(v._mediaPlayer)
    end
    video.stop = function(v)
        libvlc.libvlc_media_player_stop(v._mediaPlayer)
    end
    video.isPlaying = function(v)
        return libvlc.libvlc_media_player_is_playing(v._mediaPlayer)
    end
    video.tell = function(v)
        return tonumber(libvlc.libvlc_media_player_get_time(v._mediaPlayer)) / 1000.0
    end
    video.getDuration = function(v)
        return libvlc.libvlc_media_player_get_length(v._mediaPlayer) / 1000.0
    end
    video.seek = function(v, time)
        libvlc.libvlc_media_player_set_time(v._mediaPlayer, time * 1000.0)
    end
    video.release = function(v)
        -- kill the media player
        libvlc.libvlc_media_player_stop(v._mediaPlayer)
        libvlc.libvlc_media_player_release(v._mediaPlayer)

        -- free luavlc audio struct stuff
        libvlcWrapper.luavlc_audio_free_ptr(v._luaVlcAudio)

        -- free love2d resources
        if v.imageData then
            v.imageData:release()
            v.imageData = nil
        end
        if v.image then
            v.image:release()
            v.image = nil
        end
        table.remove(vids, table.indexOf(vids, v))
    end
    video.getWidth = function(v)
        if not v.imageData then
            return 1
        end
        return v.imageData:getWidth()
    end
    video.getHeight = function(v)
        if not v.imageData then
            return 1
        end
        return v.imageData:getHeight()
    end
    video.getDimensions = function(v)
        return video.getWidth(v), video.getHeight(v)
    end
    video.getSource = function(v)
        return video._fakeSource
    end
    video.draw = function(v, ...)
        if not v._rendered then
            local state = libvlc.libvlc_media_player_get_state(v._mediaPlayer)
            if state == 3 then -- 3 = playing
                local cw, ch = ffi.new("unsigned int[1]"), ffi.new("unsigned int[1]")
                libvlc.libvlc_video_get_size(v._mediaPlayer, 0, cw, ch)
                
                local w, h = tonumber(cw[0]), tonumber(ch[0])
                if w > 0 and h > 0 then
                    v._luaVlcVideo.width = cw[0]
                    v._luaVlcVideo.height = ch[0]

                    libvlc.libvlc_video_set_format(v._mediaPlayer, "RGBA", w, h, w * 4)
                    v.imageData = love.image.newImageData(w, h, "rgba8")
                    v._luaVlcVideo.pixelBuffer = v.imageData:getFFIPointer()

                    libvlcWrapper.video_use_all_callbacks(v._mediaPlayer, ffi.cast("void*", v._luaVlcVideo.pixelBuffer))
                    
                    v.image = love.graphics.newImage(v.imageData)
                    v._rendered = true
                end
            end
        else
            local state = libvlc.libvlc_media_player_get_state(v._mediaPlayer)
            if state == 3 and libvlcWrapper.can_update_texture() and v.imageData then
                -- we don't need to update the pixels here since
                -- we passed the ffi pointer to them directly to vlc
                v.image:replacePixels(v.imageData)
            end
            libvlc.libvlc_audio_set_volume(v._mediaPlayer, v._volume * 100)
        end
        if v.image then
            love.graphics.draw(v.image, ...)
        end
    end
    return video
end

-- override love.graphics.draw so you can directly draw vlc videos
-- as if they were a native Love2D video

local gfxDraw = love.graphics.draw
love.graphics.draw = function(item, ...)
    if type(item) == "table" and item._type == "LoveVLCVideo" then
        item:draw(...)
        return
    end
    return gfxDraw(item, ...)
end
local audioStop = love.audio.stop
love.audio.stop = function()
    for i = 1, #vids do
        vids[i]:stop()
    end
    return audioStop()
end