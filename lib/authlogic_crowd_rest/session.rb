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
    end

    module Methods
      def self.included(klass)
        klass.class_eval do
          validate :validate_by_crowd_rest, :if => :authenticating_with_crowd_rest?
        end
      end

      private
        def authenticating_with_crowd_rest?
          !(crowd_base_url.blank? || crowd_application_name.blank? || crowd_application_password.blank?)
        end

        def validate_by_crowd_rest
          self.invalid_password = false
          errors.add(login_field, I18n.t('error_messages.login_blank', :default => "cannot be blank")) if send(login_field).blank?
          errors.add(password_field, I18n.t('error_messages.password_blank', :default => "cannot be blank")) if send("protected_#{password_field}").blank?
          return if errors.count > 0

          self.attempted_record = search_for_record(find_by_login_method, send(login_field))
          if attempted_record.blank?
            generalize_credentials_error_messages? ?
            add_general_credentials_error :
              errors.add(login_field, I18n.t('error_messages.login_not_found', :default => "is not valid"))
            return
          end

          if !(send( :verify_crowd_password, attempted_record))
            puts "Invalid!"
            self.invalid_password = true
            generalize_credentials_error_messages? ?
            add_general_credentials_error :
              errors.add(password_field, I18n.t('error_messages.password_invalid', :default => "is not valid"))
            return
          end
        end

        def verify_crowd_password(attempted_record)
          password = attempted_record.send(verify_password_method, send("protected_#{password_field}"))
          require 'net/http'
          require 'net/https'
          uri = URI.parse(send("crowd_base_url"))

          begin
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = uri.scheme == "https"
            http.start {|http|
              req = Net::HTTP::Post.new(uri.path + "?" + "username=#{attempted_record.login}")
              req.basic_auth send("crowd_application_name"), send("crowd_application_password")
              req.body="<password><value>#{send("protected_#{password_field}")}</value></password>"
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
    end
  end
end
