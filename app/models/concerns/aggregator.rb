module Aggregator

  class << self
    def queries_of(type, *klasses)
      klasses.map do |klass|
        klass.main.feature#.non_aggregated
          .send(type.name.demodulize.underscore.to_sym)#.cache
      end
    end

    def perform_rotate(queries)
      queries.size.times do
        base_query, targets = [queries[0], queries[1..-1]]
        target_results_set = targets.map(&:to_a)
        base_query.non_aggregated.each do |base|
          yield base, target_results_set
        end
        queries.rotate!
      end
    end
  end

end
