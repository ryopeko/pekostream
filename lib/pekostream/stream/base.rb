module Pekostream
  module Stream
    class Base
      private def output(type, text)
        puts "[#{type}] #{text}"
      end
    end
  end
end

