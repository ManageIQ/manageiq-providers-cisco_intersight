describe ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::Refresher do
  subject(:ems) do
    FactoryBot.create(:ems_cisco_intersight_physical_infra, :vcr)
  end

  describe "refresh", :vcr do
    it "will perform a full refresh" do
      2.times do # Test for refresh idempotence
        EmsRefresh.refresh(ems)
        ems.reload

        assert_ems

        # servers tests

        # Asserting specific active/undecomissioned server:
        assert_specific_physical_server
        assert_specific_physical_server_details
        assert_specific_physical_server_hardwares
        assert_specific_physical_server_firmwares
        assert_specific_physical_server_network_devices

        # Asserting specific decomissioned server:
        assert_specific_decommissioned_physical_server
        assert_specific_decommissioned_physical_server_details
        assert_specific_decommissioned_physical_server_hardwares

        # chasses tests
        assert_specific_physical_chassis
        assert_specific_physical_chassis_details

        # switches tests
        assert_specific_physical_switch
        assert_specific_physical_switch_details
        assert_specific_physical_switch_hardwares
        assert_specific_physical_switch_firmwares
        assert_specific_physical_switch_network_ports
        assert_specific_physical_switch_networks
      end
    end
  end

  def assert_ems
    # physical server's collections
    # These numbers also take into account decommissioned servers
    expect(ems.physical_servers.count).to(eq(4))
    expect(ems.physical_server_details.count).to(eq(4))
    expect(ems.physical_server_computer_systems.count).to(eq(4))
    expect(ems.physical_server_hardwares.count).to(eq(4))
    expect(ems.physical_server_network_devices.count).to(eq(3))
    expect(ems.physical_server_firmwares.count).to(eq(41))
    expect(ems.physical_server_storage_adapters.count).to(eq(0))

    # physical rack's collections
    # In our available lab, we have informations about racks yet.
    expect(ems.physical_racks.count).to(eq(0))

    # physical chassis' collections
    expect(ems.physical_chassis.count).to(eq(1))
    expect(ems.physical_chassis_details.count).to(eq(1))

    # physical switch's collections
    expect(ems.physical_switches.count).to(eq(2))
    expect(ems.physical_switch_details.count).to(eq(2))
    expect(ems.physical_switch_hardwares.count).to(eq(2))
    expect(ems.physical_switch_firmwares.count).to(eq(2))

    expect(ems.physical_switch_network_ports.count).to(eq(108))
    expect(ems.physical_switch_networks.count).to(eq(2))
  end

  # Asserting specific objects type of tests

  def assert_specific_physical_server
    server_ems_ref = "6272cb176176752d36b0dd57"
    server = get_physical_server_from_ems_ref(server_ems_ref)

    chassis_ems_ref = "614ceb786176752d35ab8b41"
    chassis = get_physical_chassis_from_ems_ref(chassis_ems_ref)

    expect(server).to(have_attributes(
                        :ems_ref                => server_ems_ref,
                        :hostname               => "C1-B2-UCSX-210C-M6",
                        :type                   => "ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalServer",
                        :product_name           => nil,
                        :manufacturer           => "Cisco Systems Inc",
                        :machine_type           => nil,
                        :model                  => nil,
                        :serial_number          => nil,
                        :field_replaceable_unit => nil,
                        :raw_power_state        => "on",
                        :vendor                 => nil,
                        :health_state           => "Valid",
                        :power_state            => "on",
                        :physical_chassis       => chassis
                      ))

    expect(server.ext_management_system).to(eq(ems))
  end

  def assert_specific_physical_server_details
    server_ems_ref = "6272cb176176752d36b0dd57"
    server = get_physical_server_from_ems_ref(server_ems_ref)
    asset_detail = AssetDetail.find_by!(:resource => server)

    expect(asset_detail).to(have_attributes(
                              :description            => "UCS 210c M6 Compute Node w/o CPU,  Memory, Storage, Mezz",
                              :contact                => nil,
                              :location               => "3800 ZANKER ROAD SAN JOSE US 95134 CA",
                              :room                   => "2",
                              :rack_name              => nil,
                              :lowest_rack_unit       => nil,
                              :resource_type          => "PhysicalServer",
                              :product_name           => "CISCO SYSTEMS INC FOR US INTERNAL DEMO EVAL ONLY",
                              :machine_type           => "CiscoUcsServer",
                              :model                  => "UCSX-210C-M6",
                              :serial_number          => "FCH250671HR",
                              :field_replaceable_unit => nil,
                              :part_number            => nil,
                              :location_led_ems_ref   => nil,
                              :location_led_state     => "off"
                            ))
  end

  def assert_specific_physical_server_hardwares
    server_ems_ref = "6272cb176176752d36b0dd57"
    server = get_physical_server_from_ems_ref(server_ems_ref)
    hardware = server.hardware

    expect(hardware).to(have_attributes(
                          :virtual_hw_version   => nil,
                          :config_version       => nil,
                          :guest_os             => nil,
                          :cpu_sockets          => 1,
                          :bios                 => nil,
                          :bios_location        => nil,
                          :time_sync            => nil,
                          :annotation           => nil,
                          :vm_or_template_id    => nil,
                          :memory_mb            => 512,
                          :host_id              => nil,
                          :cpu_speed            => 145,
                          :cpu_type             => nil,
                          :size_on_disk         => nil,
                          :manufacturer         => "",
                          :model                => "",
                          :number_of_nics       => nil,
                          :cpu_usage            => nil,
                          :memory_usage         => nil,
                          :cpu_cores_per_socket => nil,
                          :cpu_total_cores      => 56,
                          :vmotion_enabled      => nil,
                          :disk_free_space      => nil,
                          :disk_capacity        => nil,
                          :guest_os_full_name   => nil,
                          :memory_console       => nil,
                          :bitness              => nil,
                          :virtualization_type  => nil,
                          :root_device_type     => nil,
                          :disk_size_minimum    => nil,
                          :memory_mb_minimum    => nil,
                          :introspected         => nil,
                          :provision_state      => nil,
                          :serial_number        => nil,
                          :switch_id            => nil,
                          :firmware_type        => nil,
                          :canister_id          => nil
                        ))
  end

  def assert_specific_physical_server_firmwares
    server_ems_ref = "6272cb176176752d36b0dd57"
    server = get_physical_server_from_ems_ref(server_ems_ref)
    firmware = server.hardware.firmwares.first

    expect(firmware).to(have_attributes(
                          :name            => "BIOS",
                          :build           => "BIOS",
                          :version         => "X210M6.5.0.1d.0.0816211754",
                          :release_date    => nil,
                          :resource_type   => "Hardware",
                          :guest_device_id => nil
                        ))
  end

  def assert_specific_physical_server_network_devices
    server_ems_ref = "6272cb176176752d36b0dd57"
    server = get_physical_server_from_ems_ref(server_ems_ref)
    nic = server.hardware.nics.first

    expect(nic).to(have_attributes(
                     :device_name            => "UCSX-V4-Q25GML_FCH250672ZM",
                     :device_type            => "ethernet",
                     :location               => nil,
                     :filename               => nil,
                     :mode                   => nil,
                     :controller_type        => nil,
                     :size                   => nil,
                     :free_space             => nil,
                     :size_on_disk           => nil,
                     :address                => nil,
                     :switch_id              => nil,
                     :lan_id                 => nil,
                     :model                  => "UCSX-V4-Q25GML",
                     :iscsi_name             => nil,
                     :iscsi_alias            => nil,
                     :present                => true,
                     :start_connected        => true,
                     :auto_detect            => nil,
                     :uid_ems                => "6272cced6176752d36b15a96",
                     :chap_auth_enabled      => nil,
                     :manufacturer           => "Cisco Systems Inc",
                     :field_replaceable_unit => nil,
                     :parent_device_id       => nil,
                     :vlan_key               => nil,
                     :vlan_enabled           => nil,
                     :peer_mac_address       => nil,
                     :speed                  => nil
                   ))
  end

  def assert_specific_decommissioned_physical_server
    # Note that these tests have to be updated if a re/decommission operation is done on this server.
    server_ems_ref = "614cebe76f62692d3083863f"
    server_decommissioned = get_physical_server_from_ems_ref(server_ems_ref)

    expect(server_decommissioned).to(have_attributes(
                                       :ems_ref                => server_ems_ref,
                                       :hostname               => nil,
                                       :type                   => "ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalServer",
                                       :product_name           => nil,
                                       :manufacturer           => nil,
                                       :machine_type           => nil,
                                       :model                  => nil,
                                       :serial_number          => nil,
                                       :field_replaceable_unit => nil,
                                       :raw_power_state        => "decomissioned",
                                       :vendor                 => nil,
                                       :health_state           => nil,
                                       :power_state            => "decomissioned"
                                     ))
  end

  def assert_specific_decommissioned_physical_server_details
    # Note that these tests have to be updated if a re/decommission operation is done on this server.
    server_ems_ref = "614cebe76f62692d3083863f"
    server_decommissioned = get_physical_server_from_ems_ref(server_ems_ref)
    asset_detail = AssetDetail.find_by!(:resource => server_decommissioned)

    expect(asset_detail).to(have_attributes(
                              :description            => nil,
                              :contact                => nil,
                              :location               => nil,
                              :room                   => nil,
                              :rack_name              => nil,
                              :lowest_rack_unit       => nil,
                              :resource_type          => "PhysicalServer",
                              :product_name           => nil,
                              :machine_type           => nil,
                              :model                  => nil,
                              :serial_number          => nil,
                              :field_replaceable_unit => nil,
                              :part_number            => nil,
                              :location_led_ems_ref   => nil,
                              :location_led_state     => nil
                            ))
  end

  def assert_specific_decommissioned_physical_server_hardwares
    # Note that these tests have to be updated if a re/decommission operation is done on this server.
    server_ems_ref = "614cebe76f62692d3083863f"
    server_decommissioned = get_physical_server_from_ems_ref(server_ems_ref)

    hardware_decommissioned = server_decommissioned.hardware

    expect(hardware_decommissioned).to(have_attributes(
                                         :virtual_hw_version   => nil,
                                         :config_version       => nil,
                                         :guest_os             => nil,
                                         :cpu_sockets          => 1,
                                         :bios                 => nil,
                                         :bios_location        => nil,
                                         :time_sync            => nil,
                                         :annotation           => nil,
                                         :vm_or_template_id    => nil,
                                         :memory_mb            => nil,
                                         :host_id              => nil,
                                         :cpu_speed            => nil,
                                         :cpu_type             => nil,
                                         :size_on_disk         => nil,
                                         :manufacturer         => "",
                                         :model                => "",
                                         :number_of_nics       => nil,
                                         :cpu_usage            => nil,
                                         :memory_usage         => nil,
                                         :cpu_cores_per_socket => nil,
                                         :cpu_total_cores      => nil,
                                         :vmotion_enabled      => nil,
                                         :disk_free_space      => nil,
                                         :disk_capacity        => nil,
                                         :guest_os_full_name   => nil,
                                         :memory_console       => nil,
                                         :bitness              => nil,
                                         :virtualization_type  => nil,
                                         :root_device_type     => nil,
                                         :disk_size_minimum    => nil,
                                         :memory_mb_minimum    => nil,
                                         :introspected         => nil,
                                         :provision_state      => nil,
                                         :serial_number        => nil,
                                         :switch_id            => nil,
                                         :firmware_type        => nil,
                                         :canister_id          => nil
                                       ))
  end

  def assert_specific_physical_chassis
    chassis_ems_ref = "614ceb786176752d35ab8b41"
    chassis = get_physical_chassis_from_ems_ref(chassis_ems_ref)

    expect(chassis).to(have_attributes(
                         :uid_ems                      => nil,
                         :ems_ref                      => chassis_ems_ref,
                         :physical_rack_id             => nil,
                         :name                         => "LAB02D02F01-1",
                         :vendor                       => nil,
                         :type                         => "ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalChassis",
                         :health_state                 => "Valid",
                         :overall_health_state         => nil,
                         :management_module_slot_count => nil,
                         :switch_slot_count            => nil,
                         :fan_slot_count               => nil,
                         :blade_slot_count             => nil,
                         :powersupply_slot_count       => nil
                       ))

    expect(chassis.ext_management_system).to(eq(ems))
  end

  def assert_specific_physical_chassis_details
    chassis_ems_ref = "614ceb786176752d35ab8b41"
    chassis = get_physical_chassis_from_ems_ref(chassis_ems_ref)
    asset_detail = AssetDetail.find_by!(:resource => chassis)

    expect(asset_detail).to(have_attributes(
                              :description            => "UCS 9508 Chassis Configured",
                              :location               => "3800 ZANKER ROAD SAN JOSE US 95134 CA",
                              :room                   => nil,
                              :contact                => nil,
                              :rack_name              => nil,
                              :lowest_rack_unit       => nil,
                              :resource_type          => "PhysicalChassis",
                              :product_name           => "CISCO SYSTEMS INC FOR US INTERNAL DEMO EVAL ONLY",
                              :manufacturer           => nil,
                              :machine_type           => "CiscoUcsChassis",
                              :model                  => "UCSX-9508",
                              :serial_number          => "FOX2510P5HJ",
                              :field_replaceable_unit => nil,
                              :part_number            => "68-6847-03  ",
                              :location_led_ems_ref   => nil,
                              :location_led_state     => "off"
                            ))
  end

  def assert_specific_physical_switch
    switch_uid_ems = "614ce2a16176752d35a7ec96"
    switch = get_physical_switch_from_uid_ems(switch_uid_ems)

    expect(switch).to(have_attributes(
                        :name              => "LAB02D02F01 FI-B",
                        :ports             => nil,
                        :uid_ems           => switch_uid_ems,
                        :allow_promiscuous => nil,
                        :forged_transmits  => nil,
                        :mac_changes       => nil,
                        :mtu               => nil,
                        :type              => "ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalSwitch",
                        :health_state      => "Warning",
                        :power_state       => nil
                      ))
    expect(switch.ext_management_system).to(eq(ems))
  end

  def assert_specific_physical_switch_details
    switch_uid_ems = "614ce2a16176752d35a7ec96"
    switch = get_physical_switch_from_uid_ems(switch_uid_ems)
    asset_detail = AssetDetail.find_by!(:resource => switch)

    expect(asset_detail).to(have_attributes(
                              :description            => "UCS 9508 Chassis Configured",
                              :location               => "3800 ZANKER ROAD SAN JOSE US 95134 CA",
                              :room                   => nil,
                              :contact                => nil,
                              :rack_name              => nil,
                              :lowest_rack_unit       => nil,
                              :resource_type          => "Switch",
                              :product_name           => "CISCO SYSTEMS INC FOR US INTERNAL DEMO EVAL ONLY",
                              :manufacturer           => "Cisco Systems, Inc.",
                              :machine_type           => "CiscoUcsChassis",
                              :model                  => "UCS-FI-6454",
                              :serial_number          => "FDO244106VJ",
                              :field_replaceable_unit => nil,
                              :part_number            => nil,
                              :location_led_ems_ref   => nil,
                              :location_led_state     => nil
                            ))
  end

  def assert_specific_physical_switch_hardwares
    switch_uid_ems = "614ce2a16176752d35a7ec96"
    switch = get_physical_switch_from_uid_ems(switch_uid_ems)
    hardware = switch.hardware

    expect(hardware).to(have_attributes(
                          :virtual_hw_version   => nil,
                          :config_version       => nil,
                          :guest_os             => nil,
                          :cpu_sockets          => 1,
                          :bios                 => nil,
                          :bios_location        => nil,
                          :time_sync            => nil,
                          :annotation           => nil,
                          :vm_or_template_id    => nil,
                          :memory_mb            => nil,
                          :host_id              => nil,
                          :cpu_speed            => nil,
                          :cpu_type             => nil,
                          :size_on_disk         => nil,
                          :manufacturer         => "",
                          :model                => "",
                          :number_of_nics       => nil,
                          :cpu_usage            => nil,
                          :memory_usage         => nil,
                          :cpu_cores_per_socket => nil,
                          :cpu_total_cores      => nil,
                          :vmotion_enabled      => nil,
                          :disk_free_space      => nil,
                          :disk_capacity        => nil,
                          :guest_os_full_name   => nil,
                          :memory_console       => nil,
                          :bitness              => nil,
                          :virtualization_type  => nil,
                          :root_device_type     => nil,
                          :disk_size_minimum    => nil,
                          :memory_mb_minimum    => nil,
                          :introspected         => nil,
                          :provision_state      => nil,
                          :serial_number        => nil,
                          :firmware_type        => nil,
                          :canister_id          => nil
                        ))
  end

  def assert_specific_physical_switch_firmwares
    switch_uid_ems = "614ce2a16176752d35a7ec96"
    switch = get_physical_switch_from_uid_ems(switch_uid_ems)
    firmware = switch.hardware.firmwares.first

    expect(firmware).to(have_attributes(
                          :name            => "switch-FDO244106VJ/mgmt/fw-system",
                          :build           => "9.3(5)I42(1f)",
                          :version         => "9.3(5)I42(1f)",
                          :resource_type   => "Hardware",
                          :guest_device_id => nil
                        ))
  end

  def assert_specific_physical_switch_network_ports
    switch_uid_ems = "614ce25c4630312d42bf1d67"
    physical_switch_network_port = PhysicalNetworkPort.find_by(:uid_ems => switch_uid_ems)

    expect(physical_switch_network_port).to(have_attributes(
                                              :ems_ref            => nil,
                                              :uid_ems            => switch_uid_ems,
                                              :type               => nil,
                                              :port_name          => "switch-FDO244106VJ/slot-1/switch-ether/port-42",
                                              :port_type          => "ethernet",
                                              :peer_mac_address   => nil,
                                              :vlan_key           => nil,
                                              :mac_address        => "00:3A:9C:DA:78:F1",
                                              :port_index         => 42,
                                              :vlan_enabled       => nil,
                                              :guest_device_id    => nil,
                                              :connected_port_uid => switch_uid_ems,
                                              :port_status        => "Disabled"
                                            ))
  end

  def assert_specific_physical_switch_networks
    switch_uid_ems = "614ce2a16176752d35a7ec96"
    switch = get_physical_switch_from_uid_ems(switch_uid_ems)
    hardware = switch.hardware
    network = Network.find_by(:hardware => hardware)

    expect(network).to(have_attributes(
                         :device_id       => nil,
                         :description     => nil,
                         :guid            => nil,
                         :dhcp_enabled    => nil,
                         :ipaddress       => "100.66.11.142",
                         :subnet_mask     => "255.255.255.192",
                         :lease_obtained  => nil,
                         :lease_expires   => nil,
                         :default_gateway => "100.66.11.129",
                         :dhcp_server     => nil,
                         :dns_server      => nil,
                         :hostname        => nil,
                         :domain          => nil,
                         :ipv6address     => ""
                       ))
  end

  # Helper methods

  def get_physical_switch_from_uid_ems(uid_ems)
    PhysicalSwitch.find_by(:uid_ems => uid_ems)
  end

  def get_physical_server_from_ems_ref(ems_ref)
    PhysicalServer.find_by(:ems_ref => ems_ref)
  end

  def get_physical_chassis_from_ems_ref(ems_ref)
    PhysicalChassis.find_by(:ems_ref => ems_ref)
  end

  def get_switch_network_port_from_uid_ems(uid_ems)
    PhysicalNetworkPort.find_by(:connected_port_uid => uid_ems)
  end
end
