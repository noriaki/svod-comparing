module Netflix
  class Episode < Base::Episode
    include Mongoid::Versioning
    include Mongoid::Random

    belongs_to :series, index: true, counter_cache: true

    def url(relative_path=false)
      path = "/watch/#{identifier}"
      path = URI(self.class.parent.top_page) + path if not relative_path
      path.to_s
    end

    def movie?
      content_type == "movie"
    end

    def tv?
      content_type == "episode"
    end

    def build_by_api(versionning_date, data)
      self.episode_number = data[:episode_number].to_i
      self.season_number = data[:season_number].to_i
      self.title = data[:title]
      self.description = data[:description]
      self.image_url = data[:image_url]
      self.caption = data[:closed_captions].present?
      self.duration = data[:duration]
      self.released_at = nil
      self.ppv = false
      self.content_type = data[:type]
      self.stored_at = versionning_date if new_record?
      self.last_updated_at = versionning_date
      #save! # because versionning
    end

    class << self

      def build_by_api(versionning_date, data, force=true)
        episode_data = data[:episode] || {}
        episode = self.where(identifier: episode_data[:id]).first_or_initialize
        if force || episode.new_record?
          episode.build_by_api(versionning_date, episode_data)
        end
        episode
      end

    end
  end
end
