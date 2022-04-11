module ManageIQ::Providers::CiscoIntersight
  class PhysicalInfraManager::PhysicalSwitchNetworkPort < ::PhysicalSwitchNetworkPort

    def self.display_name(number = 1)
      n_('Physical Switch Network Port (CiscoIntersight)', 'Physical Switches Network Ports (CiscoIntersight)', number)
    end
  end
end
