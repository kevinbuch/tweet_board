class Post < ActiveRecord::Base
  belongs_to :board
  belongs_to :contributor
  has_many :posts_tags
  has_many :tags, through: :posts_tags
  validates :tweet_id, uniqueness: true
  validates :contributor_id, presence: true

  def self.create_from_tweet(tweet)
    attributes = {}
    contributor = Contributor.find_by_twitter_name(tweet.user.screen_name)
    contributor.update_attributes(name: tweet.user.name)
    attributes[:contributor_id] = contributor.id
    attributes[:text] = Post.get_plain_text(tweet.text)
    attributes[:tweet_id] = tweet.id
    attributes[:start_date] = Time.now
    attributes[:end_date] = Time.now + 2.days
    post = contributor.posts.create(attributes)
    post
  end

  def self.get_plain_text(tweet_text)
    without_ats = tweet_text.gsub(/@\w+/, '')
    without_tags = without_ats.gsub(/#\w+/, '')
    without_tags.strip.capitalize
  end

  def create_tags(tweet)
    tweet.hashtags.each do |tag|
      self.tags << Tag.find_or_create_by_text(tag.text)
      add_contributor(tweet) if tag.text == 'add'
    end
  end

  def add_contributor
    self.update_attribute(:end_date, Time.now)
    tweet.text.scan(/@\w+/).each do |new_contributor|
      self.board.contributors << Contributor.find_or_create_by_twitter_name(new_contributor[1..-1])
    end
  end
end
