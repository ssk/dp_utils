namespace :dp do 

  task :add_encoding do 
    def replace(f)
      text = File.read(f)
      unless text =~ /^#\s*encoding: utf-8/
        File.open(f, 'w') do |fout|
          fout << "# encoding: utf-8" << "\n\n" << text
        end
      end
    end
    Dir[File.join(Rails.root, "app/**/*.rb")].each { |f| replace(f) }
    Dir[File.join(Rails.root, "lib/tasks/*.rake")].each { |f| replace(f) }
  end

end