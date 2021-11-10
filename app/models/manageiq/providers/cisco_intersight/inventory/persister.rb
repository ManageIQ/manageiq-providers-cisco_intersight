module ManageIQ::Providers::CiscoIntersight
  class Inventory::Persister < ManageIQ::Providers::Inventory::Persister
    require_nested :PhysicalInfraManager

    def initialize_inventory_collections
      add_cloud_collection(:vms)
    end
  end
end
