/* This file and its contents are licensed under the Apache License 2.0.
 * Please see the included NOTICE for copyright information and
 * LICENSE for a copy of the license
 */

#include <postgres.h>
#include <fmgr.h>


#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif

PG_FUNCTION_INFO_V1(bench_cross_fn);
PG_FUNCTION_INFO_V1(bench_try_fn);

/* linker hack to make sure the rust code is actually linked in */
Datum _ensure_functions_link(PG_FUNCTION_ARGS);
Datum
_ensure_functions_link(PG_FUNCTION_ARGS)
{
	bench_cross_fn(fcinfo);
	bench_try_fn(fcinfo);
	return 0;
}

int64 bench_pg_fn_add(int64 a, int64 b);

int64
bench_pg_fn_add(int64 a, int64 b)
{
	return a + b;
}

