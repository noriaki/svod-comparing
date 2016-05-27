module Netflix
  class Category < Base::Category
    has_and_belongs_to_many :series, index: true
  end
end
