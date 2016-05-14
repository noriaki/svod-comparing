module Mongoid
  module Random
    extend ActiveSupport::Concern
    included do
      scope :random, -> { skip(rand(self.count)) }
    end
  end
end
