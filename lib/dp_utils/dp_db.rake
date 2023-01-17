namespace :dp do
  task :setup => :environment do
    @db_config = YAML.load(File.read("config/database.yml")).with_indifferent_access[Rails.env]

    def backup_path
      if ENV['tables'].present?
        Rails.root.join("backup/#{Rails.env}_tables_#{Time.current.strftime("%Y%m%d%H%M%S")}.sql.gz")
      else
        Rails.root.join("backup/#{Rails.env}_#{Time.current.strftime("%Y%m%d%H%M%S")}.sql.gz")
      end
    end

    def backup_script
      <<-TXT.lines.map(&:strip).reject(&:blank?).join(" ")
        mysqldump -u #{@db_config[:username]}
        #{@db_config[:password].present? ? "-p#{@db_config[:password]}" : "-p" }
        #{"-h #{@db_config[:host]}" if @db_config[:host]}
        --single-transaction
        #{@db_config[:tables_to_skip_backup].map { |t| "--ignore-table=#{@db_config[:database]}.#{t}" }.join(" ")}
        --ignore-table=#{@db_config[:database]}.sessions
        #{@db_config[:database]}
        #{ENV['tables'].to_s.split(",").join(" ")}
        | gzip -c > #{backup_path}
      TXT
    end

    def restore_script
      if ENV["path"].blank?
        puts "Provide path= option"
        exit
      end
      script = <<-TXT.lines.map(&:strip).reject(&:blank?).join(" ")
        mysql -u #{@db_config[:username]}
        #{@db_config[:password].present? ? "-p#{@db_config[:password]}" : "-p" }
        #{"-h #{@db_config[:host]}" if @db_config[:host]}
        --default-character-set=utf8
        #{@db_config[:database]}
      TXT
      if ENV['path'] =~ /sql.gz/
        script = "gunzip < #{ENV['path']} | " + script
      else
        script = script + " < #{ENV["path"]}"
      end
    end
  end

  desc "Backup DB. Provide tables"
  task :backup => :setup do
    `#{backup_script}`
  end

  desc "Displays Backup Script"
  task :backup_script => :setup do
    puts "-" * 80
    puts backup_script
    puts "-" * 80
  end

  task :restore => :setup do
    `#{restore_script}`
  end

  task :restore_script => :setup do
    puts "-" * 80
    puts restore_script
    puts "-" * 80
  end
end

# Aliases
task 'sa:backup'         => 'dp:backup'
task 'sa:backup_script'  => 'dp:backup_script'
task 'sa:restore'        => 'dp:restore'
task 'sa:restore_script' => 'dp:restore_script'

