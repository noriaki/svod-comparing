module Aggregator
  module Series
    extend ActiveSupport::Concern

    class_methods do
      def service_klasses
        self.services.map{|s| "#{s}/series".classify.constantize }
      end
    end

    def aggregate_attributes(series, attrs_priority)
      attrs_priority.map{|attr, priority|
        case priority
        when Array
          [attr, priority.map{|k| series[k].try(attr) }.compact.first]
        when Hash
          case attr
          when :description
            [attr, priority[:func].map{|k| series[k].try(attr) }.compact]
          end
        when :functional
          case attr
          when :identifiers
            self[attr].present? ? nil :
              [attr, self.class.extract_ids(series.map{|k,e| e })]
          when :stored_at
            [attr, series.map{|k,e| e[attr] }.min]
          when :last_updated_at
            [attr, series.map{|k,e| e[attr] }.max]
          end
        end
      }.compact.to_h
    end

  end
end
