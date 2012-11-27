namespace :dp do
  
  namespace :generate do 

    task :setup => :environment do
      def object_name
        ENV["object"]
      end

      def class_name
        if ENV["class"].blank?
          object_name.camelize
        else
          ENV["class"].camelize
        end
      end

      def get_class
        eval("#{class_name}")
      end

      def columns
        columns_to_exclude = %w(id created_at updated_at position crypted_password salt remember_token remember_token_expires_at)
        if ENV["columns"].blank?
          get_class.column_names.select { |i| not columns_to_exclude.include? i }
        else
          ENV["columns"].split(/\W/)
        end
      end
    end

    task :controller => :setup do 
      puts <<END

  def index
    @#{object_name.pluralize} = #{class_name}.paginate :page => params[:page], :per_page => 25 
  end

  def new
    @#{object_name} = #{class_name}.new
  end

  def create
    @#{object_name} = #{class_name}.new params[:#{object_name}]
    if @#{object_name}.save
      redirect_to index_with_params, :notice => "#{class_name} was created."
    else
      render :action => :new
    end
  end

  def show
    @#{object_name} = #{class_name}.find params[:id]
  end

  def edit
    @#{object_name} = #{class_name}.find params[:id]
  end 
          
  def update
    @#{object_name} = #{class_name}.find params[:id]
    if @#{object_name}.update_attributes params[:#{object_name}]
      redirect_to index_with_params, :notice => "#{class_name} was updated."
    else
      render :action => :edit
    end
  end
    
  def destroy 
    @#{object_name} = #{class_name}.find params[:id]
    @#{object_name}.destroy
    redirect_to index_with_params, :notice => "#{class_name} was deleted."
  end
END
    end

    desc "Generate bootstrap view files in erb format."
    task :bootstrap_haml => :setup do 
      def table_name
        get_class.table_name
      end

      def filename(name)
        path = ENV["path"].blank? ? object_name.pluralize : ENV["path"]
        File.join(RAILS_ROOT, "app", "views", path, name + ".html.haml")
      end

      def template_for fn
        arr = []
        case fn
        when "index"
          arr << <<END
.page-header          
  %h1 #{class_name.pluralize}

= link_to "New", {:action => :new}, :class => "btn btn-primary"

%table.table.table-striped
  %thead
    %tr
END
          columns.each do |col|
            arr << "      %th #{col.titleize}"
          end
          arr << "      %th "
          arr << <<END
  %tbody
    - @#{object_name.pluralize}.each do |#{object_name}|
      %tr
END
        columns.each do |col|
          arr << "      %td= #{object_name}.#{col}"
        end
        arr << <<END
      %td
        = link_to "Edit", {:action => :edit, :id => #{object_name}}, :class => "btn btn-mini"
        = link_to icon_for(:delete), {:action => :destroy, :id => #{object_name}}, :method => :delete, :confirm => "Are you sure?", :class => "btn btn-mini btn-danger"

END
arr << "= will_paginate @#{object_name.pluralize}"
        when "new"
          arr << <<END
.page-header
  %h1 New #{class_name}

= render "form"
END
        when "_form"
          arr << <<END
= form_for @#{object_name}, :html => {:class => 'form-horizontal'} do |f|
  = render "shared/error_messages", :object => f.object
END
          columns.each do |col|
            arr << <<END 
  .control-group
    = f.label "#{col.titleize}", :class => 'control-label'
    .controls
      = f.text_field :#{col}, :class => 'text_field'
END
          end
          arr << <<END 
  .form-actions
    = f.submit nil, :class => 'btn btn-primary'
END
        when "edit"
          arr << <<END
.page-header
  %h1 Edit #{class_name}

= render "form"
END
        when "show"
          arr << <<END
.page-header
  %h1= #{class_name}

%table
END
          columns.each do |col|
            arr << <<END
  %tr
    %th #{col.titleize}:
    %td= @#{object_name}.#{col}
END
          end
          arr << <<END
.form-actions
  = link_to "Back", index_with_params, :class => "btn"
  = link_to "Edit", {:action => :edit, :id => @#{object_name}}, :class => "btn"
  = link_to "Delete", {:action => :destroy, :id => @#{object_name}}, :method => :delete, :confirm => 'Are you sure?', :class => "btn btn-danger"
END
        end
        arr.join("\n")
      end
      ["index", "new", "_form", "edit", "show"].each do |fn|
        path = filename(fn)
        unless ENV.keys.include? "force"
          if File.exist?(path)
            puts "ERROR: #{path} already exists."
            exit
          end
        end
        File.open(path, "w") do |f|
          # f << comment
          f << template_for(fn)
          puts "created #{path}"
        end
      end

    end
  end

end