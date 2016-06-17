class Series
  include Mongoid::Document
  include Mongoid::Timestamps

  include Mongoid::Random
  include Mongoid::PartFinder

  include Aggregator::Series

  # [mutable] save when save callback, see also :identifiers
  field :identifier,      type: String

  # [immutable] save when create callback, identifier.to_i(16).base62_encode
  field :slug,            type: String

  # prefix -> { h: hulu, n: netflix, d: dtv, a: amazon, g: gyao }
  field :identifiers,     type: Array

  field :title,           type: String
  field :description,     type: Array
  field :original,        type: Boolean
  field :image_url,       type: String
  field :company,         type: String
  field :episodes_count,  type: Integer, default: 0
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
    title: [ :n, :h ],
    description: { func: [ :n, :h ] },
    original: [ :n, :h ],
    image_url: [ :n, :h ],
    company: [ :n, :h ],
    episode_count: :fixed,
    stored_at: :functional,
    last_updated_at: :functional
  }
  mattr_reader :priority

  has_many :episodes
  @@services.each do |service|
    has_one service, {
      class_name: "#{service.to_s.camelize}::Series",
      inverse_of: :unified
    }
  end
  has_many :children, {
    class_name: "Base::Series", inverse_of: :unified, dependent: :nullify
  }

  before_validation :set_identifier
  before_create :set_slug

  def to_param; slug; end

  def identifier_to_slug
    identifier.to_i(16).base62_encode
  end

  def slug_to_identifier
    slug.base62_decode.to_s(16)
  end

  def build_by_series(series)
    series = series.map{|s| [s.initial_letter.to_sym, s] }.to_h
    self.attributes = aggregate_attributes(series, @@priority)
    self
  end

  def build_by_series!(series)
    build_by_series(series).save!
    series.each do |element|
      element.versionless do |s|
        s.unified = self
        s.save!
      end
    end
  end

  # Do not normally use
  def build_by_episodes(episodes)
    build_by_series episodes.map(&:series)
  end

  # Do not normally use
  def build_by_episodes!(episodes)
    build_by_series! episodes.map(&:series)
  end

  class << self
    def build_by_series!(*series)
      s = (
        self.fix_ids_in(series).first ||
        self.any_ids_in(series).first_or_initialize)
      s.build_by_series!(series)
      s
    end

    def build_by_episodes!(*episodes)
      build_by_series!(*episodes.map(&:series))
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
