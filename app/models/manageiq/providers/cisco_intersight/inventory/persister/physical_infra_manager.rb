module ManageIQ::Providers::CiscoIntersight
  class Inventory::Persister::PhysicalInfraManager < Inventory::Persister

    include ActiveSupport::Concern
    include Inventory::Persister::Definitions::PhysicalInfraCollections

    # TODO: Find out, why the line below isn't processed properly. After that, uncomment it
    # include Inventory::Persister::Definitions::PhysicalInfraCollections

    # TODO: Write initializer function for this collections.
    # At the moment, initialize_physical_infra_collections is empty function
    def initialize_inventory_collections
      # initialize_physical_infra_collections
      # add_cloud_collection(:vms)

      # add_physical_infra_collection( :vms)

      add_collection(physical_infra, :vms)
    end
  end
end
