# This module is responsible for adding Crowd functionality to Authlogic. Checkout the README for more info and please
# see the sub modules for detailed documentation.
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
      # Set up some simple validations
      def self.included(klass)
        return if !klass.column_names.include?("crowd_login")
        klass.class_eval do
          attr_accessor :crowd_password

          if validate_crowd_login
            validates_uniqueness_of :crowd_login, :scope => validations_scope, :if => :using_crowd?
            validate :validate_crowd
            validates_length_of_password_field_options validates_length_of_password_field_options.merge(:if => :validate_password_with_crowd?)
            validates_confirmation_of_password_field_options validates_confirmation_of_password_field_options.merge(:if => :validate_password_with_crowd?)
            validates_length_of_password_confirmation_field_options validates_length_of_password_confirmation_field_options.merge(:if => :validate_password_with_crowd?)
          end
        end
      end
      # Set the crowd_login field and also resets the persistence_token if this value changes.
      def crowd_login=(value)
        write_attribute(:crowd_login, value.blank? ? nil : value)
        reset_persistence_token if crowd_login_changed?
      end

      def save(perform_validation = true, &block)
        return false if perform_validation && block_given? && authenticate_with_crowd? && !authenticate_with_crowd
        return false if new_record? && !crowd_complete?
        result = super
        yield(result) if block_given?
        result
      end

      private
        def using_crowd?
          respond_to?(:crowd_login) && !crowd_login.blank?
        end

        def authenticate_with_crowd
          @crowd_error = nil

          if !crowd_complete?
            session_class.controller.session[:crowd_attributes] = attributes_to_save
          else
            map_saved_attributes(session_class.controller.session[:crowd_attributes])
            session_class.controller.session[:crowd_attributes] = nil
          end

          options = {}
          options[:required] = self.class.openid_required_fields
          options[:optional] = self.class.openid_optional_fields
          options[:return_to] = session_class.controller.url_for(:for_model => "1",:controller=>"users",:action=>"create")

          session_class.controller.send(:authenticate_with_open_id, openid_identifier, options) do |result, openid_identifier, registration|
            if result.unsuccessful?
              @openid_error = result.message
            else
              self.openid_identifier = openid_identifier
              map_openid_registration(registration)
            end

            return true
          end
          return false
        end

        # Override this method to map the OpenID registration fields with fields in your model. See the required_fields and
        # optional_fields configuration options to enable this feature.
        #
        # Basically you will get a hash of values passed as a single argument. Then just map them as you see fit. Check out
        # the source of this method for an example.
        def map_openid_registration(registration) # :doc:
          registration.symbolize_keys!
          [self.class.openid_required_fields+self.class.openid_optional_fields].flatten.each do |field|
            setter="#{field.to_s}=".to_sym
            if respond_to?(setter)
              send setter,registration[field]
            end
          end
        end

        # This method works in conjunction with map_saved_attributes.
        #
        # Let's say a user fills out a registration form, provides an OpenID and submits the form. They are then redirected to their
        # OpenID provider. All is good and they are redirected back. All of those fields they spent time filling out are forgetten
        # and they have to retype them all. To avoid this, AuthlogicOpenid saves all of these attributes in the session and then
        # attempts to restore them. See the source for what attributes it saves. If you need to block more attributes, or save
        # more just override this method and do whatever you want.
        def attributes_to_save # :doc:
          attrs_to_save = attributes.clone.delete_if do |k, v|
            [:id, :password, crypted_password_field, password_salt_field, :persistence_token, :perishable_token, :single_access_token, :login_count,
              :failed_login_count, :last_request_at, :current_login_at, :last_login_at, :current_login_ip, :last_login_ip, :created_at,
              :updated_at, :lock_version].include?(k.to_sym)
          end
          attrs_to_save.merge!(:password => password, :password_confirmation => password_confirmation)
        end

        # This method works in conjunction with attributes_to_save. See that method for a description of the why these methods exist.
        #
        # If the default behavior of this method is not sufficient for you because you have attr_protected or attr_accessible then
        # override this method and set them individually. Maybe something like this would be good:
        #
        #   attrs.each do |key, value|
        #     send("#{key}=", value)
        #   end
        def map_saved_attributes(attrs) # :doc:
          self.attributes = attrs
        end

        def validate_openid
          errors.add(:openid_identifier, "had the following error: #{@openid_error}") if @openid_error
        end

        def using_openid?
          respond_to?(:openid_identifier) && !openid_identifier.blank?
        end

        def openid_complete?
          session_class.controller.params[:open_id_complete] && session_class.controller.params[:for_model]
        end

        def authenticate_with_openid?
          session_class.activated? && ((using_openid? && openid_identifier_changed?) || openid_complete?)
        end

        def validate_password_with_openid?
          !using_openid? && require_password?
        end
    end
  end
end
