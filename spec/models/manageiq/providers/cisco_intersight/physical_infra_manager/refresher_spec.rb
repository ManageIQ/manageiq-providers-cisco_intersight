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
        assert_specific_physical_server
        assert_specific_physical_server_details
        assert_specific_physical_server_hardwares
        assert_specific_physical_server_firmwares
        assert_specific_physical_server_network_devices
        assert_specific_physical_chassis
        assert_specific_physical_chassis_details
      end
    end
  end

  def assert_ems
    expect(ems.physical_servers.count).to eq(29)
    expect(ems.physical_server_details.count).to eq(29)
    expect(ems.physical_server_computer_systems.count).to eq(29)
    expect(ems.physical_server_hardwares.count).to eq(29)
    expect(ems.physical_server_firmwares.count).to eq(45)

    # In our available lab, we don't yet have a rack information.
    expect(ems.physical_racks.count).to eq(0)

    expect(ems.physical_chassis.count).to eq(7)
    expect(ems.physical_chassis_details.count).to eq(7)
    expect(ems.physical_server_network_devices.count).to eq(55)
  end

  def assert_specific_physical_server
    server_ems_ref = "5ed10e4a6176752d31a406fc"
    server = get_physical_server_from_ems_ref(server_ems_ref)

    expect(server).to have_attributes(
      :ems_ref                => "5ed10e4a6176752d31a406fc",
      :hostname               => "CLABS000D000F001",
      :type                   => "ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalServer",
      :product_name           => nil,
      :manufacturer           => nil,
      :machine_type           => nil,
      :model                  => nil,
      :serial_number          => nil,
      :field_replaceable_unit => nil,
      :raw_power_state        => "policy",
      :vendor                 => nil,
    )

    expect(server.ext_management_system).to eq(ems)
  end

  def assert_specific_physical_server_details
    server_ems_ref = "5ed10e4a6176752d31a406fc"
    server = get_physical_server_from_ems_ref(server_ems_ref)
    asset_detail = AssetDetail.find_by!(:resource => server)

    expect(asset_detail).to have_attributes(
      :description => "UCS 6332-16UP 1RU FI/No PSU/24 QSFP+ 16UP/4x40G Lic/8xUP Lic",
      :contact => nil,
      :location => "IBM TUCSON LAB 11619032-1, 9000 S RITA RD, 85744-0002, 85744-0002, TUCSON, US",
      :room => "2",
      :rack_name => nil,
      :lowest_rack_unit => nil,
      :resource_type => "PhysicalServer",
      :product_name => "CLABS000D000F001-2-2",
      :machine_type => "CiscoUcsFI",
      :model => "UCSB-B200-M5",
      :serial_number => "FLM23490685",
      :field_replaceable_unit => nil,
      :part_number => nil,
      :location_led_ems_ref => nil,
      :location_led_state => "off",
    )
  end

  def assert_specific_physical_server_hardwares
    server_ems_ref = "5ed10e4a6176752d31a406fc"
    server = get_physical_server_from_ems_ref(server_ems_ref)
    hardware = server.hardware

    expect(hardware).to have_attributes(
      :virtual_hw_version => nil,
      :config_version => nil,
      :guest_os => nil,
      :cpu_sockets => 1,
      :bios => nil, :bios_location => nil,
      :time_sync => nil,
      :annotation => nil,
      :vm_or_template_id => nil,
      :memory_mb => 393216,
      :host_id => nil,
      :cpu_speed => 100,
      :cpu_type => nil,
      :size_on_disk => nil,
      :manufacturer => "",
      :model => "",
      :number_of_nics => nil,
      :cpu_usage => nil,
      :memory_usage => nil,
      :cpu_cores_per_socket => nil,
      :cpu_total_cores => 40,
      :vmotion_enabled => nil,
      :disk_free_space => nil,
      :disk_capacity => nil,
      :guest_os_full_name => nil,
      :memory_console => nil,
      :bitness => nil,
      :virtualization_type => nil,
      :root_device_type => nil,
      :disk_size_minimum => nil,
      :memory_mb_minimum => nil,
      :introspected => nil,
      :provision_state => nil,
      :serial_number => nil,
      :switch_id => nil,
      :firmware_type => nil,
      :canister_id => nil
    )

  end

  def assert_specific_physical_server_firmwares
    server_ems_ref = "614cec406176752d35abe2dc"
    server = get_physical_server_from_ems_ref(server_ems_ref)
    firmware = server.hardware.firmwares.first

    expect(firmware).to have_attributes(
      :name            => "BIOS",
      :build           => "BIOS",
      :version         => "B210M6.4.1.5a.0.0324212030",
      :release_date    => nil,
      :resource_type   => "Hardware",
      :guest_device_id => nil,
    )
  end

  def assert_specific_physical_server_network_devices
    server_ems_ref = "614cec406176752d35abe2dc"
    server = get_physical_server_from_ems_ref(server_ems_ref)
    nic = server.hardware.nics.first

    expect(nic).to have_attributes(
      :device_name            => "LAB02D02F01-1-2",
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
      :model                  => "",
      :iscsi_name             => nil,
      :iscsi_alias            => nil,
      :present                => true,
      :start_connected        => true,
      :auto_detect            => nil,
      :uid_ems                => "614cec8c6176752d35ac0525",
      :chap_auth_enabled      => nil,
      :manufacturer           => "unknown",
      :field_replaceable_unit => nil,
      :parent_device_id       => nil,
      :vlan_key               => nil,
      :vlan_enabled           => nil,
      :peer_mac_address       => nil,
      :speed                  => nil
    )
  end

  def assert_specific_physical_chassis
    chassis_ems_ref = "5ed10e4b6176752d31a40743"
    chassis = get_physical_chassis_from_ems_ref(chassis_ems_ref)

    expect(chassis).to have_attributes(
     :uid_ems                      => nil,
     :type                         => "ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalChassis",
     :health_state                 => "Valid",
     :overall_health_state         => nil,
     :management_module_slot_count => nil,
     :switch_slot_count            => nil,
     :fan_slot_count               => nil,
     :blade_slot_count             => nil,
     :powersupply_slot_count       => nil,
     :parent_physical_chassis_id   => nil,
     )

    expect(chassis.ext_management_system).to eq(ems)
  end

  def assert_specific_physical_chassis_details
    chassis_ems_ref = "5ed10e4b6176752d31a40743"
    chassis = get_physical_chassis_from_ems_ref(chassis_ems_ref)
    asset_detail = AssetDetail.find_by!(:resource => chassis)

    expect(asset_detail).to have_attributes(
     :description            => "UCS 6332-16UP 1RU FI/No PSU/24 QSFP+ 16UP/4x40G Lic/8xUP Lic",
     :location               => "IBM TUCSON LAB 11619032-1, 9000 S RITA RD, 85744-0002, 85744-0002, TUCSON, US",
     :room                   => nil,
     :contact                => nil,
     :rack_name              => nil,
     :lowest_rack_unit       => nil,
     :resource_type          => "PhysicalChassis",
     :product_name           => nil,
     :manufacturer           => nil,
     :machine_type           => nil,
     :model                  => "UCSB-5108-AC2",
     :serial_number          => "FOX2337P25E",
     :field_replaceable_unit => nil,
     :part_number            => "68-5091-06",
     :location_led_ems_ref   => nil,
     :location_led_state     => nil,
     )
  end

  def get_physical_server_from_ems_ref(ems_ref)
    PhysicalServer.find_by(:ems_ref => ems_ref)
  end

  def get_physical_chassis_from_ems_ref(ems_ref)
    PhysicalChassis.find_by(:ems_ref => ems_ref)
  end

end

