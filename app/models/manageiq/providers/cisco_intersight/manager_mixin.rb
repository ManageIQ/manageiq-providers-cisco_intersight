module ManageIQ::Providers::CiscoIntersight::ManagerMixin
  extend ActiveSupport::Concern

  def connect(options = {})
    raise MiqException::MiqHostError, "No credentials defined" if missing_credentials?(options[:auth_type])

    auth_token = authentication_token(options[:auth_type])
    self.class.raw_connect(project, auth_token, options, options[:proxy_uri] || http_proxy_uri)
  end

  def disconnect(connection)
    connection.logout
  rescue StandardError => error
    _log.warn("Disconnect failed: #{error}")
  end

  def verify_credentials(auth_type = nil, options = {})
    options[:auth_type] = auth_type
    with_provider_connection(options) { true }
  end

  module ClassMethods

    class MyRubySDK
      def vms
        [
          OpenStruct.new(
            :id       => '1',
            :name     => 'funky',
            :location => 'dc-1',
            :vendor   => 'unknown'
          ),
          OpenStruct.new(
            :id       => '2',
            :name     => 'bunch',
            :location => 'dc-1',
            :vendor   => 'unknown'
          ),
        ]
      end
  
      def find_vm(id)
        vms.find { |v| v.id == id.to_s }
      end
  
      def events
        [
          OpenStruct.new(
            :name       => %w(instance_power_on instance_power_off).sample,
            :id         => Time.zone.now.to_i,
            :timestamp  => Time.zone.now,
            :vm_ems_ref => [1, 2].sample
          ),
          OpenStruct.new(
            :name       => %w(instance_power_on instance_power_off).sample,
            :id         => Time.zone.now.to_i + 1,
            :timestamp  => Time.zone.now,
            :vm_ems_ref => [1, 2].sample
          )
        ]
      end
  
      def metrics(start_time, end_time)
        timestamp = start_time
        metrics = {}
        while (timestamp < end_time)
          metrics[timestamp] = {
            'cpu_usage_rate_average'  => rand(100).to_f,
            'disk_usage_rate_average' => rand(100).to_f,
            'mem_usage_rate_average'  => rand(100).to_f,
            'net_usage_rate_average'  => rand(100).to_f,
          }
          timestamp += 20.seconds
        end
        metrics
      end
    end
  
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

    def verify_credentials(auth_type = nil, options = {})
      begin
        connect
      rescue => err
        raise MiqException::MiqInvalidCredentialsError, err.message
      end
    end

    def self.raw_connect(*args)
      # TODO: Replace this with a client connection from your Ruby SDK library and remove the MyRubySDK class
      MyRubySDK.new
    end

  end
end
