module Aggregator

  class << self
    def queries_of(type, *klasses)
      klasses.map do |klass|
        klass.main.feature#.non_aggregated
          .includes(:series)
          .send(type.name.demodulize.underscore.to_sym)
          .asc(:identifier)
          .no_timeout.cache
      end
    end

    def perform_rotate(queries)
      queries.size.times do
        base_query, targets = [queries[0], queries[1..-1]]
        targets.reject!{|query| query.count.zero? }
        next if targets.blank?
        base_query.in_batches_of.each do |base|
          yield base, targets#.map{|query| query.batch_size(1000) }
        end
        queries.rotate!
      end
    end
  end

end
