module ManageIQ::Providers::CiscoIntersight
  class PhysicalInfraManager::PhysicalRack < ::PhysicalRack
    def self.display_name(number = 1)
      n_('Physical Rack (CiscoIntersight)', 'Physical Rack (CiscoIntersight)', number)
    end
  end
end
