require "rack_utm/version"

module Rack
  class Utm
    DEFAULT_REQUIRED_PARAMETERS =
      %w[utm_source utm_medium utm_term utm_content utm_campaign].freeze

    def initialize(app, **options)
      @app = app
      @required_parameters =
        options.fetch(:required_parameters, DEFAULT_REQUIRED_PARAMETERS).map(&:to_s)
      @cookie_time_to_live = options.fetch(:cookie_time_to_live, default_cookie_time_to_live)
      @allow_overwrite = options.fetch(:allow_overwrite, true)
      @cookie_path = options[:cookie_path]
      @cookie_domain = options[:cookie_domain]
      @optional_parameters = options.fetch(:optional_parameters, []).map(&:to_s)
    end

    def call(env)
      @req = Rack::Request.new(env)

      set_env(env)

      status, headers, body = app.call(env)

      set_cookies(headers)

      [status, headers, body]
    end

    private

    attr_reader :app,
                :required_parameters,
                :cookie_time_to_live,
                :allow_overwrite,
                :cookie_path,
                :cookie_domain,
                :extras,
                :req,
                :optional_parameters

    def all_parameter_names
      required_parameters.concat(optional_parameters)
    end

    def params
      req.params
    end

    def cookies
      req.cookies
    end

    def set_cookies_for_env?
      !required_cookie_values.empty?
    end

    def set_params_for_env?
      return false unless !required_param_values.compact.empty?

      true
    end

    def values
      values = []
      values = cookies if set_cookies_for_env?
      values = newer_parameters if set_params_for_env? && allow_overwrite

      values
    end

    def set_env(env)
      values.each { |key, value| env["#{key}"] = value }
    end

    def required_param_values
      params.values_at(*required_parameters)
    end

    def required_cookie_values
      cookies.values_at(*required_parameters)
    end

    def default_cookie_time_to_live
      # 30 days
      60*60*24*30
    end

    def expires
      Time.now + cookie_time_to_live
    end

    def set_cookies?
      return false unless values.values_at(*required_parameters).all?
      required_param_values != required_cookie_values
    end

    def newer_parameters
      params
        .slice(*required_parameters.dup.concat(optional_parameters))
        .merge(
          'utm_from' => req.env["HTTP_REFERER"],
          'utm_time' => Time.now.to_i,
        )
    end

    def delete_cookies(headers)
      cookies.each_key do |key|
        cookie =
          {
            value: nil,
            expires: expires,
            domain: cookie_domain,
            path: cookie_path
          }

        Rack::Utils.delete_cookie_header!(headers, key, cookie)
      end
    end

    def set_cookies(headers)
      return unless set_cookies?
      values.each do |key, value|
        cookie =
          {
            value: value,
            expires: expires,
            domain: cookie_domain,
            path: cookie_path
          }

        Rack::Utils.set_cookie_header!(headers, key, cookie)
      end
    end
  end
end
