# Tuned thread pool for the throughput benchmark. Puma's sweet spot for an
# I/O-bound (DB-write-heavy) Rails API is usually 4-16 threads per worker —
# more threads than that just adds context-switch overhead without raising
# throughput, since Postgres becomes the bottleneck first.

max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 16 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { 8 }
threads min_threads_count, max_threads_count

# Multiple worker processes lets you use more than one CPU core — set this
# to your machine's core count when load-testing for the throughput number.
workers ENV.fetch("WEB_CONCURRENCY") { 0 }

# on_worker_boot do
#   ActiveRecord::Base.establish_connection
# end

preload_app!

port ENV.fetch("PORT") { 3000 }

plugin :tmp_restart

on_worker_boot do
  ActiveRecord::Base.establish_connection
end
