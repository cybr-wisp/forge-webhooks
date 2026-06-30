# Webhook Vault

A lightweight Rails API that ingests arbitrary webhook payloads into PostgreSQL
JSONB, with a 1-click replay tool and a React/Vite dashboard. Built to be
benchmarked honestly — the numbers you put on your resume should come from
the `benchmarks/` scripts below, run on your own machine.

I can't run Ruby/Rails/Postgres inside this sandbox (no Ruby installed, and
rubygems.org isn't network-reachable from here), so this repo is built for
you to generate + drop in locally. It's ~15 minutes of setup, then the app
just runs.

---

## 1. Generate the Rails API skeleton

You need Ruby 3.x and PostgreSQL installed locally (`brew install postgresql`
on Mac, or use the Postgres.app / Windows installer). Then:

```bash
cd webhook-vault
rails new api --api --database=postgresql --skip-test
cd api
```

This creates the full Rails boilerplate (config/boot.rb, config/application.rb,
bin/rails, etc.) which is brittle to hand-write and not worth reproducing —
`rails new` does it correctly every time.

## 2. Drop in the app-specific files

Copy these files from this repo into the generated `api/` folder, overwriting
where they collide:

```
app/models/webhook_event.rb
app/controllers/application_controller.rb
app/controllers/api/v1/webhooks_controller.rb
app/controllers/api/v1/replays_controller.rb
db/migrate/<timestamp>_create_webhook_events.rb
config/puma.rb
config/initializers/cors.rb
```

And append the contents of `config/routes_snippet.rb` into your generated
`config/routes.rb`, and the contents of `Gemfile_additions.txt` into your
generated `Gemfile`.

## 3. Install gems, set up DB, run

```bash
bundle install
bin/rails db:create db:migrate
bin/rails server -p 3000
```

## 4. Run the frontend

```bash
cd ../frontend
npm install
npm run dev
```

Vite dev server proxies `/api` to `localhost:3000` (see `vite.config.js`),
so CORS only matters in production — `config/initializers/cors.rb` handles
that for the deployed case.

## 5. Get your real numbers

```bash
cd ../benchmarks
ruby latency_test.rb         # 50 sequential POSTs, prints avg/median/p95 write latency
./load_test.sh               # wrk-based concurrent throughput test
ruby replay_delta.rb         # times the 1-click replay vs a scripted "manual Postman" baseline
```

Whatever those print is what goes on the resume. If your numbers come in
different from the bullet points you started with (4.2ms / 620 req/s / 93%),
that's normal — hardware, Postgres config, and Puma thread count all move
these. Use your actual numbers; they hold up better in an interview than
round ones you can't reproduce live.

## 6. CI

`.github/workflows/ci.yml` runs `rails test` against a Postgres service
container and builds the frontend on every push. Push to GitHub and it
should go green out of the box.
