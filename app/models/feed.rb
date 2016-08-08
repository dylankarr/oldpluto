class Feed < ApplicationRecord
  has_many :links, dependent: :destroy

  validates :title, :url, presence: true
  validates :title, :url, uniqueness: true

  before_validation :set_title

  def self.fetch_all
    Feed.find_each { |feed| feed.fetch }
  end

  def fetch
    Feedjira::Feed.fetch_and_parse(url).entries.each do |entry|
      link = self.links.find_or_initialize_by(url: entry.url)
      link.title = entry.title
      link.save
    end
  end

  private

  def set_title
    self.title = Feedjira::Feed.fetch_and_parse(url).title if title.nil?
  end
end