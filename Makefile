PG_CONFIG?=pg_config

EXTENSION=bench_pg_unwind
SQL_FILES=sql/bench_pg_unwind.sql

EXT_VERSION = $(shell cat bench_pg_unwind.control | grep 'default' | sed "s/^.*'\(.*\)'$\/\1/g")
EXT_SQL_FILE = sql/$(EXTENSION)--$(EXT_VERSION).sql
PG_VER ?= pg12
TIMESCALEDB_VER ?= 1.7.0

DATA = $(EXT_SQL_FILE)
MODULE_big = $(EXTENSION)

SRCS = \
	src/bench.c

OBJS = $(SRCS:.c=.o)
DEPS = $(SRCS:.c=.d)

DEPS += target/release/libbench_pg_unwind.d

SHLIB_LINK_INTERNAL = target/release/libbench_pg_unwind.a

MKFILE_PATH := $(abspath $(MAKEFILE_LIST))
CURRENT_DIR = $(dir $(MKFILE_PATH))

TEST_PGPORT ?= 5432
TEST_PGHOST ?= localhost
TEST_PGUSER ?= postgres
TESTS = $(sort $(wildcard test/sql/*.sql))
USE_MODULE_DB=true
REGRESS = $(patsubst test/sql/%.sql,%,$(TESTS))
REGRESS_OPTS = \
	--inputdir=test \
	--outputdir=test \
	--host=$(TEST_PGHOST) \
	--port=$(TEST_PGPORT) \
	--user=$(TEST_PGUSER) \
	--load-language=plpgsql \
	--load-extension=$(EXTENSION)

PGXS := $(shell $(PG_CONFIG) --pgxs)

RUST_PG_INCLUDE := $(shell $(PG_CONFIG)  --includedir-server)

EXTRA_CLEAN = $(EXT_SQL_FILE) $(DEPS)

DOCKER_IMAGE_NAME=bench_pg_unwind
ORGANIZATION=timescaledev

include $(PGXS)
override CFLAGS += -DINCLUDE_PACKAGE_SUPPORT=0 -MMD
override pg_regress_clean_files = test/results/ test/regression.diffs test/regression.out tmp_check/ log/
-include $(DEPS)

all: $(EXT_SQL_FILE) target/release/libbench_pg_unwind.a

$(EXT_SQL_FILE): $(SQL_FILES)
	@cat $^ > $@

check-sql-files:
	@echo $(SQL_FILES)

rust: target/release/libbench_pg_unwind.a

bench_pg_unwind.so: target/release/libbench_pg_unwind.a

target/release/libbench_pg_unwind.a: Cargo.toml src/*.rs
	cargo build --release $(EXTRA_RUST_ARGS)

clean:
	rm -f $(OBJS) $(patsubst %.o,%.bc, $(OBJS))
	cd rust && cargo clean

install: $(EXT_SQL_FILE)

package: clean $(EXT_SQL_FILE)
	@mkdir -p package/lib
	@mkdir -p package/extension
	$(install_sh) -m 755 $(EXTENSION).so 'package/lib/$(EXTENSION).so'
	$(install_sh) -m 644 $(EXTENSION).control 'package/extension/'
	$(install_sh) -m 644 $(EXT_SQL_FILE) 'package/extension/'

docker-image: Dockerfile
	docker build --build-arg TIMESCALEDB_VERSION=$(TIMESCALEDB_VER) --build-arg PG_VERSION_TAG=$(PG_VER) -t $(ORGANIZATION)/$(DOCKER_IMAGE_NAME):latest-$(PG_VER) .
	docker tag $(ORGANIZATION)/$(EXTENSION):latest-$(PG_VER) $(ORGANIZATION)/$(EXTENSION):${EXT_VERSION}-$(PG_VER)

docker-push: docker-image
	docker push $(ORGANIZATION)/$(EXTENSION):latest-$(PG_VER)
	docker push $(ORGANIZATION)/$(EXTENSION):${EXT_VERSION}-$(PG_VER)

.PHONY: check-sql-files all docker-image docker-push rust