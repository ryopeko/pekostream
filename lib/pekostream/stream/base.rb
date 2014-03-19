require 'pry'
module Pekostream
  module Stream
    class Base
      private def output(type, text)
        infof "[#{type}] #{text}"
      end
    end
  end
end

