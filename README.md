# Creator Intelligence API

API-only Rails 8 backend for creator analytics, audience insights, JWT authentication, and background processing.

## Stack

- Ruby 3.2.3
- Rails 8.0.5 API-only
- PostgreSQL
- Redis + Sidekiq
- JWT authentication
- Blueprinter serializers
- Pagy pagination
- Rack Attack rate limiting
- RSpec + FactoryBot + Faker + Shoulda Matchers

## Setup

```bash
cd /home/felipepd7/my-workflow/forCreatorsTk/creator_intelligence_api
bundle install
cp .env.example .env
```

Update `.env` as needed, then create and prepare the database in an environment with PostgreSQL and Redis running:

```bash
bundle exec rails db:create
bundle exec rails db:migrate
```

## Run the app

```bash
bundle exec rails server
```

## Run Sidekiq

```bash
bundle exec sidekiq -C config/sidekiq.yml
```

## Run tests

```bash
bundle exec rspec
```

## Docker

```bash
docker compose up --build
```

## Important endpoints

- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/refresh`
- `POST /auth/logout`
- `GET /me`
- `GET /videos`
- `GET /analytics/overview`
- `GET /insights`
- `GET /health`
