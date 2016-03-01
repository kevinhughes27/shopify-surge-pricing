Shopify Surge Pricing
=====================

A demo of surge pricing for Shopify based on cart update webhooks. Originally Live coded at [Junction2015](http://hackjunction.com/), later presented at Unite 2015.


1. Rails New
------------

```
mkdir surge_app
cd surge_app

rails new .

git init
git add .
git ci -m "rails new"
```


2. Add Shopify App Gem
----------------------

```
gem 'shopify_app', '7.0.0'
bundle install
```


3. Make a new Shopify App
-------------------------

In the Shopify [partners area](https://app.shopify.com/services/partners/auth/login) make a new app, make sure to set the follow settings:

```
embedded: true
callback: https://kevin-shopifyapps.fwd.wf
redirect_uri: https://kevin-shopifyapps.fwd.wf/auth/shoify/callback
```

Note: I am using forward so I can receive webhooks locally and serve the app through ssl.


4. Run the generator
--------------------

Grab the api_key and secret from your new app and run the generator, I'm also passing the access scope we require to the generator:

```
rails g shopify_app -api_key=... -secret=... -scope="read_orders, write_products"
bundle exec rake db:migrate
```


5. Adding the webhook:
----------------------

To build our app we're going to need to listen to cart webhooks. Shopify sends this webhook anytime a cart is updated on the shop.

Adding a webhook is super simple with ShopifyApp - just add the webhook to the shopify_app initializer:

```ruby
config.webhooks = [
  {topic: 'carts/update', address: 'https://kevin-shopifyapps.fwd.wf/webhooks/carts_update', format: 'json'}
]
```

Shopify_app will now take care of creating this webhook for every shop when they install the app.

The webhooks are created using ActiveJob. ActiveJob is an abstraction for running tasks in different processes or with different worker computers. Since we haven't specified a backend for ActiveJob it will run the code inline like a normal function.


6. Install the App
-----------------------

visit `https://kevin-shopifyapps.fwd.wf` and install the app.

Note: If you're not using a service like forward or ngrok you'll need to click `load unsafe scripts` in the top right corner since localhost doesn't have ssl which is required for the esdk.


7. Testing the Webhook
----------------------

Now if we go add something to our cart we should see a request hit our server (might take a second since we have to wait for Shopify to send it and for forward to forward it)

Bam 500 ShopifyApp::MissingWebhookJobError

We defined our webhook but didn't define the job to process it. ShopifyApp provides a WebhooksController which will automatically receive the webhook, queue the right job (based on the request url) and respond to Shopify.


8. Processing the Webhook
------------------------

Now lets add a job to process the webhook by adding a new job class:

```ruby
class CartsUpdateJob < ActiveJob::Base
  def perform(shop_domain:, webhook:)
end
```

then we can add code to implement surge pricing. Its going to be a pretty naive implementation - anytime we get the cart update webhook we are going to add $1 to the price of each item in the cart and save the product.

```ruby
class CartsUpdateJob < ActiveJob::Base
  def perform(shop_domain:, webhook:)
    shop = Shop.find_by(shopify_domain: shop_domain)

    shop.with_shopify_session do
      line_items = webhook[:line_items]
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
