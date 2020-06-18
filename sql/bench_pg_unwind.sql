
CREATE FUNCTION bench_cross_fn(num_iters BIGINT, start_num BIGINT, increment BIGINT)
RETURNS BIGINT AS '$libdir/bench_pg_unwind', 'bench_cross_fn'
LANGUAGE C VOLATILE;

CREATE FUNCTION bench_try_fn(num_iters BIGINT, start_num BIGINT, increment BIGINT)
RETURNS BIGINT AS '$libdir/bench_pg_unwind', 'bench_try_fn'
LANGUAGE C VOLATILE;
