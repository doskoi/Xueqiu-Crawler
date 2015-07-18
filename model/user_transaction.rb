class UserTransaction
  attr_accessor :id, :created_at, :stock_name, :stock_symbol, :price, :prev_price, :net_value, :prev_net_value, :weight, :target_weight, :prev_target_weight, :prev_weight_adjusted
  
  def weight
    (@weight) ? @weight : "0"
  end
  
  def target_weight
    (@target_weight) ? @target_weight : "0"
  end
  
  def prev_target_weight
    (@prev_target_weight) ? @prev_target_weight : "0"
  end
  
  def prev_weight_adjusted
    (@prev_weight_adjusted) ? @prev_weight_adjusted : "0"
  end
  
  def created_at_readable
    @created_at.strftime("%Y-%m-%d %H:%M:%S")
  end
end