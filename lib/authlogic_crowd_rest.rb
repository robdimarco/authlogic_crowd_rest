require "authlogic_crowd_rest/version"
require "authlogic_crowd_rest/acts_as_authentic"
require "authlogic_crowd_rest/session"

ActiveRecord::Base.send(:include, AuthlogicCrowdRest::ActsAsAuthentic)
Authlogic::Session::Base.send(:include, AuthlogicCrowdRest::Session)
