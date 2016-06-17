require 'netflix/series'
require 'netflix/category'
require 'netflix/episode'

module Netflix
  @@id = Rails.application.secrets.accounts["netflix"]["id"]
  @@pw = Rails.application.secrets.accounts["netflix"]["pw"]
  mattr_reader :id, :pw

  @display_port = 67
  mattr_reader :display_port

  @@top_page = "http://www.netflix.com/jp/"
  mattr_reader :top_page

  class Crawler < Base::Crawler
    @@top_page = self.parent.top_page

    def login?
      get @@top_page if URI(page.current_url).host != URI(@@top_page).host
      metadata.dig("userInfo", "data", "membershipStatus") == "CURRENT_MEMBER"
    end

    def login
      unless login?
        get 'https://www.netflix.com/Login?locale=ja-JP'
        page.first('[name=email]').set self.class.parent.id
        unless page.has_css? 'form:first-of-type [name=password]'
          page.first('button[type=submit]').click
          wait_until do |pg|
            pg.has_css? 'form:first-of-type [name=password]'
          end
        end
        page.first('[name=password]').set self.class.parent.pw
        page.first('button[type=submit]').click
        ## not fire. because of react...?
        #if page.all('.profile-name').size > 0
        #  page.find('a', text: 'Machine').click
        #end
      end
      url = page.current_url
      Rails.logger.tagged(self.class, "Logged-in") {
        Rails.logger.debug { url }
      }
      url
    end

    def crawl_contents_and_save
      crawl_contents_and_save!(false)
    end

    def crawl_contents_and_save!(force=true)
      get_genres.each do |genre|
        get_contents(genre[:id]) do |content|
          case content[:type]
          when 'show'
            get_seasons(content[:id]) do |season|
              get_episodes_in_season(season[:id]) do |e|
                Episode.build_all_by_api!(self.versionning_date,
                  episode: get_episode(e[:id]), genre: genre, show: content)
              end
            end
          when 'episode', 'movie'
            Episode.build_all_by_api!(self.versionning_date,
              episode: get_episode(content[:id]), genre: genre, show: content)
          end
        end
      end
    end

    private

    def get_genres
      if @client.cookies.blank?
        @client.cookie_manager.cookies = page.driver.cookies.to_httpclient
      end
      res = post(api_endpoint,
        paths: [
          [ "genreList", { from: 0, to: 100 }, [ "id", "menuName" ]],
          [ "genreList", "summary" ]],
        authURL: access_token
      )
      res["genres"].values.grep(Hash).map do |g|
        { id: g["id"], name: g["menuName"] }
      end
    end

    def get_contents(genre_id, &block)
      if @client.cookies.blank?
        @client.cookie_manager.cookies = page.driver.cookies.to_httpclient
      end
      _ret = []
      window = 0..99
      payload = {
        paths: [
          [ "genres", genre_id, "su", # Suggestion for you
            #"yr", # Year Released (Desc)
            { from: window.first, to: window.last }, [ "summary", "title" ]],
          [ "genres", genre_id, "su", { from: window.first, to: window.last },
            "boxarts","_665x375","webp" ]],
        authURL: access_token
      }
      begin
        (0..1).each do |i|
          payload[:paths][i][3] = {
            from: window.first, to: window.last
          }
        end
        res = post(api_endpoint, payload)
        result = (res["videos"].presence || {}).values.grep(Hash)
        ret = result.map do |v|
          video = {
            id: v.dig("summary", "id"),
            type: v.dig("summary", "type"),
            title: v["title"],
            image_url: v.dig("boxarts", "_665x375", "webp", "url"),
            original: v.dig("summary", "isOriginal")
          }
          yield video
          video
        end
        _ret.concat ret
        window = (window.first+window.size)..(window.last+window.size)
      end while result.present?
      _ret
    end

    def get_seasons(show_id)
      payload = {
        paths: [
          [ "videos", show_id, "seasonList", { from: 0, to: 49 }, "summary" ],
          [ "videos", show_id, "seasonList", "summary" ]],
        authURL: access_token
      }
      res = post(api_endpoint, payload)
      seasons = res["seasons"].presence || {}
      ret = (res.dig("videos", show_id.to_s, "seasonList") || {}).map do |i,s|
        if s.is_a? Array
          season = seasons.dig(s[1], "summary")
          yield({
              id: season["id"], name: season["name"],
              size: season["length"], index: i.to_i
            })
        else
          nil
        end
      end
      ret.compact
    end

    def get_casts(show_id)
      payload = {
        paths: [
          ["videos", show_id, "cast", { from: 0, to: 49 }, [ "id", "name" ]]],
        authURL: access_token
      }
      res = post(api_endpoint, payload)
      people = (res["person"].presence || {}).values.grep(Hash)
      people.map do |person|
        { id: person["id"], name: person["name"] }
      end
    end

    def get_episodes_in_season(season_id)
      payload = {
        paths: [
          [ "seasons", season_id, "episodes", { from: -1, to: 99 },
            [ "summary", "synopsis", "title", "runtime", "episodeBadges" ]],
          [ "seasons", season_id, "episodes", { from: -1, to: 99 },
            "interestingMoment", "_665x375", "webp" ],
          [ "seasons", season_id, "episodes", { from: -1, to: 99 },
            "ancestor", "summary" ],
          [ "seasons", season_id, "episodes", "summary" ],
          [ "seasons", season_id, "episodes", "current", "summary" ]],
        authURL: access_token
      }
      res = post(api_endpoint, payload)
      episodes = res["videos"].presence || {}
      ret = (res.dig("seasons", season_id.to_s, "episodes") ||{}).map do |i,e|
        if e.is_a? Array
          episode = episodes[e[1]]
          return nil if episode.blank?
          yield({
              id: episode.dig("summary", "id"),
              title: episode.dig("title"),
              duration: episode.dig("runtime"),
              description: episode.dig("synopsis"),
              type: episode.dig("summary", "type"),
              original: episode.dig("summary", "isOriginal"),
              image_url: episode.dig(
                "interestingMoment", "_342x192", "webp", "url"),
              episode_number: episode.dig("summary", "episode"),
              season_number: episode.dig("summary", "season")
            })
        else
          nil
        end
      end
      ret.compact
    end

    def get_episode(episode_id)
      payload = {
        paths: [
          ["videos", episode_id, [
              "creditsOffset", "synopsis", "episodeCount", "info",
              "runtime", "seasonCount", "summary", "releaseYear",
              "title", "userRating", "numSeasonsLabel" ]],
          ["videos", episode_id, "current", "ancestor", "summary"],
          ["videos", episode_id, "seasonList", "current", "summary"],
          ["videos", episode_id, ["requestId", "regularSynopsis"]],
          ["videos", episode_id,
            ["subtitles", "audio", "availabilityEndDateNear", "copyright"]],
          ["videos", episode_id, "genres", { from: 0, to: 2 }, ["id","name"]],
          ["videos", episode_id, "genres", "summary"],
          ["videos", episode_id, "tags", { from: 0, to: 9 }, ["id","name"]],
          ["videos", episode_id, "tags", "summary"],
          ["videos", episode_id, "cast", { from: 0, to: 49 }, ["id","name"]],
          ["videos", episode_id, "cast", "summary"],
          ["videos", episode_id, "interestingMoment", "_665x375", "webp"],
          ["videos", episode_id, "boxarts","_665x375","webp"]
        ],
        authURL: access_token
      }
      begin
        res = post(api_endpoint, payload)
        extract_data res.dig("videos", episode_id.to_s, "summary"), res
      rescue EpisodeIdNotFound => e
        Rails.logger.tagged(self.class, "Error", "Extract") {
          Rails.logger.error { "#{e}: API Request (payload) #{payload}" }
          Rails.logger.error { "#{e}: API Response #{res}" }
        }
        sleep 2
        retry
      end
    end

    def extract_data(info, data)
      if info.nil? || info.dig("type").nil? || info.dig("id").nil?
        raise EpisodeIdNotFound
      end
      send :"extract_data_#{info['type']}", info['id'].to_s, data
    end

    def extract_data_episode(id, data)
      ret = extract_data_common(id, data)
      raw = data.dig("videos", id)
      ret.merge(
        series_id: raw["ancestor"].is_a?(Array) ? raw["ancestor"][1] : nil,
        episode_number: raw.dig("summary", "episode"),
        season_number: raw.dig("summary", "season")
      )
    end

    def extract_data_movie(id, data)
      ret = extract_data_common(id, data)
      ret.merge({})
    end

    def extract_data_common(id, data)
      raw = data["videos"][id]
      {
        id: raw.dig("summary", "id"),
        type: raw.dig("summary", "type"),
        title: raw.dig("title"),
        original: raw.dig("summary", "isOriginal"),
        description: extract_description(raw),
        duration: raw.dig("runtime").to_f,
        main_duration: raw.dig("creditsOffset").to_f,
        caption: raw.dig("subtitles").presence || false,
        released_at: Time.zone.local(raw.dig("releaseYear")).to_date,
        image_url: raw.dig("boxarts", "_665x375", "webp", "url"),
        genres: extract_indexed_data(raw.dig("genres"), data.dig("genres")),
        tags: extract_tags(raw.dig("tags")),
        casts: extract_indexed_data(raw.dig("cast"), data.dig("person"))
      }
    end

    def extract_description(raw)
      [
        raw.dig("info", "narrativeSynopsis"),
        raw.dig("synopsis"),
        raw.dig("info", "synopsis"),
        raw.dig("regularSynopsis")
      ].compact.uniq.join(' ')
    end

    # genres, casts
    def extract_indexed_data(indexes, data)
      (0..49).map{|i|
        key = indexes[i.to_s]
        key.is_a?(Array) ? {
          id: data.dig(key[1], "id"), name: data.dig(key[1], "name")
        } : nil
      }.compact
    end

    def extract_tags(data)
      (0..9).map{|i|
        tag = data[i.to_s]
        tag["id"].is_a?(Integer) ? {
          id: tag["id"], name: tag["name"]
        } : nil
      }.compact
    end

    def metadata
      page.evaluate_script 'netflix && netflix.contextData || reactApp && reactApp.metadata && reactApp.metadata.models'
    end

    def access_token
      metadata.dig "userInfo", "data", "authURL"
    end

    def api_endpoint
      d = metadata.dig "serverDefs", "data"
      d["API_ROOT"] + d["API_BASE_URL"] + '/pathEvaluator/' +
        d.dig("endpointIdentifiers", "/pathEvaluator") +
        '?withSize=true&materialize=true&model=harris'
    end

    def post(url, payload)
      begin
        res = @client.post(url, payload.to_json)
        raise UnavailableError unless res.ok?
      rescue UnavailableError => e
        Rails.logger.tagged(self.class, "Error", "Getting") {
          Rails.logger.error { "#{e}: (#{res.status})#{res.reason}" }
        }
        sleep 2
        retry
      end
      Rails.logger.tagged(self.class, "Getting") {
        base, query, object = payload[:paths][0][0..2]
        Rails.logger.debug { "#{base}: query: #{query}, #{object}" }
      }
      JSON.parse(res.body)["value"]
    end

    def wait_until
      Timeout.timeout(5.seconds) do
        loop until yield page
      end
    end

  end

end
