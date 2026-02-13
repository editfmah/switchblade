# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Switchblade is a Swift ORM/persistence framework providing type-safe, protocol-based data storage with pluggable backends (SQLite, sharded SQLite, UserDefaults). It uses `Codable` generics for automatic serialization, supports encryption at rest (AES-256-CBC via CryptoSwift), TTL-based expiration, reactive data bindings, schema versioning/migration, and atomic transactions.

- **Swift Tools Version**: 6.2
- **Platform**: macOS 10.15+
- **System dependency**: libsqlite3 (wrapped via CSQLite system library target)

## Build & Test Commands

```bash
swift build                  # Build the library
swift test                   # Run all tests
swift test --filter SwitchbladeTests/switchbladeTests/testPersistObject  # Run a single test
```

Tests create temporary `.db` files in the current working directory using random UUIDs.

## Architecture

### Data Hierarchy

**Partition** → **Keyspace** → **Key** → **Object (JSON blob)**

Default partition is `"default"`. Keyspace groups objects by type (e.g. `"person"`). Keys are `PrimaryKeyType` (Int, UUID, or String).

### Core Protocol Chain

`Switchblade` (main class, `@unchecked Sendable`) implements functionality via extensions, each backed by a protocol:

| Protocol | Purpose |
|---|---|
| `SwitchbladeInterface` | Init/close lifecycle |
| `SwitchbadeRetriever` | `get`, `all`, `query`, `iterate` |
| `SwitchbadePutter` | `put` operations |
| `SwitchbadeRemove` | `remove` operations (soft-delete via TTL) |
| `SwitchbadeBinder` | Reactive `SWBinding`/`SWBindingCollection` |
| `Atomic` | `perform {}` transactions with `.success`/`.failure`/`.finally` |

Note: the protocol names use the spelling `Switchbade` (missing 'l') — this is intentional existing naming.

### DataProvider Protocol

All backends implement `DataProvider` (`Core/DataProvider.swift`). Methods receive already-resolved partition/keyspace/key strings. The `Switchblade` extensions handle extracting these from `Identifiable` and `KeyspaceIdentifiable` conformances before calling the provider.

### Storage Providers

- **SQLiteProvider** — Single SQLite file. Compound primary key `(partition, keyspace, id)`. Full transaction support. Background TTL cleanup every 60s.
- **SQLiteShardProvider** — One SQLite file per (partition, keyspace) pair, stored as `{md5(partition+keyspace)}.sqlite` in a directory. Each shard uses a simplified schema with just `id` as primary key. No cross-shard transactions.
- **UserDefaultsProvider** — Minimal implementation using `UserDefaults.standard`. No filtering, transactions, or TTL.

### Model Protocols

Objects stored in Switchblade must be `Codable`. Additional protocols provide features:

- **`Identifiable`** — `var key: PrimaryKeyType` — automatic key extraction on put/get
- **`KeyspaceIdentifiable`** — `var keyspace: String` — automatic keyspace routing
- **`Filterable`** — `var filters: [Filters]` — indexed filter columns (MD5-hashed for LIKE queries)
- **`SchemaVersioned`** — `static var version: (objectName: String, version: Int)` — enables `migrate(from:to:migration:)`
- **`CompositeKey`** — multi-field keys joined with `|` separator

### Thread Safety

All provider operations are synchronized through `Mutex` (`Core/Mutex.swift`), a custom wrapper around `DispatchQueue` that detects same-thread re-entrancy to avoid deadlocks.

### Key Source Layout

```
Sources/switchblade/
  Switchblade.swift              # Main class, WeakContainer for bindings
  Core/
    protocols/                   # All protocol definitions
    Providers/                   # SQLiteProvider, SQLiteShardProvider, UserDefaultsProvider
    Switchblade+Query.swift      # Retrieval extension
    Switchblade+Setters.swift    # Put extension
    Switchblade+Delete.swift     # Delete extension
    Switchblade+Bindings.swift   # Reactive binding extension
    Switchblade+Atomic.swift     # Transaction extension
    Switchblade+Migration.swift  # Schema migration extension
    SwitchbladeConfig.swift      # Configuration (encryption key, hash filters, etc.)
    SWBinding.swift              # SWBinding<T> and SWBindingCollection<T>
Sources/CSQLite/                 # System library module map for libsqlite3
```
