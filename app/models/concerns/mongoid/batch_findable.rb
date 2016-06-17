module Mongoid
  module BatchFindable
    extend ActiveSupport::Concern

    class_methods do
      def in_batches_of(window_size = 1_000)
        count, criteria = self.count, self.hint
        Enumerator.new do |yielder|
          0.step(by: window_size, to: count) do |index|
            criteria.limit(window_size).skip(index).each do |item|
              yielder << item
            end
          end
        end
      end
    end

  end
end
