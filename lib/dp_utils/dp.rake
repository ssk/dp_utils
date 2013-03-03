namespace :dp do 

  task :setup => :environment do 
    def get_appname
      line = `heroku apps:info | grep git@heroku.com`
      line.split(":").last.strip.sub(".git", "")
    end
  end

  task :test_get_appname => :setup do 
    puts get_appname
  end

  desc "Backup Postgresql DB."
  task :local_backup => :environment do 
    datestamp = Time.now.strftime("%Y%m%d%H%M%S")    
    backup_file = File.join(Rails.root, "db", "#{Rails.env}_#{datestamp}.dump")    
    db_config = ActiveRecord::Base.configurations[Rails.env]   
    sh "pg_dump -U #{db_config['username'].to_s} -w -h localhost -E UTF8 #{db_config['database']} > #{backup_file}"     
    puts "CREATED: db/#{Rails.env}_#{datestamp}.dump"
  end

  desc "Restore Postgresql DB with DB you provide. It drops and creates DB first."
  task :local_restore => ["db:drop", "db:create"] do 
    if ENV["path"].blank?
      puts "Provide path= option"
      exit
    end
    db_config = ActiveRecord::Base.configurations[Rails.env]   
    sh "psql --set ON_ERROR_STOP=on --single-transaction -U #{db_config['username'].to_s} -w -h localhost #{db_config['database']} < #{File.join(Rails.root, ENV["path"])}"
  end


  desc "Backup Heroku DB and download. heroku addons:add pgbackups first."
  task :download_backup => :setup do 
    puts "Capturing..."
    `heroku pgbackups:capture --expire`
    url = `heroku pgbackups:url`
    puts "URL: #{url}"
    datestamp = Time.now.strftime("%Y%m%d%H%M%S")    
    $backup_file = File.join(Rails.root, "db", "production_#{datestamp}.dump")   
    puts "Downloading into db/#{File.basename($backup_file)}"
    `curl -o #{$backup_file} "#{url}"`
  end

  desc "Backup remote and download the file and restore."
  task :remote_restore => :download_backup do 
    db_config = ActiveRecord::Base.configurations['development']   

    puts "Restoring..."
    `pg_restore --verbose --clean --no-acl --no-owner -U #{db_config['username'].to_s} -w -h localhost -d #{db_config['database']} < #{$backup_file}`
    puts "Done!"

  end

  task :uncompress_backup do 
    if ENV["path"].blank?
      puts "Provide path= option"
      exit
    end
    `pg_restore -f #{ENV["path"].strip}.sql #{ENV["path"]}`
    puts "Created #{ENV["path"].strip}.sql"
  end

end