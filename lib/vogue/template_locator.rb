
module Vogue
  module TemplateLocator
    
    private
    
    # Use dynamic scaffold fallback if a template can't be found in the view paths.
    def default_template(action_name = self.action_name)
      view_paths.find_template(default_template_name(action_name), default_template_format)
    rescue ActionView::MissingTemplate => ex
      raise if self.vogue(:root).blank?
      action_name = "index" if action_name.blank?
      
      scaffold_paths = view_paths.class.new
      Array(self.vogue(:root)).each do |path|
        scaffold_paths.unshift(path)
      end
      
      begin
        scaffold_paths.find_template(action_name, default_template_format)
      rescue ActionView::MissingTemplate
        raise ex
      end
      
    end
  end
end