require 'intersight_client'

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
      expect(config_mock).to receive(:scheme=).with("https")
      expect(config_mock).to receive(:host=).with("intersight.com:443")
      expect(config_mock).to receive(:verify_ssl=).with(true)
      expect(config_mock).to receive(:api_key_id=).with("keyid")
      expect(config_mock).to receive(:api_key=).with("secretkey")

      described_class.raw_connect("https://intersight.com", OpenSSL::SSL::VERIFY_PEER, "keyid", "secretkey")
    end

    it "defaults to url=https://intersight.com and verify_ssl=true" do
      expect(IntersightClient::Configuration).to receive(:new).and_yield(config_mock)
      expect(config_mock).to receive(:scheme=).with("https")
      expect(config_mock).to receive(:host=).with("intersight.com:443")
      expect(config_mock).to receive(:verify_ssl=).with(true)
      expect(config_mock).to receive(:api_key_id=).with("keyid")
      expect(config_mock).to receive(:api_key=).with("secretkey")

      described_class.raw_connect(nil, nil, "keyid", "secretkey")
    end
  end

  context "#pause!" do
    let(:zone) { FactoryBot.create(:zone) }
    let(:ems)  { FactoryBot.create(:ems_cisco_intersight_physical_infra, :zone => zone) }

    include_examples "ExtManagementSystem#pause!"
  end

  context "#resume!" do
    let(:zone) { FactoryBot.create(:zone) }
    let(:ems)  { FactoryBot.create(:ems_cisco_intersight_physical_infra, :zone => zone) }

    include_examples "ExtManagementSystem#resume!"
  end

  context "#connect" do
    context "with missing credentials" do
      let(:ems) { FactoryBot.create(:ems_cisco_intersight_physical_infra) }

      it "aborts" do
        expect { ems.connect }.to raise_error(MiqException::MiqHostError)
      end
    end

    it "connects with key_id and secret key" do
      expect(IntersightClient::Configuration).to receive(:new).and_yield(config_mock)
      expect(config_mock).to receive(:scheme=).with("https")
      expect(config_mock).to receive(:host=).with("intersight.com:443")
      expect(config_mock).to receive(:verify_ssl=).with(true)
      expect(config_mock).to receive(:api_key_id=).with("keyid")
      expect(config_mock).to receive(:api_key=).with("secretkey")

      ems.connect
    end

    context "with an alternate URL" do
      let(:url) { "http://intersight.localdomain:8080" }
      let(:ems) do
        FactoryBot.create(:ems_cisco_intersight_physical_infra, :auth).tap do |ems|
          ems.default_endpoint.url = url
          ems.default_endpoint.verify_ssl = OpenSSL::SSL::VERIFY_NONE
        end
      end

      it "connects with the alternate host" do
        expect(IntersightClient::Configuration).to receive(:new).and_yield(config_mock)
        expect(config_mock).to receive(:scheme=).with("http")
        expect(config_mock).to receive(:host=).with("intersight.localdomain:8080")
        expect(config_mock).to receive(:verify_ssl=).with(false)
        expect(config_mock).to receive(:api_key_id=).with("keyid")
        expect(config_mock).to receive(:api_key=).with("secretkey")

        ems.connect
      end
    end
  end
end
