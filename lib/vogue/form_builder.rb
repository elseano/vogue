module Vogue
  # The Vogue FormBuilder adds a few handy methods for working with related data. Make your own FormBuilders inherit from this
  # to gain all the Voguey goodness.
  class FormBuilder < ActionView::Helpers::FormBuilder
    
    # Pulls in selection options from methods defined on Dropdowns, the :from option defines the method name to use. In
    # addition to the from option, many other options are supported which can enhance the functionality of the select field generated.
    #
    # :value_method => The method to use on the data source to obtain the value that should be returned to the server.
    # :text_method => The method to use on the data source to obtain the display text that should be displayed to the user.
    # :from => If a symbol, it calls the relevant method on IProperty::Render::Dropdowns, otherwise it accepts an array.
    # :include_blank => A blank option will be included at the top of the list displaying the assigned string.
    # :include_create => The assigned text will be displayed at the bottom of the list allowing the creation of a new value. This new value is returned to the server.
    # :create_width => How wide the creation text box should be (defaults to 20em).
    # :include_current => Includes the currently selected option at the top of the list. If a string, displays the string, replacing "~" with the current display text.
    def select_field(method = nil, options = {})
      source = options.delete(:from)
      extra_html = []
      html_options = Hash.new
      
      id_method = options.delete(:value_method) || "id"
      text_method = options.delete(:text_method) || "name"
      value = object.try(method)
      selections = nil
      
      data = if source.is_a?(Symbol)
        drop_down(source, options)
      elsif source.is_a?(Array)
        source
      else
        # Attempt to infer from the field name.
        if reflection = object.class.reflect_on_association(method.to_sym)
          drop_down(reflection.class_name.tableize, options)
        else
          raise "from must be either a symbol or an array"
        end
      end
      
      # Check to see if the data is in a grouped format. That is, we're getting [["Group Name", [data...]], ["Another Group", [data...]]].
      selections = if data.first.is_a?(Array) && data.first.last.is_a?(Array)
        
        # Check to see if the grouped data has already been converted into an array (instead of a list of domain objects).
        if data.first.last.first.is_a?(Array)
          id_method = :last
          text_method = :first
        end
        
        template.option_groups_from_collection_for_select(data, :last, :first, id_method, text_method, value)
      else
        # Check to see if its de-normalized (i.e, we're receiving data like this: [["Name", "Value"], ["Name", "Value"]])
        if data.first.is_a?(Array)
          id_method = :last
          text_method = :first
        elsif !data.first.is_a?(ActiveRecord::Base)
          id_method = :to_s
          text_method = :to_s
          value = value.to_s
        end
        
        template.options_from_collection_for_select(data, id_method, text_method, value)
      end
      
      if options[:include_blank]
        selections = template.content_tag(:option, options[:include_blank].is_a?(String) ? options[:include_blank] : nil, :value => "") + selections
      end
      
      if options[:include_create]
        working_with_new_value = !value.blank? && !selections.any? { |a| a.last.to_s == value.to_s }

        selections = selections + template.content_tag(:option, options[:include_create], :value => "-new-")

        if !value.blank? && options[:include_current]
          selections = template.content_tag(:option, options[:include_current].sub("~", value.send(text_method)), :value => value.send(id_method)) + selections
          working_with_new_value = false
        end

        width = options[:create_width] || "20em"

        result = []
        if working_with_new_value
          extra_html << template.tag(:input, :type => "text", :id => "#{@object_name}_#{method}_new_input", :name => "#{@object_name}[#{method}]", :style => "width: #{width}", :value => value)
        else
          html_options[:onchange] = "if($F(this) == '-new-') { $('#{@object_name}_#{method}_new').show(); $('#{@object_name}_#{method}').hide(); $('#{@object_name}_#{method}').writeAttribute('disabled', true); $('#{@object_name}_#{method}_new_input').writeAttribute('disabled', false); }"
          
          input = template.tag(:input, :type => "text", :id => "#{@object_name}_#{method}_new_input", :name => "#{@object_name}[#{method}]", :style => "width: #{width}", :disabled => "disabled")
          extra_html << template.content_tag(:div, input, :id => "#{@object_name}_#{method}_new", :style => "display: none")
        end

        result.join
      else
        if !value.blank? && options[:include_current]
          selections = @template.content_tag(:option, options[:include_current].sub("~", value), :value => value) + selections
        end
      end
      
      html_options[:onclick] = options.delete(:onclick) if options[:onclick]
      html_options[:class] = options.delete(:class) if options[:class]
      html_options[:style] = options.delete(:style) if options[:style]
      
      template.select_tag("#{@object_name}[#{method}]", selections, html_options) + " " + extra_html.join
    end
    
    # Displays a list of checkboxes which can be ticked. #method must return an array.
    # Check box items will display the name (or to_s) value of each element obtained by the :from option,
    # of is a block is given, will yield to the block for custom rendering.
    def check_box_array(method, options = {}, &contents)
      data = options.delete(:from)
      data = drop_down(data, options) if data.is_a?(Symbol)

      columns = options.delete(:columns) || 1
      output = ["<table style='width: 100%; border: 0; border-collapse: collapse'>"]
      output << "<tr>"
      
      value = object.send(method)
      
      Array(data).each_with_index do |data_item, index|
        if index % columns == 0 && index > 0
          output << "</tr><tr>"
        end
        
        output << "<td>"
        output << @template.check_box_tag("#{@object_name}[#{method}][]", data_item.id, value.include?(id_value))
        output << " " + @template.capture(data_item, &contents)
        output << "</td>"
      end
      
      output << "</tr></table>"
      @template.concat output.join
    end
    
    # Presents an extendable array of fields for a has_many relationship on a model.
    # The model must have accepts_nested_attributes_for defined on the relationship.
    # Use this as you would use #fields_for, but the block within will be rendered many times.
    #
    # For Example:
    # <% form.field_array_for :tasks do |task| %>
    #   Name: <%= task.text_field :name %><br/>
    #   Priority: <%= task.select_field :priority, :from => :priorities %>
    # <% end %>
    def field_array_for(method, options = {}, &standard_field)
      method_id = "#{@object_name}_#{method}"
      template_id = method_id + "_template"
      array_id = method_id + "_array"
      list_id = method_id + "_instance"
      max_size = options.delete(:max_size)
      container_tag = options.delete(:container_tag) || "div"
      row_tag = options.delete(:row_tag) || "div"
      controls_tag = options.delete(:controls_tag) || "span"

      # Build the add and remove buttons.
      adder = lambda do |show| 
        style = { :class => "field-array-add" }
        style[:style] = "display: none" unless show
      
        @template.link_to_function(@template.image_tag("actions/add.png", :class => "icon"), "#{list_id}.add(this)", style)
      end
    
      remover = @template.link_to_function(@template.image_tag("actions/delete.png", :class => "icon remove"), "#{list_id}.remove(this)")
    
      standard_controls = lambda { |show_add| @template.content_tag(controls_tag, remover + adder.call(show_add)) }
    
      # Make a list of all the current values, with their remove link and hidden add link.
      output = []
      
      fields_for(method) do |form|
        contents = template.capture(form, &standard_field)
        contents += form.hidden_field(:_destroy, :class => "deletion_marker") unless form.object.new_record?
        
        if contents.include?("__controls__")
          contents.sub!("__controls__", standard_controls.call(false))
        else
          contents += " " + standard_controls.call(false)
        end
        
        output << @template.content_tag(row_tag, contents, :class => "element")
      end
      
      new_object = object.class.reflect_on_association(method).klass.new
      new_contents = nil
      
      Rails.logger.debug("[DashFormBuilder] Generating fields for blank records...")
      fields_for(method, new_object, :child_index => "NEW_RECORD") do |form|
        new_contents = @template.capture(form, &standard_field)
        
        if new_contents.include?("__controls__")
          new_contents.sub!("__controls__", standard_controls.call(false))
        else
          new_contents += " " + standard_controls.call(false)
        end
        
      end

      template = @template.content_tag(row_tag, new_contents, :class => "element")
      blank_entry = @template.escape_javascript(template)

      0.upto(max_size || 0) do
        output << template.gsub(/NEW_RECORD/, Time.now.to_i.to_s)
      end
      
      Rails.logger.debug("[DashFormBuilder] Rendering output...")
      render_output = @template.javascript_tag("var #{list_id} = null;") + \
        @template.content_tag(container_tag, output.to_s, :id => array_id, :class => "text_field_array") + \
        @template.javascript_tag("#{list_id} = new DashList('#{array_id}', '#{blank_entry}'#{max_size.blank? ? '' : ',' + max_size.to_s});")
      
      @template.concat render_output
    end
    
    # Handy if you want to put the controls for the field array somewhere other than the default.
    #
    # For Example:
    # <% form.field_array_for :tasks do |task| %>
    #   <%= task.field_array_controls %>
    #   <%= task.text_field :name %>
    # <% end %>
    def field_array_controls
      "__controls__"
    end
    
    
    protected
    
    attr_reader :template, :object_name
    
    # Override this if you're going to be using a different class name to Dropdowns.
    def drop_downs_instance
      @_vogue_drop_downs ||= ::Dropdowns.new(template)
    end
    
    # Fetch the drop down data, override this if you want to support a different method of obtaining this data.
    def drop_down(source, options)
      method_info = drop_downs_instance.method(source)
      
      if method_info.arity == 1
        drop_downs_instance.send(source, options)
      else
        drop_downs_instance.send(source)
      end
    end

  end
end