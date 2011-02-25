ENV['RDOCOPT'] = "-S -f html -T hanna"

require "rubygems"
require "hoe"
require File.dirname(__FILE__) << "/lib/authlogic_crowd_rest/version"

Hoe.new("Authlogic Crowd REST Client", AuthlogicCrowdRest::Version::STRING) do |p|
  p.name = "authlogic_crowd_rest"
  p.author = "Rob Di Marco of 416 Software"
  p.summary = "Extension of the Authlogic library to add Atlassian Crowd 2.x support."
  p.description = "Extension of the Authlogic library to add Atlassian Crowd 2.x support."
  p.url = "http://github.com/robdimarco/authlogic_crowd_rest"
  p.history_file = "CHANGELOG.rdoc"
  p.readme_file = "README.rdoc"
  p.extra_rdoc_files = ["CHANGELOG.rdoc", "README.rdoc"]
  p.remote_rdoc_dir = ''
  p.test_globs = ["test/*/test_*.rb", "test/*_test.rb", "test/*/*_test.rb"]
  p.extra_deps = %w(authlogic)
end
