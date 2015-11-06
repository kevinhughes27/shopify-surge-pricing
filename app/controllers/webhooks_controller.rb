class WebhooksController < ApplicationController
  include ShopifyApp::WebhooksController

  def carts_update
    CartUpdateJob.perform_later(shop_domain: shop_domain, webhook: params[:webhook])
    head :ok
  end
end
