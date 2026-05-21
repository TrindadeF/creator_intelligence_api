module Auth
  class JwtService
    ALGORITHM = "HS256".freeze

    def self.encode(payload, exp: nil)
      exp ||= JwtConfig::EXPIRATION_HOURS.hours.from_now.to_i
      payload = payload.merge(exp: exp, iat: Time.current.to_i)
      JWT.encode(payload, JwtConfig::SECRET_KEY, ALGORITHM)
    end

    def self.decode(token)
      return { success: false, error: "Token not provided" } if token.blank?

      decoded = JWT.decode(token, JwtConfig::SECRET_KEY, true, { algorithm: ALGORITHM })
      { success: true, payload: decoded.first }
    rescue JWT::ExpiredSignature
      { success: false, error: "Token has expired" }
    rescue JWT::DecodeError => e
      { success: false, error: "Invalid token: #{e.message}" }
    end
  end
end
