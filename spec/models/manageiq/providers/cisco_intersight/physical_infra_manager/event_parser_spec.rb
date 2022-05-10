describe ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::EventParser do
  let(:event) do
    require "ostruct"
    OpenStruct.new(
      :moid     => "62043fa2696f6e2d307d186e",
      :name     => "Chassis Rediscover",
      :class_id => "workflow.WorkflowInfo",
      :mod_time => "2022-05-10 12:19:03 UTC"
    )
  end

  context ".event_to_hash" do
    it "parses event data" do
      expect(described_class.event_to_hash(event, 1234)).to(eq(
                                                              :ems_id     => 1234,
                                                              :ems_ref    => "62043fa2696f6e2d307d186e",
                                                              :event_type => "Chassis Rediscover",
                                                              :full_data  => JSON.parse(event.to_json),
                                                              :message    => " (Chassis Rediscover)",
                                                              :source     => "CiscoIntersight",
                                                              :timestamp  => "2022-05-10 12:19:03 UTC"
                                                            ))
    end
  end
end
