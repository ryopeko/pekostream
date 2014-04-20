require 'twitter'
require 'pekostream/filter/twitter'
require 'pekostream/stream/base'

module Pekostream
  module Stream
    class Twitter < Pekostream::Stream::Base
      attr_reader :screen_name

      @@stream_type = 'twitter'
      TWEET_INTERVAL_THRESHOLD = 420

      def initialize(screen_name:, notification_words:[], credentials:)
        @client = ::Twitter::Streaming::Client.new do |config|
          config.consumer_key        = credentials[:consumer_key]
          config.consumer_secret     = credentials[:consumer_secret]
          config.access_token        = credentials[:access_token]
          config.access_token_secret = credentials[:access_secret]
        end

        @screen_name = screen_name
        @last_received_at = Time.now

        twitter_filter = Pekostream::Filter::Twitter.new(notification_words)

        @hooks = {
          tweet: ->(tweet){
            screen_name = tweet.user.screen_name

            prefix = ''
            if /^RT\s@#{@screen_name}/ =~ tweet.text
              prefix = "Retweeted by "
              invoke(:notify,
                "#{prefix}@#{screen_name}: #{tweet.text}",
                "twitter://status?id=#{tweet.id}"
              )
            elsif twitter_filter.filter(tweet.text)
              prefix = "maybe mentioned from "
              invoke(:notify,
                "#{prefix}@#{screen_name}: #{tweet.text}",
                "twitter://status?id=#{tweet.id}"
              )
            end

            output "#{screen_name.colorlize}: #{tweet.text} #{tweet.created_at}", prefix: prefix

            @last_received_at = tweet.created_at
          },
          favorite: ->(event){
            return if event.source.screen_name == @screen_name
            prefix = event.name.to_s
            text = " from #{event.source.screen_name}: #{event.target_object.text}"
            invoke(:notify,
              "#{prefix}#{text}",
              "twitter://status?id=#{event.target_object.id}"
            )
            output text, prefix: prefix
          },
          follow: ->(target){
            prefix = target.name.to_s
            text = " from #{target.source.screen_name}"
            invoke(:notify,
              "#{prefix}#{text}",
              "twitter://user?id=#{target.source.id}"
            )
            output text, prefix: prefix
          }
        }
      end

      def start
        @thread = Thread.new do
          @client.user do |object|
            case object
            when ::Twitter::Tweet
              @hooks[:tweet].call(object)
            when ::Twitter::Streaming::Event
              unless @hooks[object.name].nil?
                @hooks[object.name].call(object)
              end
            end
          end
        end
      end

      def alive?
        Time.now - @last_received_at < TWEET_INTERVAL_THRESHOLD
      end

      def stop
        return unless @thread
        @thread.kill
        @thread.join
        @thread = nil
      end

      def reconnect
        self.stop
        if self.start
          invoke(:notify, "#{@screen_name}'s user stream reconnect is success")
        else
          invoke(:notify, "#{@screen_name}'s user stream reconnect is failed")
        end

        @thread
      end

      private def output(text, prefix: '')
        super @@stream_type, "[#{@screen_name.colorlize}] #{prefix.bg_colorlize}#{text}"
      end
    end
  end
end


