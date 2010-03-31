# Vogue

Vogue is both a extremely handy plugin, and a development style - with the end result of trying to reduce your view and controller code as much as possible - ironically we think your models should be as fat as possible (but, of course, no fatter).

There are three main ideas behind Vogue:

* Template Inheritance
* View Simplification
* Action standardisation.

## Template Inheritance

Vogue extends how Rails handles template searching, catching a ActionView::MissingTemplate error and attempting to find the view at a designated location. Locations can be designated per controller, and can be inherited so all your admin controllers can use different default templates.

Long story short, you only need to define a form partial for each controller in your administration views. Any time you want to override the default template file, just create the file in your controller's directory.

Your controllers can provide variables to modify the behaviour of your default views. These variables are accessed through a vogue helper.

    class Admin::UserController < Admin::BaseController
      resource_controller
      vogue :name => "User Account", :scaffold => "layouts/admin"
    end

/app/views/layout/vogue/edit.html.erb

    <h1><%= vogue :name %></h1>

    <% form_for :object, object_url do |form| %>
      <%= render "form", :form => form %>

      <%= form.submit "Update" %>
    <% end %>

/app/views/admin/users/_form.html.erb

    <%= form.label :name %>
    <%= form.text_field :name %>

With the extensions installed, a GET to /posts/1/edit would cause Rails to attempt to render /app/views/posts/edit.html.erb. If that cannot be found, resource_controller_views will make Rails attempt to render /app/views/common/edit.html.erb. The common edit helper will then attempt to render the "form" partial, which again uses the same mechanism as for standard views. In the second case however it finds the _form.html.erb partial in the controllers own directory, and so renders that.

## View Simplification

Naturally, you have a number of friends with Vogue in this department. One of the key points is to love the FormBuilder. We do, and most of our work has gone there.

### Cleaner selections

Ugly, out of fashion, and unhip:

    <%= form.select :country, [Country.new(:name => "Outer Space")] + Country.find(:all) %>
    <%= form.select :plan, Plan.order(:name).free.all %>
    <%= form.select :priority, controller.current_user.account.priorities.all %>

New, stylish, and clean:

    <%= form.select_field :country, :from => :eu_countries, :include_blank => "Outer Space" %>
    <%= form.select_field :plan, :type => :free %>
    <%= form.select_field :priority %>

The :from attribute defines a method name which returns the array selections to use. These can be name/value pairs as a Hash, as a nested Array, or as any object which responds to #name and #id. The :from attribute defaults to the underscored version of the class name of the relationship, if there is one.

Dropdowns are defined in the file lib/dropdowns.rb. Any options passed to select_field are also passed to the corresponding method in this class.

    class Dropdowns < Vogue::Dropdowns

      def eu_countries(options = {})
        Rails.cache("eu_countries_by_name") { Country.order(:name).eu.all }
      end

      def plans(options = {})
        if options.delete(:type) == :free
          Plan.order(:name).free.all
        else
          Plan.order(:name).all
        end
      end

      def priorities
        controller.current_user.account.priorities.all
      end
  
    end

Why? Its damn easy to test, great for re-use, easily cacheable, and your views won't be littered with as much confusing ERB code.

### Easy Arrays

Almost every application we make has some kind of expandable list. "Add Another", "Remove This", its all very repetitive.

    <% form.field_array_for :tasks, :blank => 1 do |task| %>
      <%= task.text_field :name %>
      <%= task.select_field :priority %>
      <%= task.delete_link "Remove This" %>
    <% end %>

This helper renders all existing tasks, and provides the ability to add another one, and even gives you a blank one for free.

Whats even better, you can customise the code it uses in the same way you can customise your own view code. All the views for this are rendered from the gem's resources, but can be overridden file-by-file by adding a view path to your controller.

    config.view_paths << "layouts/vogue/ui"   # Todo, is this really how its going to work?

## Action Standardisation

We're not talking about using REST in your application. That was _sooo_ Rails 2.0 - so we assume you're already using that. We're talking about defining standard ways in which your application responds to XML, JSON, JS, or whatever requests. 

XML/JSON POSTs should ALWAYS return either 201 or 422 errors, and should always return the object with its location, or the list of errors.

Vogue was initially a fork of `resource_controller`, but has grown a bit since then. It now can work with `resource_controller`, however it's not required to use Vogue.

Vogue provides a few extensions to resource_controller:

* Searchlogic integration
* Standard Action Sets
* Will Paginate integration

### Standard Action Sets

Action Sets provide a standard way for you to define how your application responds to various mime-types. For example, many applications now want to provide an XML API, and having to continually provide this in each controller can be a pain.

    class Admin::UsersController < Admin::BaseController
      vogue :action_sets => [:js, :json, :xml, :rss]
    end

Action Sets are defined in lib/action_sets/, and would appear like this:

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

Vogue is really an extraction of all the handy things we use at iProperty for our products, so it's quite battle hardened.

