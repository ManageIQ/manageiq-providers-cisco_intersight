module ManageIQ::Providers::CiscoIntersight::Inventory::Persister::Definitions::PhysicalInfraCollections
  include ActiveSupport::Concern

  def initialize_physical_infra_collections
    %i(
      physical_servers
      physical_server_details
      physical_server_computer_systems
      physical_racks
      physical_chassis
    ).each do |name|
      add_collection(physical_infra, name)
    end    
    # TODO: Add the following collections to the loop above after you start implementing new collections
      # physical_server_hardwares
      # physical_server_network_devices
      # physical_server_storage_adapters
      # physical_server_firmwares
      # physical_chassis_details
  end
end
