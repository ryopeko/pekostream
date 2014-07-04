require 'spec_helper'
require 'pekostream/stream/twitter'
require 'twitter'
require 'active_support/core_ext/time'
require 'active_support/core_ext/numeric'

describe Pekostream::Stream::Twitter do
  before do
    @me = 'ryopeko'
    @filter_word = 'filter'
    allow_any_instance_of(Pekostream::Stream::Twitter).to receive(:output).and_return('')
  end

  subject {
    described_class.new do |config|
      config.screen_name = 'ryopeko'
      config.credentials = {
        consumer_key:        'consumer_key',
        consumer_secret:     'consumer_secret',
        access_token:        'access_token',
        access_token_secret: 'access_token_secret'
      }
      config.notification_words = [@filter_word]
    end
  }

  describe "#favorite" do
    before do
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

  describe "#tweet" do
    before do
      @tweet_data = {
        created_at: "Sat Apr 26 13:48:14 +0000 2014",
        id: 460052735073611776,
        id_str: "460052735073611776",
        text: "提督各位大変そう...",
        source: "<a href=\"http://sites.google.com/site/yorufukurou/\" rel=\"nofollow\">YoruFukurou</a>",
        user: {
          id: 15562743,
          id_str: "15562743",
          name: "新卒ふなっしー",
          screen_name: "ryopeko",
        },
        favorited: false,
        retweeted: false
      }
    end

    context "when normal text" do
      it "should not call #invoke" do
        expect(subject).to receive(:invoke).exactly(0).times
        subject.tweet(::Twitter::Tweet.new(@tweet_data))
      end
    end

    context "when text included of rt" do
      it "should call #invoke" do
        expect(subject).to receive(:invoke)
        subject.tweet(::Twitter::Tweet.new(@tweet_data.merge(text: "RT @ryopeko_retro: hogehoge")))
      end
    end

    context "when text included of filter word" do
      it "should call #invoke" do
        expect(subject).to receive(:invoke)
        subject.tweet(::Twitter::Tweet.new(@tweet_data.merge(text: @filter_word)))
      end
    end
  end

  describe "#alive?" do
    context "when last received at" do
      before do
        @twitter = subject
      end

      after(:each) do
        Timecop.return
      end

      context "later than threshold" do
        before do
          Timecop.freeze(Time.now.since((Pekostream::Stream::Twitter::TWEET_INTERVAL_THRESHOLD - 1).second))
        end

        it { expect(@twitter.alive?).to be true }
      end

      context "more than threshold" do
        before do
          Timecop.freeze(Time.now.since((Pekostream::Stream::Twitter::TWEET_INTERVAL_THRESHOLD).second))
        end

        it { expect(@twitter.alive?).to be false }
      end
    end
  end
end
