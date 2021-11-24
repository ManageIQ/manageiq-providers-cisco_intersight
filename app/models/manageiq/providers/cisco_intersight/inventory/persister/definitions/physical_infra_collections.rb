module ManageIQ::Providers::CiscoIntersight::Inventory::Persister::Definitions::PhysicalInfraCollections
  include ActiveSupport::Concern

  def initialize_physical_infra_collections
    add_cloud_collection(:vms)
    # TODO (Tjaz Erzen): Define physical infra collections.

  end
end
