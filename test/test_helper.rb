$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "rack_utm"
require "minitest/autorun"
require 'rack/test'
require 'timecop'

class Minitest::Test
  include Rack::Test::Methods

  def app
    application = lambda { |env| [200, {}, 'All responses are OK'] }

    @app = Rack::Utm.new(application, **(@options || {}))
  end
end
