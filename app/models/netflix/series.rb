module Netflix
  class Series < Base::Series
    include Mongoid::Versioning
    include Mongoid::Random
    include Mongoid::MagicCounterCache

    has_and_belongs_to_many :categories, index: true, autosave: true
    has_many :episodes

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
      self.stored_at = versionning_date if new_record?
      self.last_updated_at = versionning_date

      category_query = { identifier: genre_data[:id], name: genre_data[:name] }
      unless self.categories.where(category_query).exists?
        self.categories << Category.where(category_query).first_or_create!
      end

      self
    end

  end
end
