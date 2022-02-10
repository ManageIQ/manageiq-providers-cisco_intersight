describe ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager do
  it ".ems_type" do
    expect(described_class.ems_type).to eq("cisco_intersight")
  end

  it ".description" do
    expect(described_class.description).to eq("Cisco Intersight")
  end

  let(:ci_module) { class_double("IntersightClient").as_stubbed_const }
  let(:ci_client) { instance_double("RedfishClient::Root") }
  subject(:ems) do
    FactoryBot.create(:ems_cisco_intersight_physical_infra, :auth)
  end
  let(:config_mock) { double }

  context ".raw_connect" do
    it "connects with key_id and secret key" do
      expect(ci_module).to receive(:configure).and_yield(config_mock)
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
      expect(ci_module).to receive(:configure).and_yield(config_mock)
      expect(config_mock).to receive(:api_key_id=).with("keyid")
      expect(config_mock).to receive(:api_key=).with("secretkey")
      ems.connect
    end

  end
end
