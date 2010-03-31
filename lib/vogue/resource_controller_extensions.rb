module Vogue
  module ResourceControllerExtensions
    
    def self.included(base)
      include ResourceController::Helpers::Pagination if base.vogue_data[:per_page] || base.vogue_data[:pagination]
      include ResourceController::Helpers::Searchlogic if base.vogue_data[:searchlogic] == true
    end
    
    module Pagination
      protected
      def collection
        end_of_association_chain.paginate(:page => params[:page], :per_page => self.class.vogue_data[:per_page] || params[:per_page])
      end
    end
    
    module Searchlogic
    
      def self.included(base)
        base.class_eval do
          alias_method_chain :end_of_association_chain, :searchlogic
          before_filter do
            @search = end_of_association_chain
          end
        end
      end
    
      protected
    
      def end_of_association_chain_with_searchlogic
        end_of_association_chain_without_searchlogic.searchlogic(params[:search])
      end
    
    end
    
  end
end