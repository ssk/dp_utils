require 'rails'
module TestHello
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path('../dp_db.rake', __FILE__)
    end
  end
end
