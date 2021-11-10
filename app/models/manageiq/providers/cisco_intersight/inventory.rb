module ManageIQ::Providers::CiscoIntersight
  class Inventory < ManageIQ::Providers::Inventory
    require_nested :Collector
    require_nested :Parser
    require_nested :Persister
  end
end
