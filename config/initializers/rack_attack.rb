class Rack::Attack
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip
  end

  throttle("auth/ip", limit: 10, period: 20.minutes) do |req|
    req.ip if req.path =~ /\A\/auth\// && req.post?
  end

  throttle("logins/email", limit: 5, period: 20.minutes) do |req|
    if req.path == "/auth/login" && req.post?
      req.params["email"]&.downcase&.gsub(/\s+/, "")
    end
  end

  self.throttled_responder = lambda do |env|
    [
      429,
      { "Content-Type" => "application/json" },
      [{ error: "Too many requests. Please try again later." }.to_json]
    ]
  end
end
