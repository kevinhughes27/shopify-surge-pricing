Shopify Surge Pricing
=====================

A demo of surge pricing for Shopify based on cart update webhooks. Live coded at [Junction2015](http://hackjunction.com/)


1. Rails New
------------

```
rails new appinfive

cd appinfive

git init
git add .
git ci -m "rails new"

atom appinfive &
```


2. Add Shopify App Gem
----------------------

```
gem 'shopify_app', '6.3.0'
bi
```


3. Make a new Shopify App
-------------------------

In the Shopify [partners area](https://app.shopify.com/services/partners/auth/login) make a new app, make sure to set the follow setings:

```
embedded: true
callback: http://localhost:3000/
redirect_uri: http://localhost:3000/auth/shoify/callback
```


4. Run the generator
--------------------

Grab the api_key and secret from your new app and run the generator:

```
rails g shopify_app -api_key=... -secret=...
bx rake db:migrate
```


5. Demo the app install
-----------------------

visit `http://localhost:3000` and install the app. After the app is installed click `load unsafe scripts` in the top right corner (since localhost doesn't have ssl you need to do this for the esdk to load locally)


6. Adding the webhook:
----------------------

To build our app we're going to need to listen to cart webhooks. Shopify sends this webhook anytime a cart is updated for the shop.

We're going to use some new hotness from the [shopify_app](https://github.com/Shopify/shopify_app) gem to make and handle our webhook - I seriously pushed this change at 4:40 today so this is fresh.


To receive the webhook locally we are going to use ngrok to forward the hook. Install and start ngrok to get the url:

`ngrok http 3000`


Then add the webhook to the shopify_app initializer:

```ruby
config.webhooks = [
  {topic: 'carts/update', address: 'https://d3ca26ed.ngrok.io/webhooks/carts_update', format: 'json'}
]
```

Shopify_app will now take care of creating this webhook for every shop when they install the app.

The webhooks are created using ActiveJob which will run inline without a proper queue but we're going to do this legit so lets add `sidekiq` to our app:

```
gem 'sidekiq'
bi
```

and we need to configure active job

in application.rb
`config.active_job.queue_adapter = :sidekiq`

and we'll need an instance of `redis` running

`redis-server`


Lets this out and see if our Webhooks gets created:

```
bx rails s
bx sidekiq
```

If we look in the sidekiq console we can see that our job ran!


7. Testing the Webhook
----------------------

Now if we go add something to our cart we should see a request hit our server

Might take a second and bam 404 we dont' have a route yet.


8. Receiving the Webhook
------------------------

first lets make our controller:

```ruby
class WebhooksController < ApplicationController
  include ShopifyApp::WebhooksController
end
```

and lets add our route

```ruby
namespace :webhooks do
  post '/carts_update' => :carts_update
end
```

And lets add our code to implement surge pricing. Its going to be a pretty naive implementation - anytime we get the cart update webhook we are going to add $1 to the price of each item in the cart and save the product.

And we're going to be good developers and background receiving the webhook:

```ruby
  def carts_update
    CartUpdateJob.perform_later(shop_domain: shop_domain, webhook: params[:webhook])
    head :ok
  end
```

and the job implementation:

```ruby
class CartUpdateJob < ActiveJob::Base

  def perform(params = {})
    shop = Shop.find_by(shopify_domain: params[:shop_domain])

    shop.with_shopify_session do
      line_items = params[:webhook][:line_items]
      line_items.each do |item|
        variant_id = item[:variant_id]
        price = item[:price].to_f

        ShopifyAPI::Variant.new({
          id: variant_id,
          price: price + 1
        }).save
      end
    end
  end

end
```

before this can work we need to update our App permissions to include writing products:

```ruby
ShopifyApp.configure do |config|
  #...
  config.scope = "read_orders, write_products"
  #...
end
```
