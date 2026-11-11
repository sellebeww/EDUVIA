# Copyright (c) 2026 Vassel Goleyu. All rights reserved.
# Image demo/pengembangan Siaga Kelas. Dijalankan lewat `docker compose up`.
FROM ruby:3.4-slim

RUN apt-get update -qq \
 && apt-get install -y --no-install-recommends build-essential git libpq-dev libyaml-dev curl postgresql-client \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /rails
ENV RAILS_ENV=development \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_JOBS=4

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .
RUN chmod +x bin/*

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
