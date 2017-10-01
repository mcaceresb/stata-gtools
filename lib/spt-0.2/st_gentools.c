/**
 * @file st_gentools.c
 * @version 0.3.0
 * @author Mauricio Caceres Bravo
 * @email <mauricio.caceres.bravo@gmail.com>
 * @date 25 Jul 2017
 * @brief General-purpose utility functions for writing Stata plugins
 *
 * These are various wrappers to make it easier to write Stata plugins.
 * At the moment it only contains printf function wrappers to print
 * formatted statements to the Stata console, but I plan to expand the
 * utilities in future versions.
 *
 * Note because functions are for use by Stata C-based plugins they
 * must be used in conjunction with stplugin.c and stplugin.h (see
 * stata.com/plugins for more on Stata plugins). In particular, both
 * should exist in the same directory and your main file should have
 *
 *     #include "stplugin.h"
 *
 * as one of its include statements.
 *
 * @see st_gsltools.c
 * @see http://www.stata.com/plugins for more on Stata plugins
 */

#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
// #include <locale.h>
#include "st_gentools.h"

#define BUF_MAX 4096

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
