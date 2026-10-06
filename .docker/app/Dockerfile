# hadolint ignore=DL3006,DL3026
ARG BASE_IMAGE="harbor.k8s.temple.edu/library/ruby:4.0-alpine"
ARG BASH_VERSION="5.3.9-r1"
ARG LIBXSLT_VERSION="1.1.43-r3"
ARG POSTGRESQL_VERSION="17.11-r0"
ARG TZDATA_VERSION="2026e-r0"

# ==========================================
# STAGE 1: Builder
# ==========================================
# hadolint ignore=DL3006,DL3026
FROM "${BASE_IMAGE}" AS builder

# Switch to root to allow apk package installation
USER 0

WORKDIR /app

# Set build environment
ARG RAILS_ENV=production
ARG BASH_VERSION
ARG LIBXSLT_VERSION
ARG POSTGRESQL_VERSION
ARG TZDATA_VERSION
ENV RAILS_ENV=${RAILS_ENV}

# Install all dependencies needed for building gems/assets
RUN apk add -U --no-cache \
    bash=${BASH_VERSION} \
    build-base=0.5-r4 \
    git=2.54.0-r0 \
    yaml=0.2.5-r2 \
    yaml-dev=0.2.5-r2 \
    libxslt-dev=${LIBXSLT_VERSION} \
    libffi-dev=3.5.2-r1 \
    postgresql17-dev=${POSTGRESQL_VERSION} \
    nodejs=24.18.1-r0 \
    yarn=1.22.22-r1 \
    tzdata=${TZDATA_VERSION}

# Leverage Docker cache: Only copy dependency files first
COPY Gemfile Gemfile.lock package.json yarn.lock ./

# Install Ruby gems and Javascript packages
RUN BUNDLE_WITHOUT="development test" bundle install --jobs=8 && \
    yarn install --frozen-lockfile

# Copy the rest of the application code
COPY . .

# Handle fallback config maps, compile assets, and clean up in one layer.
# SECRET_KEY_BASE_DUMMY tells Rails not to require the production secret
# during asset precompilation and is not persisted as an environment variable.
RUN if [ ! -f config/apis.yml ]; then cp config/apis.yml.example config/apis.yml; fi && \
    BUNDLE_WITHOUT="development test" SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile && \
    rm -rf node_modules tmp/* && \
    find "$GEM_HOME" -name yarn.lock -exec rm "{}" \;

# Drop back to a standard user at the end of the builder stage to satisfy DL3002
USER 65534


# ==========================================
# STAGE 2: Final Runner
# ==========================================
# hadolint ignore=DL3006,DL3026
FROM "${BASE_IMAGE}" AS runner

WORKDIR /app

# Switch to root to install packages and configure directories
USER 0

ARG RAILS_ENV=production
ARG BASH_VERSION
ARG LIBXSLT_VERSION
ARG POSTGRESQL_VERSION
ARG TZDATA_VERSION

# Set production environment variables for the runtime container
ENV RAILS_ENV=${RAILS_ENV} \
    BUNDLE_WITHOUT="development:test" \
    LD_PRELOAD="libjemalloc.so.2" \
    MALLOC_CONF="dirty_decay_ms:1000,narenas:2,background_thread:true" \
    RUBY_YJIT_ENABLE="1"

# Install only runtime dependencies
RUN apk add -U --no-cache \
    bash=${BASH_VERSION} \
    jemalloc=5.3.0-r6 \
    libc6-compat=1.1.0-r4 \
    libxslt=${LIBXSLT_VERSION} \
    postgresql17-client=${POSTGRESQL_VERSION} \
    shared-mime-info=2.4-r7 \
    tzdata=${TZDATA_VERSION}

# Copy compiled gems and assets from the builder stage
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app /app

# Configure secure temporary directories
RUN mkdir -p /secure-tmp /secure-tmp/bootsnap /secure-tmp/cached_pages /secure-tmp/storage && \
    chown nobody:nobody -R /secure-tmp && \
    chmod 700 /secure-tmp /secure-tmp/bootsnap /secure-tmp/cached_pages /secure-tmp/storage && \
    mkdir -p /app/tmp /app/log && \
    chown nobody:nobody -R /app/tmp /app/log

# Drop down to a safe, unprivileged user for production execution
USER 65534

ENTRYPOINT [".docker/app/entrypoint.sh"]

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
