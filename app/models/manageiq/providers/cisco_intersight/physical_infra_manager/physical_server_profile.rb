module ManageIQ::Providers::CiscoIntersight
  class PhysicalInfraManager::PhysicalServerProfile < ::PhysicalServerProfile
    def self.display_name(number = 1)
      n_('Physical Server Profile (CiscoIntersight)', 'Physical Server Profile (CiscoIntersight)', number)
    end

    def provider_object(connection)
      connection.find!(ems_ref)
    end
  end
end
