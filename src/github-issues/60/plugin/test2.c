#include "stplugin.h"
#include "spookyhash_api.h"

#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main()
{
    return(0);
}

int WinMain()
{
    return(0);
}

STDLL stata_call(int argc, char *argv[])
{
    char * buffer = malloc(1024 * sizeof(char));
    char * string = strdup("foo");

    ST_double * number = calloc(1, sizeof(ST_double));
    number[1] = 1729.42;

    sprintf (buffer, "%s: %9.2f\n", string, *number);
    SF_display (buffer);

    uint64_t h1, h2;
    spookyhash_128(number, sizeof(ST_double), &h1, &h2);

    sprintf (buffer, "hash: %"PRIu64", %"PRIu64"\n", h1, h2);
    SF_display (buffer);

    free (buffer);
    return(0) ;
}
