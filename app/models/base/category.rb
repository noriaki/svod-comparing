module Base
  class Category
    include Mongoid::Document

    field :name, type: String
    field :series_count, type: Integer, default: 0

    has_and_belongs_to_many :series, index: true, autosave: true

    index({ name: 1 }, { background: true, unique: true })
    index({ series_count: 1 }, { background: true })
    index({ _type: 1, name: 1 }, { background: true, unique: true })
    index({ _type: 1, series_count: 1 }, { background: true })

    validates_presence_of :name

  end
end
