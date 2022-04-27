describe ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager do
  it ".ems_type" do
    expect(described_class.ems_type).to eq("cisco_intersight")
  end

  it ".description" do
    expect(described_class.description).to eq("Cisco Intersight")
  end

  let(:ems)         { FactoryBot.create(:ems_cisco_intersight_physical_infra, :auth) }
  let(:config_mock) { double("IntersightClient::Configuration") }

  context ".raw_connect" do
    it "connects with key_id and secret key" do
      expect(IntersightClient::Configuration).to receive(:new).and_yield(config_mock)
      expect(config_mock).to receive(:api_key_id=).with("keyid")
      expect(config_mock).to receive(:api_key=).with("secretkey")

      described_class.raw_connect("keyid", "secretkey")
    end
  end

  context "#connect" do
    it "aborts on missing credentials" do
      ems = FactoryBot.create(:ems_cisco_intersight_physical_infra)
      expect { ems.connect }.to raise_error(MiqException::MiqHostError)
    end

    it "connects with key_id and secret key" do
      expect(IntersightClient::Configuration).to receive(:new).and_yield(config_mock)
      expect(config_mock).to receive(:api_key_id=).with("keyid")
      expect(config_mock).to receive(:api_key=).with("secretkey")

      ems.connect
    end
  end
end
