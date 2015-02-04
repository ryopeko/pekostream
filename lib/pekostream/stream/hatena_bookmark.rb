require 'rss'

module Pekostream
  module Stream
    class HatenaBookmark < Pekostream::Stream::Base
      attr_accessor :feed_url, :interval, :timezone

      @@stream_type = 'hatebu'

      def initialize(options={})
        super
        @last_checked_at ||= 60.minutes.ago
        @interval ||= 300
        @timezone ||= 'Asia/Tokyo'
      end

      def run
        RSS::Parser.parse(feed_url).items.each do |item|
          posted_at = item.dc_date.in_time_zone(@timezone)

          if posted_at < @last_checked_at
            output('skipped..')
            break
          end

          invoke(:notify, "#{item.dc_creator} hatebed #{item.title}", item.link.gsub(/^http/, 'googlechrome'))
          output "hatebed #{item.title} (#{item.link}) at #{item.dc_date}", prefix: item.dc_creator
        end
        @last_checked_at = Time.now
      end

      def start
        @thread = Thread.new do
          loop do
            self.run
            sleep @interval
          end
        end
      end

      private def output(text, prefix: '')
        super @@stream_type, "#{prefix.colorlize} #{text}"
      end
    end
  end
end
