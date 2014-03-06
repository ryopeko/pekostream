require 'pekostream/configurable'
require 'pekostream/stream/twitter'
require 'pekostream/stream/github'

module Pekostream
  class CLI
    def initialize(args)
      config_file_path = 'config.yaml'
      @config = Pekostream::Configurable.new(config: config_file_path)
    end

    def run
      twitter_streams = @config.twitter['users'].map do |user|
        twitter_stream = Pekostream::Stream::Twitter.new(
          screen_name: user['screen_name'],
          credentials: {
            consumer_key:    @config.twitter['consumer_key'],
            consumer_secret: @config.twitter['consumer_secret'],
            access_token:    user['access_token'],
            access_secret:   user['access_secret'],
            im_kayac_secret: @config.imkayac['secret']
          },
        )
      end

      twitter_streams.each do |stream|
        Thread.new { stream.start }
      end

      github_stream = Pekostream::Stream::Github.new(access_token: @config.github['access_token'])

      loop do
        github_stream.run
        infof('sleeping')
        sleep 600
      end
    end
  end
end
