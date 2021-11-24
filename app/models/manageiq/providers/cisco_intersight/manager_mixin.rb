module ManageIQ::Providers::CiscoIntersight::ManagerMixin
  extend ActiveSupport::Concern

  def connect(options = {})
    # Temprorarily hardcoding for the connection to happen even if the credentials are missing.
    # TODO (Tjaz Erzen): When the connection is verified properly, un-hardcode properly verified connection
    # raise MiqException::MiqHostError, "No credentials defined" if missing_credentials?(options[:auth_type])
    # auth_token = authentication_token(options[:auth_type])

    auth_token = nil # a temporary value - it won't be needed in raw_connection anyways.

    self.class.raw_connect(project, auth_token, options, options[:proxy_uri] || http_proxy_uri)
  end

  def disconnect(connection)
    connection.logout
  rescue StandardError => error
    _log.warn("Disconnect failed: #{error}")
  end

  def verify_credentials(auth_type = nil, options = {})
    begin
      connect
    rescue => err
      raise MiqException::MiqInvalidCredentialsError, err.message
    end
  end

  module ClassMethods

    def params_for_create
      @params_for_create ||= {
        :fields => [
          {
            :component => 'sub-form',
            :id        => 'endpoints-subform',
            :name      => 'endpoints-subform',
            :title     => _('Endpoints'),
            :fields    => [
              {
                :component              => 'validate-provider-credentials',
                :id                     => 'authentications.default.valid',
                :name                   => 'authentications.default.valid',
                :skipSubmit             => true,
                :isRequired             => true,
                :validationDependencies => %w[type],
                :fields                 => [
                  {
                    :component  => "text-field",
                    :id         => "endpoints.default.endpoint",
                    :name       => "endpoints.default.endpoint",
                    :label      => _("Endpoint"),
                    :isRequired => true,
                    :validate   => [{:type => "required"}],
                  },
                  {
                    :component  => "text-field",
                    :id         => "authentications.default.key_id",
                    :name       => "authentications.default.key_id",
                    :label      => "Key ID",
                    :isRequired => true,
                    :validate   => [{:type => "required"}],
                  },
                  {
                    # Question: Is this form of type "password" (since it's a private key)
                    :component  => "password-field",
                    :id         => "authentications.default.key_file",
                    :name       => "authentications.default.key_file",
                    :label      => "Key File",
                    # Question: Is this form of type "password" (since it's a private key)
                    :type       => "password",
                    :isRequired => true,
                    :validate   => [{:type => "required"}],
                  },
                ]
              },
            ],
          },
        ]
      }.freeze
    end

    # Verify Credentials
    #
    # args: {
    #   "endpoints" => {
    #     "default" => {
    #       "security_protocol" => String,
    #       "hostname" => String,
    #       "port" => Integer,
    #     }
    #   "authentications" => {
    #     "default" => {
    #       "userid" => String,
    #       "password" => String,
    #     }
    #   }

    def verify_credentials(args)
      # Verify the credentials without having an actual record created.
      # This method is being called from the UI upon validation when adding/editing a provider via DDF
      # Ideally it should pass the args with some kind of mapping to the connect method
    end

    def raw_connect(*args)
      # TODO: Replace this with a client connection from your Ruby SDK library and remove the MyRubySDK class
      MyRubySDK.new
    end

    def hostname_required?
      # TODO: ExtManagementSystem is validating this
      false
    end

    def validate_authentication_args(params)
      # return args to be used in raw_connect
      [params[:default_userid], ManageIQ::Password.encrypt(params[:default_password])]
    end

    def ems_type
      @ems_type ||= "cisco_intersight".freeze
    end

    def description
      @description ||= "Cisco Intersight".freeze
    end


  end
end
