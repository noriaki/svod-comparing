module Netflix
  class Series < Base::Series
    include Mongoid::Versioning
    include Mongoid::Random
    include Mongoid::MagicCounterCache

    has_and_belongs_to_many :categories, index: true, autosave: true
    has_many :episodes

    counter_cache :categories

    def build_by_api(show, company)
      self.title = show[:name]
      self.description = show[:description]
      self.company = company[:name]
      show[:genres].split('|').each do |genre|
        unless self.categories.where(name: genre).exists?
          self.categories << Category.where(name: genre).first_or_create!
        end
      end
    end

  end
end
