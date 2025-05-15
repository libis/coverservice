-- https://briandouglas.ie/sqlite-defaults/
-- Set the journal mode to Write-Ahead Logging for concurrency
PRAGMA journal_mode = WAL;

-- Set synchronous mode to NORMAL for performance and data safety balance
PRAGMA synchronous = NORMAL;

-- Set busy timeout to 5 seconds to avoid "database is locked" errors
PRAGMA busy_timeout = 5000;

-- Set cache size to 20MB for faster data access
PRAGMA cache_size = -20000;

-- Enable foreign key constraint enforcement
PRAGMA foreign_keys = ON;

-- Enable auto vacuuming and set it to incremental mode for gradual space reclaiming
PRAGMA auto_vacuum = INCREMENTAL;

-- Store temporary tables and data in memory for better performance
PRAGMA temp_store = MEMORY;

-- Set the mmap_size to 2GB for faster read/write access using memory-mapped I/O
PRAGMA mmap_size = 2147483648;

-- Set the page size to 8KB for balanced memory usage and performance
PRAGMA page_size = 8192;

CREATE TABLE IF NOT EXISTS "tenants"
(
    "id"   INTEGER PRIMARY KEY,
    "name" text not null,
    "code" text not null,
    "key"  text NOT NULL
);

CREATE TABLE IF NOT EXISTS "institutions"
(
    "id"        INTEGER PRIMARY KEY,
    "name"      text not null,
    "code"      text    not null,
    "tenant_id" integer NOT NULL,
    "key"       text NOT NULL,
    foreign key (tenant_id) references tenants (id)
);

CREATE TABLE IF NOT EXISTS "covers"
(
    "id"         INTEGER PRIMARY KEY,
    "institutions_id" integer NOT NULL,
    foreign key (institutions_id) references institutions (id)
);

CREATE TABLE IF NOT EXISTS "covers_exceptions"
(
    "id"         INTEGER PRIMARY KEY,
    "covers_id" integer NOT NULL,
    "description" text,
    foreign key (covers_id) references covers (id)
);

CREATE TABLE IF NOT EXISTS "audit"
(
    "id"                   INTEGER PRIMARY KEY,
    "tenant_code"          text      NOT NULL,
    "institution_code"     text      NOT NULL,
    "cover"                text      NOT NULL,
    "user_id"              text      NOT NULL,
    "execution_time"       timestamp NOT NULL,
    "method"               text      NOT NULL
);