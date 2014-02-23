require 'active_support/core_ext'
require 'octokit'

module Pekostream
  module Stream
    class Github
      def initialize(access_token:, default_checked_at: 60.minutes.ago, logger: Logger.new($stdout))
        @client          = Octokit::Client.new access_token: access_token

        @last_checked_at = default_checked_at
        @logger = logger
      end

      def run
        @client.received_events('ryopeko').each do |event|
          created_at = event.created_at.in_time_zone('Asia/Tokyo')

          @logger.info('skipped..') and break if created_at < @last_checked_at

          payload = event.payload
          case event.type.to_sym
          when :WatchEvent
            @logger.info "#{event.actor.login} starred #{event.repo.name} at #{created_at}"
          when :ForkEvent
            @logger.info "#{event.actor.login} forked #{event.repo.name} at #{created_at}"
          when :CreateEvent
            case payload.ref_type.to_sym
            when :repository
              @logger.info "#{event.actor.login} created repository #{event.repo.name} at #{created_at}"
            else
              @logger.info payload.ref_type
              pp event
            end
          when :GistEvent
            case payload.action.to_sym
            when :create
              @logger.info "#{event.actor.login} created gist #{payload.gist.id} at #{created_at}"
            else
              @logger.info payload.action
              pp event
            end
          else
            @logger.info event.type
            pp event
          end
        end

        @last_checked_at = Time.now
      end
    end
  end
end
