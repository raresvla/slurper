# -*- encoding: utf-8 -*-

require 'bundler'

Gem::Specification.new do |gem|
  gem.name = %q{jira-slurper}
  gem.version = "1.3.5"

  gem.required_rubygems_version = ">= 1.3.6"
  gem.authors = ["Wes Gibbs", "Adam Lowe", "Stephen Caudill", "Tim Pope", "Catalin Costache"]
  gem.date = Date.today.to_s
  gem.default_executable = %q{slurp}
  gem.description = %q{
      Slurps stories from the given file (stories.slurper by default) and creates Pivotal Tracker stories from them. Useful during story carding sessions when you want to capture a number of stories quickly without clicking your way through the Tracker UI.
    }
  gem.email = %q{dev@hashrocket.com}
  gem.executables = ["slurp"]
  gem.extra_rdoc_files = [
    "README.rdoc"
  ]
  gem.files = [
    "bin/slurp",
    "lib/jira.rb",
    "lib/jira/inflectors.rb",
    "lib/pivotal.rb",
    "lib/slurper.rb",
    "lib/story.rb",
    "lib/cacert.pem"
  ]
  gem.homepage = %q{http://github.com/hashrocket/slurper}
  gem.rdoc_options = ["--charset=UTF-8"]
  gem.require_paths = ["lib"]
  gem.summary = %q{takes a formatted story file and puts it on Pivotal / Jira Tracker}
  gem.test_files = [
    "spec/jira_spec.rb",
    "spec/pivotal_spec.rb",
    "spec/slurper_spec.rb",
    "spec/story_spec.rb",
  ]

  gem.add_dependency("faraday", ["~> 0.8.8"])
  gem.add_dependency("configliere", ["~> 0.4.8"])
  gem.add_dependency("json", ["~> 1.7.7"])
  gem.add_development_dependency("rspec", ["~> 3.0.0"])
  gem.add_development_dependency("rspec-its", ["~> 1.0.1"])
end
