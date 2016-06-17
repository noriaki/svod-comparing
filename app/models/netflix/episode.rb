module Netflix
  class Episode < Base::Episode
    include Mongoid::Versioning
    include Mongoid::Random

    prepend Netflix::IdentifierWithNormalizeMultisub

    belongs_to :series, index: true, counter_cache: true
    belongs_to :unified, {
      index: true, class_name: "::#{leaf_class_name}",
      inverse_of: root_class_name.underscore.to_sym
    }

    scope :movie, -> { where content_type: "movie" }
    scope :tv, -> { where content_type: "episode" }

    def url(relative_path=false)
      path = "/title/#{identifier}"
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
      self.caption = data[:caption].present?
      self.duration = data[:duration]
      self.released_at = data[:released_at]
      self.ppv = false
      self.content_type = data[:type]
      self.stored_at = versionning_date if new_record?
      self.last_updated_at = versionning_date
      #save! # because versionning
    end

    class << self

      def build_all_by_api!(versionning_date, data, force=true)
        episode = data[:episode] || {}
        caption_data = episode.delete :caption
        episode_ja =
          Episode.build_by_api!(versionning_date, data.merge(episode: episode))
        if caption_data.is_a? Array
          episode_en = Episode.build_by_api(versionning_date, data.merge(
              episode: episode.merge(id: "#{episode[:id]}_en", caption: true)))
          episode_en.ja_sibling = episode_ja
          episode_en.series.save! && episode_en.save!
        end
      end

      def build_by_api!(versionning_date, data, force=true)
        e = build_by_api(versionning_date, data, force)
        (e.series.save! && e.save!) ? e : nil
      end

      def build_by_api(versionning_date, data, force=true)
        show_data = data[:show] || {}
        episode_data = data[:episode] || {}
        episode = self.where(identifier: episode_data[:id]).first_or_initialize
        if force || episode.new_record?
          episode.build_by_api(versionning_date, episode_data)
          episode.series ||=
            Series.where(identifier: show_data[:id]).first_or_initialize
          episode.series.build_by_api(versionning_date, data)
        end
        episode
      end

    end

  end
end
