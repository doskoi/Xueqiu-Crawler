class Comment
  attr_accessor :id, :text, :author_id, :author_screenname, :created_at, :reply_comment_id
  
  def created_at_readable
    @created_at.strftime("%Y-%m-%d %H:%M:%S")
  end
end