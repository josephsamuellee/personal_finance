module Rack
  class Attack
    class Request
      def remote_ip
        forwarded = get_header("action_dispatch.remote_ip")
        forwarded.present? ? forwarded.to_s : ip
      end
    end
  end
end

Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

Rack::Attack.throttle("quick-expense/ip", limit: 10, period: 60) do |request|
  request.remote_ip if request.post? && request.path == "/quick-expense"
end

Rack::Attack.throttled_responder = lambda do |_request|
  [ 429, { "Content-Type" => "text/plain" }, [ "Too many expense submissions. Try again shortly.\n" ] ]
end
