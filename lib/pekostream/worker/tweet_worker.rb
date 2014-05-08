require 'sidekiq'

class TweetWorker
  include Sidekiq::Worker
end
