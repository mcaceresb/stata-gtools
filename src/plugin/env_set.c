/* adapted from https://github.com/kousu/statasvm/blob/master/src/_svm_setenv.c */
/* env_set.c: a Stata plugin to set environemnt variables */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "spi/stplugin.h"
#include "spt/st_gentools.c"

#if defined(_WIN64) || defined(_WIN32)

#if defined(__MINGW32__) || defined(__MINGW64__)
/* MINGW defines _wgetenv_s(), but not getenv_s. However, it *is* in the
 * runtime .dll, so if we just add it here we're good. MINGW wants you to
 * use getenv(), it seems.
 */
errno_t getenv_s (
   size_t *pReturnValue,
   char* buffer,
   size_t numberOfElements,
   const char *varname
);
#endif

/* from http://stackoverflow.com/questions/17258029/c-setenv-undefined-identifier-in-visual-studio */
int setenv (const char *name, const char *value, int overwrite);
int setenv (const char *name, const char *value, int overwrite)
{
    if ( overwrite ) {
        return (_putenv_s(name, value));
    }
    else {
        return (0);
    }
}

int unsetenv (const char *name);
int unsetenv (const char *name) {
    return (_putenv_s(name, ""));
}
#define ENV_DELIM ';'
#else
#define ENV_DELIM ':'
#endif

#ifdef __APPLE__
#else
void * memcpy (void *dest, const void *src, size_t n);
void * memcpy (void *dest, const void *src, size_t n)
{
    return memmove(dest, src, n);
}
#endif

char* EMPTY = "";

STDLL stata_call (int argc, char *argv[])
{
    ST_retcode rc;
sf_errprintf("debug-1\n");

    if ( argc != 2 ) {
        sf_errprintf ("env_set: incorrect number of arguments (%d). Use:\n", argc);
        sf_errprintf ("\tplugin call env_set, ENV `\"VALUE\"'\n");
        return (198);
    }
    else if ( argc == 2 ) {
sf_errprintf("debug-2\n");
        rc = unsetenv(argv[0]);
sf_errprintf("debug-3\n");
        if ( rc ) {
sf_errprintf("debug-4\n");
            sf_errprintf ("env_set: unable to unset %s: %d\n", argv[0], rc);
sf_errprintf("debug-5\n");
            return (rc);
        }
sf_errprintf("debug-6\n");
        rc = setenv(argv[0], argv[1], 1);
sf_errprintf("debug-7\n");
        if ( rc ) {
sf_errprintf("debug-8\n");
            sf_errprintf ("env_set: unable to set %s to '%s': %d\n", argv[0], argv[1], rc);
sf_errprintf("debug-9\n");
            return (rc);
sf_errprintf("debug-10\n");
        }
        else {
sf_errprintf("debug-11\n");
            sf_printf ("Set '%s' to %s\n", argv[0], argv[1]);
        }
sf_errprintf("debug-12\n");
    }
sf_errprintf("debug-13\n");
    return (0);
sf_errprintf("debug-14\n");
}
