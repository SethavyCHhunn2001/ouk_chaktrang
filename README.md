# Ouk Chaktrang (អុកចត្រង្គ) – Flutter

Setup (Flutter 3.22+):
1. `flutter create ouk_chaktrang` then copy `lib/` and `pubspec.yaml` from this folder over it
   (or `cd` here and run `flutter create .` to add the platform folders).
2. `flutter run`

Structure
- lib/game/engine.dart       rules, legal moves, check/mate, AI search, game review
- lib/game/controller.dart   match state, clocks, AI turns (isolate), draw/resign
- lib/game/board_view.dart   board + piece widgets
- lib/screens/               lobby, match, rules guide, analysis

Oracle database and API (local development)
1. Install Docker with Compose.
2. Copy `.env.example` to `.env` and set strong local values for `ORACLE_PASSWORD` and `DB_PASSWORD`.
3. Start the database and API with `docker compose up --build -d`.
   The first Oracle startup can take a few minutes while the database is initialized.
4. Check API liveness at `http://localhost:3000/api/health` and Oracle readiness at
   `http://localhost:3000/api/health/ready`.
5. Stop the services with `docker compose down`. The named `oracle_data` volume keeps
   database data; remove it only when you intentionally want to erase that data.

Oracle is available on localhost port 1522 by default (override with `ORACLE_HOST_PORT`
if that port is also in use). The API connects to the database internally on port 1521.
The API container connects to Oracle over Docker's private network and keeps database
credentials out of the Flutter app. To run the API directly with Node instead, first
start Oracle with `docker compose up -d oracle`, then run `docker compose stop api` to
free port 3000. From `backend/`, run `npm ci` once and `npm run start`; the start script
loads `../.env` and connects to the host-mapped Oracle port. The API currently exposes
health checks only; game/profile tables and Flutter data features can be added once
their requirements are defined.
