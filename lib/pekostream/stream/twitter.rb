require 'twitter'
require 'pekostream/notification/im_kayac'
require 'pekostream/filter/twitter'
require 'pekostream/stream/base'

module Pekostream
  module Stream
    class Twitter < Pekostream::Stream::Base
      attr_reader :screen_name

      @@stream_type = 'twitter'

      def initialize(screen_name:, notification_words:[], credentials:, imkayac_config:)
        @client = ::Twitter::Streaming::Client.new do |config|
          config.consumer_key        = credentials[:consumer_key]
          config.consumer_secret     = credentials[:consumer_secret]
          config.access_token        = credentials[:access_token]
          config.access_token_secret = credentials[:access_secret]
        end

        @screen_name = screen_name

        notifier = Pekostream::Notification::ImKayac.new(
          username: imkayac_config[:username],
          secret: imkayac_config[:secret]
        )

        twitter_filter = Pekostream::Filter::Twitter.new(notification_words)

        @hooks = {
          tweet: ->(tweet){
            output "#{tweet.user.screen_name}: #{tweet.text}"

            if /^RT\s@#{@screen_name}/ =~ tweet.text
              notifier.notify(
                "Retweeted by @#{tweet.user.screen_name}: #{tweet.text}",
                handler: "twitter://status?id=#{tweet.id}"
              )
            elsif twitter_filter.filter(tweet.text)
              notifier.notify(
                "maybe mentioned from @#{tweet.user.screen_name}: #{tweet.text}",
                handler: "twitter://status?id=#{tweet.id}"
              )
            end
          },
          favorite: ->(event){
            return if event.source.screen_name == @screen_name
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
            infof object.class
          end
        end
      end

      private def output(text)
        super @@stream_type, "[#{@screen_name}] #{text}"
      end
    end
  end
end


