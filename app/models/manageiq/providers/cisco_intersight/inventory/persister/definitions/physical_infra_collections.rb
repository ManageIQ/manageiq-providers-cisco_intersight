module ManageIQ::Providers::CiscoIntersight::Inventory::Persister::Definitions::PhysicalInfraCollections
  include ActiveSupport::Concern

  def initialize_physical_infra_collections
    %i[
      physical_servers
      physical_server_details
      physical_server_computer_systems
      physical_racks
      physical_server_hardwares
      physical_server_network_devices
      physical_server_firmwares
      physical_server_storage_adapters
      physical_chassis
      physical_chassis_details
      physical_switches
      physical_switch_details
      physical_switch_hardwares
      physical_switch_firmwares
    ].each do |name|
      add_collection(physical_infra, name)

      add_physical_switch_network_ports
      add_physical_server_networks
      add_physical_switch_networks
      add_physical_server_management_devices
    end
  end

  def add_physical_switch_network_ports
    add_collection(physical_infra, "physical_switch_network_ports".to_sym) do |builder|
      builder.add_properties(
        :model_class                  => ::PhysicalNetworkPort,
        :manager_ref                  => %i[port_type port_name physical_switch],
        :parent_inventory_collections => %i[physical_switches]
      )
    end
  end

  def add_physical_server_management_devices
    add_collection(physical_infra, :physical_server_management_devices) do |builder|
      builder.add_properties(
        :model_class                  => ::GuestDevice,
        :manager_ref                  => %i[device_type hardware],
        :parent_inventory_collections => %i[physical_servers]
      )
    end
  end

  def add_physical_server_networks
    add_collection(physical_infra, :physical_server_networks) do |builder|
      builder.add_properties(
        :model_class                  => ::Network,
        :manager_ref                  => %i[guest_device ipaddress ipv6address],
        :manager_ref_allowed_nil      => %i[ipaddress ipv6address],
        :parent_inventory_collections => %i[physical_server_management_devices]
      )
    end
  end

  def add_physical_switch_networks
    add_collection(physical_infra, :physical_switch_networks) do |builder|
      builder.add_properties(
        :model_class                  => ::Network,
        :manager_ref                  => %i[hardware ipaddress ipv6address],
        :manager_ref_allowed_nil      => %i[ipaddress ipv6address],
        :parent_inventory_collections => %i[physical_switches]
      )
    end
  end
end
