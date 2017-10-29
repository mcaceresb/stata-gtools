/* adapted from https://github.com/kousu/statasvm/blob/master/src/_svm_setenv.c */
/* env_set.c: a Stata plugin to set environemnt variables */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "spi/stplugin.h"
#include "common/sf_printf.c"

#if defined(_WIN64) || defined(_WIN32)
// #include <stdio.h>

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
        // return (_wputenv_s(name, value));
        return (_putenv_s(name, value));
    }
    else {
        return (0);
    }
}

int unsetenv (const char *name);
int unsetenv (const char *name) {
    // return (_wputenv_s(name, ""));
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

#define MAX_LEN 4096
char* EMPTY = "";

STDLL stata_call (int argc, char *argv[])
{
    ST_retcode rc = 0;

    if ( argc < 2 ) {
        sf_errprintf ("env_set: incorrect number of arguments (%d). Use:\n", argc);
        sf_errprintf ("\tplugin call env_set, ENV `\"VALUE\"'\n");
        return (198);
    }
    else if ( argc >= 2 ) {
        rc = unsetenv(argv[0]);
        if ( rc ) {
            sf_errprintf ("env_set: unable to unset %s: %d\n", argv[0], rc);
            return (rc);
        }

        if ( argc == 2 ) {
            rc = setenv(argv[0], argv[1], 1);
        }
        else {
            int c; char *path;
            path = malloc((argc - 1) * MAX_LEN * sizeof(char));
            memset (path, '\0', (argc - 1) * MAX_LEN);
            strcpy (path, argv[1]);
            for (c = 2; c < argc; c++) {
                strcat(path, argv[c]);
            }
            rc = setenv(argv[0], path, 1);
        }

        if ( rc ) {
            sf_errprintf ("env_set: unable to set %s: %d\n", argv[0], rc);
            return (rc);
        }
        else {
            sf_printf ("Successfully set %s\n", argv[0]);
        }
    }

    return (rc);
}
