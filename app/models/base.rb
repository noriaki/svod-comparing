require 'base/series'
require 'base/category'
require 'base/episode'

module Base

  class Crawler

    class UnavailableError < StandardError; end
    class EpisodeIdNotFound < StandardError; end

    def initialize(agent, versionning)
      @agent = agent
      @client = HTTPClient.new({
          agent_name: Agent.name, default_header: {
            "Content-Type" => "application/json"
          }
        })
      @versionning = versionning
      @versionning_date = versionning.stored_at
    end
    attr_reader :versionning_date

    def page
      @agent.page
    end

    class << self

      def display_num(base_num)
        (2_000 * base_num + Date.current.strftime("%m%d").to_i) % 10_000
      end

      def crawl!(date=Time.current.to_date, force=true)
        klass = self
        puts "Start crawling(#{klass.parent}):  #{Time.current}"
        date = Time.current.to_date if date.nil?
        versionning = "#{klass.parent}::StoredVersion".constantize.
          where(stored_at: date).first_or_create
        Agent.run(display: klass.display_num) do
          crawler = klass.new self, versionning
          #binding.pry
          crawler.login unless crawler.login?
          #binding.pry
          force ? crawler.crawl_contents_and_save! : crawler.crawl_contents_and_save
        end
        puts "Finish crawling(#{klass.parent}): #{Time.current}"
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
