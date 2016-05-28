require 'hulu/series'
require 'hulu/category'
require 'hulu/episode'

module Hulu
  @@id = Rails.application.secrets.accounts["hulu"]["id"]
  @@pw = Rails.application.secrets.accounts["hulu"]["pw"]
  mattr_reader :id, :pw

  @@display_port = 57
  mattr_reader :display_port

  @@top_page = "http://www.hulu.jp/"
  mattr_reader :top_page

  @@launch_at_japan = Time.zone.parse('2011/08/31')
  mattr_reader :launch_at_japan

  class Crawler < Base::Crawler
    @@top_page = self.parent.top_page

    def login?
      get @@top_page
      page.evaluate_script 'Hulu.Behaviors.isLoggedIn()'
    end

    def login
      get @@top_page
      unless login?
        login_link_elem = page.first('#user-menu a.login')
        if login_link_elem
          login_form_elem = page.first('#popup-body')
          unless login_form_elem
            login_link_elem.click
            sleep 0.05 while !page.has_css?('#popup-body')
          end
          login_form_elem = page.first('#popup-body')
          login_form_elem.first('input.inactive.dummy.user').try(:click)
          login_form_elem.first('#login').set self.class.parent.id
          login_form_elem.first('#password').set self.class.parent.pw
          login_form_elem.first('a.login').click
        end
      end
      url = page.current_url
      Rails.logger.debug("[#{self.class}] Logged-in: #{url}")
      url
    end

    def crawl_contents_and_save
      crawl_contents_and_save!(false)
    end

    def crawl_contents_and_save!(force=true, past=true)
      crawl_movies_and_save!(force)
      crawl_episodes_and_save!(force, past)
      Episode.set_relations!
    end

    def crawl_movies_and_save!(force=true)
      crawl_movies(access_token) do |data|
        data[:versionning_date] = self.versionning_date
        Episode.build_by_api! data, force
      end
    end

    def crawl_episodes_and_save!(force=true, past=false, date=Time.zone.now)
      day_of_origin = self.class.parent.launch_at_japan.utc.beginning_of_day
      target_date = date.utc.beginning_of_day
      while past && day_of_origin < target_date
        target_range = target_date.weeks_ago(1)..target_date
        crawl_episodes(access_token, target_range) do |data|
          data[:versionning_date] = self.versionning_date
          Episode.build_by_api! data, force
        end
        target_date = target_range.first
      end
    end

    private

    def crawl_movies(token)
      request_uri = URI(@@top_page)
      request_uri.path = "/mozart/v1.h2o/movies/films"
      request_options = {
        language: 'ja', region: 'jp', locale: 'ja',
        _language: 'ja', _region: 'jp', _device_id: 1,
        exclude_hulu_content: 1, sort: 'release_with_popularity',
        items_per_page: 100, max_count: 100, position: 0,
        _user_pgid: 24, _content_pgid: 24, access_token: token
      }
      position = 0
      total_count = 0
      begin
        request_uri.query = request_options.merge(position: position).to_param
        get request_uri
        result_json = JSON.parse(page.body).deep_symbolize_keys
        #binding.pry
        result_json[:data].each{|item| yield item[:video] }
        total_count = result_json[:total_count]
        position += request_options[:items_per_page]
        #binding.pry
      rescue StandardError, Capybara::Webkit::TimeoutError => e
        Rails.logger.debug([
          "[#{self.class}#crawl_movies] ERROR: #{e.message}",
            "position(#{position}); sleep 5sec and Retry"].join("\n"))
        sleep 5
        retry
      end while total_count > position
    end

    def crawl_episodes(token, range)
      request_uri = URI(@@top_page)
      request_uri.path = "/mozart/v1.h2o/shows/episodes"
      request_options = {
        language: 'ja', region: 'jp', locale: 'ja',
        _language: 'ja', _region: 'jp', _device_id: 1,
        _user_pgid: 24, _content_pgid: 24, access_token: token,
        released_at_gte: range.first.utc.iso8601,
        released_at_lt: range.last.utc.iso8601,
        exclude_hulu_content: 1, sort: 'popular_this_week',#'release_with_popularity',#
        items_per_page: 100, position: 0
      }
      position = 0
      total_count = 0

      begin
        request_uri.query = request_options.merge(position: position).to_param
        get request_uri
        result_json = JSON.parse(page.body).deep_symbolize_keys
        #binding.pry
        result_json[:data].each{|item| yield item[:video] }
        total_count = result_json[:total_count]
        position += request_options[:items_per_page]
      rescue StandardError, Capybara::Webkit::TimeoutError => e
        Rails.logger.debug([
          "[#{self.class}#crawl_episodes] ERROR: #{e.message}",
            "position(#{position}); sleep 5sec and Retry"].join("\n"))
        sleep 5
        retry
      end while total_count > position
    end

    def access_token
      login unless login?
      get @@top_page
      page.evaluate_script 'API_DONUT'
    end

  end

end
