require 'im-kayac'

module Pekostream
  module Notification
    class ImKayac
      def initialize(username:, secret:, handler: nil)
        @notifier = ::ImKayac::Message.new
        @notifier.to(username).secret(secret)
        @notifier.handler(handler)
      end

      def notify(message, handler: nil)
        @notifier.handler(handler).post(message)
      end
    end
  end
end
