# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'heroku-deploy/version'

Gem::Specification.new do |gem|
  gem.name          = "heroku-deploy"
  gem.version       = Heroku::Deploy::VERSION
  gem.authors       = ["Rodrigo Pinto"]
  gem.email         = ["rodrigopqn@gmail.com"]
  gem.description   = %q{A collection of rake tasks that help to deploy an application following a common way to every app.}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency('colored', '~> 1.2')
end
