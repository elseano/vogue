# Vogue

Vogue makes it easier for your to reduce your view code through template inheritance.

## Template Inheritance

Vogue extends how Rails handles template searching, catching a ActionView::MissingTemplate error and attempting to find the view at a designated location. Locations can be designated per controller, and can be inherited so all your admin controllers can use different default templates.

Long story short, you only need to define a form partial for each controller in your administration views. Any time you want to override the default template file, just create the file in your controller's directory.

Your controllers can provide variables to modify the behaviour of your default views. These variables are accessed through a vogue helper.

    class Admin::UserController < Admin::BaseController
      resource_controller
      vogue :name => "User Account", :root => "layouts/admin"
    end

/app/views/layouts/admin/edit.html.erb

    <h1><%= vogue :name %></h1>

    <% form_for :object, object_url do |form| %>
      <%= render "form", :form => form %>

      <%= form.submit "Update" %>
    <% end %>

/app/views/admin/users/_form.html.erb

    <%= form.label :name %>
    <%= form.text_field :name %>

With the extensions installed, a GET to /posts/1/edit would cause Rails to attempt to render /app/views/posts/edit.html.erb. If that cannot be found, resource_controller_views will make Rails attempt to render /app/views/common/edit.html.erb. The common edit helper will then attempt to render the "form" partial, which again uses the same mechanism as for standard views. In the second case however it finds the _form.html.erb partial in the controllers own directory, and so renders that.


## Action Standardisation

We're not talking about using REST in your application. That was _sooo_ Rails 2.0 - so we assume you're already using that. We're talking about defining standard ways in which your application responds to XML, JSON, JS, or whatever requests. 

XML/JSON POSTs should ALWAYS return either 201 or 422 errors, and should always return the object with its location, or the list of errors. Vogue was initially a fork of `resource_controller`, and so this action standardisation can work with resource_controller, or with normal rails.

Vogue provides a few extensions to resource_controller:

* Searchlogic integration
* Standard Action Sets
* Will Paginate integration

### Standard Action Sets

Action Sets provide a standard way for you to define how your application responds to various mime-types. For example, many applications now want to provide an XML API, and having to continually provide this in each controller can be a pain.


Action Sets are defined in lib/action_sets/, and would appear like this for `resource_controller`:

    class Admin::UsersController < Admin::BaseController
      vogue :action_sets => [:js, :json, :xml, :rss]
    end

    module ActionSets::JsActionSet
      def self.included(base)
        base.class_eval do

          index.wants.js
          edit.wants.js
          show.wants.js
          update.wants.js
          create.wants.js
          destroy.wants.js
          new_action.wants.js

          create.failure.wants.js
          update.failure.wants.js
        end
      end
    end
    
For standard Rails, we're still working this out.

Simply put, they're just modules which get included in your controller, but having this as an explicit feature will make your think about using it. When this is combined with the Template Inheritance, you've suddenly got a very powerful framework that works with whatever you've designed.

### Searchlogic Integration

    @search = SomeBody.search(params[:search])
    @somebodies = @search.find(:all)

Superfluous! Include resource_controller, and use the searchlogic gem in your config, and this will happen automatically for all indexes.

### Will Paginate Integration

    @somebodies = @search.paginate(:per_page => 20, :page => params[:page])

More superfluousness! Use the will_paginate gem in your config, and this will also happen automatically.

You can customise this by passing options into the resource_controller statement.

    class SomeController < ApplicationController
      vogue :per_page => 20
    end

    class SomeController < ApplicationController
      vogue :pagination => false
    end

Or in your config:

    Vogue.pagination = false


## Summary

Vogue is about setting your own style, keeping to that style, but letting you break out when required. All the tools are there for you to standardise and DRY some of the more repetitive code points.


