# -*- encoding : utf-8 -*-
namespace :heroku do
  def run(*cmd)
    system(*cmd)
    raise "Command #{cmd.inspect} failed!" unless $?.success?
  end

  def confirm(message)
    print "\n#{message}\nAre you sure? [Yn] "
    raise 'Aborted' unless STDIN.gets.chomp.downcase == 'y'
  end

  namespace :deploy do
    desc "Deploy application to staging"
    task :staging do
      APP = ENV["STAGING_APP"]

      puts "-----> Backing up database via Heroku..."
      run "heroku pgbackups:capture --expire --app #{APP}"

      puts "-----> Pushing..."
      run "git push git@heroku.com:#{APP}.git HEAD:master -f"

      puts "-----> Migrating..."
      run "heroku run rake db:migrate --app #{APP}"

      puts "-----> Restarting..."
      run "heroku restart --app #{APP}"
    end

    desc "Deploy application to production"
    task :production do
      APP = ENV["PRODUCTION_APP"]

      current_branch = Git.open(File.expand_path(Rails.root)).current_branch
      if current_branch != "production"
        puts "-----> You can't do a deploy from '#{current_branch}'. Please use 'production' branch."
        exit
      end

      if ENV['SKIP_TESTS'] != "true"
        puts "-----> Running all specs..."
        Rake::Task['spec'].invoke
      end

      print "\nPut in maintenance mode? [Yn] "
      maintenance = (ENV['MAINTENANCE'] == "true" or (STDIN.gets.chomp.downcase == 'y'))

      if maintenance
        puts "-----> Setting Maintenance on..."
        run "heroku maintenance:on --app #{APP}"

        puts "-----> Restarting..."
        run "heroku restart --app #{APP}"

        puts "-----> Waiting 20 seconds to app come back (in maintenance mode)..."
        sleep(20)
      end

      puts "-----> Backing up database via Heroku..."
      run "heroku pgbackups:capture --expire --app #{APP}"

      iso_date = Time.now.strftime('%Y-%m-%dT%H%M%S')
      tag_name = "production-#{iso_date}"
      puts "-----> Tagging as #{tag_name}..."
      run "git tag #{tag_name} production"

      puts "-----> Pushing..."
      run "git push origin #{tag_name}"
      run "git push git@heroku.com:#{APP}.git #{tag_name}:master"

      puts "-----> Migrating..."
      run "heroku run rake db:migrate --app #{APP}"

      if maintenance
        puts "Setting Maintenance off..."
        run "heroku maintenance:off --app #{APP}"
      end

      puts "-----> Restarting..."
      run "heroku restart --app #{APP}"
    end
  end
end