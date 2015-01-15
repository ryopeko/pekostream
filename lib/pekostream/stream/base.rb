require "pekostream/core_ext/string"
require 'logger'

module Pekostream
  module Stream
    class Base
      def initialize(options={})
        options.each do |key, value|
          send(:"#{key}=", value)
        end

        @logger = Logger.new(STDOUT)

        yield self if block_given?
      end

      def event(event, hook)
        @hooks ||= {}
        (@hooks[event.to_sym] ||= []) << hook
      end

      def invoke(event, *args)
        @hooks[event].each do |m|
          m.call(*args)
        end
      end

      private def output(type, text)
        @logger.info "[#{type.colorlize}] #{text}"
      end
    end
  end
end

