require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'test/unit'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'active_record'
require 'authlogic'
require 'authlogic_crowd_rest'

ActiveRecord::Schema.verbose = false
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
ActiveRecord::Base.configurations = true
ActiveRecord::Schema.define(:version => 1) do
  create_table :users do |t|
    t.datetime  :created_at
    t.datetime  :updated_at
    t.integer   :lock_version, :default => 0
    t.string    :login
    t.string    :crypted_password
    t.string    :password_salt
    t.string    :persistence_token
    t.string    :single_access_token
    t.string    :perishable_token
    t.string    :email
    t.string    :first_name
    t.string    :last_name
    t.integer   :login_count, :default => 0, :null => false
    t.integer   :failed_login_count, :default => 0, :null => false
    t.datetime  :last_request_at
    t.datetime  :current_login_at
    t.datetime  :last_login_at
    t.string    :current_login_ip
    t.string    :last_login_ip
  end
end

# require File.dirname(__FILE__) + '/libs/user'
# require File.dirname(__FILE__) + '/libs/user_session'

# class ActiveSupport::TestCase
#   include ActiveRecord::TestFixtures
#   self.fixture_path = File.dirname(__FILE__) + "/fixtures"
#   self.use_transactional_fixtures = false
#   self.use_instantiated_fixtures  = false
#   self.pre_loaded_fixtures = false
#   fixtures :all
#   setup :activate_authlogic
  
#   private
#     def activate_authlogic
#       Authlogic::Session::Base.controller = controller
#     end
    
#     def controller
#       @controller ||= Authlogic::ControllerAdapters::RailsAdapter.new(ActionController.new)
#     end
# end
