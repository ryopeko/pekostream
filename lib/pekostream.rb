require 'log_minimal'
require "pekostream/stream/twitter"
require "pekostream/stream/github"
require "pekostream/version"
require 'pry'
require 'sidekiq'

$:.unshift(File.dirname(__FILE__) + '/../workers')

include LogMinimal::Methods
LogMinimal::Configuration.path = $stdout
