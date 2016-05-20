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
      member_info = metadata["userInfo"]["data"]["membershipStatus"]
      member_info == "CURRENT_MEMBER"
    end

    def login
      unless login?
        get 'https://www.netflix.com/Login?locale=ja-JP'
        page.first('[name=email]').set self.class.parent.id
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
      binding.pry
      get_genres.each do |genre|
        get_contents(genre[:id]) do |content|
          case content[:type]
          when 'show'
            get_seasons(content[:id]) do |season|
              get_episodes_in_season(season[:id]) do |episode|
                e = Episode.build_by_api(self.versionning_date,
                  episode: episode
                )
                e.series ||=
                  Series.where(identifier: content[:id]).first_or_initialize
                e.series.build_by_api(self.versionning_date,
                  genre: genre, show: content
                )
                e.series.save! && e.save!
                binding.pry
              end
            end
          when 'episode'
          when 'movie'
          end
        end
      end
    end

    private

    def get_genres
      if @client.cookies.blank?
        @client.cookie_manager.cookies = page.driver.cookies.to_httpclient
      end
      res_json = post(api_endpoint,
        paths: [
          [
            "genreList",
            { from: 0, to: 100 },
            [ "id", "menuName" ]
          ],
          [ "genreList", "summary" ]
        ],
        authURL: access_token
      )
      res_json["genres"].values.grep(Hash).map do |g|
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
          [
            "genres", genre_id,
            "su", # Suggestion for you
            #"yr", # Year Released (Desc)
            { from: window.first, to: window.last },
            [ "summary", "title" ]
          ],
          [
            "genres", genre_id, "su",
            { from: window.first, to: window.last },
            "boxarts","_342x192","webp"
          ]
        ], authURL: access_token
      }
      begin
        (0..1).each do |i|
          payload[:paths][i][3] = {
            from: window.first, to: window.last
          }
        end
        res_json = post(api_endpoint, payload)
        result = (res_json["videos"].presence || {}).values.grep(Hash)
        ret = result.map do |v|
          video = {
            id: v["summary"]["id"],
            type: v["summary"]["type"],
            title: v["title"],
            image_url: v["boxarts"]["_342x192"]["webp"]["url"],
            original: v["summary"]["isOriginal"]
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
          [
            "videos", show_id, "seasonList",
            { from: 0, to: 49 },
            "summary"
          ],
          [
            "videos", show_id, "seasonList",
            "summary"
          ]
        ], authURL: access_token
      }
      res_json = post(api_endpoint, payload)
      seasons = res_json["seasons"].presence || {}
      ret = res_json["videos"][show_id.to_s]["seasonList"].map do |i,s|
        if s.is_a? Array
          season_id = s[1]
          season = seasons[season_id]["summary"]
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
          [
            "videos", show_id, "cast",
            { from: 0, to: 49 },
            [ "id", "name" ]
          ]
        ], authURL: access_token
      }
      res_json = post(api_endpoint, payload)
      people = (res_json["person"].presence || {}).values.grep(Hash)
      people.map do |person|
        { id: person["id"], name: person["name"] }
      end
    end

    def get_episodes_in_season(season_id)
      payload = {
        paths: [
          [
            "seasons", season_id, "episodes",
            { from: -1, to: 99 },
            [ "summary", "synopsis", "title", "runtime", "episodeBadges" ]
          ],
          [
            "seasons", season_id, "episodes",
            { from: -1, to: 99 },
            "interestingMoment", "_342x192", "webp"
          ],
          [
            "seasons", season_id, "episodes",
            { from: -1, to: 99 },
            "ancestor", "summary"
          ],
          [ "seasons", season_id, "episodes", "summary" ],
          [ "seasons", season_id, "episodes", "current", "summary" ]
        ], authURL: access_token
      }
      res_json = post(api_endpoint, payload)
      episodes = res_json["videos"].presence || {}
      ret = res_json["seasons"][season_id.to_s]["episodes"].map do |i,e|
        if e.is_a? Array
          episode_id = e[1]
          episode = episodes[episode_id]
          episode_summary = episode["summary"]
          yield({
              id: episode_summary["id"], title: episode["title"],
              duration: episode["runtime"], description: episode["synopsis"],
              type: episode_summary["type"],
              original: episode_summary["isOriginal"],
              image_url: episode["interestingMoment"]["_342x192"]["webp"]["url"],
              episode_number: episode_summary["episode"],
              season_number: episode_summary["season"]
          })
        else
          nil
        end
      end
      ret.compact
    end

    def get_episodes(season_id)
      {"paths"=>
        [["videos",
            season_id,
            "similars",
            {"from"=>0, "to"=>25},
            ["synopsis",
              "title",
              "summary",
              "queue",
              "trackId",
              "maturity",
              "runtime",
              "seasonCount",
              "releaseYear",
              "userRating",
              "numSeasonsLabel",
              "availability"]],
          ["videos", season_id, "similars", {"from"=>0, "to"=>25}, "boxarts", ["_260x146", "_342x192"], "webp"],
          ["videos", season_id, "similars", {"from"=>0, "to"=>25}, "current", "summary"],
          ["videos", season_id, "similars", ["summary", "trackId"]],
          ["videos", season_id, ["commonsense", "subtitles", "audio", "availabilityEndDateNear", "copyright"]],
          ["videos", season_id, "festivals", {"from"=>0, "to"=>10}, {"from"=>0, "to"=>10}, ["type", "winner"]],
          ["videos", season_id, "festivals", {"from"=>0, "to"=>10}, {"from"=>0, "to"=>10}, "person", ["name", "id"]],
          ["videos", season_id, "festivals", {"from"=>0, "to"=>10}, ["length", "name", "year"]],
          ["videos", season_id, "festivals", "length"],
          ["videos", season_id, ["creators", "directors"], {"from"=>0, "to"=>49}, ["id", "name"]],
          ["videos", season_id, ["creators", "directors"], "summary"],
          ["videos", season_id, "cast", {"from"=>12, "to"=>49}, ["id", "name"]],
          ["videos", season_id, "genres", 3, ["id", "name"]],
          ["videos", season_id, "trailers", {"from"=>0, "to"=>25}, ["title", "summary", "trackId", "availability"]],
          ["videos", season_id, "trailers", {"from"=>0, "to"=>25}, "interestingMoment", "_260x146", "webp"],
          ["videos", season_id, "trailers", {"from"=>0, "to"=>25}, "current", "summary"],
          ["videos", season_id, "seasonList", {"from"=>0, "to"=>20}, "summary"],
          ["videos", season_id, "seasonList", "summary"],
          ["seasons", 70019370, "episodes", {"from"=>-1, "to"=>40}, ["summary", "synopsis", "title", "runtime", "bookmarkPosition", "episodeBadges"]],
          ["seasons", 70019370, "episodes", {"from"=>-1, "to"=>40}, "interestingMoment", "_342x192", "webp"],
          ["seasons", 70019370, "episodes", {"from"=>-1, "to"=>40}, "ancestor", "summary"],
          ["seasons", 70019370, "episodes", "summary"],
          ["seasons", 70019370, "episodes", "current", "summary"]],
        "authURL"=>"1463548877601.6j5ZJxjnWvLlQR4v/GSTB3SATxU="}
    end

    def metadata
      page.evaluate_script 'netflix && netflix.contextData || reactApp && reactApp.metadata && reactApp.metadata.models'
    end

    def access_token
      metadata["userInfo"]["data"]["authURL"]
    end

    def api_endpoint
      d = metadata["serverDefs"]["data"]
      d["API_ROOT"] + d["API_BASE_URL"] + '/pathEvaluator/' +
        d["endpointIdentifiers"]["/pathEvaluator"] +
        '?withSize=true&materialize=true&model=harris'
    end

    def post(url, payload)
      res = @client.post(url, payload.to_json)
      Rails.logger.tagged(self.class, "Getting") {
        base, query, object = payload[:paths][0][0..2]
        Rails.logger.debug { "#{base}: query: #{query}, #{object}" }
      }
      JSON.parse(res.body)["value"]
    end

  end

end
