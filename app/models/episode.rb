class Episode
  include Mongoid::Document
  include Mongoid::Timestamps

  include Mongoid::Random
  include Mongoid::PartFinder
  include Mongoid::BatchFindable

  include Aggregator::Episode

  # [mutable] save when save callback, see also :identifiers
  field :identifier,      type: String

  # [immutable] save when create callback, identifier.to_i(16).base62_encode
  field :slug,            type: String

  # prefix -> { h: hulu, n: netflix, d: dtv, a: amazon, g: gyao }
  field :identifiers,     type: Array

  field :content_type,    type: String
  field :episode_number,  type: Integer
  field :season_number,   type: Integer
  field :title,           type: String
  field :description,     type: Array
  field :image_url,       type: String
  field :caption,         type: Boolean, default: false
  field :duration,        type: Float
  field :released_at,     type: Date
  field :ppv,             type: Boolean, default: false
  field :stored_at,       type: Date
  field :last_updated_at, type: Date

  with_options background: true, unique: true do |d|
    d.index({ identifier: 1 }, {})
    d.index({ slug: 1 }, {})
    d.index({ identifiers: 1 }, {})
  end

  @@services = Rails.application.secrets.accounts.keys.map(&:to_sym)
  mattr_reader :services
  @@priority = {
    identifier: :fixed,
    slug: :fixed,
    identifiers: :functional,
    content_type: :fixed,
    episode_number: [ :n, :h ],
    season_number: [ :n, :h ],
    title: [ :n, :h ],
    description: { func: [ :n, :h ] },
    image_url: [ :n, :h ],
    caption: :functional,
    duration: [ :n, :h ],
    released_at: [ :h, :n ],
    ppv: [ :n, :h ],
    stored_at: :functional,
    last_updated_at: :functional
  }
  mattr_reader :priority

  belongs_to :series, index: true, counter_cache: true
  @@services.each do |service|
    has_one service, {
      class_name: "#{service.to_s.camelize}::Episode",
      inverse_of: :unified
    }
  end
  has_many :children, {
    class_name: "Base::Episode", inverse_of: :unified, dependent: :nullify
  }

  scope :movie, -> { where(content_type: "movie") }
  scope :tv, -> { where(content_type: "tv") }

  before_validation :set_identifier
  before_create :set_slug

  def to_param; slug; end
  def content_type; self[:content_type].inquiry; end

  def identifier_to_slug
    identifier.to_i(16).base62_encode
  end

  def slug_to_identifier
    slug.base62_decode.to_s(16)
  end

  def build_by_episodes(episodes)
    episodes = episodes.map{|e| [e.initial_letter.to_sym, e] }.to_h
    self.attributes = aggregate_attributes(episodes, @@priority)
    self
  end

  def build_by_episodes!(episodes)
    build_by_episodes(episodes).save!
    episodes.each do |episode|
      episode.versionless do |e|
        e.unified = self
        e.save!
      end
    end
  end

  class << self
    def build_movie_by_episodes!(*episodes)
      build_by_episodes!(:movie, *episodes)
    end

    def build_tv_by_episodes!(*episodes)
      build_by_episodes!(:tv, *episodes)
    end

    def build_by_episodes!(type, *episodes)
      episode = (
        self.fix_ids_in(episodes).first ||
        self.any_ids_in(episodes).first_or_initialize)
      episode.content_type = type.to_s
      episode.build_by_episodes!(episodes)
      episode
    end
  end

  private
  def generate_identifier(ids)
    self.class.generate_identifier(ids) # PartFinder
  end

  def set_identifier
    self[:identifier] = generate_identifier(self[:identifiers])
    true
  end

  def set_slug
    self[:slug] = identifier_to_slug
    true
  end
end
