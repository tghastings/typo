# syntax=docker/dockerfile:1
# Typo Blog - Rails 8 Docker Image
# Multi-stage build for optimized production image

# Stage 1: Base image with Ruby and system dependencies
FROM ruby:3.3-slim AS base

# Set working directory
WORKDIR /app

# Install base system dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    libsqlite3-0 \
    libpq5 \
    libyaml-0-2 \
    imagemagick \
    libvips42 \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

# Stage 2: Build stage for gems and assets
FROM base AS build

# Install build dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    libsqlite3-dev \
    libpq-dev \
    libyaml-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/ 2>/dev/null || true

# Precompile assets
RUN SECRET_KEY_BASE=placeholder bundle exec rails assets:precompile

# Stage 3: Production image
FROM base AS production

# Copy built artifacts from build stage
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app

# Create non-root user for security
RUN useradd -m -s /bin/bash rails && \
    chown -R rails:rails /app

# Create necessary directories
RUN mkdir -p /app/db /app/log /app/tmp/pids /app/tmp/cache /app/tmp/sockets /app/public/uploads && \
    chown -R rails:rails /app/db /app/log /app/tmp /app/public/uploads

# Switch to non-root user
USER rails

# Set environment variables
ENV RAILS_LOG_TO_STDOUT="1" \
    RAILS_SERVE_STATIC_FILES="true" \
    PORT="3000"

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:3000/ || exit 1

# Entrypoint script
COPY --chown=rails:rails docker-entrypoint.sh /app/
RUN chmod +x /app/docker-entrypoint.sh

ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
