module ManageIQ::Providers::CiscoIntersight
  class Inventory::Persister::PhysicalInfraManager < Inventory::Persister

    # TODO: Find out, why the line below isn't processed properly
    # include Inventory::Persister::Definitions::PhysicalInfraCollections

    # TODO: Write initializer function for this collections.
    # At the moment, initialize_physical_infra_collections is empty function
    def initialize_inventory_collections
      initialize_physical_infra_collections
    end
  end
end
