Rails.configuration.stripe = {
  publishable_key: ENV['STRIPE_PUBLISHABLE_KEY'],
  secret_key:      ENV['STRIPE_SECRET_KEY']
}

Stripe.api_key = Rails.configuration.stripe[:secret_key]

# Force Stripe gem (Net::HTTP) to use IPv4 only — resolves NAT64/DNS fallback
# timeouts on networks where api.stripe.com is unreachable via IPv6.
require "net/http"
require "resolv"

module Net
  class HTTP
    alias_method :__original_address__, :address

    def address
      # Resolve hostname to IPv4 address only to avoid NAT64/IPv6 timeouts
      ipv4 = ::Resolv::DNS.new.getaddresses(__original_address__).find do |addr|
        addr.is_a?(::Resolv::IPv4)
      end
      ipv4 ? ipv4.to_s : __original_address__
    rescue Resolv::ResolvError
      __original_address__
    end
  end
end
