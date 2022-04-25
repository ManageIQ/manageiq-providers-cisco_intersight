require 'intersight_client'

module ManageIQ::Providers::CiscoIntersight::ManagerMixin
  extend ActiveSupport::Concern

  def connect(_options = {})
    keyid = authentication_userid
    key = authentication_password
    raise MiqException::MiqHostError, "No credentials defined" if !keyid || !key

    self.class.raw_connect(keyid, key)
  end

  def disconnect(connection)
    # no need to disconnect - connection not persistent
    # TODO: should we clear configuration here (api_key=nil) ? (-> may require changes in intersight-client gem)
  end

  def verify_credentials(_auth_type = nil, options = {})
    with_provider_connection(options) do
      self.class.verify_provider_connection
    end
  end

  def self.verify_provider_connection(api_client)
    IntersightClient::IamApi.new(api_client).get_iam_api_key_list({:count => true}).count > 0
  rescue IntersightClient::ApiError => err
    case err.code
    when 401
      raise MiqException::MiqInvalidCredentialsError, "Invalid API key"
    else
      raise MiqException::MiqCommunicationsError, "HTTP error #{err.code}"
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
            :title     => _('Authentication'),
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
                    :id         => "authentications.default.userid",
                    :name       => "authentications.default.userid",
                    :label      => "Intersight API key ID",
                    :isRequired => true,
                    :validate   => [{:type => "required"}],
                  },
                  {
                    :component  => "textarea",
                    :id         => "authentications.default.password",
                    :name       => "authentications.default.password",
                    :label      => "Intersight API key",
                    :type       => "password",
                    :isRequired => true,
                    :validate   => [{:type => "required"}, {
                      :type    => "pattern",
                      :pattern => "-+BEGIN EC PRIVATE KEY-+[ \r\nA-Za-z0-9\\+/=]+-+END EC PRIVATE KEY-+",
                      :message => "PEM-formatted X.509 EC private key required"
                    }],
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
    #   "authentications" => {
    #     "default" => {
    #       "userid" => String,
    #       "password" => String,
    #     }
    #   }

    def verify_credentials(args)
      authentication = args.dig("authentications", "default")
      keyid, enc_key = authentication&.values_at("userid", "password")
      key = ManageIQ::Password.try_decrypt(enc_key)

      verify_provider_connection(raw_connect(keyid, key))
    end

    def raw_connect(key_id, key)
      require "intersight_client"

      IntersightClient::ApiClient.new(
        IntersightClient::Configuration.new do |config|
          config.api_key    = key
          config.api_key_id = key_id
        end
      )
    rescue OpenSSL::PKey::ECError
      raise MiqException::MiqInvalidCredentialsError, "Invalid key structure"
    end

    def hostname_required?
      false
    end
  end
end
