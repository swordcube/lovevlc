local os = require("os")

--- @protected
--- @return "Windows"|"MacOS"|"Linux"|"Unknown"
local function _osname() return "Unknown" end

if jit and jit.os then
    _osname = function()
        return jit.os
    end
else
    local binaryFormat = package.cpath:match("%p[\\|/]?%p(%a+)")
    if binaryFormat == "dll" then
        _osname = function()
            return "Windows"
        end
    elseif binaryFormat == "so" then
        _osname = function()
            return "Linux"
        end
    elseif binaryFormat == "dylib" then
        _osname = function()
            return "MacOS"
        end
    end
    binaryFormat = nil
end
os.name = _osname

local settings = {
    EXECUTABLE_NAME = "LoveVLCTest",
    EXPORT_DIR = "../../export",

    FOLDERS_TO_COPY = {},
    FILES_TO_INCLUDE = {"conf.lua", "main.lua", "libvlc_h.lua"},
    FILES_TO_EXCLUDE = {},

    EXTERNAL_FILES = {},
    LOVE_PATH = {
        WINDOWS = "C:/Program Files/LOVE",
        LINUX = "love.AppImage"
    }
}
if os.name() == "Windows" then
    settings.EXTERNAL_FILES["../../plugins/Windows"] = "plugins"
    settings.EXTERNAL_FILES["../../lib/win64/libvlc.dll"] = "libvlc.dll"
    settings.EXTERNAL_FILES["../../lib/win64/libvlccore.dll"] = "libvlccore.dll"
    settings.EXTERNAL_FILES["../../lib/win64/libvlc_wrapper.dll"] = "libvlc_wrapper.dll"

elseif os.name() == "Linux" then
    settings.EXTERNAL_FILES["../../lib/linux/libvlc_wrapper.so"] = "lib/linux/libvlc_wrapper.so"
end
return settings