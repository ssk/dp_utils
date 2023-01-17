namespace :dp do

  namespace :db do

    desc "Back up DB at db directory"
    task :backup => [:environment] do
      datestamp = Time.now.strftime("%Y%m%d%H%M%S")
      backup_file = File.join(Rails.root, "backup", "#{Rails.env}_#{datestamp}.sql.gz")
      db_config = ActiveRecord::Base.configurations[Rails.env].with_indifferent_access rescue ActiveRecord::Base.connection_db_config.configuration_hash.with_indifferent_access
      sh "mysqldump -u #{db_config['username'].to_s} #{'-p' if db_config['password']}#{db_config['password'].to_s} -h #{db_config['host']} --single-transaction --ignore-table=#{db_config['database']}.sessions #{db_config['database']} | gzip -c > #{backup_file}"
      puts "#{Rails.env}_#{datestamp}.sql.gz was created."
    end

    task :backup_script do
      require 'yaml'
      env = ENV['Rails.env'].blank? ? 'development' : ENV['Rails.env']
      datestamp = Time.now.strftime("%Y%m%d%H%M%S")
      backup_file = File.join(Rails.root, "backup", "#{env}_#{datestamp}.sql.gz")
      db_config = YAML.load(File.read("config/database.yml"))[env].with_indifferent_access
      puts "-" * 80
      puts ""
      puts "mysqldump -u #{db_config['username'].to_s} #{'-p' if db_config['password']}#{db_config['password'].to_s} -h #{db_config['host']} --single-transaction --ignore-table=#{db_config['database']}.sessions #{db_config['database']} | gzip -c > #{backup_file}"
      puts ""
      puts "-" * 80
    end

    desc "Restore DB from the path given"
    task :restore => [:environment] do
      if ENV["path"].blank?
        puts "Provide path= option"
        exit
      end
      db_config = ActiveRecord::Base.configurations[Rails.env].with_indifferent_access rescue ActiveRecord::Base.connection_db_config.configuration_hash.with_indifferent_access
      if ENV["path"] =~ /sql.gz/
        sh "gunzip < #{File.join(Rails.root, ENV["path"])} | mysql -u #{db_config['username'].to_s} #{'-p' if db_config['password']}#{db_config['password'].to_s} -h #{db_config['host']} #{db_config['database']} --default-character-set=utf8"
      else
        sh "mysql -u #{db_config['username'].to_s} #{'-p' if db_config['password']}#{db_config['password'].to_s} -h #{db_config['host']} #{db_config['database']} --default-character-set=utf8 < #{File.join(Rails.root, ENV["path"])}"
      end
    end

    task :restore_script do
      if ENV["path"].blank?
        puts "Provide path= option"
        exit
      end
      require 'yaml'
      env = ENV['Rails.env'].blank? ? 'development' : ENV['Rails.env']
      db_config = YAML.load(File.read("config/database.yml"))[env].with_indifferent_access
      puts "-" * 80
      puts ""
      if ENV["path"] =~ /sql.gz/
        puts "gunzip < #{File.join(Rails.root, ENV["path"])} | mysql -u #{db_config['username'].to_s} #{'-p' if db_config['password']}#{db_config['password'].to_s} -h #{db_config['host']} #{db_config['database']} --default-character-set=utf8"
      else
        puts "mysql -u #{db_config['username'].to_s} #{'-p' if db_config['password']}#{db_config['password'].to_s} -h #{db_config['host']} #{db_config['database']} --default-character-set=utf8 < #{File.join(Rails.root, ENV["path"])}"
      end
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

task 'sa:backup' => 'dp:db:backup'
task 'sa:backup_script' => 'dp:db:backup_script'
task 'sa:restore' => 'dp:db:restore'
task 'sa:restore_script' => 'dp:db:restore_script'

