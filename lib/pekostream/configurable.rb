require 'yaml'

module Pekostream
  class Configurable
    def initialize(config:)
      @config = YAML.load_file(config)
    end

    def twitter
      @config['twitter']
    end

    def github
      @config['github']
    end

    def imkayac
      @config['imkayac']
    end
  end
end
