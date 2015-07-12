class Post
  attr_accessor :id, :title, :text, :author_id, :author_screenname, :created_at, :retweet_title, :retweet_text, :comments
  
  def created_at_readable
    @created_at.strftime("%Y-%m-%d %H:%M:%S")
  end
end