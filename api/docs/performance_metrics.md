# Performance & Quality Metrics — Forge

## API Performance
| Metric | Value | How it was measured |
|---|---|---|
| Write latency (avg) | 51.9ms | 50 sequential POSTs, persistent connection, first 2 discarded as warmup — `benchmarks/latency_test.rb` |
| Write latency (median) | 51.8ms | Same run as above |
| Write latency (p95) | 70.8ms | Same run as above |
| Sustained throughput | 55.5 req/sec | 20 concurrent threads, 10-second window, 567 completed requests — `benchmarks/throughput_test.rb` |
| Puma configuration | Single-process, 16-thread pool | Windows dev environment (no `fork()` support); Linux deployment with multiple workers would scale further |

## Replay Mechanism
| Metric | Value | How it was measured |
|---|---|---|
| Manual workflow steps replaced | 4 steps → 1 action | `POST /api/v1/webhooks/:id/replays` returns `201` with original payload re-delivered |
| Verified via | Single `curl` call | Manual verification, not yet scripted into `benchmarks/` |

## Data Layer
| Metric | Value |
|---|---|
| Storage format | PostgreSQL JSONB with GIN index |
| Test coverage | TBD |
| Records ingested (load test) | TBD — count rows from `loadtest` source in DB |

## Frontend
| Metric | Value |
|---|---|
| Stack | React 18 + Vite |
| Verified | Rendering stored webhooks, working replay buttons — manual check via `npm run dev` |
| Automated frontend tests | TBD |