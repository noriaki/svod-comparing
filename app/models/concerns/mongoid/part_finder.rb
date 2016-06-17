module Mongoid
  module PartFinder
    extend ActiveSupport::Concern

    class_methods do
      def extract_ids(*ids)
        (ids[0].is_a?(Array) ? ids[0] : ids).map{|id|
          id.is_a?(String) ? id : id.id_with_prefix
        }.sort
      end

      def generate_identifier(ids)
        Digest::MD5.hexdigest ids.join('-')
      end
    end

    included do
      scope :all_ids_in, ->(*ids) {
        self.all(identifiers: extract_ids(*ids)) }
      scope :any_ids_in, ->(*ids) {
        self.in(identifiers: extract_ids(*ids)) }
      scope :fix_ids_in, ->(*ids) {
        where(identifier: generate_identifier(extract_ids(*ids))) }
    end

  end
end
