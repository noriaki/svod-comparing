Capybara::Webkit.configure do |config|
  config.allow_unknown_urls
  config.timeout = 10
  config.ignore_ssl_errors
  config.skip_image_loading
end
