module AuthlogicCrowdRest
  module Session
    def self.included(klass)
      klass.class_eval do
        extend Config
        include Methods
      end
    end

    module Config
      # The URL of your crowd rest API.  Should be
      # something like https://localhost:8095/crowd/rest
      #
      # * <tt>Default:</tt> nil
      # * <tt>Accepts:</tt> String
      def crowd_base_url(value = nil)
        rw_config(:crowd_base_url, value)
      end
      alias_method :crowd_base_url=, :crowd_base_url

      # The name in crowd for your application
      #
      # * <tt>Default:</tt> nil
      # * <tt>Accepts:</tt> String
      def crowd_application_name(value = nil)
        rw_config(:crowd_application_name, value)
      end
      alias_method :crowd_application_name=, :crowd_application_name

      # The password in crowd for your application
      #
      # * <tt>Default:</tt> nil
      # * <tt>Accepts:</tt> String
      def crowd_application_password(value = nil)
        rw_config(:crowd_application_password, value)
      end
      alias_method :crowd_application_password=, :crowd_application_password

      # Once Crowd authentication has succeeded we need to find the user in the database. By default this just calls the
      # find_by_crowd_login method provided by ActiveRecord. If you have a more advanced set up and need to find users
      # differently specify your own method and define your logic in there.
      #
      # For example, if you allow users to store multiple crowd logins with their account, you might do something like:
      #
      #   class User < ActiveRecord::Base
      #     def self.find_by_crowd_login(login)
      #       first(:conditions => ["#{CrowdLogin.table_name}.login = ?", login], :join => :crowd_logins)
      #     end
      #   end
      #
      # * <tt>Default:</tt> :find_by_crowd_login
      # * <tt>Accepts:</tt> Symbol
      def find_by_crowd_login_method(value = nil)
        rw_config(:find_by_crowd_login_method, value, :find_by_crowd_login)
      end
      alias_method :find_by_crowd_login_method=, :find_by_crowd_login_method
    end

    module Methods
      def self.included(klass)
        klass.class_eval do
          validate :validate_by_crowd_rest, :if => :authenticating_with_crowd_rest?
          attr_accessor :crowd_login
          attr_accessor :crowd_password
        end
      end

      # Hooks into credentials so that you can pass an :ldap_login and :ldap_password key.
      # Hooks into credentials to print out meaningful credentials for LDAP authentication.
      def credentials
        if authenticating_with_crowd_rest?
          details = {}
          details[:crowd_login] = crowd_login
          details[:crowd_password] = "<protected>"
          details
        else
          super
        end
      end

      def credentials=(value)
        super
        values = value.is_a?(Array) ? value : [value]
        hash = values.first.is_a?(Hash) ? values.first.with_indifferent_access : nil
        if !hash.nil?
          self.crowd_login = hash[:crowd_login] if hash.key?(:crowd_login)
          self.crowd_password = hash[:crowd_password] if hash.key?(:crowd_password)
        end
      end

      private
        def authenticating_with_crowd_rest?
          !(crowd_base_url.blank? || crowd_application_name.blank? || crowd_application_password.blank?)
        end

        def validate_by_crowd_rest
          self.invalid_password = false

          errors.add(:crowd_login, I18n.t('error_messages.crowd_login_blank', :default => "can not be blank")) if crowd_login.blank?
          errors.add(:crowd_password, I18n.t('error_messages.crowd_password_blank', :default => "can not be blank")) if crowd_password.blank?
          return if errors.count > 0

          self.attempted_record = search_for_record(find_by_crowd_login_method, crowd_login)
          if attempted_record.blank?
            generalize_credentials_error_messages? ?
            add_general_credentials_error :
              errors.add("crowd_login", I18n.t('error_messages.crowd_login_not_found', :default => "is not valid"))
            return
          end

          if !(send( :verify_crowd_password, attempted_record))
            self.invalid_password = true
            generalize_credentials_error_messages? ?
            add_general_credentials_error :
              errors.add("crowd_password", I18n.t('error_messages.crowd_password_invalid', :default => "is not valid"))
            return
          end
        end

        def verify_crowd_password(attempted_record)
          require 'net/http'
          require 'net/https'
          uri = URI.parse(send("crowd_base_url") + "/rest/usermanagement/latest/authentication")

          begin
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = uri.scheme == "https"
            http.start {|http|
              req = Net::HTTP::Post.new(uri.path + "?" + "username=#{crowd_login}")
              req.basic_auth send("crowd_application_name"), send("crowd_application_password")
              req.body="<password><value>#{crowd_password}</value></password>"
              req.add_field 'Content-Type', 'text/xml'
              resp, data = http.request(req)
              resp.code.to_i == 200
            }
          rescue Interrupt
            errors.add(password_field, I18n.t('error_messages.crowd_password_timeout', :default=>"Timeout occurred when connecting to crowd"))
          end
        end

        def crowd_application_password
          self.class.crowd_application_password
        end

        def crowd_application_name
          self.class.crowd_application_name
        end
        def crowd_base_url
          self.class.crowd_base_url
        end
        def find_by_crowd_login_method
          self.class.find_by_crowd_login_method
        end
    end
  end
end
