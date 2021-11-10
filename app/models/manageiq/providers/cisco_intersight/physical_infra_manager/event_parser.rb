module ManageIQ::Providers::CiscoIntersight
  class PhysicalInfraManager::EventParser
    def self.event_to_hash(event, ems_id)
      {
        :ems_id     => ems_id,
        :ems_ref    => event["EventId"],
        :event_type => "CiscoIntersight_#{event["MessageId"]}",
        :full_data  => event,
        :message    => event["Message"],
        :source     => "CiscoIntersight",
        :timestamp  => event["EventTimestamp"] || Time.now.utc.to_s,
      }
    end
  end
end
