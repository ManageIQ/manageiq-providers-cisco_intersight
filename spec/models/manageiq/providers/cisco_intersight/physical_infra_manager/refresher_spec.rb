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
      end
    end
  end

  def assert_ems
    expect(ems.physical_servers.count).to eq(29)
    expect(ems.physical_server_details.count).to eq(29)
    expect(ems.physical_server_computer_systems.count).to eq(29)
    expect(ems.physical_server_hardwares.count).to eq(29)

    # In our available lab, we don't yet have a rack information.
    expect(ems.physical_racks.count).to eq(0)

    expect(ems.physical_chassis.count).to eq(7)
  end

  def assert_specific_physical_server
    s = ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalServer.where(
      :ems_ref => "5ed10e4a6176752d31a406fc"
    ).first

    expect(s).to have_attributes(
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

    expect(s.ext_management_system).to eq(ems)
  end
end

