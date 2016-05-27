module Agent
  @@name = [
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_4)",
    "AppleWebKit/537.36 (KHTML, like Gecko)",
    "Chrome/50.0.2661.102 Safari/537.36"
  ].join(' ')
  mattr_reader :name

  Capybara.default_driver = :webkit
  Capybara.javascript_driver = :webkit

  def self.run(options={}, &block)
    h = Headless.new(options)
    h.start
    agent = Class.new do
      include Capybara::DSL
      def initialize
        page.driver.header 'user-agent', @@name
      end
    end.new

    ObjectSpace.define_finalizer(agent) do
      h.destroy
    end

    agent.instance_eval &block
  end
end
