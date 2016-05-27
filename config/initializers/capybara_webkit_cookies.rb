class Capybara::Webkit::CookieJar
  include Enumerable
  extend Forwardable
  def_delegators :cookies, :each

  def to_httpclient
    map do |c|
      HTTP::Cookie.new(
        name: c.name,
        value: c.value,
        domain: c.domain,
        path: c.path,
        origin: nil,
        for_domain: nil,
        expires: c.expires,
        httponly: nil,
        secure: c.secure
      )
    end
  end
end
