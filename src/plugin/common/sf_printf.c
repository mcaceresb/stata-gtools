#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include "sf_printf.h"

#define BUF_MAX 4096

void sf_printf_debug (const char *fmt, ...)
{
    va_list args;
    va_start (args, fmt);
    char buf[BUF_MAX];
    vsprintf (buf, fmt, args);
    printf ("%s", buf);
    SF_display (buf);
    va_end (args);
}

/**
 * @brief Short wrapper to print to Stata
 *
 * Basic wrapper to print formatted strings to Stata
 *
 * @param *fmt a string to format
 * @param ... Arguments to pass to pritnf
 * @return Prints to Stata's console
 */
void sf_printf (const char *fmt, ...)
{
    va_list args;
    va_start (args, fmt);
    char buf[BUF_MAX];
    vsprintf (buf, fmt, args);
    SF_display (buf);
    // printf (buf);
    va_end (args);
}

/**
 * @brief Short wrapper to print error to Stata
 *
 * Basic wrapper to print formatted error strings to Stata
 *
 * @param *fmt a string to format
 * @param ... Arguments to pass to pritnf
 * @return Prints to Stata's console
 */
void sf_errprintf (const char *fmt, ...)
{
    va_list args;
    va_start (args, fmt);
    char buf[BUF_MAX];
    vsprintf (buf, fmt, args);
    SF_error (buf);
    va_end (args);
}
