module ManageIQ::Providers::CiscoIntersight
  class PhysicalInfraManager < ManageIQ::Providers::PhysicalInfraManager
    require_nested :MetricsCapture
    require_nested :MetricsCollectorWorker
    require_nested :Refresher
    require_nested :RefreshWorker
    require_nested :Vm
    require_nested :EventCatcher
    require_nested :EventParser
    require_nested :PhysicalServer


    include Vmdb::Logging
    include ManagerMixin
    include_concern "Operations"

    supports :create

    def self.ems_type
      @ems_type ||= "cisco_intersight".freeze
    end

    def self.description
      @description ||= "Cisco Intersight".freeze
    end
  end
end
