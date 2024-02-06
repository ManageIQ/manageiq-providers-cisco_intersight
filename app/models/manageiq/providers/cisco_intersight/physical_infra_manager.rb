module ManageIQ::Providers::CiscoIntersight
  class PhysicalInfraManager < ManageIQ::Providers::PhysicalInfraManager
    supports :catalog

    include Vmdb::Logging
    include ManagerMixin
    include Operations

    supports :create

    def self.ems_type
      @ems_type ||= "cisco_intersight".freeze
    end

    def self.description
      @description ||= "Cisco Intersight".freeze
    end

    def self.catalog_types
      {"cisco_intersight" => N_("Cisco Intersight")}
    end
  end
end
