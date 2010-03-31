module Vogue
  module Helpers
    
    def self.included(base)
      base.class_eval do
        helper_method :vogue
        include InstanceMethods
      end
    end
    
    module InstanceMethods
      
      # Vogue helper method.
      # Call within your controllers or views to fetch vogue data.
      def vogue(options = {})
        if options.blank?
          self.class.vogue_data
        elsif options.is_a?(Symbol)
          self.class.vogue_data[options]
        elsif options.is_a?(Hash)
          self.class.vogue_data = options
        else
          raise ArgumentError, "options must be a symbol, a hash or blank."
        end
      end
      
    end
  end
end