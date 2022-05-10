module ManageIQ::Providers::CiscoIntersight
  class PhysicalInfraManager::EventParser
    def self.event_to_hash(event, ems_id)
      # event.class_id will be always equal to either "cond.Alarm" or "workflow.WorkflowInfo". Just in case this
      # doesn't happen, nil value gets returned
      case event.class_id
      when "cond.Alarm"
        {
          :ems_id     => ems_id,
          :ems_ref    => event.moid,
          :event_type => "Alarm",
          :full_data  => JSON.parse(event.to_json),
          :message    => "#{event.description} (#{event.name})",
          :source     => "CiscoIntersight",
          :timestamp  => event.mod_time || Time.now.utc.to_s,
        }
      when "workflow.WorkflowInfo"
        {
          :ems_id     => ems_id,
          :ems_ref    => event.moid,
          :event_type => event.name,
          :full_data  => JSON.parse(event.to_json),
          :message    => "#{event.message&.first&.message} (#{event.name})",
          :source     => "CiscoIntersight",
          :timestamp  => event.mod_time || Time.now.utc.to_s,
        }
      end
    end
  end
end
