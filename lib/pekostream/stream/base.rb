module Pekostream
  module Stream
    class Base
      private def output(type, text)
        puts "[#{type.colorlize}] #{text}"
      end
    end
  end
end

