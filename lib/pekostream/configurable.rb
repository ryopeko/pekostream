require 'yaml'

module Pekostream
  class Configurable
    def initialize(config:)
      @config = YAML.load_file(config)
      @config.each do |k, v|
        self.singleton_class.send(:define_method, k.to_sym, ->() { v })
      end
    end
  end
end
