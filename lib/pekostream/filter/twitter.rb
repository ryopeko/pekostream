module Pekostream
  module Filter
    class Twitter
      def initialize(patterns=[])
        @patterns = patterns
      end

      def filter(target)
        @patterns.each do |pattern|
          return $~ if matches = /#{pattern}/.match(target)
        end
        return
      end
    end
  end
end



