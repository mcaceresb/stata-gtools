/*
    stplugin.c, version 2.0
    copyright (c) 2003, 2006        			StataCorp
*/

#include "stplugin.h"

ST_plugin *_stata_ ;

STDLL pginit(ST_plugin *p)
{
	_stata_ = p ;
	return(SD_PLUGINVER) ;
}
