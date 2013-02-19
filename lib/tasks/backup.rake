namespace :heroku do
  def run(*cmd)
    system(*cmd)
    raise "Command #{cmd.inspect} failed!" unless $?.success?
  end

  namespace :db do
    namespace :backup do
      def backup(app)
        puts "-----> Backing-up #{app}...".yellow
        run("heroku pgbackups:capture --app #{app} --expire")

        puts "-----> Downloading backup...".yellow
        run("curl -o #{app}-db-bkup `heroku pgbackups:url --app #{app}`")
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

    namespace :restore do
      def dbname
        config   = Rails.configuration.database_configuration
        config[Rails.env]["database"]
      end

      def restore(app)
        puts "-----> Backup restoring...".yellow

        run("pg_restore --verbose --clean --no-acl --no-owner -h localhost -U postgres -d #{dbname} #{app}-db-bkup")

        puts "-----> Backup restored...".green
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