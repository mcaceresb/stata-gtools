#ifndef ST_PRINT
#define ST_PRINT

void sf_printf (const char *fmt, ...);
void sf_errprintf (const char *fmt, ...);

/*
 * #if defined(_WIN64) || defined(_WIN32)
 * 
 * #define COMMA_PRINTING                      \
 *     setlocale(LC_NUMERIC, "");              \
 *     struct lconv *ptrLocale = localeconv(); \
 *     strcpy(ptrLocale->thousands_sep, ",");
 * #else
 * #define COMMA_PRINTING setlocale (LC_ALL, "");
 * #endif
 *
 */

#endif
