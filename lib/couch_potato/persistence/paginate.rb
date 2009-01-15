require "will_paginate/collection"

module CouchPotato
  module Persistence
    module Pagination

      def self.included(base)
        base.extend ClassMethods
      end
      
      module ClassMethods
        def paginate(page = 1, per_page = 15, options = {})
          WillPaginate::Collection.create(page, per_page) do |pager|
            ids, total = find_page_ids_ordered_by(page, per_page, options[:order])
            docs = db.documents(:include_docs => true, :keys => ids)["rows"].map { |row| row["doc"] }
            objects = docs.map { |doc| self.class.json_create doc }
            pager.replace(objects)
          end
        end

        def find_page_ids_ordered_by(page, per_page, order_by_attr, descending=false, clazz=self)
          skip = (page - 1) * per_page
          view_parameters = {:skip => skip, :count => per_page}
          view_parameters[:descending] = descending if descending
          query = ViewQuery.new("#{self.class.name.underscore}", "ids_by_#{order_by_attr}", paginate_map_function(order_by_attr, clazz), nil, nil, view_parameters)
          result = query.query_view!
          return result['rows'].map{|row| row['id']}, result['total_rows']
        end

        def paginate_map_function(keys, clazz)
          key_ary = []
          case keys
          when Array
            key_ary += keys
          else 
            key_ary << keys
          end
          key_ary << "_id"
          "function(doc) {
              if(doc.ruby_class == '#{clazz.name}')
                emit([#{key_ary.map{|k|"doc.#{k}"}.join(', ')}], null);
           }"
        end

      end

    end
  end
end
