#include <cstdlib>
#include "vlc/vlc.h"

// NOTE: this only wraps functions that i can't call correctly in lua code

#if _WIN32
extern "C" __declspec(dllexport)
#endif

extern "C" {
    #if _WIN32
    #define EXPORT_DLL __declspec(dllexport)
    #else
    #define EXPORT_DLL 
    #endif

    typedef struct {
        unsigned char* pixelBuffer;
        unsigned int width;
        unsigned int height;
    } LuaVLC_Video;

    static bool _can_update_texture = false;

    EXPORT_DLL LuaVLC_Video luavlc_new() {
        LuaVLC_Video video;
        return video;
    }

    EXPORT_DLL unsigned char* luavlc_new_pixel_buffer(unsigned int width, unsigned int height) {
        return (unsigned char*)malloc(width * height * 3);
    }

    EXPORT_DLL void luavlc_free_pixel_buffer(unsigned char* pixelBuffer) {
        if(pixelBuffer != NULL && pixelBuffer != nullptr)
            free((void*)pixelBuffer);
    }

    EXPORT_DLL void luavlc_free(LuaVLC_Video video) {
        if(video.pixelBuffer != NULL && video.pixelBuffer != nullptr) {
            luavlc_free_pixel_buffer(video.pixelBuffer);
            video.pixelBuffer = NULL;
        }
    }

    // i can't write this or unlock_cb function in lua code
    // because (in the context of love2d atleast) it causes a segfault after running a few times
    // so i have to write it here in C land
    void *lock_cb(void *opaque, void **planes) {
        *planes = opaque;
        _can_update_texture = false;
        return NULL;
    }

    void unlock_cb(void *opaque, void *picture, void *const *planes) {
        _can_update_texture = true;
    }

    EXPORT_DLL bool can_update_texture(void) {
        return _can_update_texture;
    }

    EXPORT_DLL void video_use_unlock_callback(libvlc_media_player_t *mp, void *opaque) {
        libvlc_video_set_callbacks(mp, NULL, unlock_cb, NULL, opaque);
    }
    
    EXPORT_DLL void video_use_all_callbacks(libvlc_media_player_t *mp, void *opaque) {
        libvlc_video_set_callbacks(mp, lock_cb, unlock_cb, NULL, opaque);
    }
}