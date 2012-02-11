# Copyright (c) 2010-2011 Michael Dvorkin
#
# Awesome Print is freely distributable under the terms of MIT license.
# See LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
module AwesomePrint
  module MongoMapper

    def self.included(base)
      base.send :alias_method, :cast_without_mongo_mapper, :cast
      base.send :alias_method, :cast, :cast_with_mongo_mapper
    end

    # Add MongoMapper class names to the dispatcher pipeline.
    #------------------------------------------------------------------------------
    def cast_with_mongo_mapper(object, type)
      cast = cast_without_mongo_mapper(object, type)
      if defined?(::MongoMapper::Document)
        if object.is_a?(Class) && (object.ancestors & [ ::MongoMapper::Document, ::MongoMapper::EmbeddedDocument ]).size > 0
          cast = :mongo_mapper_class
        elsif (object.class.ancestors & [ ::MongoMapper::Document, ::MongoMapper::EmbeddedDocument ]).size > 0
          cast = :mongo_mapper_instance
        elsif object.is_a?(::BSON::ObjectId)
          cast = :mongo_mapper_bson_id
        end
      end
      cast
    end

    # Format MongoMapper class object.
    #------------------------------------------------------------------------------
    def awesome_mongo_mapper_class(object)
      return object.inspect if !defined?(::ActiveSupport::OrderedHash) || !object.respond_to?(:keys)

      data = object.keys.sort.inject(::ActiveSupport::OrderedHash.new) do |hash, c|
        hash[c.first] = (c.last.type || "undefined").to_s.underscore.intern
        hash
      end
      "class #{object} < #{object.superclass} " << awesome_hash(data)
    end

    # Format MongoMapper Document object.
    #------------------------------------------------------------------------------
    def awesome_mongo_mapper_instance(object)
      return object.inspect if !defined?(::ActiveSupport::OrderedHash)

      data = object.attributes.sort_by { |key| key }.inject(::ActiveSupport::OrderedHash.new) do |hash, c|
        hash[c[0].to_sym] = c[1]
        hash
      end
      if !object.errors.empty?
        data = {:errors => object.errors, :attributes => data}
      end
      "#{object} #{awesome_hash(data,true)}"
    end

    # Format BSON::ObjectId
    #------------------------------------------------------------------------------
    def awesome_mongo_mapper_bson_id(object)
      object.inspect
    end
  end
end

AwesomePrint::Formatter.send(:include, AwesomePrint::MongoMapper)
