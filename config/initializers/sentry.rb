require "uri"

dsn = ENV["SENTRY_DSN"].to_s.strip
sentry_enabled = ENV.fetch("SENTRY_ENABLED", "true") != "false"
dsn_host = URI.parse(dsn).host if dsn.present?

if !sentry_enabled
  Rails.logger.warn("Sentry disabled because SENTRY_ENABLED=false.")
elsif dsn.present? && dsn_host&.match?(/\Ao\d+\.ingest(\.[a-z0-9-]+)?\.sentry\.io\z/)
  Rails.logger.info("Sentry enabled with host: #{dsn_host}.")
  Sentry.init do |config|
    config.dsn = dsn
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]
    config.traces_sample_rate = ENV.fetch("SENTRY_TRACES_SAMPLE_RATE", 0.1).to_f
  end
elsif dsn.present?
  Rails.logger.warn("Sentry disabled because SENTRY_DSN host '#{dsn_host || "unknown"}' must use an o*.ingest*.sentry.io host.")
end
