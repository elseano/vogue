module Vogue
  module PartialLocator
    
    def self.included(base)
      base.module_eval do
        alias_method_chain :_pick_partial_template, :vogue
      end
    end
    
    def _pick_partial_template_with_vogue(partial_path) #:nodoc:
      _pick_partial_template_without_vogue(partial_path)
    rescue ActionView::MissingTemplate
      raise if !controller.respond_to?(:vogue_data)
      raise if controller.nil? || controller.vogue_data[:root].blank?
      
      scaffold_paths = view_paths.class.new
      scaffold_paths.unshift(controller.vogue_data[:root])
      scaffold_paths.find_template("_#{partial_path}", self.template_format)
    end
  end
end

