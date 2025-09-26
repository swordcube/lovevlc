if not _G.LOVEVLC_PARENT then
    error("You need to require LoveVLC first before requiring it's handle module!")
end
local ffi = require("ffi")

local handle = {}
handle.instance = nil

--- Whether or not the VLC instance is currently loading
handle.loading = false

--- Creates a new vlc instance without creating
--- a reference to it in this class, instead directly returning the instance
function handle.create()
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
    libvlcWrapper.luavlc_init_vlc(#args, argsPtr)
end

--- Creates a new vlc instance and creates
--- a reference to it in this class (`handle.instance`)
function handle.init()
    handle.loading = true
    
    handle.create()
    handle.instance = libvlcWrapper.luavlc_get_vlc_instance()

    handle.loading = false
end

--- Creates a new vlc instance asynchronously
--- and creates a reference to it in this class afterwards
function handle.initasync()
    if handle.loading then
        print("VLC is already loading!")
        return
    end
    if handle.instance then
        print("VLC is already initialized!")
        return
    end
    handle.loading = true
    local thread = love.thread.newThread([[
        require("love.event")
        local parent, hp = ...

        require(parent)
        _G.LOVEVLC_PARENT = parent

        local handle = require(hp)
        handle.create()
        love.event.push("vlcinit")
    ]])
    love.handlers.vlcinit = function()
        handle.instance = libvlcWrapper.luavlc_get_vlc_instance()
        ffi.gc(handle.instance, nil)
    end
    thread:start(_G.LOVEVLC_PARENT, (_G.LOVEVLC_PARENT and (_G.LOVEVLC_PARENT .. ".") or "") .. "util.handle")
end

function handle.quit()
    libvlc.libvlc_release(handle.instance)
end

return handle