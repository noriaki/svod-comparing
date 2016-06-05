module Aggregator
  module Episode
    extend ActiveSupport::Concern

    class_methods do
      def aggregate_all!
        aggregate!(*self.services.map{|s|
            "#{s}/episode".classify.constantize })
      end

      def aggregate!(*klasses)
        Movie.perform!(*klasses)
      end
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
          Aggregator.perform_rotate(queries) do |video, results_set|
            ::Episode.build_movie_by_episodes!(
              *search_and_compare(video, results_set))
          end
        end

        private
        def search_and_compare(video, results_set)
          accuracy = video.duration * 0.04
          durations = (video.duration-accuracy)..(video.duration+accuracy)
          videos = results_set.map do |results|
            next nil if results.blank?
            results.find_all{|result|
              durations.cover?(result.duration) &&
              video.released_at.year === result.released_at.year
            }.map{|result|
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
    end

  end
end
