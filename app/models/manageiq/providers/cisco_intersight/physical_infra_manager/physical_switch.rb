module ManageIQ::Providers::CiscoIntersight
  class PhysicalInfraManager::PhysicalSwitch < ::PhysicalSwitch

    def self.display_name(number = 1)
      n_('Physical Switch (CiscoIntersight)', 'Physical Switches (CiscoIntersight)', number)
    end
  end
end
