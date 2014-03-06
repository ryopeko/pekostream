require 'active_support/core_ext'
require 'octokit'

module Pekostream
  module Stream
    class Github
      def initialize(access_token:, default_checked_at: 60.minutes.ago)
        @client          = Octokit::Client.new access_token: access_token

        @last_checked_at = default_checked_at
      end

      def run
        @client.received_events('ryopeko').each do |event|
          created_at = event.created_at.in_time_zone('Asia/Tokyo')

          infof('skipped..') and break if created_at < @last_checked_at

          payload = event.payload
          case event.type.to_sym
          when :WatchEvent
            infof "#{event.actor.login} starred #{event.repo.name} at #{created_at}"
          when :ForkEvent
            infof "#{event.actor.login} forked #{event.repo.name} at #{created_at}"
          when :CreateEvent
            case payload.ref_type.to_sym
            when :repository
              infof "#{event.actor.login} created repository #{event.repo.name} at #{created_at}"
            else
              infof payload.ref_type
              pp event
            end
          when :IssuesEvent
            infof "#{event.actor.login} #{payload.action} issue #{event.repo.name}##{payload.issue.number}"
          when :IssueCommentEvent
            infof "#{event.actor.login} commented on issue #{event.repo.name}##{payload.issue.number}"
          when :GistEvent
            case payload.action.to_sym
            when :create
              infof "#{event.actor.login} created gist #{payload.gist.id} at #{created_at}"
            when :update
              infof "#{event.actor.login} updated gist #{payload.gist.id} at #{created_at}"
            else
              infof payload.action
              pp event
            end
          when :MemberEvent
            infof "#{event.actor.login} added #{payload.member.login} to #{event.repo.name} at #{created_at}"
          else
            infof event.type
            pp event
          end
        end

        @last_checked_at = Time.now
      end
    end
  end
end
