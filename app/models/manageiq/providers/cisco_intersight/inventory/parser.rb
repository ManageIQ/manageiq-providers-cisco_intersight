module ManageIQ::Providers::CiscoIntersight
  class Inventory::Parser < ManageIQ::Providers::Inventory::Parser
    require_nested :PhysicalInfraManager
  end
end
