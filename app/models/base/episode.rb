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

    with_options background: true do |d|
      d.index({ _id: 1 }, { unique: true })
      d.index({ episode_number: 1 }, {})
      d.index({ season_number: 1 }, {})
      d.index({ identifier: 1 }, {})
      d.index({ caption: 1 }, {})
      d.index({ duration: -1 }, {})
      d.index({ content_type: 1 }, {})
      d.index({ stored_at: -1 }, {})
      d.index({ last_updated_at: -1 }, {})
    end
    { _type: 1 }.tap do |f|
      { background: true }.tap do |o|
        index f.reverse_merge(_id: 1), o.reverse_merge(unique: true)
        index f.reverse_merge(episode_number: 1), o
        index f.reverse_merge(season_number: 1), o
        index f.reverse_merge(identifier: 1), o.reverse_merge(unique: true)
        index f.reverse_merge(series_id: 1), o
        index f.reverse_merge(caption: 1), o
        index f.reverse_merge(duration: -1), o
        index f.reverse_merge(released_at: -1), o
        index f.reverse_merge(content_type: 1), o
        index f.reverse_merge(stored_at: -1), o
        index f.reverse_merge(last_updated_at: -1), o
        index f.reverse_merge(ja_sibling_id: -1), o
        index f.reverse_merge(unified_id: -1), o
        f.reverse_merge(
          #identifier: 1,
          duration: -1, ja_sibling_id: -1, content_type: 1
        ).tap do |mf|
          index mf, o
          index mf.reverse_merge(
            episode_number: 1, season_number: 1
          ), o.reverse_merge(name: "aggregation_tv_search")
          index mf.reverse_merge(
            released_at: -1), o.reverse_merge(name: "aggregation_movie_searh")
          index mf.reverse_merge(
            last_updated_at: -1
          ), o.reverse_merge(name: "last_updated_at-aggregation")
          index mf.reverse_merge(
            unified_id: -1), o.reverse_merge(name: "unified_id-aggregation")
        end
      end
    end

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
