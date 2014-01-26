require 'twitter'
require 'pekostream/notification/im_kayac'
require 'pekostream/filter/twitter'

module Pekostream
  module Stream
    class Twitter
      def initialize(credentials, logger: Logger.new($stdout))
        @client = ::Twitter::Streaming::Client.new do |config|
          config.consumer_key        = credentials[:consumer_key]
          config.consumer_secret     = credentials[:consumer_secret]
          config.access_token        = credentials[:access_token]
          config.access_token_secret = credentials[:access_secret]
        end

        notifier = Pekostream::Notification::ImKayac.new(
          username: 'ryopeko',
          secret: credentials[:im_kayac_secret]
        )

        twitter_filter = Pekostream::Filter::Twitter.new([
          'ryopeko',
          /りょう{,1}ぺこ/
        ])

        @hooks = {
          tweet: ->(tweet){
            logger.info "#{tweet.user.screen_name}: #{tweet.text}"

            return unless twitter_filter.filter(tweet.text)

            notifier.notify(
              "maybe mentioned from @#{tweet.user.screen_name}: #{tweet.text}",
              handler: "twitter://status?id=#{tweet.id}"
            )
          },
          favorite: ->(event){
            notifier.notify(
              "#{event.name} from #{event.source.screen_name}: #{event.target_object.text}",
              handler: "twitter://status?id=#{event.target_object.id}"
            )
          },
          follow: ->(target){
            notifier.notify(
              "#{target.name} from #{target.source.screen_name}",
              handler: "twitter://user?id=#{target.source.id}"
            )
          }
        }

        @logger = logger
      end

      def start
        @client.user do |object|
          case object
          when ::Twitter::Tweet
            @hooks[:tweet].call(object)
          when ::Twitter::Streaming::Event
            unless @hooks[object.name].nil?
              @hooks[object.name].call(object)
            end
          else
            @logger.info object.class
          end
        end
      end
    end
  end
end


