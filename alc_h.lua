local ffi = require("ffi")
ffi.cdef [[\
/** Opaque device handle */
typedef struct ALCdevice ALCdevice;
/** Opaque context handle */
typedef struct ALCcontext ALCcontext;

/** 8-bit boolean */
typedef char ALCboolean;

/** character */
typedef char ALCchar;

/** signed 8-bit integer */
typedef signed char ALCbyte;

/** unsigned 8-bit integer */
typedef unsigned char ALCubyte;

/** signed 16-bit integer */
typedef short ALCshort;

/** unsigned 16-bit integer */
typedef unsigned short ALCushort;

/** signed 32-bit integer */
typedef int ALCint;

/** unsigned 32-bit integer */
typedef unsigned int ALCuint;

/** non-negative 32-bit integer size */
typedef int ALCsizei;

/** 32-bit enumeration value */
typedef int ALCenum;

/** 32-bit IEEE-754 floating-point */
typedef float ALCfloat;

/** 64-bit IEEE-754 floating-point */
typedef double ALCdouble;

/** void type (for opaque pointers only) */
typedef void ALCvoid;

/* Context management. */

/** Create and attach a context to the given device. */
ALCcontext* alcCreateContext(ALCdevice *device, const ALCint *attrlist);
/**
 * Makes the given context the active process-wide context. Passing NULL clears
 * the active context.
 */
ALCboolean  alcMakeContextCurrent(ALCcontext *context);
/** Resumes processing updates for the given context. */
void        alcProcessContext(ALCcontext *context);
/** Suspends updates for the given context. */
void        alcSuspendContext(ALCcontext *context);
/** Remove a context from its device and destroys it. */
void        alcDestroyContext(ALCcontext *context);
/** Returns the currently active context. */
ALCcontext* alcGetCurrentContext(void);
/** Returns the device that a particular context is attached to. */
ALCdevice*  alcGetContextsDevice(ALCcontext *context);

/* Device management. */

/** Opens the named playback device. */
ALCdevice* alcOpenDevice(const ALCchar *devicename);
/** Closes the given playback device. */
ALCboolean alcCloseDevice(ALCdevice *device);

/* Error support. */

/** Obtain the most recent Device error. */
ALCenum alcGetError(ALCdevice *device);

/* Extension support. */

/**
 * Query for the presence of an extension on the device. Pass a NULL device to
 * query a device-inspecific extension.
 */
ALCboolean alcIsExtensionPresent(ALCdevice *device, const ALCchar *extname);
/**
 * Retrieve the address of a function. Given a non-NULL device, the returned
 * function may be device-specific.
 */
ALCvoid*   alcGetProcAddress(ALCdevice *device, const ALCchar *funcname);
/**
 * Retrieve the value of an enum. Given a non-NULL device, the returned value
 * may be device-specific.
 */
ALCenum    alcGetEnumValue(ALCdevice *device, const ALCchar *enumname);

/* Query functions. */

/** Returns information about the device, and error strings. */
const ALCchar* alcGetString(ALCdevice *device, ALCenum param);
/** Returns information about the device and the version of OpenAL. */
void           alcGetIntegerv(ALCdevice *device, ALCenum param, ALCsizei size, ALCint *values);

/* Capture functions. */

/**
 * Opens the named capture device with the given frequency, format, and buffer
 * size.
 */
ALCdevice* alcCaptureOpenDevice(const ALCchar *devicename, ALCuint frequency, ALCenum format, ALCsizei buffersize);
/** Closes the given capture device. */
ALCboolean alcCaptureCloseDevice(ALCdevice *device);
/** Starts capturing samples into the device buffer. */
void       alcCaptureStart(ALCdevice *device);
/** Stops capturing samples. Samples in the device buffer remain available. */
void       alcCaptureStop(ALCdevice *device);
/** Reads samples from the device buffer. */
void       alcCaptureSamples(ALCdevice *device, ALCvoid *buffer, ALCsizei samples);

/* Pointer-to-function types, useful for storing dynamically loaded ALC entry
 * points.
 */
typedef ALCcontext*    (*LPALCCREATECONTEXT)(ALCdevice *device, const ALCint *attrlist);
typedef ALCboolean     (*LPALCMAKECONTEXTCURRENT)(ALCcontext *context);
typedef void           (*LPALCPROCESSCONTEXT)(ALCcontext *context);
typedef void           (*LPALCSUSPENDCONTEXT)(ALCcontext *context);
typedef void           (*LPALCDESTROYCONTEXT)(ALCcontext *context);
typedef ALCcontext*    (*LPALCGETCURRENTCONTEXT)(void);
typedef ALCdevice*     (*LPALCGETCONTEXTSDEVICE)(ALCcontext *context);
typedef ALCdevice*     (*LPALCOPENDEVICE)(const ALCchar *devicename);
typedef ALCboolean     (*LPALCCLOSEDEVICE)(ALCdevice *device);
typedef ALCenum        (*LPALCGETERROR)(ALCdevice *device);
typedef ALCboolean     (*LPALCISEXTENSIONPRESENT)(ALCdevice *device, const ALCchar *extname);
typedef ALCvoid*       (*LPALCGETPROCADDRESS)(ALCdevice *device, const ALCchar *funcname);
typedef ALCenum        (*LPALCGETENUMVALUE)(ALCdevice *device, const ALCchar *enumname);
typedef const ALCchar* (*LPALCGETSTRING)(ALCdevice *device, ALCenum param);
typedef void           (*LPALCGETINTEGERV)(ALCdevice *device, ALCenum param, ALCsizei size, ALCint *values);
typedef ALCdevice*     (*LPALCCAPTUREOPENDEVICE)(const ALCchar *devicename, ALCuint frequency, ALCenum format, ALCsizei buffersize);
typedef ALCboolean     (*LPALCCAPTURECLOSEDEVICE)(ALCdevice *device);
typedef void           (*LPALCCAPTURESTART)(ALCdevice *device);
typedef void           (*LPALCCAPTURESTOP)(ALCdevice *device);
typedef void           (*LPALCCAPTURESAMPLES)(ALCdevice *device, ALCvoid *buffer, ALCsizei samples);
]]