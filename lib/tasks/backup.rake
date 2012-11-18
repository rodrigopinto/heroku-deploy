namespace :heroku do
  def run(*cmd)
    system(*cmd)
    raise "Command #{cmd.inspect} failed!" unless $?.success?
  end

  namespace :backup do
    def backup(app)
      puts "-----> Backing-up #{app}..."
      run("heroku pgbackups:capture --app #{app} --expire")

      puts "-----> Downloading backup..."
      run("curl -o #{app}_db_bkup `heroku pgbackups:url --app #{app}`")
    end

    desc "Copy database from production"
    task :production => :environment do
      backup(ENV["PRODUCTION_APP"])
    end

    desc "Copy database from staging"
    task :staging => :environment do
      backup(ENV["STAGING_APP"])
    end
  end

  namespace :db do
    namespace :restore do
      def restore(app)
        puts "-----> Backup restoring..."
        run("pg_restore --verbose --clean --no-acl --no-owner -h localhost -U postgres -d #{dbname} #{app}_db_bkup")
      end

      desc "Restore heroku production database locally"
      task :production => 'backup:production' do
        restore(ENV["PRODUCTION_APP"])
      end

      desc "Restore heroku staging database locally"
      task :staging => 'backup:staging' do
        restore(ENV["STAGING_APP"])
      end
    end
  end
end