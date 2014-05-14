require 'active_support/core_ext'
require 'octokit'
require 'pp'
require 'pekostream/stream/base'

module Pekostream
  module Stream
    class Github < Pekostream::Stream::Base
      @@stream_type = 'github'

      attr_accessor :username, :access_token, :last_checked_at, :notify_event_types

      def initialize(options={})
        super

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
          actor     = event.actor.login
          repo_name = event.repo.name

          text = case event.type.to_sym
                 when :WatchEvent
                   "starred #{repo_name} at #{created_at}"
                 when :ForkEvent
                   "forked #{repo_name} at #{created_at}"
                 when :CreateEvent
                   case payload.ref_type.to_sym
                   when :repository
                     "created repository #{repo_name} at #{created_at}"
                   when :branch
                     "created branch #{payload.ref} at #{repo_name} #{created_at}"
                   else
                     pp event
                     payload.ref_type
                   end
                 when :IssuesEvent
                   "#{payload.action} issue #{repo_name}##{payload.issue.number}"
                 when :IssueCommentEvent
                   "commented on issue #{repo_name}##{payload.issue.number}"
                 when :CommitCommentEvent
                   "commented on commit #{repo_name}@#{payload.comment.commit_id}"
                 when :GistEvent
                   gist_id = payload.gist.id

                   case payload.action.to_sym
                   when :create
                     "created gist #{gist_id} at #{created_at}"
                   when :update
                     "updated gist #{gist_id} at #{created_at}"
                   else
                     pp event
                     payload.action
                   end
                 when :MemberEvent
                   "added #{payload.member.login} to #{repo_name} at #{created_at}"
                 when :PublicEvent
                   "open sourced #{repo_name} at #{created_at}"
                 when :PushEvent
                   branch_name = payload.ref.match(/refs\/heads\/(.+)$/)[1]
                   "pushed to #{branch_name} at #{repo_name} #{created_at}"
                 when :PullRequestEvent
                   "#{payload.action} #{repo_name}##{payload.pull_request.number} #{created_at}"
                 when :DeleteEvent
                   "deleted #{payload.ref_type} #{payload.ref} #{repo_name} at #{created_at}"
                 else
                   pp event
                   event.type
                 end

          if @notify_event_types.include?(event.type.to_sym)
            invoke(:notify, "#{actor} #{text}")

            Sidekiq::Client.push(
              'class' => 'ActivityWorker',
              'args' => [{
                actor_screen_name: actor,
                source_service_name: 'github',
                source_type: event.type,
                description: text,
                created_at: created_at
              }]
            )
          end

          output "#{actor.colorlize} #{text}"
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
