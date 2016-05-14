module Base
  class Series
    include Mongoid::Document

    field :identifier, type: String
    field :title, type: String
    field :description, type: String
    field :company, type: String
    field :episodes_count, type: Integer, default: 0
    field :stored_at, type: Date

    has_and_belongs_to_many :categories, index: true, autosave: true
    has_many :episodes

    index({ company: 1 }, { background: true })
    index({ identifier: 1 }, { background: true, unique: true })
    index({ episodes_count: 1 }, { background: true })
    index({ stored_at: -1 }, { background: true })
    index({ _type: 1, company: 1 }, { background: true })
    index({ _type: 1, identifier: 1 }, { background: true, unique: true })
    index({ _type: 1, episodes_count: 1 }, { background: true })
    index({ _type: 1, stored_at: -1 }, { background: true })

    validates_presence_of :identifier
    validates_presence_of :title

  end
end