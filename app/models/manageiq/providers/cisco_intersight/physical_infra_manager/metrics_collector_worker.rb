module ManageIQ::Providers::CiscoIntersight
  class PhysicalInfraManager::MetricsCollectorWorker < ManageIQ::Providers::BaseManager::MetricsCollectorWorker
    require_nested :Runner

    self.default_queue_name = "cisco_intersight"

    def friendly_name
      @friendly_name ||= "C&U Metrics Collector for ManageIQ::Providers::CiscoIntersight"
    end
  end
end
