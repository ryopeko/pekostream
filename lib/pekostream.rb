require "pekostream/stream/twitter"
require "pekostream/version"
require 'logger'
require 'pry'
require 'sidekiq'

$:.unshift(File.dirname(__FILE__) + '/../workers')

