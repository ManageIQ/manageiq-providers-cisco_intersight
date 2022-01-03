module ManageIQ::Providers::CiscoIntersight
  class PhysicalInfraManager < ManageIQ::Providers::PhysicalInfraManager
    require_nested :MetricsCapture
    require_nested :MetricsCollectorWorker
    require_nested :Refresher
    require_nested :RefreshWorker
    require_nested :EventCatcher
    require_nested :EventParser
    require_nested :PhysicalServer


    include Vmdb::Logging
    include ManagerMixin
    include_concern "Operations"

    supports :create

  end
end
