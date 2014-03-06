require 'log_minimal'
require "pekostream/version"
require 'sidekiq'

$:.unshift(File.dirname(__FILE__) + '/../workers')

LogMinimal::Configuration.path = $stdout
