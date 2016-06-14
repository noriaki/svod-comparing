module Base
  class Episode
    include Mongoid::Document

    include Mongoid::Random
    include Mongoid::BatchFindable

    include Aggregator::Comparable

    field :identifier, type: String
    field :episode_number, type: Integer
    field :season_number, type: Integer
    field :title, type: String
    field :description, type: String
    field :image_url, type: String
    field :caption, type: Boolean, default: false
    field :duration, type: Float
    field :released_at, type: Date
    field :ppv, type: Boolean, default: false
    field :content_type, type: String
    field :stored_at, type: Date
    field :last_updated_at, type: Date

    belongs_to :series, index: true
    has_one :en_sibling, class_name: self.to_s, inverse_of: :ja_sibling
    belongs_to :ja_sibling, class_name: self.to_s, inverse_of: :en_sibling, index: true

    index({ episode_number: 1 }, { background: true })
    index({ season_number: 1 }, { background: true })
    index({ identifier: 1 }, { background: true })
    index({ caption: 1 }, { background: true })
    index({ content_type: 1 }, { background: true })
    index({ stored_at: -1 }, { background: true })
    index({ last_updated_at: -1 }, { background: true })
    index({ _type: 1, episode_number: 1 }, { background: true })
    index({ _type: 1, season_number: 1 }, { background: true })
    index({ _type: 1, identifier: 1 }, { background: true, unique: true })
    index({ _type: 1, series_id: 1 }, { background: true })
    index({ _type: 1, caption: 1 }, { background: true })
    index({ _type: 1, content_type: 1 }, { background: true })
    index({ _type: 1, stored_at: -1 }, { background: true })
    index({ _type: 1, last_updated_at: -1 }, { background: true })
    index({ _type: 1, series_id: -1 }, { background: true })
    index({ _type: 1, ja_sibling_id: -1 }, { background: true })

    validates_presence_of :identifier
    validates_presence_of :title

    scope :main, -> { where(ja_sibling_id: nil) }
    scope :feature, ->(l=300) { where(:duration.gte => l.seconds) }
    scope :non_aggregated, -> { where(unified_id: nil) }

    before_validation :normalize_text

    private
    def normalize_text
      table = {
        "\n"     => "",       # line break
        "\r"     => "",
        "\uFF65" => "\u30FB", # centered dot
        "\u309B" => "\u3099", # dull sound mark
        "\u309C" => "\u309A"  # P-sound mark
      }
      regexp = Regexp.new "[#{table.keys.join('')}]"
      self[:title] = Unicode::nfkc(self[:title].gsub(regexp, table))
      self[:description] = Unicode::nfkc(self[:description].gsub(regexp, table))
      true
    end

  end
end
