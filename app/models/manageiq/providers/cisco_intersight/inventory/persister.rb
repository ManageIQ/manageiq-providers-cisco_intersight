module ManageIQ::Providers::CiscoIntersight
  class Inventory::Persister < ManageIQ::Providers::Inventory::Persister
    require_nested :PhysicalInfraManager
  end
end
