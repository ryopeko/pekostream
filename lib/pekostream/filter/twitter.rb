module Pekostream
  module Filter
    class Twitter
      def initialize(patterns)
        @patterns = patterns.map do |pattern|
          unless pattern.is_a?(Regexp)
            Regexp.new(pattern)
          else
            pattern
          end
        end
      end

      def filter(target)
        @patterns.each do |pattern|
          return $~ if matches = pattern.match(target)
        end
        return
      end
    end
  end
end



