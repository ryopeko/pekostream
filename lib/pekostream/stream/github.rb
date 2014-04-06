require 'active_support/core_ext'
require 'octokit'
require 'pp'
require 'pekostream/stream/base'

module Pekostream
  module Stream
    class Github < Pekostream::Stream::Base
      @@stream_type = 'github'

      def initialize(access_token:, default_checked_at: 60.minutes.ago)
        @client          = Octokit::Client.new access_token: access_token

        @last_checked_at = default_checked_at
      end

      def run
        @client.received_events('ryopeko').each do |event|
          created_at = event.created_at.in_time_zone('Asia/Tokyo')
          if created_at < @last_checked_at
            output('skipped..')
            break
          end

          payload = event.payload
          case event.type.to_sym
          when :WatchEvent
            output "#{event.actor.login} starred #{event.repo.name} at #{created_at}"
          when :ForkEvent
            output "#{event.actor.login} forked #{event.repo.name} at #{created_at}"
          when :CreateEvent
            case payload.ref_type.to_sym
            when :repository
              output "#{event.actor.login} created repository #{event.repo.name} at #{created_at}"
            else
              output payload.ref_type
              pp event
            end
          when :IssuesEvent
            output "#{event.actor.login} #{payload.action} issue #{event.repo.name}##{payload.issue.number}"
          when :IssueCommentEvent
            output "#{event.actor.login} commented on issue #{event.repo.name}##{payload.issue.number}"
          when :GistEvent
            case payload.action.to_sym
            when :create
              output "#{event.actor.login} created gist #{payload.gist.id} at #{created_at}"
            when :update
              output "#{event.actor.login} updated gist #{payload.gist.id} at #{created_at}"
            else
              output payload.action
              pp event
            end
          when :MemberEvent
            output "#{event.actor.login} added #{payload.member.login} to #{event.repo.name} at #{created_at}"
          when :PublicEvent
            output "#{event.actor.login} open sourced #{event.repo.name} at #{created_at}"
          when :PushEvent
            branch_name = payload.ref.match(/refs\/heads\/(.+)$/)[1]
            output "#{event.actor.login} pushed to #{branch_name} at #{event.repo.name} #{created_at}"
          when :PullRequestEvent
            output "#{event.actor.login} #{payload.action} #{event.repo.name}##{payload.pull_request.number} #{created_at}"
          when :DeleteEvent
            output "#{event.actor.login} deleted #{payload.ref_type} #{payload.ref} #{event.repo.name} at #{created_at}"
          else
            output event.type
            pp event
          end
        end

        @last_checked_at = Time.now
      end

      def start
        @thread = Thread.new do
          loop do
            self.run
            sleep 600
          end
        end
      end

      private def output(text)
        super @@stream_type, text
      end
    end
  end
end
