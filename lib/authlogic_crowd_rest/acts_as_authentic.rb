module AuthlogicCrowdRest
  module ActsAsAuthentic
    def self.included(klass)
      klass.class_eval do
        extend Config
        add_acts_as_authentic_module(Methods, :prepend)
      end
    end

    module Config
      # Whether or not to validate the crowd_login field. If set to false ALL crowd validation will need to be
      # handled by you.
      #
      # * <tt>Default:</tt> true
      # * <tt>Accepts:</tt> Boolean
      def validate_crowd_login(value = nil)
        rw_config(:validate_crowd_login, value, true)
      end
      alias_method :validate_crowd_login=, :validate_crowd_login
    end

    module Methods
      def self.included(klass)
        return if !klass.column_names.include?("crowd_login")
        klass.class_eval do
          attr_accessor :crowd_password

          if validate_crowd_login
            validates_uniqueness_of :crowd_login, :scope => validations_scope, :if => :using_crowd?
          end
        end
      end
      private
      def using_crowd?
        respond_to?(:crowd_login) && !crowd_login.blank?
      end
    end
  end
end
