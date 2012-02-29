module Fancygrid
  module Generators#:nodoc:
    
    class InstallGenerator < Rails::Generators::Base#:nodoc:
      source_root File.expand_path('../../..', __FILE__)
      def copy_initializer
        plugin_path = "config/initializers/fancygrid.rb"
        rails_path = Rails.root.join("config/initializers/fancygrid.rb")
        copy_file(plugin_path, rails_path)
      end
    
      def copy_default_cells_view
        plugin_path = "app/views/fancygrid/_cells.html.haml"
        rails_path = Rails.root.join("app/views/fancygrid/_cells.html.haml")
        copy_file(plugin_path, rails_path)
      end
      
      def copy_locale
        %w(de en).each do |locale|
          plugin_path = "config/locales/fancygrid.#{locale}.yml"
          rails_path = Rails.root.join("config/locales/fancygrid.#{locale}.yml")
          copy_file(plugin_path, rails_path)
        end
      end

      def print_info
        puts "====================================================================="
        puts ""
        puts "  Almost done. Next steps you have to do yourself"
        puts "  -----------------------------------------------"
        puts "  1 include the javascript file in your layout : \"= javascript_include_tag 'fancygrid'\""
        puts "  2 include the stylesheet file in your layout : \"= stylesheet_link_tag 'fancygrid'\""
        puts ""
        puts "====================================================================="
      end
    end
  end
  
end