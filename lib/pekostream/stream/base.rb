module Pekostream
  module Stream
    class Base
      def event(event, hook)
        (@hooks[event.to_sym] ||= []) << hook
      end

      def invoke(event, *args)
        @hooks[event].each do |m|
          m.call(*args)
        end
      end

      private def output(type, text)
        puts "[#{type.colorlize}] #{text}"
      end
    end
  end
end

