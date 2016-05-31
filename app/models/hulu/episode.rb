module Hulu
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
      content_type == "feature_film"
    end

    def tv?
      content_type == "episode"
    end

    def build_by_api!(data)
      self.episode_number = data[:episode_number]
      self.season_number = data[:season_number]
      self.title = data[:title]
      self.description = data[:description]
      self.caption = data[:closed_captions].present?
      self.duration = data[:duration]
      self.released_at = data[:original_premiere_date]
      self.ppv = false
      self.content_type = data[:video_type]
      #save! # because versionning
    end

    class << self

      def build_by_api!(data, force=true)
        episode = self.where(identifier: data[:id]).first_or_initialize
        if force || episode.new_record?
          episode.build_by_api!(data)
          show = data[:show]
          episode.series ||= Series.where(identifier: show[:canonical_name]).first_or_initialize
          episode.series.build_by_api(show, data[:company])
          if episode.new_record?
            data[:versionning_date].tap do |today|
              episode.stored_at = today
              episode.series.stored_at = today
            end
          end
        end
        data[:versionning_date].tap do |today|
          episode.last_updated_at = today
          episode.series.last_updated_at = today
        end
        episode.series.save!
        episode.save!
        episode
      end

      def set_relations!
        self.where(caption: true).each do |episode|
          episode_ja =
            if episode.movie?
              episode.series.episodes.where(caption: false).first
            elsif episode.tv?
              episode.series.episodes.where({
                caption: false,
                episode_number: episode.episode_number,
                season_number: episode.season_number
              }).first
            else
              nil
            end
          episode.versionless do |ep|
            ep.update_attributes ja_sibling_id: episode_ja.id
          end if episode_ja.present?
        end
      end

    end

    private
    def normalize_text
      table = {
        "\uFF65" => "\u30FB" # centered dot
      }
      regexp = Regexp.new "[#{table.keys.join('')}]"
      self[:title] = self[:title].gsub(regexp, table)
      self[:description] = self[:description].gsub(regexp, table)
    end
  end
end
