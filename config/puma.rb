# Puma configuration file for Typo Blog
# https://github.com/puma/puma

# Thread pool configuration
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Worker count for production
worker_count = ENV.fetch("WEB_CONCURRENCY") { 2 }

if ENV["RAILS_ENV"] == "production"
  workers worker_count
  preload_app!
end

# Port binding
port ENV.fetch("PORT") { 3000 }

# Environment
environment ENV.fetch("RAILS_ENV") { "development" }

# Puma control app for stats and management (development only)
if ENV["RAILS_ENV"] == "development"
  plugin :tmp_restart
end

# PID file
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# Logging
stdout_redirect(
  ENV.fetch("PUMA_STDOUT") { nil },
  ENV.fetch("PUMA_STDERR") { nil },
  true
) if ENV["PUMA_STDOUT"]

# Worker boot hook
on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

# Lower latency for first request
lowlevel_error_handler do |e|
  [500, {}, ["An error has occurred: #{e.message}"]]
end
