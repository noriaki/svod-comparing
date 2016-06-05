class Series
  include Mongoid::Document

  field :identifier, type: String

  %i(hulu netflix).each do |service|
    has_one service, class_name: "#{service.to_s.camelize}::Series", inverse_of: :unified
  end
end
