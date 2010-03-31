class Dropdowns < Vogue::Dropdowns
  
  def priorities
    Priority.find(:all, :order => "level asc")
  end
  
end