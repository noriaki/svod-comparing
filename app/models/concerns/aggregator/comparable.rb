module Aggregator
  module Comparable
    extend ActiveSupport::Concern

    def id_with_prefix
      initial_letter + identifier
    end

    def initial_letter
      self.class.service_class_name.underscore[0]
    end

    def normalize_title
      title
        .sub(/^\([\u5439\u5B57]\)/,'') # dubbed / subbed
        .strip
    end

    def comparable_title
      ct = normalize_title.upcase
      ct.size < 3 ? ct + "**" : ct
    end

    def similarity_of(other)
      Trigram.compare comparable_title, other.comparable_title
      #st, ot = [comparable_title, other.comparable_title]
      #min_size = [st.size, ot.size].min
      #Trigram.compare st.first(min_size), ot.first(min_size)
    end

    class_methods do
      def paths; self.name.split("::"); end
      def leaf_class_name; paths.last; end
      def root_class_name; paths.first; end
      alias :service_class_name :root_class_name
    end

  end
end
