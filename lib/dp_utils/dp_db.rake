namespace :dp do 

  namespace :db do 

    desc "Back up DB at db directory"
    task :backup => [:environment] do
      datestamp = Time.now.strftime("%Y%m%d%H%M%S")    
      backup_file = File.join(Rails.root, "db", "#{Rails.env}_#{datestamp}.sql")    
      db_config = ActiveRecord::Base.configurations[Rails.env]   
      sh "mysqldump -u #{db_config['username'].to_s} #{'-p' if db_config[
  'password']}#{db_config['password'].to_s} -h #{db_config['host']} --ignore-table=#{db_config['database']}.sessions #{db_config['database']} > #{backup_file}"     
      puts "#{Rails.env}_#{datestamp}.sql was created."
    end
    
    task :backup_script do
      require 'yaml'
      env = ENV['Rails.env'].blank? ? 'development' : ENV['Rails.env']
      datestamp = Time.now.strftime("%Y%m%d%H%M%S")    
      backup_file = File.join(Rails.root, "db", "#{env}_#{datestamp}.sql")    
      db_config = YAML.load(File.read("config/database.yml"))[env]
      puts "-" * 80
      puts ""
      puts "mysqldump -u #{db_config['username'].to_s} #{'-p' if db_config[
  'password']}#{db_config['password'].to_s} -h #{db_config['host']} --ignore-table=#{db_config['database']}.sessions #{db_config['database']} > #{backup_file}"     
      puts ""
      puts "-" * 80
    end

    desc "Restore DB from the path given"
    task :restore => [:environment] do
      if ENV["path"].blank?
        puts "Provide path= option"
        exit
      end
      db_config = ActiveRecord::Base.configurations[Rails.env]   
      sh "mysql -u #{db_config['username'].to_s} #{'-p' if db_config[
  'password']}#{db_config['password'].to_s} -h #{db_config['host']} #{db_config['database']} --default-character-set=utf8 < #{File.join(Rails.root, ENV["path"])}"
    end
    
    task :restore_script do
      if ENV["path"].blank?
        puts "Provide path= option"
        exit
      end
      require 'yaml'
      env = ENV['Rails.env'].blank? ? 'development' : ENV['Rails.env']
      db_config = YAML.load(File.read("config/database.yml"))[env]
      puts "-" * 80
      puts ""
      puts "mysql -u #{db_config['username'].to_s} #{'-p' if db_config[
  'password']}#{db_config['password'].to_s} -h #{db_config['host']} #{db_config['database']} --default-character-set=utf8 < #{File.join(Rails.root, ENV["path"])}"
      puts ""
      puts "-" * 80
    end

    namespace :sessions do 
      desc "Clear sessions table fast"
      task :clear => :environment do 
        sqls = <<-END 
          create table sessions_temp like sessions 
          drop table sessions 
          rename table sessions_temp to sessions 
        END
        sqls.each_line do |line|
          puts line.strip
          ActiveRecord::Base.connection.execute(line.strip)
        end
      end
    end

  end

end