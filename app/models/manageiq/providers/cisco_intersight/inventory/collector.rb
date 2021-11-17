module ManageIQ::Providers::CiscoIntersight
  class Inventory::Collector < ManageIQ::Providers::Inventory::Collector
    require_nested :PhysicalInfraManager
  end
end
