class Feed < ApplicationRecord
  extend FriendlyId

  has_many :links, dependent: :destroy

  validates :slug, :title, :url, presence: true
  validates :slug, :title, :url, uniqueness: true

  after_create :start_fetching
  before_validation :set_title

  friendly_id :title, use: :slugged

  def fetch
    feed.entries.each do |entry|
      # Find or start a new link for the url
      link = links.find_or_initialize_by(url: entry.url)

      # Set published_at date
      published_date = [entry.published, DateTime.now].compact.min
      link.published_at ||= [published_date, last_fetched_at].compact.max

      # Skip link if older than 1 week
      next if link.published_at < Link::TTL.ago

      # Set guid
      link.guid = entry.entry_id || entry.url

      # Set title
      title = ActionController::Base.helpers.strip_tags(entry.title)
      link.title = HTMLEntities.new.decode(title)

      # Set body
      body = entry.content || entry.summary || title
      body = ActionController::Base.helpers.strip_tags(body)
      link.body  = HTMLEntities.new.decode(body)

      # Set author
      author_name = ActionController::Base.helpers.strip_tags entry.author
      link.author = Author.find_or_create_by(name: author_name)

      # Save changes
      link.save
    end

    # Update the last fetched time once done
    update(last_fetched_at: DateTime.now)
  end

  def publish_rate
    7.days / (links_count + 1)
  end

  def points
    @points ||= ['clicks', 'shares', 'favorites'].reduce(0) do |sum, column|
      sum + links.sum("#{column}_count".to_sym)
    end
  end

  def score
    @score ||= points.to_f / (links_count.to_f + 1.0)
  end

  private

  def start_fetching
    FetchLinksJob.perform_later id
  end

  def set_title
    self.title ||= feed.title
  end

  def feed
    @feed ||= Feedjira::Feed.fetch_and_parse(url)
  end
end
