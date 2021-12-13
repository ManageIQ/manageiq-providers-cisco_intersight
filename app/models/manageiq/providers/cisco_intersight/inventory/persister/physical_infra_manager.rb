module ManageIQ::Providers::CiscoIntersight
  class Inventory::Persister::PhysicalInfraManager < Inventory::Persister

    include ActiveSupport::Concern
    include Inventory::Persister::Definitions::PhysicalInfraCollections

    def initialize_inventory_collections
      add_collection(physical_infra, :vms)
      add_collection(physical_infra, :physical_servers)
    end
  end
end
