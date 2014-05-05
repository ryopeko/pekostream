require 'active_record'

ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  host: 'localhost',
  username: 'pekostream',
  database: 'pekostream'
)

module Pekostream
  module Recorder
    module Twitter
      class Tweet < ActiveRecord::Base
      end
    end
  end
end
