require_relative 'user_transaction'

class Transaction
  attr_accessor :id, :created_at, :status, :cash, :net_value, :category, :comment, :trades
  
  #status: success, failed, canceled
  #category: user_rebalancing, sys_rebalancing
  
  def category_readable
    if @category == "user_rebalancing"
      ""
    elsif @category == "sys_rebalancing"
      "分红配送"
    end
  end
  
  def status_readable
    if @status == "success"
      "成功"
    elsif @status == "failed"
      "失败"
    elsif @status == "canceled"
      "取消"
    end
  end
  
  def created_at_readable
    @created_at.strftime("%Y-%m-%d %H:%M:%S")
  end
end