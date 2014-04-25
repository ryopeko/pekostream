require 'pekostream/stream/twitter'
require 'twitter'

describe Pekostream::Stream::Twitter do
  subject {
    described_class.new do |config|
      config.screen_name = 'ryopeko'
      config.credentials = {
        consumer_key:        'consumer_key',
        consumer_secret:     'consumer_secret',
        access_token:        'access_token',
        access_token_secret: 'access_token_secret'
      }
      config.notification_words = []
    end
  }

  describe "#favorite" do
    before do
      @me = 'ryopeko'
      @target_object = {
        id: 459259871234244608,
        text: 'hogehoge',
        screen_name: @me
      }
    end

    context "when source event's user" do
      context "is other user" do
        it 'should call #invoke' do
          expect(subject).to receive(:invoke)
          subject.favorite(::Twitter::Streaming::Event.new(
            event: 'favorite',
            source: {
              id: '2311766360',
              screen_name: 'ryopeko_test'
            },
            target: {
              id: '15562743',
              screen_name: @me
            },
            target_object: @target_object
          ))
        end
      end

      context "is me" do
        it 'should not call #invoke' do
          expect(subject).to receive(:invoke).exactly(0).times
          subject.favorite(::Twitter::Streaming::Event.new(
            event: 'favorite',
            source: {
              id: '2311766360',
              screen_name: @me
            },
            target: {
              id: '15562743',
              screen_name: @me
            },
            target_object: @target_object
          ))
        end
      end
    end
  end
end
