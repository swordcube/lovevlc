#include <cstdlib>
#include <cstring>
#include <vector>

#include "AL/al.h"
#include "AL/alc.h"
#include "AL/alext.h"
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
        unsigned char* pixelBuffer = nullptr;
        unsigned int width = 0;
        unsigned int height = 0;
    } LuaVLC_Video;
    
    typedef struct {
        ALuint source = 0;
        ALuint* buffers = nullptr;
        unsigned int bufferCount = 0;
        unsigned int bufferIndex = 0;

        ALenum format = 0;
        unsigned sampleRate = 0;
        unsigned int frameSize = 0;
    } LuaVLC_Audio;

    static const int MAX_BUFFER_COUNT = 255;
    static bool _can_update_texture = false;

    static int _alUseEXTFLOAT32 = -1;
    static int _alUseEXTMCFORMATS = -1;

    EXPORT_DLL LuaVLC_Video luavlc_new() {
        LuaVLC_Video video = {0};
        return video;
    }

    EXPORT_DLL LuaVLC_Audio* luavlc_audio_new_ptr() {
        LuaVLC_Audio* audio = (LuaVLC_Audio*)malloc(sizeof(LuaVLC_Audio));
        memset(audio, 0, sizeof(LuaVLC_Audio));
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

    EXPORT_DLL void luavlc_audio_free_ptr(LuaVLC_Audio* audio) {
        if (audio == NULL || audio == nullptr)
            return;
        alDeleteSources(1, &audio->source);
        alDeleteBuffers(audio->bufferCount, audio->buffers);
        free((void*)audio->buffers);
        free((void*)audio);
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

    void audio_play(void *data, const void *rawSamples, unsigned count, int64_t pts) {
        LuaVLC_Audio* audio = (LuaVLC_Audio*)data;
        if(audio == NULL || audio == nullptr || audio->source == 0)
            return;

        ALint nb = 0;
        bool useUnqueue = audio->bufferIndex > audio->bufferCount - 1;
        if (!useUnqueue) {
            audio->bufferIndex += 1;
            nb = 1;
        } else {
            alGetSourcei(audio->source, AL_BUFFERS_PROCESSED, &nb);
        }

        if(nb == 0)
            return;

        ALuint buffer;
        if (useUnqueue) {
            alSourceUnqueueBuffers(audio->source, 1, &buffer);
        } else {
            buffer = audio->buffers[audio->bufferIndex - 1];
        }

        ALsizei size = count * audio->frameSize;
        alBufferData(buffer, audio->format, rawSamples, size, audio->sampleRate);
        alSourceQueueBuffers(audio->source, 1, &buffer);

        ALint state = 0;
        alGetSourcei(audio->source, AL_SOURCE_STATE, &state);
        if(state != AL_PLAYING) {
            alSourcePlay(audio->source);
        }
    }

    void audio_resume(void *data, int64_t pts) {
        LuaVLC_Audio* audio = (LuaVLC_Audio*)data;
        if(audio == NULL || audio == nullptr || audio->source == 0)
            return;

        ALint state = 0;
        alGetSourcei(audio->source, AL_SOURCE_STATE, &state);

        if(state == AL_PAUSED || state == AL_STOPPED)
            alSourcePlay(audio->source);
    }

    void audio_pause(void *data, int64_t pts) {
        LuaVLC_Audio* audio = (LuaVLC_Audio*)data;
        if(audio == NULL || audio == nullptr || audio->source == 0)
            return;

        ALint state;
        alGetSourcei(audio->source, AL_SOURCE_STATE, &state);

        if(state != AL_PAUSED)
            alSourcePause(audio->source);
    }

    void audio_flush(void *data, int64_t pts) {
        LuaVLC_Audio* audio = (LuaVLC_Audio*)data;
        if(audio == NULL || audio == nullptr || audio->source == 0)
            return;

        ALint state;
        alGetSourcei(audio->source, AL_SOURCE_STATE, &state);

        if(state != AL_STOPPED)
            alSourceStop(audio->source);
    }

    void audio_set_volume(void *data, float volume, bool mute) {
        LuaVLC_Audio* audio = (LuaVLC_Audio*)data;
        if(audio == NULL || audio == nullptr || audio->source == 0)
            return;

        alSourcef(audio->source, AL_GAIN, mute ? 0.0f : volume);
    }

    int audio_setup(void **data, char *format, unsigned *p_rate, unsigned *p_channels) {
        LuaVLC_Audio* audio = *((LuaVLC_Audio**)data);
        if(audio == NULL || audio == nullptr || audio->source == 0)
            return 1;
        
        if(_alUseEXTFLOAT32 == -1)
            _alUseEXTFLOAT32 = (int)alIsExtensionPresent("AL_EXT_FLOAT32");

        if(_alUseEXTMCFORMATS == -1)
            _alUseEXTMCFORMATS = (int)alIsExtensionPresent("AL_EXT_MCFORMATS");
        
        audio->sampleRate = *p_rate;
        unsigned channels = *p_channels;
        
        if(_alUseEXTMCFORMATS == 1 && channels > 8)
            channels = 8;
        else if(channels > 2)
            channels = 2;

        bool useFloat32 = _alUseEXTFLOAT32 == 1 && strcmp(format, "FL32") == 0;
        // memcpy(format, useFloat32 ? "FL32" : "S16N", 4);

        switch(channels) {
            case 1:
                audio->format = useFloat32 ? AL_FORMAT_MONO_FLOAT32 : AL_FORMAT_MONO16;
                channels = 1;
                break;

            case 2:
            case 3:
                audio->format = useFloat32 ? AL_FORMAT_STEREO_FLOAT32 : AL_FORMAT_STEREO16;
                channels = 2;
                break;

            case 4:
                audio->format = useFloat32 ? AL_FORMAT_QUAD32 : AL_FORMAT_QUAD16;
                channels = 4;
                break;

            case 5:
            case 6:
                audio->format = useFloat32 ? AL_FORMAT_51CHN32 : AL_FORMAT_51CHN16;
                channels = 6;
                break;

            case 7:
            case 8:
                audio->format = useFloat32 ? AL_FORMAT_71CHN32 : AL_FORMAT_71CHN16;
                channels = 8;
                break;
        }
        audio->frameSize = (useFloat32 ? sizeof(float) : sizeof(int16_t)) * channels;
        return 0;
    }

    // have to pass as a void* then cast to LuaVLC_Audio* because
    // luajit is being really strange and picky about the struct types
    EXPORT_DLL void video_setup_audio(void* p_audio, libvlc_media_player_t *mp) {
        LuaVLC_Audio* audio = (LuaVLC_Audio*)p_audio;
        if (audio == NULL || audio == nullptr)
            return;
        if (mp == NULL || mp == nullptr)
            return;

        alGenSources(1, &audio->source);
        audio->bufferCount = MAX_BUFFER_COUNT;
        audio->buffers = (ALuint*)malloc(audio->bufferCount * sizeof(ALuint));
        for (int i = 0; i < audio->bufferCount; i++) {
            alGenBuffers(1, &audio->buffers[i]);
        } 

        libvlc_audio_set_callbacks(mp, audio_play, audio_pause, audio_resume, audio_flush, NULL, audio);
        libvlc_audio_set_volume_callback(mp, audio_set_volume);
        libvlc_audio_set_format_callbacks(mp, audio_setup, NULL);
    }
}