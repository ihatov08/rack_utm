Rack::UTM
================

Rack::UTM is a rack middleware that extracts information about the utm tracking codes.

Common Scenario
---------------

UTM links tracking is very common task if you want to promote your online business. This middleware helps you to do that.

1. Use UTM Link to promote your business like <code>http://yoursite.org?utm_source=ABC123....</code>.
2. A user clicks through the link and lands on your site.
3. Rack::Utm middleware finds <code>utm_*</code> parameters in the request, extracts them and saves it in a cookie
4. User signs up (now or later) and you know the utm params the user has assigned
5. PROFIT!

Installation
------------

Piece a cake:

    gem install rack_utm


Rails 3+ Example Usage
---------------------

Add the middleware to your application stack:

    # Rails 3 App - in config/application.rb
    class Application < Rails::Application
      ...
      config.middleware.use Rack::Utm
      ...
    end

    # Rails 2 App - in config/environment.rb
    Rails::Initializer.run do |config|
      ...
      config.middleware.use "Rack::Utm"
      ...
    end

Now you can check any request to see who came to your site via an affiliated link and use this information in your application. Affiliate tag is saved in the cookie and will come into play if user returns to your site later.

    class ExampleController < ApplicationController
      def index
        str = if request.env['utm_source']
          "Hallo, user! You've been referred here by #{request.env['utm_source']}, #{request.env['utm_medium']}, ...."
        else
          "We're glad you found us on your own!"
        end

        render :text => str
      end
    end


Customization
-------------

By default cookie is set for 30 days, you can extend time to live with <code>:ttl</code> option (default is 30 days).

    #Rails 3+ in config/application.rb
    class Application < Rails::Application
      ...
      config.middleware.use Rack::Utm, { cookie_time_to_live: 60*60*24*30 }
      ...
    end

The <code>:domain</code> option allows to customize cookie domain.

    #Rails 3+ in config/application.rb
    class Application < Rails::Application
      ...
      config.middleware.use Rack::Utm, cookie_domain: '.example.org'
      ...
    end

By default required parameters are `utm_source, utm_medium, utm_campaign, utm_content, utm_term`.
The <code>:required_parameters</code> option change required parameters.

    #Rails 3+ in config/application.rb
    class Application < Rails::Application
      ...
      config.middleware.use Rack::Utm, required_parameters: %w[utm_source]
      ...
    end

If you want to tracking optional parameters(not required), please use <code>optional_parameters</code> option.

    #Rails 3+ in config/application.rb
    class Application < Rails::Application
      ...
      config.middleware.use Rack::Utm, optional_parameters: %w[optional_param]
      ...
    end

Middleware will set cookie on <code>.example.org</code> so it's accessible on <code>www.example.org</code>, <code>app.example.org</code> etc.

The <code>:overwrite</code> option allows to set whether to overwrite the existing utm tag(`required_parameters`) previously stored in cookies. By default it is set to `true`.

Credits
=======

Thanks goes to Rack::Affiliates (https://github.com/alexlevin/rack-affiliates) for the inspiration.
