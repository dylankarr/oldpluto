require 'htmlentities'

class Link < ApplicationRecord
  delegate :title, to: :feed, prefix: true

  has_many   :clicks,      dependent: :destroy
  has_many   :shares,      dependent: :destroy
  has_many   :favorites,   dependent: :destroy
  has_many   :users,       through: :favorites
  belongs_to :author,      counter_cache: true
  belongs_to :feed,        counter_cache: true

  validates :title, :url, :feed_id, presence: true
  validates :title, :url, uniqueness: true

  before_validation :sanitize_attributes
  before_validation :fix_post_dated_links
  after_create      :set_expiration
  after_create      :increment_word_counts

  scope :search, -> (terms) {
    if terms.any?
      query = (['links.title LIKE ? OR links.body LIKE ?'] * terms.count).join(' OR ')
      where(*([query, terms.map{ |term| ["%#{term}%"] * 2 }].flatten))
    end
  }
  scope :since, -> (t) { where('published_at > ?', t.hours.ago) if t.present? }
  scope :authored_by, -> (ids) { where(authors: { slug: ids })  if ids.any? }
  scope :from_feeds,  -> (ids) { where(feeds: { slug: ids })    if ids.any? }

  def author_name=(name)
    name = ActionController::Base.helpers.strip_tags name
    self.author = Author.find_or_create_by(name: name)
  end

  def favorited?(user)
    Favorite.where(user: user, link: self).any?
  end

  def tags
    corpus = (title.scan(/\w+/) + body.scan(/\w+/)).uniq
    @tags ||= Tag.where(name: corpus).order(score: :desc).first(5)
  end

  private

  def increment_word_counts
    corpus = title.scan(/\w+/) + body.scan(/\w+/)
    corpus.uniq.each do |word|
      tag = Tag.find_or_create_by(name: word)
      tag.increment!(:count, corpus.count(tag.name))
    end
  end

  def fix_post_dated_links
    self.published_at = [published_at, DateTime.now].compact.min
  end

  def sanitize_attributes
    self.title = ActionController::Base.helpers.strip_tags(title)
    self.body  = ActionController::Base.helpers.strip_tags(body)

    self.title = HTMLEntities.new.decode(title)
    self.body  = HTMLEntities.new.decode(body)
  end

  def set_expiration
    DestroyLinkJob.set(wait: 7.days).perform_later(self.id)
  end
end
