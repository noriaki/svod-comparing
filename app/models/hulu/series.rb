module Hulu
  class Series < Base::Series
    include Mongoid::Versioning
    include Mongoid::Random
    include Mongoid::MagicCounterCache

    has_and_belongs_to_many :categories, index: true
    has_many :episodes
    belongs_to :unified, class_name: "::Series", inverse_of: self.parent.to_s.underscore.to_sym, index: true

    counter_cache :categories

    def url(relative_path=false)
      path = "/#{identifier}"
      path = URI(self.class.parent.top_page) + path if not relative_path
      path.to_s
    end

    def build_by_api(show, company)
      self.title = show[:name]
      self.description = show[:description]
      self.original = false
      self.image_url = URI(show[:thumbnail_url]).to_s
      self.art_image_url = URI(show[:key_art_url]).to_s
      self.company = company[:name]
      show[:genres].split('|').each do |genre|
        unless self.categories.where(name: genre).exists?
          self.categories << Category.where(name: genre).first_or_create!
        end
      end
    end

  end
end
