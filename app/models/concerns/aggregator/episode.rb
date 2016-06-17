module Aggregator
  module Episode
    extend ActiveSupport::Concern

    class_methods do
      def service_klasses
        self.services.map{|s| "#{s}/episode".classify.constantize }
      end

      def aggregate_all!
        aggregate!(*service_klasses)
      end

      def aggregate!(*klasses)
        aggregate_movie!(*klasses)
        aggregate_tv!(*klasses)
      end

      def aggregate_movie!(*klasses); Movie.perform!(*klasses); end
      def aggregate_tv!(*klasses); Tv.perform!(*klasses); end
    end

    def aggregate_attributes(episodes, attrs_priority)
      attrs_priority.map{|attr, priority|
        #binding.pry
        case priority
        when Array
          [attr, priority.map{|k| episodes[k].try(attr) }.compact.first]
        when Hash
          case attr
          when :description
            [attr, priority[:func].map{|k| episodes[k].try(attr) }.compact]
          end
        when :functional
          case attr
          when :identifiers
            self[attr].present? ? nil :
              [attr, self.class.extract_ids(episodes.map{|k,e| e })]
          when :caption
            [attr, false]
          when :stored_at
            [attr, episodes.map{|k,e| e[attr] }.min]
          when :last_updated_at
            [attr, episodes.map{|k,e| e[attr] }.max]
          end
        else
          nil
        end
      }.compact.to_h
    end

    module Movie

      class << self

        def perform!(*klasses)
          queries = Aggregator.queries_of(self, *klasses)
          Aggregator.perform_rotate(queries) do |video, targets|
            results = search_and_compare(video, targets)
            episode = ::Episode.build_movie_by_episodes!(*results)
            episode.series = ::Series.build_by_episodes!(*results)
            episode.save!
          end
        end

        private
        def search_and_compare(video, targets)
          accuracy = video.duration * 0.04
          duration_range = (video.duration-accuracy)..(video.duration+accuracy)
          release_range = video.released_at.beginning_of_year..video.released_at.end_of_year
          videos = targets.map do |query|
            query
              .between(duration: duration_range)
              .between(released_at: release_range)
              .in_batches_of.map{|result|
              score = video.similarity_of result
              score >= 0.15 ? [score, result] : nil
            }.compact
              .sort_by{|result| -result[0] }.map{|result| result[1] }.first
          end
          videos.prepend(video).compact
        end

      end
    end

    module Tv

      class << self

        def perform!(*klasses)
          queries = Aggregator.queries_of(self, *klasses)
          Aggregator.perform_rotate(queries) do |video, targets|
            results = search_and_compare(video, targets)
            episode = ::Episode.build_tv_by_episodes!(*results)
            episode.series = ::Series.build_by_episodes!(*results)
            episode.save!
          end
        end

        private
        def search_and_compare(video, targets)
          accuracy = video.duration * 0.01
          duration_range = (video.duration-accuracy)..(video.duration+accuracy)
          videos = targets.map do |query|
            query.between(duration: duration_range).where(
              episode_number: video.episode_number,
              season_number: video.season_number
            ).in_batches_of.map{|result|
              score = video.series.similarity_of result.series
              score > 0 ? [score, result] : nil
            }.compact
              .sort_by{|result| -result[0] }.map{|result| result[1] }.first
          end
          videos.prepend(video).compact
        end

      end
    end

  end
end
