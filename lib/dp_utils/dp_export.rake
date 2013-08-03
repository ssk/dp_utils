namespace :dp do 

  task :export_all => :environment do 
    require 'csv'
    models = []
    ActiveRecord::Base.connection.tables.select { |i| not %w(schema_migrations session).include?(i) }.map do |model|
      models << eval(model.capitalize.singularize.camelize)
    end
    `mkdir -p tmp/export`
    models.each do |klass| 
      cols = klass.column_names
      CSV.open("tmp/export/#{klass.name}.csv", "w") do |csv|
        csv << cols
        klass.all.each do |object|
          csv << cols.map { |col| object.send(col.to_sym) }
        end
      end      
    end
  end

end