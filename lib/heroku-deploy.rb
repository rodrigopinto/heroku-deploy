require "heroku-deploy/version"

module Heroku
  module Deploy
  end
end

def gem_path
  Gem::Specification.find_by_name('heroku-deploy').full_gem_path
end

Dir["#{gem_path}/lib/tasks/*.rake"].each { |ext| load ext } if defined?(Rake)