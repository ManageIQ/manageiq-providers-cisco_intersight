module ManageIQ::Providers::CiscoIntersight
  class PhysicalInfraManager::PhysicalServerProfileTemplate < ::PhysicalServerProfileTemplate
    def self.display_name(number = 1)
      n_('Physical Server Profile Template (CiscoIntersight)', 'Physical Server Profile Template (CiscoIntersight)', number)
    end

    def provider_object(connection)
      connection.find!(ems_ref)
    end
  end
end
