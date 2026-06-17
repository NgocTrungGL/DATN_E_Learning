require "uri"

dsn = ENV["SENTRY_DSN"].to_s.strip
dsn_host = URI.parse(dsn).host if dsn.present?

if dsn.present? && dsn_host&.match?(/\Ao\d+\.ingest(\.[a-z0-9-]+)?\.sentry\.io\z/)
  Sentry.init do |config|
    config.dsn = dsn
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]
    config.traces_sample_rate = ENV.fetch("SENTRY_TRACES_SAMPLE_RATE", 0.1).to_f
  end
elsif dsn.present?
  Rails.logger.warn("Sentry disabled because SENTRY_DSN must use an o*.ingest*.sentry.io host.")
end
