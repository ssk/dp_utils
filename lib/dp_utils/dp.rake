namespace :dp do 

  task :help do 
    puts "dp:local_backup"
    puts "dp:local_restore path="
    puts "dp:download_backup"
    puts "dp:download_and_restore"
    puts "dp:uncompress_backup path="
    puts "dp:upload_backup path="
    puts "dp:delete_backup path="
  end

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
    if ENV["path"] =~ /production/
      #sh "psql --set ON_ERROR_STOP=on --no-owner --single-transaction -U #{db_config['username'].to_s} -w -h localhost #{db_config['database']} < #{File.join(Rails.root, ENV["path"])}"
      `pg_restore --verbose --clean --no-acl --no-owner -U #{db_config['username'].to_s} -w -h localhost -d #{db_config['database']} < #{File.join(Rails.root, ENV["path"])}`
    else
      sh "psql --set ON_ERROR_STOP=on --single-transaction -U #{db_config['username'].to_s} -w -h localhost #{db_config['database']} < #{File.join(Rails.root, ENV["path"])}"
    end
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
  task :download_and_restore => :download_backup do 
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

  task :upload_backup do
    if ENV["path"].blank?
      puts "Provide path= option"
      exit
    end

    puts "Uploading file..."
    puts "Password: share1111"
    `scp "#{ENV["path"]}" share33@share.samanne.com:files/pg/`

    puts "Make sure you did 'heroku addons:add pgbackups'"
    puts "Run the command and delete it after that (rake dp:delete_backup path=#{ENV["path"]}"
    puts "heroku pgbackups:restore DATABASE \"http://share.samanne.com/pg/#{File.basename(ENV["path"])}\""

  end

  task :delete_backup do 
    if ENV["path"].blank?
      puts "Provide path= option"
      exit
    end
    puts "Deleting file..."
    `ssh share33@share.samanne.com "rm -f files/pg/#{File.basename(ENV["path"])}"`
  end


end