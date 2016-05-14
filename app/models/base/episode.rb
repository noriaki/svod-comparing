module Base
  class Episode
    include Mongoid::Document

    field :identifier, type: String
    field :episode_number, type: Integer
    field :season_number, type: Integer
    field :title, type: String
    field :description, type: String
    field :caption, type: Boolean, default: false
    field :duration, type: Float
    field :released_at, type: Date
    field :ppv, type: Boolean, default: false
    field :content_type, type: String
    field :stored_at, type: Date

    belongs_to :series, index: true

    index({ episode_number: 1 }, { background: true })
    index({ season_number: 1 }, { background: true })
    index({ identifier: 1 }, { background: true, unique: true })
    index({ caption: 1 }, { background: true })
    index({ content_type: 1 }, { background: true })
    index({ stored_at: -1 }, { background: true })
    index({ _type: 1, episode_number: 1 }, { background: true })
    index({ _type: 1, season_number: 1 }, { background: true })
    index({ _type: 1, identifier: 1 }, { background: true, unique: true })
    index({ _type: 1, series_id: 1 }, { background: true })
    index({ _type: 1, caption: 1 }, { background: true })
    index({ _type: 1, content_type: 1 }, { background: true })
    index({ _type: 1, stored_at: -1 }, { background: true })

    validates_presence_of :identifier
    validates_presence_of :title
  end
end
