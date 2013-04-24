require 'rails'
module DpUtils
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path('../dp_db.rake', __FILE__)
      load File.expand_path('../dp.rake', __FILE__)
      load File.expand_path('../dp_generate.rake', __FILE__)
      load File.expand_path('../dp_encoding.rake', __FILE__)
    end
  end
end
