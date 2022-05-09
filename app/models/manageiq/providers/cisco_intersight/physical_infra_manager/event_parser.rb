module ManageIQ::Providers::CiscoIntersight
  class PhysicalInfraManager::EventParser
    def self.event_to_hash(event, ems_id)
      {
        :ems_id     => ems_id,
        :ems_ref    => event.moid,
        :event_type => "Alarm",
        :full_data  => JSON.parse(event.to_json),
        :message    => "#{event.description} (#{event.name})",
        :source     => "CiscoIntersight",
        :timestamp  => event.mod_time || Time.now.utc.to_s,
      }
    end
  end
end
