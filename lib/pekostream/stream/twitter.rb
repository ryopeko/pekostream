require 'twitter'
require 'sidekiq'
require 'active_support/core_ext/object'
require 'pekostream/filter/twitter'
require 'pekostream/stream/base'

module Pekostream
  module Stream
    class Twitter < Pekostream::Stream::Base
      attr_accessor :screen_name, :credentials, :notification_words

      @@stream_type = 'twitter'
      TWEET_INTERVAL_THRESHOLD = 420

      def initialize(options={})
        super
        @client = ::Twitter::Streaming::Client.new(credentials)

        @last_received_at = Time.now
        @twitter_filter = Pekostream::Filter::Twitter.new(notification_words)
      end

      def tweet(tweet)
        screen_name = tweet.user.screen_name

        prefix = ''
        if /^RT\s@#{@screen_name}/ =~ tweet.text
          prefix = "Retweeted by "
          invoke(:notify,
                 "#{prefix}@#{screen_name}: #{tweet.text}",
                 "twitter://status?id=#{tweet.id}"
                )
        elsif @twitter_filter.filter(tweet.text)
          prefix = "maybe mentioned from "
          invoke(:notify,
                 "#{prefix}@#{screen_name}: #{tweet.text}",
                 "twitter://status?id=#{tweet.id}"
                )
        end

        Sidekiq::Client.push(
          'class' => 'TweetWorker',
          'args' => [
            tweet.id,
            tweet.text,
            tweet.user.screen_name,
            tweet.in_reply_to_status_id,
            tweet.created_at
          ]
        )

        output "#{screen_name.colorlize}: #{tweet.text} #{tweet.created_at}", prefix: prefix

        @last_received_at = tweet.created_at
      end

      def favorite(event)
        return if event.source.screen_name == @screen_name
        prefix = event.name.to_s
        text = " from #{event.source.screen_name}: #{event.target_object.text}"
        invoke(:notify,
               "#{prefix}#{text}",
               "twitter://status?id=#{event.target_object.id}"
              )
        output text, prefix: prefix
      end

      def follow(event)
        prefix = event.name.to_s
        text = " from #{event.source.screen_name}"
        invoke(:notify,
               "#{prefix}#{text}",
               "twitter://user?id=#{event.source.id}"
              )
        output text, prefix: prefix
      end

      def start
        @thread = Thread.new do
          @client.user do |object|
            case object
            when ::Twitter::Tweet
              tweet(object)
            when ::Twitter::Streaming::Event
              try(object.name.to_sym, object)
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


