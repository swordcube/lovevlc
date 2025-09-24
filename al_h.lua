local ffi = require("ffi")
ffi.cdef [[\
/** 8-bit boolean */
typedef char ALboolean;

/** character */
typedef char ALchar;

/** signed 8-bit integer */
typedef signed char ALbyte;

/** unsigned 8-bit integer */
typedef unsigned char ALubyte;

/** signed 16-bit integer */
typedef short ALshort;

/** unsigned 16-bit integer */
typedef unsigned short ALushort;

/** signed 32-bit integer */
typedef int ALint;

/** unsigned 32-bit integer */
typedef unsigned int ALuint;

/** non-negative 32-bit integer size */
typedef int ALsizei;

/** 32-bit enumeration value */
typedef int ALenum;

/** 32-bit IEEE-754 floating-point */
typedef float ALfloat;

/** 64-bit IEEE-754 floating-point */
typedef double ALdouble;

/** void type (opaque pointers only) */
typedef void ALvoid;

/* Renderer State management. */
void alEnable(ALenum capability);
void alDisable(ALenum capability);
ALboolean alIsEnabled(ALenum capability);

/* Context state setting. */
void alDopplerFactor(ALfloat value);
void alDopplerVelocity(ALfloat value);
void alSpeedOfSound(ALfloat value);
void alDistanceModel(ALenum distanceModel);

/* Context state retrieval. */
const ALchar* alGetString(ALenum param);
void alGetBooleanv(ALenum param, ALboolean *values);
void alGetIntegerv(ALenum param, ALint *values);
void alGetFloatv(ALenum param, ALfloat *values);
void alGetDoublev(ALenum param, ALdouble *values);
ALboolean alGetBoolean(ALenum param);
ALint alGetInteger(ALenum param);
ALfloat alGetFloat(ALenum param);
ALdouble alGetDouble(ALenum param);

/**
 * Obtain the first error generated in the AL context since the last call to
 * this function.
 */
ALenum alGetError(void);

/** Query for the presence of an extension on the AL context. */
ALboolean alIsExtensionPresent(const ALchar *extname);
/**
 * Retrieve the address of a function. The returned function may be context-
 * specific.
 */
void* alGetProcAddress(const ALchar *fname);
/**
 * Retrieve the value of an enum. The returned value may be context-specific.
 */
ALenum alGetEnumValue(const ALchar *ename);


/* Set listener parameters. */
void alListenerf(ALenum param, ALfloat value);
void alListener3f(ALenum param, ALfloat value1, ALfloat value2, ALfloat value3);
void alListenerfv(ALenum param, const ALfloat *values);
void alListeneri(ALenum param, ALint value);
void alListener3i(ALenum param, ALint value1, ALint value2, ALint value3);
void alListeneriv(ALenum param, const ALint *values);

/* Get listener parameters. */
void alGetListenerf(ALenum param, ALfloat *value);
void alGetListener3f(ALenum param, ALfloat *value1, ALfloat *value2, ALfloat *value3);
void alGetListenerfv(ALenum param, ALfloat *values);
void alGetListeneri(ALenum param, ALint *value);
void alGetListener3i(ALenum param, ALint *value1, ALint *value2, ALint *value3);
void alGetListeneriv(ALenum param, ALint *values);


/** Create source objects. */
void alGenSources(ALsizei n, ALuint *sources);
/** Delete source objects. */
void alDeleteSources(ALsizei n, const ALuint *sources);
/** Verify an ID is for a valid source. */
ALboolean alIsSource(ALuint source);

/* Set source parameters. */
void alSourcef(ALuint source, ALenum param, ALfloat value);
void alSource3f(ALuint source, ALenum param, ALfloat value1, ALfloat value2, ALfloat value3);
void alSourcefv(ALuint source, ALenum param, const ALfloat *values);
void alSourcei(ALuint source, ALenum param, ALint value);
void alSource3i(ALuint source, ALenum param, ALint value1, ALint value2, ALint value3);
void alSourceiv(ALuint source, ALenum param, const ALint *values);

/* Get source parameters. */
void alGetSourcef(ALuint source, ALenum param, ALfloat *value);
void alGetSource3f(ALuint source, ALenum param, ALfloat *value1, ALfloat *value2, ALfloat *value3);
void alGetSourcefv(ALuint source, ALenum param, ALfloat *values);
void alGetSourcei(ALuint source,  ALenum param, ALint *value);
void alGetSource3i(ALuint source, ALenum param, ALint *value1, ALint *value2, ALint *value3);
void alGetSourceiv(ALuint source,  ALenum param, ALint *values);


/** Play, restart, or resume a source, setting its state to AL_PLAYING. */
void alSourcePlay(ALuint source);
/** Stop a source, setting its state to AL_STOPPED if playing or paused. */
void alSourceStop(ALuint source);
/** Rewind a source, setting its state to AL_INITIAL. */
void alSourceRewind(ALuint source);
/** Pause a source, setting its state to AL_PAUSED if playing. */
void alSourcePause(ALuint source);

/** Play, restart, or resume a list of sources atomically. */
void alSourcePlayv(ALsizei n, const ALuint *sources);
/** Stop a list of sources atomically. */
void alSourceStopv(ALsizei n, const ALuint *sources);
/** Rewind a list of sources atomically. */
void alSourceRewindv(ALsizei n, const ALuint *sources);
/** Pause a list of sources atomically. */
void alSourcePausev(ALsizei n, const ALuint *sources);

/** Queue buffers onto a source */
void alSourceQueueBuffers(ALuint source, ALsizei nb, const ALuint *buffers);
/** Unqueue processed buffers from a source */
void alSourceUnqueueBuffers(ALuint source, ALsizei nb, ALuint *buffers);


/** Create buffer objects */
void alGenBuffers(ALsizei n, ALuint *buffers);
/** Delete buffer objects */
void alDeleteBuffers(ALsizei n, const ALuint *buffers);
/** Verify an ID is a valid buffer (including the NULL buffer) */
ALboolean alIsBuffer(ALuint buffer);

/**
 * Copies data into the buffer, interpreting it using the specified format and
 * samplerate.
 */
void alBufferData(ALuint buffer, ALenum format, const ALvoid *data, ALsizei size, ALsizei samplerate);

/* Set buffer parameters. */
void alBufferf(ALuint buffer, ALenum param, ALfloat value);
void alBuffer3f(ALuint buffer, ALenum param, ALfloat value1, ALfloat value2, ALfloat value3);
void alBufferfv(ALuint buffer, ALenum param, const ALfloat *values);
void alBufferi(ALuint buffer, ALenum param, ALint value);
void alBuffer3i(ALuint buffer, ALenum param, ALint value1, ALint value2, ALint value3);
void alBufferiv(ALuint buffer, ALenum param, const ALint *values);

/* Get buffer parameters. */
void alGetBufferf(ALuint buffer, ALenum param, ALfloat *value);
void alGetBuffer3f(ALuint buffer, ALenum param, ALfloat *value1, ALfloat *value2, ALfloat *value3);
void alGetBufferfv(ALuint buffer, ALenum param, ALfloat *values);
void alGetBufferi(ALuint buffer, ALenum param, ALint *value);
void alGetBuffer3i(ALuint buffer, ALenum param, ALint *value1, ALint *value2, ALint *value3);
void alGetBufferiv(ALuint buffer, ALenum param, ALint *values);

/* Pointer-to-function types, useful for storing dynamically loaded AL entry
 * points.
 */
typedef void          (*LPALENABLE)(ALenum capability);
typedef void          (*LPALDISABLE)(ALenum capability);
typedef ALboolean     (*LPALISENABLED)(ALenum capability);
typedef const ALchar* (*LPALGETSTRING)(ALenum param);
typedef void          (*LPALGETBOOLEANV)(ALenum param, ALboolean *values);
typedef void          (*LPALGETINTEGERV)(ALenum param, ALint *values);
typedef void          (*LPALGETFLOATV)(ALenum param, ALfloat *values);
typedef void          (*LPALGETDOUBLEV)(ALenum param, ALdouble *values);
typedef ALboolean     (*LPALGETBOOLEAN)(ALenum param);
typedef ALint         (*LPALGETINTEGER)(ALenum param);
typedef ALfloat       (*LPALGETFLOAT)(ALenum param);
typedef ALdouble      (*LPALGETDOUBLE)(ALenum param);
typedef ALenum        (*LPALGETERROR)(void);
typedef ALboolean     (*LPALISEXTENSIONPRESENT)(const ALchar *extname);
typedef void*         (*LPALGETPROCADDRESS)(const ALchar *fname);
typedef ALenum        (*LPALGETENUMVALUE)(const ALchar *ename);
typedef void          (*LPALLISTENERF)(ALenum param, ALfloat value);
typedef void          (*LPALLISTENER3F)(ALenum param, ALfloat value1, ALfloat value2, ALfloat value3);
typedef void          (*LPALLISTENERFV)(ALenum param, const ALfloat *values);
typedef void          (*LPALLISTENERI)(ALenum param, ALint value);
typedef void          (*LPALLISTENER3I)(ALenum param, ALint value1, ALint value2, ALint value3);
typedef void          (*LPALLISTENERIV)(ALenum param, const ALint *values);
typedef void          (*LPALGETLISTENERF)(ALenum param, ALfloat *value);
typedef void          (*LPALGETLISTENER3F)(ALenum param, ALfloat *value1, ALfloat *value2, ALfloat *value3);
typedef void          (*LPALGETLISTENERFV)(ALenum param, ALfloat *values);
typedef void          (*LPALGETLISTENERI)(ALenum param, ALint *value);
typedef void          (*LPALGETLISTENER3I)(ALenum param, ALint *value1, ALint *value2, ALint *value3);
typedef void          (*LPALGETLISTENERIV)(ALenum param, ALint *values);
typedef void          (*LPALGENSOURCES)(ALsizei n, ALuint *sources);
typedef void          (*LPALDELETESOURCES)(ALsizei n, const ALuint *sources);
typedef ALboolean     (*LPALISSOURCE)(ALuint source);
typedef void          (*LPALSOURCEF)(ALuint source, ALenum param, ALfloat value);
typedef void          (*LPALSOURCE3F)(ALuint source, ALenum param, ALfloat value1, ALfloat value2, ALfloat value3);
typedef void          (*LPALSOURCEFV)(ALuint source, ALenum param, const ALfloat *values);
typedef void          (*LPALSOURCEI)(ALuint source, ALenum param, ALint value);
typedef void          (*LPALSOURCE3I)(ALuint source, ALenum param, ALint value1, ALint value2, ALint value3);
typedef void          (*LPALSOURCEIV)(ALuint source, ALenum param, const ALint *values);
typedef void          (*LPALGETSOURCEF)(ALuint source, ALenum param, ALfloat *value);
typedef void          (*LPALGETSOURCE3F)(ALuint source, ALenum param, ALfloat *value1, ALfloat *value2, ALfloat *value3);
typedef void          (*LPALGETSOURCEFV)(ALuint source, ALenum param, ALfloat *values);
typedef void          (*LPALGETSOURCEI)(ALuint source, ALenum param, ALint *value);
typedef void          (*LPALGETSOURCE3I)(ALuint source, ALenum param, ALint *value1, ALint *value2, ALint *value3);
typedef void          (*LPALGETSOURCEIV)(ALuint source, ALenum param, ALint *values);
typedef void          (*LPALSOURCEPLAYV)(ALsizei n, const ALuint *sources);
typedef void          (*LPALSOURCESTOPV)(ALsizei n, const ALuint *sources);
typedef void          (*LPALSOURCEREWINDV)(ALsizei n, const ALuint *sources);
typedef void          (*LPALSOURCEPAUSEV)(ALsizei n, const ALuint *sources);
typedef void          (*LPALSOURCEPLAY)(ALuint source);
typedef void          (*LPALSOURCESTOP)(ALuint source);
typedef void          (*LPALSOURCEREWIND)(ALuint source);
typedef void          (*LPALSOURCEPAUSE)(ALuint source);
typedef void          (*LPALSOURCEQUEUEBUFFERS)(ALuint source, ALsizei nb, const ALuint *buffers);
typedef void          (*LPALSOURCEUNQUEUEBUFFERS)(ALuint source, ALsizei nb, ALuint *buffers);
typedef void          (*LPALGENBUFFERS)(ALsizei n, ALuint *buffers);
typedef void          (*LPALDELETEBUFFERS)(ALsizei n, const ALuint *buffers);
typedef ALboolean     (*LPALISBUFFER)(ALuint buffer);
typedef void          (*LPALBUFFERDATA)(ALuint buffer, ALenum format, const ALvoid *data, ALsizei size, ALsizei samplerate);
typedef void          (*LPALBUFFERF)(ALuint buffer, ALenum param, ALfloat value);
typedef void          (*LPALBUFFER3F)(ALuint buffer, ALenum param, ALfloat value1, ALfloat value2, ALfloat value3);
typedef void          (*LPALBUFFERFV)(ALuint buffer, ALenum param, const ALfloat *values);
typedef void          (*LPALBUFFERI)(ALuint buffer, ALenum param, ALint value);
typedef void          (*LPALBUFFER3I)(ALuint buffer, ALenum param, ALint value1, ALint value2, ALint value3);
typedef void          (*LPALBUFFERIV)(ALuint buffer, ALenum param, const ALint *values);
typedef void          (*LPALGETBUFFERF)(ALuint buffer, ALenum param, ALfloat *value);
typedef void          (*LPALGETBUFFER3F)(ALuint buffer, ALenum param, ALfloat *value1, ALfloat *value2, ALfloat *value3);
typedef void          (*LPALGETBUFFERFV)(ALuint buffer, ALenum param, ALfloat *values);
typedef void          (*LPALGETBUFFERI)(ALuint buffer, ALenum param, ALint *value);
typedef void          (*LPALGETBUFFER3I)(ALuint buffer, ALenum param, ALint *value1, ALint *value2, ALint *value3);
typedef void          (*LPALGETBUFFERIV)(ALuint buffer, ALenum param, ALint *values);
typedef void          (*LPALDOPPLERFACTOR)(ALfloat value);
typedef void          (*LPALDOPPLERVELOCITY)(ALfloat value);
typedef void          (*LPALSPEEDOFSOUND)(ALfloat value);
typedef void          (*LPALDISTANCEMODEL)(ALenum distanceModel);
]]