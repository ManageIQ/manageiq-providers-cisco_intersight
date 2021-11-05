module ManageIQ::Providers::CiscoIntersight
  class PhysicalInfraManager::RefreshWorker < ::MiqEmsRefreshWorker
    require_nested :Runner

    def self.settings_name
      :ems_refresh_worker_cisco_intersight_physical_infra
    end
  end
end
