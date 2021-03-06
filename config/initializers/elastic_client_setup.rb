# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

require 'gitlab/current_settings'

Gitlab.ee do
  require 'elasticsearch/model'

  ### Monkey patches

  Elasticsearch::Model::Response::Records.prepend GemExtensions::Elasticsearch::Model::Response::Records
  Elasticsearch::Model::Adapter::Multiple::Records.prepend GemExtensions::Elasticsearch::Model::Adapter::Multiple::Records
  Elasticsearch::Model::Indexing::InstanceMethods.prepend GemExtensions::Elasticsearch::Model::Indexing::InstanceMethods
  Elasticsearch::Model::Adapter::ActiveRecord::Importing.prepend GemExtensions::Elasticsearch::Model::Adapter::ActiveRecord::Importing
  Elasticsearch::Model::Adapter::ActiveRecord::Records.prepend GemExtensions::Elasticsearch::Model::Adapter::ActiveRecord::Records
  Elasticsearch::Model::Client::InstanceMethods.prepend GemExtensions::Elasticsearch::Model::Client
  Elasticsearch::Model::Client::ClassMethods.prepend GemExtensions::Elasticsearch::Model::Client
  Elasticsearch::Model::ClassMethods.prepend GemExtensions::Elasticsearch::Model::Client
  Elasticsearch::Model.singleton_class.prepend GemExtensions::Elasticsearch::Model::Client

  # This monkey patch cannot be handled by prepend like the above since this
  # module is included into other classes.
  module Elasticsearch
    module Model
      module Response
        module Base
          if Gem::Version.new(Elasticsearch::Model::VERSION) >= Gem::Version.new('7.0.0')
            raise "elasticsearch-model was upgraded, please remove this monkey patch in #{__FILE__}"
          end

          # Handle ES7 API where total is returned as an object. This
          # change is taken from the V7 gem
          # https://github.com/elastic/elasticsearch-rails/commit/9c40f630e1b549f0b7889fe33dcd826b485af6fc
          # and can be removed when we upgrade the gem to V7
          def total
            if response.response['hits']['total'].respond_to?(:keys)
              response.response['hits']['total']['value']
            else
              response.response['hits']['total']
            end
          end
        end
      end
    end
  end

  ### Modified from elasticsearch-model/lib/elasticsearch/model/searching.rb

  module Elasticsearch
    module Model
      module Searching
        class SearchRequest
          def execute!
            response = klass.client.search(@definition)
            raise Elastic::TimeoutError if response['timed_out']

            response
          end
        end
      end
    end
  end

  ### Modified from elasticsearch-model/lib/elasticsearch/model.rb

  [
    Elasticsearch::Model::Client::ClassMethods,
    Elasticsearch::Model::Naming::ClassMethods,
    Elasticsearch::Model::Indexing::ClassMethods,
    Elasticsearch::Model::Searching::ClassMethods
  ].each do |mod|
    Elasticsearch::Model::Proxy::ClassMethodsProxy.include mod
  end

  [
    Elasticsearch::Model::Client::InstanceMethods,
    Elasticsearch::Model::Naming::InstanceMethods,
    Elasticsearch::Model::Indexing::InstanceMethods,
    Elasticsearch::Model::Serializing::InstanceMethods
  ].each do |mod|
    Elasticsearch::Model::Proxy::InstanceMethodsProxy.include mod
  end

  Elasticsearch::Model::Proxy::InstanceMethodsProxy.class_eval <<-CODE, __FILE__, __LINE__ + 1
    def as_indexed_json(options={})
      target.respond_to?(:as_indexed_json) ? target.__send__(:as_indexed_json, options) : super
    end
  CODE
end
