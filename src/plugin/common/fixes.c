#ifdef __APPLE__
#else
void * memcpy (void *dest, const void *src, size_t n);

/**
 * @brief Implement memcpy as a dummy function for memset (not on OSX)
 *
 * Stata requires plugins to be compied as shared executables. Since
 * this is being compiled on a relatively new linux system (by 2017
 * standards), some of the dependencies set in this way cannot be
 * fulfilled by older Linux systems. In particular, using memcpy as
 * provided by my system creates a dependency to Glib 2.14, which cannot
 * be fulfilled on some older systems (notably the servers where I
 * intend to use the plugin; hence I implement memcpy and get rid of
 * that particular dependency).
 *
 * @param dest pointer to place in memory to copy @src
 * @param src pointer to place in memory that is source of data
 * @param n how many bytes to copy
 * @return move @src to @dest
 */
void * memcpy (void *dest, const void *src, size_t n)
{
    return memmove(dest, src, n);
}
#endif

// TODO: nice platform-specific way to profile time; the below is hack-ish

#if defined(_WIN64) || defined(_WIN64) || defined(__MINGW32__) || defined(__MINGW64__)

#define GTOOLS_TIMER(GtoolsTimerVariable) clock_t (GtoolsTimerVariable) = clock();
#define GTOOLS_RUNNING_TIMER(GtoolsTimerVariable, msg) sf_running_timer(&GtoolsTimerVariable, msg)
#define GTOOLS_UPDATE_TIMER(GtoolsTimerVariable) GtoolsTimerVariable = clock()

#elif defined(__APPLE__)

#define GTOOLS_TIMER(GtoolsTimerVariable) clock_t (GtoolsTimerVariable) = clock();
#define GTOOLS_RUNNING_TIMER(GtoolsTimerVariable, msg) sf_running_timer(&GtoolsTimerVariable, msg)
#define GTOOLS_UPDATE_TIMER(GtoolsTimerVariable) GtoolsTimerVariable = clock()

#else

void sf_running_timespec (struct timespec *timer, const char *msg);
void sf_running_timespec (struct timespec *timer, const char *msg)
{
    struct timespec update; clock_gettime(CLOCK_REALTIME, &update);
    double diff  = (double) (update.tv_nsec - timer->tv_nsec) / 1e9 +
                   (double) (update.tv_sec  - timer->tv_sec);

    sf_printf (msg);
    sf_printf (" (%.3f seconds).\n", diff);
    *timer = update;
}

#define GTOOLS_TIMER(GtoolsTimerVariable) \
    struct timespec (GtoolsTimerVariable); \
    clock_gettime(CLOCK_REALTIME, &GtoolsTimerVariable)

#define GTOOLS_RUNNING_TIMER(GtoolsTimerVariable, msg) \
    sf_running_timespec(&GtoolsTimerVariable, msg)

#define GTOOLS_UPDATE_TIMER(GtoolsTimerVariable) \
    clock_gettime(CLOCK_REALTIME, &GtoolsTimerVariable)

#endif
