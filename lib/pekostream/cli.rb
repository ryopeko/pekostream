require 'pekostream/configurable'
require 'pekostream/stream/twitter'
require 'pekostream/stream/github'
require 'optparse'

module Pekostream
  class CLI
    def initialize(args)
      option_parse(args)
      @config = Pekostream::Configurable.new(@options)
    end

    def run
      twitter_streams = @config.twitter['users'].map do |user|
        twitter_stream = Pekostream::Stream::Twitter.new(
          screen_name: user['screen_name'],
          notification_words: user['notification_words'],
          credentials: {
            consumer_key:    @config.twitter['consumer_key'],
            consumer_secret: @config.twitter['consumer_secret'],
            access_token:    user['access_token'],
            access_secret:   user['access_secret']
          },
          imkayac_config: {
            username: @config.imkayac['username'],
            secret: @config.imkayac['secret']
          }
        )
      end

      twitter_streams.each(&:start)

      github_stream = Pekostream::Stream::Github.new(access_token: @config.github['access_token'])
      github_stream.start

      loop do
        twitter_streams.each do |stream|
          stream.reconnect unless stream.alive?
        end
        sleep 300
      end
    end

    private def option_parse(args)
      return @options if @options

      @options = { config: 'config.yaml' }
      OptionParser.new do |opt|
        opt.on('--config VALUE') do |v|
          @options[:config] = v
        end
      end.parse!(args)
    end
  end
end
