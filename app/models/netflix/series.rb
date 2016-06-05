module Netflix
  class Series < Base::Series
    include Mongoid::Versioning
    include Mongoid::Random
    include Mongoid::MagicCounterCache

    has_and_belongs_to_many :categories, index: true, autosave: true
    has_many :episodes
    belongs_to :unified, class_name: "::Series", inverse_of: self.parent.to_s.underscore.to_sym, index: true

    counter_cache :categories

    def url(relative_path=false)
      path = "/title/#{identifier}"
      path = URI(self.class.parent.top_page) + path if not relative_path
      path.to_s
    end

    def build_by_api(versionning_date, data)
      show_data  = data[:show] || {}
      genre_data = data[:genre] || {}
      self.title = show_data[:title]
      self.original = show_data[:original].present?
      self.image_url = show_data[:image_url]
      self.stored_at = versionning_date if new_record?
      self.last_updated_at = versionning_date

      unless self.categories.where(name: genre_data[:name]).exists?
        self.categories <<
          Category.where(name: genre_data[:name]).first_or_create!
      end

      self
    end

  end
end
