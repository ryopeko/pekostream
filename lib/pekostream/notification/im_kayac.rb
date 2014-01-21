require 'im-kayac/message'

module Pekostream
  module Notification
    class ImKayac
      def initialize(username:, secret:, handler: nil)
        @notifier = ::ImKayac::Message.new
        @notifier.to(username).secret(secret)
        @notifier.handler(handler) if handler
        #ImKayac.to('ryopeko').secret(ENV['IMKAYAC_SECRET']).handler("twitter://status?id=422775613305270272").post(message)
      end

      def notify(message)
        @notifier.post(message)
      end
    end
  end
end
