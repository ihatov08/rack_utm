require "test_helper"
require 'pry'

class RackUtmTest < Minitest::Test
  def test_empty_required_parameters
    get '/'
    query_strings.each do |key, value|
      assert_nil last_request.env[key]
    end
  end

  def test_set_required_parameters
    Timecop.freeze do
      @time = Time.now

      get '/', query_strings, 'HTTP_REFERER' => 'http://example.com'
    end

    query_strings.each do |key, value|
      assert_equal value, last_request.env[key]
    end

    assert_equal last_request.env['utm_time'], @time.to_i
    assert_equal last_request.env['utm_from'], 'http://example.com'
  end

  def test_set_required_parameters_when_override_required__parameters
    query =
          {
            'ntm_source' => 'bing',
            'ntm_medium' => 'email',
            'ntm_campaign' => 'remarketing'
          }

    @options = { required_parameters: query.keys }

    Timecop.freeze do
      @time = Time.now

      get '/', query, 'HTTP_REFERER' => 'http://exmaple.com'
    end

    query.each do |key, value|
      assert_equal value, last_request.env[key]
    end
  end

  def test_set_optional_parameters
    optional_values = { 'optional' => 'optional_values', 'optional2' => 'optional_values2' }

    @options = { optional_parameters: optional_values.keys }
    Timecop.freeze do
      @time = Time.now
      get '/', query_strings.merge(optional_values), 'HTTP_REFERER' => 'http://example.com'
    end

    query_strings.merge(optional_values).each do |key, value|
      assert_equal last_request.env[key], value
    end

    query_strings.merge(optional_values).each do |key,value|
      assert_equal rack_mock_session.cookie_jar[key], value
    end
  end

  def test_set_params_in_a_cookie
    Timecop.freeze do
      @time = Time.now
      get '/', query_strings, 'HTTP_REFERER' => 'http://example.com'
    end

    query_strings.each do |key, value|
      assert_equal rack_mock_session.cookie_jar[key], value
    end
  end

  def test_set_optional_parameters_in_a_cookie
    optional_values = { 'optional' => 'optional_values', 'optional2' => 'optional_values2' }

    @options = { optional_parameters: optional_values.keys }

    Timecop.freeze do
      @time = Time.now
      get '/', query_strings.merge(optional_values), 'HTTP_REFERER' => 'http://example.com'
    end

    query_strings.merge(optional_values).each do |key, value|
      assert_equal rack_mock_session.cookie_jar[key], value
    end
  end

  def test_not_set_params_if_even_one_book_is_missing
    Timecop.freeze do
      @time = Time.now
      get '/', query_strings.slice("utm_source"), 'HTTP_REFERER' => 'http://example.com'
    end

    assert_equal 'google', last_request.env['utm_source']

    query_strings.slice('utm_medium', 'utm_conent', 'utm_campaign').each do |key, value|
      assert_nil last_request.env[key]
    end
  end

  def test_return_cookies_when_cookie_exists
    Timecop.freeze do
      @time = Time.now
      clear_cookies
      query_strings.each { |key, value| set_cookie("#{key}=#{value}") }
      set_cookie("utm_from=http://example.com")
      set_cookie("utm_time=#{@time.to_i}")
      get '/', {}, 'HTTP_REFERER' => 'http://hoge.com'
    end

    query_strings.each do |key, value|
      assert_equal value, last_request.env[key]
    end

    assert_equal  @time.to_i.to_s, last_request.env['utm_time']
    assert_equal 'http://example.com', last_request.env['utm_from']
  end

  def test_should_not_update_existing_cookie
    day = 60*60*24
    @time = Time.now
    clear_cookies
    query_strings.each { |key, value| set_cookie("#{key}=#{value}") }
    set_cookie("utm_from=http://example.com")
    set_cookie("utm_time=#{@time.to_i}")
    Timecop.freeze(day) do
      get '/', {}, 'HTTP_REFERER' => 'http://www.hoge.com'
    end

    query_strings.each do |key, value|
      assert_equal value, last_request.env[key]
    end

    assert_equal @time.to_i.to_s, last_request.env['utm_time']
    assert_equal 'http://example.com', last_request.env['utm_from']
  end

  def test_should_use_new_required_utm_tags_from_params
    day = 60*60*24
    @time = Time.now
    clear_cookies
    query_strings.each { |key, value| set_cookie("#{key}=#{value}") }
    set_cookie("utm_from=http://example.com")
    set_cookie("utm_time=#{@time.to_i}")

    day = 60*60*24

    new_utm_tags =
      {
        'utm_source' => 'yahoo',
        'utm_medium' => 'new_medium',
        'utm_term' => 'new_utm_term',
        'utm_content' => 'new_utm_content',
        'utm_campaign' => 'new_utm_campain'
      }

    Timecop.freeze(day) do
      @new_time = Time.now
      get '/', new_utm_tags, 'HTTP_REFERER' => 'http://hoge.com'
    end

    new_utm_tags.each do |key, value|
      assert_equal value, last_request.env[key]
    end

    new_utm_tags.each do |key, value|
      assert_equal rack_mock_session.cookie_jar[key], value
    end

    assert_equal @new_time.to_i, last_request.env['utm_time']
    assert_equal 'http://hoge.com', last_request.env['utm_from']
  end

  def test_should_overwite
    @options = { allow_overwrite: true }

    overwrite_values =
      {
        'utm_source' => 'yahoo',
        'utm_medium' => 'overwite_medium',
        'utm_term' => 'overwite_term',
        'utm_content' => 'overwrite_content',
        'utm_campaign' => 'overwite_campaign'
      }

    day = 60*60*24
    @time = Time.now
    clear_cookies
    query_strings.each { |key, value| set_cookie("#{key}=#{value}") }
    set_cookie("utm_from=http://example.com")
    set_cookie("utm_time=#{@time.to_i}")
    Timecop.freeze do
      @time = Time.now
      get '/', query_strings.merge(overwrite_values), 'HTTP_REFERER' => 'http://example.com'
    end

    overwrite_values.each do |key,value|
      assert_equal rack_mock_session.cookie_jar[key], value
    end
  end

  def test_should_not_overwite
    @options = { allow_overwrite: false }

    overwrite_values =
      {
        'utm_source' => 'yahoo',
        'utm_medium' => 'overwite_medium',
        'utm_term' => 'overwite_term',
        'utm_content' => 'overwrite_content',
        'utm_campaign' => 'overwite_campaign'
      }

    day = 60*60*24
    @time = Time.now
    clear_cookies
    query_strings.each { |key, value| set_cookie("#{key}=#{value}") }
    set_cookie("utm_from=http://example.com")
    set_cookie("utm_time=#{@time.to_i}")
    Timecop.freeze do
      @time = Time.now
      get '/', query_strings.merge(overwrite_values), 'HTTP_REFERER' => 'http://example.com'
    end

    query_strings.each do |key,value|
      assert_equal value, rack_mock_session.cookie_jar[key]
    end
  end

  def test_should_clear_cookies_when_miss_any_one_of_parameters
    overwrite_values =
      {
        'utm_source' => 'yahoo',
        # 'utm_medium' => 'overwite_medium',
        'utm_term' => 'overwite_term',
        'utm_content' => 'overwrite_content',
        'utm_campaign' => 'overwite_campaign'
      }

    @time = Time.now
    clear_cookies
    query_strings.each { |key, value| set_cookie("#{key}=#{value}") }
    set_cookie("utm_from=http://example.com")
    set_cookie("utm_time=#{@time.to_i}")
    Timecop.freeze do
      @time = Time.now
      query =
        query_strings
          .slice('utm_source', 'utm_term', 'utm_content', 'utm_campaign')
          .merge(overwrite_values)

      get '/', query, 'HTTP_REFERER' => 'http://example.com'
    end

    query_strings.each_key do |key|
      assert_equal '', rack_mock_session.cookie_jar[key]
    end
  end

  def test_should_clear_cookies_when_miss_any_one_of_parameters_and_same_domain
    overwrite_values =
      {
        'utm_source' => 'yahoo',
        # 'utm_medium' => 'overwite_medium',
        'utm_term' => 'overwite_term',
        'utm_content' => 'overwrite_content',
        'utm_campaign' => 'overwite_campaign'
      }

    @time = Time.now
    clear_cookies
    query_strings.each { |key, value| set_cookie("#{key}=#{value}") }
    set_cookie("utm_from=http://example.com")
    set_cookie("utm_time=#{@time.to_i}")
    Timecop.freeze do
      @time = Time.now
      query =
        query_strings
          .slice('utm_source', 'utm_term', 'utm_content', 'utm_campaign')
          .merge(overwrite_values)

      get '/', query
    end

    query_strings.each_key do |key|
      assert_equal '', rack_mock_session.cookie_jar[key]
    end
  end

  def test_should_set_cookies_when_not_include_utm_parameters
    day = 60*60*24
    @time = Time.now
    clear_cookies
    query_strings.each { |key, value| set_cookie("#{key}=#{value}") }
    set_cookie("utm_from=http://example.com")
    set_cookie("utm_time=#{@time.to_i}")
    Timecop.freeze do
      @time = Time.now

      get '/'
    end

    query_strings.each do |key, value|
      assert_equal value, rack_mock_session.cookie_jar[key]
    end
  end

  private

  def query_strings
    {
      'utm_source' => 'google',
      'utm_medium' => 'sample_medium',
      'utm_term' => 'utm_term',
      'utm_content' => 'sample_content',
      'utm_campaign' => 'sample_campaign'
    }
  end
end
