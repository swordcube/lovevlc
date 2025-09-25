#include <cstdlib>

#include "AL/al.h"
#include "vlc/vlc.h"

// NOTE: this only wraps functions that i can't call correctly in lua code

extern "C" {
    #if _WIN32
    extern "C" __declspec(dllexport)
    #define EXPORT_DLL __declspec(dllexport)
    #else
    #define EXPORT_DLL 
    #endif

    typedef struct {
        unsigned char* pixelBuffer;
        unsigned int width;
        unsigned int height;
    } LuaVLC_Video;
    
    typedef struct {
        ALuint *source;
        ALuint *buffers;
    } LuaVLC_Audio;

    static bool _can_update_texture = false;

    EXPORT_DLL LuaVLC_Video luavlc_new() {
        LuaVLC_Video video;
        return video;
    }

    EXPORT_DLL LuaVLC_Audio luavlc_audio_new() {
        LuaVLC_Audio audio;
        return audio;
    }

    EXPORT_DLL LuaVLC_Audio* luavlc_audio_new_ptr() {
        LuaVLC_Audio* audio = (LuaVLC_Audio*)malloc(sizeof(LuaVLC_Audio));
        *audio = luavlc_audio_new();
        return audio;
    }

    EXPORT_DLL unsigned char* luavlc_new_pixel_buffer(unsigned int width, unsigned int height) {
        return (unsigned char*)malloc(width * height * 4);
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

    EXPORT_DLL void luavlc_audio_free(LuaVLC_Audio audio) {
        alDeleteSources(1, audio.source);
        alDeleteBuffers(255, audio.buffers);
        free((void*)audio.buffers);
    }

    EXPORT_DLL void luavlc_audio_free_ptr(LuaVLC_Audio* audio) {
        alDeleteSources(1, audio->source);
        alDeleteBuffers(255, audio->buffers);
        free((void*)audio->buffers);
    }

    // i can't write this or unlock_cb function in lua code
    // because (in the context of love2d atleast) it causes a segfault after running a few times
    // so i have to write it here in C land
    void *lock_cb(void *opaque, void **planes) {
        *planes = opaque;
        _can_update_texture = false;
        return NULL;
    }

    void display_cb(void *opaque, void *picture) {
        _can_update_texture = true;
    }

    EXPORT_DLL bool can_update_texture(void) {
        return _can_update_texture;
    }

    EXPORT_DLL void video_use_unlock_callback(libvlc_media_player_t *mp, void *opaque) {
        libvlc_video_set_callbacks(mp, NULL, NULL, display_cb, opaque);
    }
    
    EXPORT_DLL void video_use_all_callbacks(libvlc_media_player_t *mp, void *opaque) {
        libvlc_video_set_callbacks(mp, lock_cb, NULL, display_cb, opaque);
    }

    void audio_play(void *data, const void *samples, unsigned count, int64_t pts) {
        // TODO: handle it.
    }

    void audio_resume(void *data, int64_t pts) {
        // TODO: handle it.
    }

    void audio_pause(void *data, int64_t pts) {
        // TODO: handle it.
    }

    void audio_flush(void *data, int64_t pts) {
        // TODO: handle it.
    }

    void audio_set_volume(void *data, float volume, bool mute) {
        // TODO: handle it.
    }

    int audio_setup(void **data, char *format, unsigned *rate, unsigned *channels) {
        // TODO: handle it.
        return 1;
    }

    // have to pass as a void* then cast to LuaVLC_Audio* because
    // luajit is being really strange and picky about the struct types
    EXPORT_DLL void video_setup_audio(void* p_audio, libvlc_media_player_t *mp) {
        LuaVLC_Audio* audio = (LuaVLC_Audio*)p_audio;
        audio->buffers = (ALuint*)malloc(sizeof(ALuint) * 255);
        alGenSources(1, audio->source);
        alGenBuffers(255, audio->buffers);

        libvlc_audio_set_callbacks(mp, audio_play, audio_pause, audio_resume, audio_flush, NULL, audio);
        libvlc_audio_set_volume_callback(mp, audio_set_volume);
        libvlc_audio_set_format_callbacks(mp, audio_setup, NULL);
    }
}