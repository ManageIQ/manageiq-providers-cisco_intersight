module ManageIQ::Providers::CiscoIntersight
  class PhysicalInfraManager::PhysicalServer < ::PhysicalServer
    include Provisioning

    def self.display_name(number = 1)
      n_('Physical Server (CiscoIntersight)', 'Physical Servers (CiscoIntersight)', number)
    end

    def provider_object(connection)
      connection.find!(ems_ref)
    end

    def power_down
      change_state(:power_down)
    end

    def power_up
      change_state(:power_up)
    end
  end
end
