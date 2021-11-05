module ManageIQ::Providers::CiscoIntersight
  class PhysicalInfraManager::EventCatcher \
      < ManageIQ::Providers::BaseManager::EventCatcher
    require_nested :Runner
  end
end
