describe ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::EventCatcher do
  it '.ems_class' do
    expect(described_class.ems_class)
      .to(eq(ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager))
  end

  it ".settings_name" do
    expect(described_class.settings_name).to(eq(:event_catcher_cisco_intersight))
  end
end
