module ManageIQ::Providers::CiscoIntersight
  class PhysicalInfraManager::PhysicalServer < ::PhysicalServer
    include_concern 'Provisioning'

    supports :decommission do
      unsupported_reason_add(:decommission, _("You cannot decommission a server while it's not powerered off.")) unless power_state == "off"
      # equivalently: ... if (power_state == "on" or power_state == "decomissioned")
    end

    supports :recommission do
      unsupported_reason_add(:recommission, _("You cannot recommission a server if the server is active.")) unless power_state == "decomissioned"
      # equivalently: ... if (power_state == "off" or power_state == "on"); meaning: The server is active
    end

    def self.display_name(number = 1)
      n_('Physical Server (CiscoIntersight)', 'Physical Servers (CiscoIntersight)', number)
    end

    def provider_object(connection)
      connection.find!(ems_ref)
    end

    def power_down
      change_state(:power_down)
    end

    def power_up
      change_state(:power_up)
    end
  end
end

