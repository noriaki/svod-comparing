require 'base/series'
require 'base/category'
require 'base/episode'

module Base

  class Crawler

    def initialize(agent, versionning)
      @agent = agent
      @versionning = versionning
      @versionning_date = versionning.stored_at
    end
    attr_reader :versionning_date

    def page
      @agent.page
    end

    class << self

      def crawl!(date=Time.current.to_date, force=true)
        klass = self
        versionning = "#{klass.parent}::StoredVersion".constantize.
          where(stored_at: date).first_or_create
        Agent.run(display: klass.parent.display_port) do
          crawler = klass.new self, versionning
          #binding.pry
          crawler.login unless crawler.login?
          #binding.pry
          force ? crawler.crawl_contents_and_save! : crawler.crawl_contents_and_save
        end
      end

    end

    protected

    def get(url)
      @agent.visit url if page.current_url != url
      Rails.logger.debug("[#{self.class}] Getting: #{url}")
      page.current_url
    end

  end

end
