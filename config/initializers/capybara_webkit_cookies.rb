class Capybara::Webkit::CookieJar
  include Enumerable
  extend Forwardable
  def_delegators :cookies, :each
end
