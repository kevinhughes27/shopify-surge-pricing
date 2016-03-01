ShopifyApp.configure do |config|
  config.api_key = "49190734efd79b5110b1e43ea7b5c3e7"
  config.secret = "f188e5de374bfcf59905afce94d16be5"
  config.redirect_uri = "https://kevin-shopifyapps.fwd.wf/auth/shopify/callback"
  config.scope = "read_orders, write_products"
  config.embedded_app = true
end
