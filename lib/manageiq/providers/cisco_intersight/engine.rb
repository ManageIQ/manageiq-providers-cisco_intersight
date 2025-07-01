module ManageIQ
  module Providers
    module CiscoIntersight
      class Engine < ::Rails::Engine
        isolate_namespace ManageIQ::Providers::CiscoIntersight

        config.autoload_paths << root.join('lib').to_s

        def self.vmdb_plugin?
          true
        end

        def self.plugin_name
          _('Cisco Intersight Provider')
        end

        def self.init_loggers
          $cisco_intersight_log ||= Vmdb::Loggers.create_logger("cisco_intersight.log")
        end

        def self.apply_logger_config(config)
          Vmdb::Loggers.apply_config_value(config, $cisco_intersight_log, :level_cisco_intersight)
        end
      end
    end
  end
end
