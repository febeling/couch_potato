require "will_paginate/collection"
require "pp"
module CouchPotato
  module Persistence
    module Pagination

      def self.included(base)
        base.extend ClassMethods
      end
      
      module ClassMethods

        # From will_paginate rdoc:
        #
        #   Array.class_eval do
        #     def paginate(page = 1, per_page = 15)
        #       WillPaginate::Collection.create(page, per_page, size) do |pager|
        #         pager.replace self[pager.offset, pager.per_page].to_a
        #       end
        #     end
        #   end
        def paginate(page = 1, per_page = 15, options = {})
          WillPaginate::Collection.create(page, per_page) do |pager|
            ids, total = find_page_ids_ordered_by(page, per_page, options[:keys])
            result = db.documents :include_docs => true, :keys => ids
            docs = result["rows"].map{|r| r["doc"]}
            pager.replace(docs)
          end
        end

        def find_page_ids_ordered_by(page, per_page, order_by_attr, descending=false)
          skip = (page - 1) * per_page
          view_parameters = {:skip => skip, :count => per_page}
          view_parameters[:descending] = descending if descending
          query = ViewQuery.new("#{self.class.name.underscore}",
                                "ids_by_#{order_by_attr}",
                                paginate_map_function(order_by_attr),
                                nil,
                                nil,
                                view_parameters)
          result = query.query_view!
          return result['rows'].map{|row| row['id']}, result['total_rows']
        end

        def paginate_map_function(keys)
          # map without doc to save space.
          # include _id in key to make non-unique key ordering stable.
          key_ary = []
          case keys
          when Array
            key_ary += keys
          else 
            key_ary << keys
          end
          key_ary << "_id"
          "function(doc) {
              emit([#{key_ary.map{|k|"doc.#{k}"}.join(', ')}], null);
           }"
        end

        def map_function(key, properties) # from custom_view.rb
          "function(doc) {
              emit(doc.#{key}, #{properties_for_map(properties)});
           }"
        end

        def view_name(*properties)
          properties.join("_and_")
        end

        def properties_for_map(properties) # from custom_view.rb
          if properties.nil?
            'null'
          else
            '{' + properties.map { |p| "#{p}: doc.#{p}" }.join(', ') + '}'
          end
        end

        def search_values(conditions)
          conditions.to_a.sort_by{|f| f.first.to_s}.map(&:last)
        end

        def search_keys(search_values, view_options) # from view_query.rb
          if search_values.select{|v| v.is_a?(Range)}.any?
            {:startkey => search_values.map{|v| v.is_a?(Range) ? v.first : v},
              :endkey => search_values.map{|v| v.is_a?(Range) ? v.last : v}}.merge(view_options)
          elsif search_values.select{|v| v.is_a?(Array)}.any?
            {:keys => prepare_multi_key_search(search_values)}.merge(view_options)
          else
            view_options.merge(search_values.any? ? {:key => search_values} : {})
          end
        end


      end
    end
  end
end