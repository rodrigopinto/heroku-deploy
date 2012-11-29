# -*- encoding : utf-8 -*-
namespace :heroku do
  def run(*cmd)
    system(*cmd)
    raise "Command #{cmd.inspect} failed!" unless $?.success?
  end

  def confirm(message)
    print "\n#{message}\nAre you sure? [Yn] ".red
    raise 'Aborted' unless STDIN.gets.chomp.downcase == 'y'
  end

  namespace :deploy do
    desc "Deploy application to staging"
    task :staging do
      APP = ENV["STAGING_APP"]

      puts "-----> Backing up database via Heroku...".yellow
      run "heroku pgbackups:capture --expire --app #{APP}"

      puts "-----> Pushing application to heroku...".yellow
      run "git push git@heroku.com:#{APP}.git HEAD:master -f"

      puts "-----> Excuting migraitons...".yellow
      run "heroku run rake db:migrate --app #{APP}"

      puts "-----> Restarting...".yellow
      run "heroku restart --app #{APP}"

      puts "-----> Done! :)...".green
    end

    desc "Deploy application to production"
    task :production do
      APP = ENV["PRODUCTION_APP"]

      current_branch = Git.open(File.expand_path(Rails.root)).current_branch
      if current_branch != "production"
        puts "-----> You can't do a deploy from '#{current_branch}'. Please use 'production' branch.".red
        exit
      end

      if ENV['SKIP_TESTS'] != "true"
        puts "-----> Running all specs...".yellow
        Rake::Task['spec'].invoke
      end

      print "\nPut in maintenance mode? [Yn] ".red
      maintenance = (ENV['MAINTENANCE'] == "true" or (STDIN.gets.chomp.downcase == 'y'))

      if maintenance
        puts "-----> Setting Maintenance on...".yellow
        run "heroku maintenance:on --app #{APP}"

        puts "-----> Restarting...".yellow
        run "heroku restart --app #{APP}"

        puts "-----> Waiting 20 seconds to app come back (in maintenance mode)...".yellow
        sleep(20)
      end

      puts "-----> Backing up database via Heroku...".yellow
      run "heroku pgbackups:capture --expire --app #{APP}"

      iso_date = Time.now.strftime('%Y-%m-%dT%H%M%S')
      tag_name = "production-#{iso_date}"
      puts "-----> Tagging as #{tag_name}...".yellow
      run "git tag #{tag_name} production"

      puts "-----> Pushing...".yellow
      run "git push origin #{tag_name}"
      run "git push git@heroku.com:#{APP}.git #{tag_name}:master"

      puts "-----> Migrating...".yellow
      run "heroku run rake db:migrate --app #{APP}"

      if maintenance
        puts "Setting Maintenance off..."yellow
        run "heroku maintenance:off --app #{APP}"
      end

      puts "-----> Restarting...".yellow
      run "heroku restart --app #{APP}"

      puts "-----> Done! :)...".green
    end

    namespace :integration do
      APP = ENV["STAGING_APP"]

      task :add_remote do
        remote = `git remote |grep heroku`
        sh "git remote add heroku git@heroku.com:#{APP}.git" if remote.strip.blank?
      end

      task :check do
        var = `heroku config -s --app #{APP}|grep INTEGRATING_BY`
        integrating_by = var.split('=')[1]
        user = `whoami`

        if !integrating_by.blank? and integrating_by != user
          puts "Project is already being integrated by #{integrating_by}".red
          exit
        end
      end

      task :lock do
        user = `whoami`
        sh "heroku config:add INTEGRATING_BY=#{user}"
      end

      task :unlock do
        `heroku config:remove INTEGRATING_BY`
      end
    end
  end
end