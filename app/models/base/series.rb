module Base
  class Series
    include Mongoid::Document

    include Mongoid::Random

    include Aggregator::Comparable

    field :identifier, type: String
    field :title, type: String
    field :description, type: String
    field :original, type: Boolean
    field :image_url, type: String
    field :art_image_url, type: String
    field :company, type: String
    field :episodes_count, type: Integer, default: 0
    field :stored_at, type: Date
    field :last_updated_at, type: Date

    index({ company: 1 }, { background: true })
    index({ original: 1 }, { background: true })
    index({ identifier: 1 }, { background: true })
    index({ episodes_count: 1 }, { background: true })
    index({ stored_at: -1 }, { background: true })
    index({ last_updated_at: -1 }, { background: true })
    index({ _type: 1, _id: 1 }, { background: true, unique: true })
    index({ _type: 1, company: 1 }, { background: true })
    index({ _type: 1, original: 1 }, { background: true })
    index({ _type: 1, identifier: 1 }, { background: true, unique: true })
    index({ _type: 1, episodes_count: 1 }, { background: true })
    index({ _type: 1, stored_at: -1 }, { background: true })
    index({ _type: 1, last_updated_at: -1 }, { background: true })

    validates_presence_of :identifier
    validates_presence_of :title

  end
end
