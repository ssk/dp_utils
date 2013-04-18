namespace :dp do 

  task :help do 
    puts "dp:local_backup"
    puts "dp:local_restore path="
    puts "dp:download_backup"
    puts "dp:download_and_restore"
    puts "dp:uncompress_backup path="
    puts "dp:upload_backup path="
    puts "dp:delete_backup path="
    puts "dp:pg_dump_data_only"
    puts "dp:convert_for_sqlite3 path="
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

  task :pg_dump_data_only => :environment do 
    datestamp = Time.now.strftime("%Y%m%d%H%M%S")    
    backup_file = File.join(Rails.root, "db", "#{Rails.env}_#{datestamp}_data_only.sql")    
    db_config = ActiveRecord::Base.configurations[Rails.env]   
    sh "pg_dump --data-only --inserts -U #{db_config['username'].to_s} -w -h localhost -E UTF8 #{db_config['database']} > #{backup_file}"     
    puts "CREATED: db/#{Rails.env}_#{datestamp}_data_only.sql"
  end

  task :convert_for_sqlite3 do 
    if ENV["path"].blank?
      puts "Provide path= option"
      exit
    end
    datestamp = Time.now.strftime("%Y%m%d%H%M%S")    
    File.open("db/sqlite_#{datestamp}.sql", "w") do |f|
      f << "BEGIN;" << "\n"
      File.readlines(ENV['path']).each do |line|
        f << line.gsub("'t'", "true").gsub("'f'", "false") unless line =~ /SET/ or line =~ /SELECT pg_catalog.setval/
      end    
      f << "END;"
    end
    puts "CREATED: db/sqlite_#{datestamp}.sql"
    puts "Now import data into sqlite3."
    puts "rake db:migrate"
    puts "sqlite3 db/development.sqlite3"
    puts "sqlite> delete from schema_migrations;"
    puts "sqlite> .read db/sqlite_#{datestamp}.sql"
    puts "sqlite> .quit"
  end

end