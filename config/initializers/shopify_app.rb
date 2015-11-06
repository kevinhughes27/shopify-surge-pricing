ShopifyApp.configure do |config|
  config.api_key = "e6fcc6d3b4fdf4b1c442b98b8a1ff820"
  config.secret = "6f8aa47e61a9c5d44dee914f5c3bafcf"
  config.redirect_uri = "http://localhost:3000/auth/shopify/callback"
  config.scope = "read_orders, read_products"
  config.embedded_app = true
end
