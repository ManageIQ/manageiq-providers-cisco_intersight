module ManageIQ::Providers::CiscoIntersight
  class PhysicalInfraManager::PhysicalServerProfile < ::PhysicalServerProfile
    def self.display_name(name)
      n_('Physical Server Profile (CiscoIntersight)', 'Physical Server Profile (CiscoIntersight)', name)
    end

    def provider_object(connection)
      connection.find!(ems_ref)
    end
  end
end
