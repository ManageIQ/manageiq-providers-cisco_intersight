module ManageIQ::Providers::CiscoIntersight
  class PhysicalInfraManager::PhysicalChassis < ::PhysicalChassis
    def self.display_name(number = 1)
      n_('Physical Chassis (CiscoIntersight)', 'Physical Chassis (CiscoIntersight)', number)
    end
  end
end
