module CouchPotato
  module Persistence
    module Json
      def self.included(base)
        base.extend ClassMethods
      end
      
      def to_json(*args)
        (self.class.properties).inject({}) do |props, property|
          property.serialize(props, self)
          props
        end.merge('ruby_class' => self.class.name).merge(id_and_rev_json).merge(timestamps_json).to_json(*args)
      end
      
      private
      
      def id_and_rev_json
        [:_id, :_rev, :_deleted].inject({}) do |hash, key|
          hash[key] = self.send(key) unless self.send(key).nil?
          hash
        end
      end
      
      def timestamps_json
        [:created_at, :updated_at].inject({}) do |hash, key|
          hash[key] = self.send(key).to_s unless self.send(key).nil?
          hash
        end
      end
      
      module ClassMethods
        def json_create(json) # TODO test
          instance = self.new
          instance.created_at = Time.parse(json['created_at']) if json.key? 'created_at'
          instance.updated_at = Time.parse(json['updated_at']) if json.key? 'updated_at'
          instance._id = json['_id']
          instance._rev = json['_rev']
          properties.each do |property|
            property.build(instance, json) unless property.is_a?(ExternalHasManyProperty)
          end
          instance
        end
      end
    end
  end
end
