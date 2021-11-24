class ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::Vm < ManageIQ::Providers::PhysicalInfraManager::Vm
  def provider_object(connection = nil)
    connection ||= ext_management_system.connect
    connection.find_vm(ems_ref)
  end

  def raw_start
    with_provider_object(&:start)
    # Temporarily update state for quick UI response until refresh comes along
    update!(:raw_power_state => "on")
  end

  def raw_stop
    with_provider_object(&:stop)
    # Temporarily update state for quick UI response until refresh comes along
    update!(:raw_power_state => "off")
  end

  def raw_pause
    with_provider_object(&:pause)
    # Temporarily update state for quick UI response until refresh comes along
    update!(:raw_power_state => "paused")
  end

  def raw_suspend
    with_provider_object(&:suspend)
    # Temporarily update state for quick UI response until refresh comes along
    update!(:raw_power_state => "suspended")
  end

  # TODO: this method could be the default in a baseclass
  def self.calculate_power_state(raw_power_state)
    # do some mapping on powerstates
    # POWER_STATES[raw_power_state.to_s] || "terminated"
    raw_power_state
  end
end
