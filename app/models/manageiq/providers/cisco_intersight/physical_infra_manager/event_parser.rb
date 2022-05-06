module ManageIQ::Providers::CiscoIntersight
  class PhysicalInfraManager::EventParser
    def self.event_to_hash(event, ems_id)
      {
        :ems_id     => ems_id,
        :ems_ref    => event.moid,
        :event_type => event.orig_severity,
        :full_data  => JSON.parse(event.to_json),
        :message    => event.description,
        :source     => "CiscoIntersight",
        :timestamp  => event.mod_time || Time.now.utc.to_s,
      }
    end
  end
end
