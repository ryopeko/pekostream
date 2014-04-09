require 'active_support/core_ext'
require 'octokit'
require 'pp'
require 'pekostream/stream/base'

module Pekostream
  module Stream
    class Github < Pekostream::Stream::Base
      @@stream_type = 'github'

      attr_accessor :username, :access_token

      def initialize(options={})
        options.each do |key, value|
          send(:"#{key}=", value)
        end

        yield self if block_given?

        @client = Octokit::Client.new access_token: @access_token
        @last_checked_at ||= 60.minutes.ago
      end

      def run
        @client.received_events(@username).each do |event|
          created_at = event.created_at.in_time_zone('Asia/Tokyo')

          if created_at < @last_checked_at
            output('skipped..')
            break
          end

          payload   = event.payload
          actor     = event.actor.login.colorlize
          repo_name = event.repo.name

          case event.type.to_sym
          when :WatchEvent
            output "#{actor} starred #{repo_name} at #{created_at}"
          when :ForkEvent
            output "#{actor} forked #{repo_name} at #{created_at}"
          when :CreateEvent
            case payload.ref_type.to_sym
            when :repository
              output "#{actor} created repository #{repo_name} at #{created_at}"
            else
              output payload.ref_type
              pp event
            end
          when :IssuesEvent
            output "#{actor} #{payload.action} issue #{repo_name}##{payload.issue.number}"
          when :IssueCommentEvent
            output "#{actor} commented on issue #{repo_name}##{payload.issue.number}"
          when :GistEvent
            gist_id = payload.gist.id

            case payload.action.to_sym
            when :create
              output "#{actor} created gist #{gist_id} at #{created_at}"
            when :update
              output "#{actor} updated gist #{gist_id} at #{created_at}"
            else
              output payload.action
              pp event
            end
          when :MemberEvent
            output "#{actor} added #{payload.member.login} to #{repo_name} at #{created_at}"
          when :PublicEvent
            output "#{actor} open sourced #{repo_name} at #{created_at}"
          when :PushEvent
            branch_name = payload.ref.match(/refs\/heads\/(.+)$/)[1]
            output "#{actor} pushed to #{branch_name} at #{repo_name} #{created_at}"
          when :PullRequestEvent
            output "#{actor} #{payload.action} #{repo_name}##{payload.pull_request.number} #{created_at}"
          when :DeleteEvent
            output "#{actor} deleted #{payload.ref_type} #{payload.ref} #{repo_name} at #{created_at}"
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
