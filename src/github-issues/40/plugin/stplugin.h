/*
	stplugin.h, version 2.0.0
	copyright (c) 2003, 2004, 2006                   StataCorp
*/
#if !defined(STPLUGIN_H)
#define STPLUGIN_H

#if !defined(SD_FASTMODE)
#define SD_SAFEMODE
#endif

#define	HP9000		1
#define OPUNIX          2
#define APPLEMAC	3
#define STWIN32         4

#ifndef SYSTEM
#define SYSTEM		STWIN32
#endif

typedef signed char	ST_sbyte ;
typedef unsigned char	ST_ubyte ;
typedef int		ST_int ;
typedef unsigned	ST_unsigned ;
typedef short int	ST_int2 ;
typedef int		ST_int4 ;
typedef long		ST_long ;
typedef unsigned int	ST_uint4 ;
typedef float		ST_float ;
typedef double		ST_double ;
typedef unsigned char	ST_boolean ;
typedef int		ST_retcode ;
typedef double *	ST_dmkey ;

#if !defined(bTrue)
#define bTrue		1
#define bFalse		0
#endif

#define SF_HIWORD(x)	((ST_int2)((ST_int4)(x)>>16))
#define SF_LOWORD(x)	((ST_int2)(x))
#define SF_MAKELONG(x,y)	((ST_int4)(((ST_int2)(x))|((ST_int4)((ST_int2)(y)))<<16))

#if SYSTEM==STWIN32
#if __cplusplus
#define STDLL	extern "C" __declspec(dllexport) ST_retcode
#else
#define STDLL   extern __declspec(dllexport) ST_retcode
#endif
#endif

#if SYSTEM!=STWIN32
#if SYSTEM==HP9000
#include <dl.h>
#endif

#if SYSTEM==OPUNIX
#include <dlfcn.h>
#endif

#if __cplusplus
#define STDLL extern "C" ST_retcode
#else
#define STDLL ST_retcode
#endif
#define LPSTR		char *
#endif

typedef struct {
	ST_int	type ;
	ST_int	nel ;
	ST_int	m ;
	ST_int	n ;
} ST_matinfo ;

#define SD_PLUGINMAJ	2
#define SD_PLUGINMIN	0
#define SD_PLUGINVER	SF_MAKELONG(SD_PLUGINMAJ,SD_PLUGINMIN)

typedef void		(* ST_VV)	(void) ;
typedef ST_int		(* ST_IV)	(void) ;
typedef ST_int		(* ST_IS)	(char *) ;
typedef void		(* ST_VU)	(ST_ubyte) ;
typedef ST_boolean	(* ST_BI)	(ST_int) ;
typedef ST_boolean	(* ST_BD)	(ST_double) ;
typedef ST_double	(* ST_DII)	(ST_int,ST_int) ;
typedef ST_double	(* ST_DV)	(void) ;
typedef ST_double	(* ST_DD)	(ST_double) ;
typedef ST_double	(* ST_DDD)	(ST_double,ST_double) ;
typedef ST_int		(* ST_ISS)	(char *,char *) ;
typedef ST_int		(* ST_ISI)	(char *,ST_int) ;
typedef ST_int		(* ST_ISSI)	(char *,char *,ST_int) ;
typedef void		(* ST_VSD)	(char *,ST_double) ;
typedef ST_int		(* ST_ISD)	(char *, ST_double) ;
typedef ST_int		(* ST_ISDp)	(char *,ST_double *) ;
typedef ST_int		(* ST_ISDpIIIII)	(char *,ST_int,ST_double *,ST_int,ST_int,ST_int,ST_int,ST_int) ;
typedef ST_int		(* ST_ISIID)	(char *, ST_int, ST_int, ST_double) ;
typedef ST_int		(* ST_ISIIDp)	(char *,ST_int,ST_int,ST_double *) ;
typedef ST_int		(* ST_ISDpI)	(char *,ST_double *,ST_int) ;
typedef void		(* ST_VSMip)	(char *,ST_matinfo *) ;
typedef ST_int		(* ST_IIIDp)	(ST_int, ST_int, ST_double *) ;
typedef ST_int 		(* ST_IIID)	(ST_int, ST_int, ST_double) ;
typedef char *		(* ST_SSI)	(char *,ST_int) ;
typedef char *		(* ST_SSSD)	(char *,char *,ST_double) ;
typedef char *		(* ST_SSSDM)	(char *,char *,ST_double, ST_dmkey) ;
typedef ST_int 		(* ST_IIIS)	(ST_int, ST_int, char *) ;

