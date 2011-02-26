module AuthlogicCrowdRest
  module ActsAsAuthentic
    def self.included(klass)
      klass.class_eval do
        extend Config
        add_acts_as_authentic_module(Methods, :prepend)
      end
    end
    
    module Config
    end
    
    module Methods
      def self.included(klass)
        klass.class_eval do
            validates_uniqueness_of :crowd_login, :scope => validations_scope, :if => :using_crowd?
            validates_presence_of :crowd_password, :if => :validate_ldap?
            validate :validate_ldap, :if => :validate_ldap?
          end
        end
      end
      
      private
        def validate_ldap
          return if errors.count > 0
          
          ldap = Net::LDAP.new
          ldap.host = session_class.ldap_host
          ldap.port = session_class.ldap_port
          ldap.auth ldap_login, ldap_password
          errors.add_to_base(ldap.get_operation_result.message) if !ldap.bind
        end
        
        def validate_ldap?
          ldap_login_changed? && !ldap_login.blank?
        end
    end
  end
end
