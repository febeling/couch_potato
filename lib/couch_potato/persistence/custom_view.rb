module CouchPotato
  module Persistence
    module CustomView
      
      def self.included(base)
        base.extend ClassMethods
      end
      
      module ClassMethods
        
        def view(name, options)
          properties = options.delete(:properties)
          key = options.delete(:key)
          (class << self; self; end).instance_eval do
            if properties
              define_method name do
                ViewQuery.new(self.name.underscore, name, map_function(key, properties), nil, {}, options).query_view!['rows'].map{|doc| self.new(doc['value'].merge(:_id => doc['id']))}
              end
            else
              define_method name do
                ViewQuery.new(self.name.underscore, name, map_function(key, properties), nil, {}, options.merge({:include_docs =>  true})).query_view!['rows'].map{|doc| self.new(doc['doc'])}
              end
            end
          end
        end
        
        def map_function(key, properties)
          "function(doc) {
              emit(doc.#{key}, #{properties_for_map(properties)});
           }"
        end
        
        def properties_for_map(properties)
          if properties.nil?
            'null'
          else
            '{' + properties.map{|p| "#{p}: doc.#{p}"}.join(', ') + '}'
          end
        end
      end
    end
  end
end
