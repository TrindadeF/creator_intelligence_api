Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Accept both default port and frontend port during development
    origins ENV.fetch("FRONTEND_URL", "http://localhost:3001"),
            "http://localhost:3000",
            "http://localhost:3001",
            "http://127.0.0.1:3001"
    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ["Authorization"],
      credentials: false,
      max_age: 600
  end
end
