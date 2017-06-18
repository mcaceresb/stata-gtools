/* adapted from https://github.com/kousu/statasvm/blob/master/src/_svm_setenv.c */
/* env_append.c: a Stata plugin to append to environemnt variables */

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
    return (_putenv_s(name, value));
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

    if ( argc != 2 ) {
        sf_errprintf ("env_append: incorrect number of arguments (%d). Use:\n", argc);
        sf_errprintf ("\tplugin call env_append, ENV `\"APPEND\"'\n");
        return (198);
    }
    else if ( argc == 2 ) {
        // lookup the environemnt variable
        char* env_value = getenv(argv[0]);
        if ( env_value == NULL ) {
            env_value = EMPTY;
        }
        sf_printf ("Read %s as '%s'\n", argv[0], env_value);

        // Append to it
        char *append_to_env;
        append_to_env = malloc(sizeof(char) * strlen(argv[1]));
        memset (append_to_env, '\0', strlen(argv[1]));
        memcpy (append_to_env, argv[1], strlen(argv[1]));
        sf_printf ("Read append as '%s'\n", append_to_env);

        char *new_env_value;
        new_env_value = malloc(sizeof(char) * (strlen(append_to_env) + strlen(env_value) + 1));
        memset (new_env_value, '\0', strlen(append_to_env) + strlen(env_value) + 1);

        memcpy (new_env_value, env_value, strlen(env_value));
        memset (new_env_value + strlen(env_value), ENV_DELIM, 1);
        memcpy (new_env_value + strlen(env_value) + 1, append_to_env, strlen(append_to_env));
        sf_printf ("New value is '%s'\n", new_env_value);

        // Set it
        rc = setenv(argv[0], new_env_value, 1);
        if ( rc ) {
            sf_errprintf ("env_append: unable to append to %s: %d\n", argv[0], rc);
            return (rc);
        }
        else {
            sf_printf ("Appended '%s' to %s\n", append_to_env, argv[0]);
        }
    }
    return (0);
}
