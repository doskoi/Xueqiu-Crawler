class Comment
  attr_accessor :id, :text, :author_id, :created_at, :reply_comment_id, :reply_screenname
  
  def created_at_readable
    @created_at.strftime("%Y-%m-%d %H:%M:%S")
  end
end