require 'twitter'
require 'pekostream/notification/im_kayac'
require 'pekostream/filter/twitter'
require 'pekostream/stream/base'

module Pekostream
  module Stream
    class Twitter < Pekostream::Stream::Base
      attr_reader :screen_name

      @@stream_type = 'twitter'
      TWEET_INTERVAL_THRESHOLD = 420

      def initialize(screen_name:, notification_words:[], credentials:, imkayac_config:)
        @client = ::Twitter::Streaming::Client.new do |config|
          config.consumer_key        = credentials[:consumer_key]
          config.consumer_secret     = credentials[:consumer_secret]
          config.access_token        = credentials[:access_token]
          config.access_token_secret = credentials[:access_secret]
        end

        @screen_name = screen_name
        @last_received_at = Time.now

        @notifier = Pekostream::Notification::ImKayac.new(
          username: imkayac_config[:username],
          secret: imkayac_config[:secret]
        )

        twitter_filter = Pekostream::Filter::Twitter.new(notification_words)
        colors = (31..36).to_a + (91..96).to_a

        @hooks = {
          tweet: ->(tweet){
            screen_name = tweet.user.screen_name
            colorlized = "\e[#{colors[screen_name.delete('_').to_i(36) % colors.size]}m#{screen_name}\e[0m"

            output "#{colorlized}: #{tweet.text} #{tweet.created_at}"

            if /^RT\s@#{@screen_name}/ =~ tweet.text
              @notifier.notify(
                "Retweeted by @#{tweet.user.screen_name}: #{tweet.text}",
                handler: "twitter://status?id=#{tweet.id}"
              )
            elsif twitter_filter.filter(tweet.text)
              @notifier.notify(
                "maybe mentioned from @#{tweet.user.screen_name}: #{tweet.text}",
                handler: "twitter://status?id=#{tweet.id}"
              )
            end

            @last_received_at = tweet.created_at
          },
          favorite: ->(event){
            return if event.source.screen_name == @screen_name
            @notifier.notify(
              "#{event.name} from #{event.source.screen_name}: #{event.target_object.text}",
              handler: "twitter://status?id=#{event.target_object.id}"
            )
          },
          follow: ->(target){
            @notifier.notify(
              "#{target.name} from #{target.source.screen_name}",
              handler: "twitter://user?id=#{target.source.id}"
            )
          }
        }
      end

      def start
        @thread = Thread.new do
          begin
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
          ensure
            puts "killed #{@screen_name}'s twitter user stream thread"
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
          @notifier.notify "#{@screen_name}'s user stream reconnect is success"
        else
          @notifier.notify "#{@screen_name}'s user stream reconnect is failed"
        end

        @thread
      end

      private def output(text)
        super @@stream_type, "[#{@screen_name}] #{text}"
      end
    end
  end
end


