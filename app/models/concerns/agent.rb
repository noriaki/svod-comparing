module Agent
  Capybara.default_driver = :webkit
  Capybara.javascript_driver = :webkit

  def self.run(options={}, &block)
    h = Headless.new(options)
    h.start
    agent = Class.new do
      include Capybara::DSL
      def initialize
        page.driver.header 'user-agent', [
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5)",
          "AppleWebKit/537.36 (KHTML, like Gecko)",
          "Chrome/47.0.2526.106", "Safari/537.36"
        ].join(' ')
      end
    end.new

    ObjectSpace.define_finalizer(agent) do
      h.destroy
    end

    agent.instance_eval &block
  end
end
