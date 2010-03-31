begin
  require_dependency 'application_controller'
rescue LoadError => e
  require_dependency 'application'
end

module Vogue
  # cattr_accessor :pagination
  # self.pagination = defined?(WillPaginate)
  
  module ActionControllerExtension
    unloadable
    
    # Adds vogue view inheritance to a controller.
    # 
    # Options Include:
    #
    # :scaffold_root => The path which contains the default views to use if they're not present in the controllers view path. Can be an array.
    #
    # Notes:
    # All options given to resource_controller are available to the views and controllers through the instance & class methods #vogue, which returns a hash.
    # This can be useful to define things such as headings, etc at the view level.
    def vogue(options = {})
      if options.blank?
        return respond_to?(:vogue_data) ? vogue_data : nil
      else
        cattr_accessor :vogue_data unless self.respond_to?(:vogue_data)
        self.vogue_data = options
        
        require File.join(File.dirname(__FILE__), "vogue/helpers")
        require File.join(File.dirname(__FILE__), "vogue/partial_locator")
        require File.join(File.dirname(__FILE__), "vogue/template_locator")
        
        include Vogue::Helpers
        include Vogue::TemplateLocator unless included_modules.include?(Vogue::TemplateLocator)
        ActionView::Partials.send(:include, Vogue::PartialLocator) unless ActionView::Partials.included_modules.include?(Vogue::PartialLocator)
        
        if defined?(ResourceController) && included_modules.include?(ResourceController) && !included_modules.include?(Vogue::ResourceControllerExtensions)
          require File.join(File.dirname(__FILE__), "vogue/resource_contorller_extensions")
          include Vogue::ResourceControllerExtensions
        end
      end
    end
  end
end

ActionController::Base.class_eval do
  extend Vogue::ActionControllerExtension
end
