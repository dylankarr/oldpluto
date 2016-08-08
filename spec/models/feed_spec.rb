require 'rails_helper'

RSpec.describe Feed, type: :model do
  let(:feedjira_feed) { double() }
  let(:feed_entry) { double() }

  let(:feed_title) { Faker::Lorem.word }
  let(:feed_url)   { Faker::Internet.url }

  let(:entry_title) { Faker::Lorem.word }
  let(:entry_url)   { Faker::Internet.url }

  before do
    allow(feedjira_feed).to receive(:title)   { feed_title }
    allow(feedjira_feed).to receive(:url)     { feed_url }
    allow(feedjira_feed).to receive(:entries) { [feed_entry] }

    allow(feed_entry).to receive(:title) { entry_title }
    allow(feed_entry).to receive(:url)   { entry_url }

    allow(Feedjira::Feed).to receive(:fetch_and_parse) { |url| feedjira_feed }
  end

  it 'sets title before validation' do
    feed = create :feed, title: nil
    expect(feed.title).to eq feed_title
  end

  describe '#fetch' do
    let(:feed) { create :feed }

    it 'creates a link' do
      expect{ feed.fetch }.to change{ Link.count }.by(1)
    end

    it 'creates a link with the correct title' do
      feed.fetch
      expect(Link.first.title).to eq entry_title
    end

    it 'creates a link with the correct title' do
      feed.fetch
      expect(Link.first.url).to eq entry_url
    end
  end
end