module Netflix
  module IdentifierWithNormalizeMultisub
    def identifier
      super.sub('_en','')
    end
  end
end