typedef struct {
	ST_IS		spoutsml ;
	ST_IS		spoutnosml ;
	ST_VV		spoutflush ;
	ST_VU		set_outputlevel ;
	ST_ISI		get_input ;

	ST_IV		pollstd ;
	ST_IV		pollnow ;

	ST_SSSD		safereforms ;
	ST_SSSDM	safereforml ;

	ST_SSI		gettok ;

	ST_ISS		macresave ;
	ST_ISSI		macuse ;

	ST_ISDp		scalaruse ;
	ST_ISDp		scalarsave ;

	ST_ISDpIIIII	matrixstore ;
	ST_ISDpI	matrixload ;
	ST_VSMip	matrixinfo ;
	ST_ISIIDp	matrixel ;
	ST_int		matsize ;

	ST_DII		data, safedata ;

	ST_IV		nobs ;
	ST_IV		nvar ;

	ST_double	missval ;
	ST_BD		ismissing ;

	ST_ISI		stfindvar ;
	ST_BI		isstr ;
	ST_VSD		abvarfcn ;

	ST_int		*stopflag ;

	ST_DDD		stround ;
	ST_DD		stsqrt ;
	ST_DDD		stpow ;
	ST_DD		stlog ;
	ST_DD		stexp ;
	ST_DV		strandom ;

	ST_IIID		store ;
	ST_IIID 	safestore ;
	ST_IIIS		sstore ;
	ST_BI		selobs ;
	ST_IV		nobs1 ;
	ST_IV		nobs2 ;
	ST_IV 		nvars ;    
	ST_IS		spouterr ;
	ST_ISIIDp	safematel ;
	ST_ISIID	safematstore ;
	ST_ISIIDp	matel ;
	ST_ISIID	matstore ;
	ST_IIIDp	safevdata ;
	ST_IIIDp	vdata ;
	ST_IS		colsof ;
	ST_IS		rowsof ;
	ST_ISD		scalsave ;

	ST_IIIS		sdata ;
} ST_plugin ;


#if __cplusplus
extern "C" ST_plugin *_stata_ ;
#else
extern ST_plugin *_stata_ ;
#endif
STDLL pginit(ST_plugin *p) ;

#define SF_display(a)		((_stata_)->spoutsml((a)))
#define SF_error(a)		((_stata_)->spouterr((a)))

#define SF_poll			((_stata_)->pollstd)
#define SW_stopflag		(*((_stata_)->stopflag))

#define SF_macro_save(m,t)	((_stata_)->macresave((m),(t)))
#define SF_macro_use(m,d,l)	((_stata_)->macuse((m),(d),(l)))

#define SF_scal_use(s,d)	((_stata_)->scalaruse((s),(d)))
#define SF_scal_save(s,d)	((_stata_)->scalsave((s),(d)))

#if defined(SD_SAFEMODE)
#define SF_mat_el(s,r,c,d)	((_stata_)->safematel((s),(r),(c),(d)))
#define	SF_mat_store(s,r,c,d)	((_stata_)->safematstore((s),(r),(c),(d)))
#else
#define SF_mat_el(s,r,c,d)	((_stata_)->matel((s),(r),(c),(d)))
#define	SF_mat_store(s,r,c,d)	((_stata_)->matstore((s),(r),(c),(d)))
#endif
#define SV_matsize		((_stata_)->matsize)
#define SF_col(s)		((_stata_)->colsof((s)))
#define SF_row(s)		((_stata_)->rowsof((s)))

#if defined(SD_SAFEMODE)
#define SF_vdata(i,j,d)		((_stata_)->safevdata((i),(j),(d)))
#define SF_vstore(i,j,v)	((_stata_)->safestore((i),(j),(v)))
#else
#define SF_vdata(i,j,d)		((_stata_)->vdata((i),(j),(d)))
#define SF_vstore(i,j,v)	((_stata_)->store((i),(j),(v)))
#endif

#define SF_nobs			((_stata_)->nobs)
#define SF_in1			((_stata_)->nobs1)
#define SF_in2			((_stata_)->nobs2)
#define SF_nvar			((_stata_)->nvar)
#define SF_nvars		((_stata_)->nvars)

#define SF_sstore(i,j,s)        ((_stata_)->sstore((i),(j),(s)))
#define SF_sdata(i,j,s)         ((_stata_)->sdata((i),(j),(s)))

#define SV_missval		((_stata_)->missval)

#define SF_is_missing(z)	((_stata_)->ismissing(z))
#define SF_ifobs(z)		((_stata_)->selobs(z))

#endif 
