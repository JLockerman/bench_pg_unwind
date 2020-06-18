
use std::time::{
    Duration,
    Instant,
};

use timescale_extension_utils::{
    elog,
    elog::Level::Warning,
    postgres_headers_rs::guard_pg,
    pg_fn,
};

extern "C" {
    fn bench_pg_fn_add(a: i64, b: i64) -> i64;
}

pg_fn!{
    pub fn bench_cross_fn(n: i64, s: i64, i: i64) -> i64 {
        let start = Instant::now();
        let mut s = s;
        for _ in 0..n {
            s = bench_pg_fn_add(s, i)
        }
        let elapsed = start.elapsed();
        print_time(start.elapsed(), n);
        s
    }

    pub fn bench_try_fn(n: i64, s: i64, i: i64) -> i64 {
        let start = Instant::now();
        let mut s = s;
        for _ in 0..n {
            s = guard_pg(|| bench_pg_fn_add(s, i))
        }
        print_time(start.elapsed(), n);
        s
    }
}

fn print_time(time: Duration, iters: i64) {
    let per_iter = time.div_f64(iters as f64);
    elog!(Warning, "\ntotal time elapsed: {}.{:09} seconds\n     time per iter: {}.{:09} seconds",
        time.as_secs(), time.subsec_nanos(),
        per_iter.as_secs(), per_iter.subsec_nanos(),
    );
}
