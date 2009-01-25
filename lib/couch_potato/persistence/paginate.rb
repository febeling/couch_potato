require "will_paginate/collection"

module CouchPotato
  module Persistence
    module Pagination

      def self.included(base)
        base.extend ClassMethods
      end
      
      module ClassMethods
        def paginate(page = 1, per_page = 15, options = {})
          page = page.to_i
          WillPaginate::Collection.create(page, per_page) do |pager|
            clazz = if instantiate?(options) then (options[:class] || self) else nil end
            ids, total = find_page_ids_ordered_by(page, per_page, options[:order], options[:descending], clazz)
            docs = db.documents(:include_docs => true, :keys => ids)['rows'].map { |row| row['doc'] }
            objects = docs.map { |doc| self.json_create(doc) }
            pager.replace(objects)
            pager.total_entries = total
          end
        end

        def instantiate?(options)
          !options.key?(:class) || (options[:class] != :none && !options[:class].nil?)
        end

        def find_page_ids_ordered_by(page, per_page, order_by_attr, descending, type_tag)
          skip = (page - 1) * per_page
          view_parameters = {:skip => skip, :count => per_page}
          view_parameters[:descending] = descending if descending
          view_name = case order_by_attr
                      when Array
                        "ids_by_#{order_by_attr.join('_and_')}"
                      else
                        "ids_by_#{order_by_attr}"
                      end
          query = ViewQuery.new("#{self.class.name.underscore}", view_name, paginate_map_function(order_by_attr, type_tag, 'ruby_class'), nil, nil, view_parameters)
          result = query.query_view!
          return result['rows'].map { |row| row['id'] }, result['total_rows']
        end

        def type_predicate(type_tag, attribute)
          if type_tag.nil?
            ""
          else
            "if(doc.#{attribute} == '#{type_tag}')"
          end
        end

        def paginate_map_function(keys, clazz, type_attribute='ruby_class')
          key_ary = []
          case keys
          when Array
            key_ary += keys
          else 
            key_ary << keys
          end
          key_ary << "_id" # Add to assure that ordering is stable.
          "function(doc) {
              #{type_predicate((clazz.nil? ? nil : clazz.name), type_attribute)} emit([#{key_ary.map{|k|"doc.#{k}"}.join(', ')}], null);
           }"
        end

      end

    end
  end
end
