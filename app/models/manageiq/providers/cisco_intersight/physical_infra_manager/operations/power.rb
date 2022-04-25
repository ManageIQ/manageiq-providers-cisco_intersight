module ManageIQ::Providers::CiscoIntersight
  module PhysicalInfraManager::Operations::Power
    # See app/models/physical_server/operations/power.rb in core.

    def power_on(server, _options)
      reset_server(server, "PowerOn")
    end

    def power_off(server, _options)
      reset_server(server, "PowerOff")
    end

    def power_off_now(server, _options)
      reset_server(server, "ForceOff")
    end

    def restart(server, _options)
      reset_server(server, "PowerCycle")
    end

    def restart_now(server, _options)
      reset_server(server, "HardReset")
    end

    def restart_to_sys_setup(_args, _options)
      _log.error("Restarting to system setup is not supported.")
      raise MiqException::Error, "Restarting to system setup is not supported."
    end

    def restart_mgmt_controller(_server, _options)
      reset_server(server, "Reboot")
    end

    private

    def reset_server(server, power_state)
      # Changing the admin_power_state attribute in IntersightClient::ComputeServerSetting object according to power_state
      # Possible values for admin_power_state:
      # @see https://github.com/xlab-si/intersight-sdk-ruby/blob/45ec426b9d061502166499a755ac119058002972/lib/intersight_client/models/compute_server_setting.rb#L28
      #   - admin_power_state == `Policy` - Power state is set to the default value in the policy
      #     [Meaning: look at result of IntersightClient::PowerApi.new.get_power_policy_list (select the relevant element according to moid of the server)]
      #   - admin_power_state == `PowerOn` - Power state of the server is set to On.
      #   - admin_power_state == `PowerOff` - Power state of the server is set to Off.
      #   - admin_power_state == `PowerCycle` - Power state of the server is reset.
      #   - admin_power_state == `HardReset` - Power state of the server is hard reset.
      #   - admin_power_state == `Shutdown` - Operating system on the server is shut down.
      #   - admin_power_state == `Reboot` - Power state of IMC is rebooted.

      _log.info("Requesting #{power_state} for #{server.ems_ref}.")

      with_provider_connection do |api_client|
        compute_api = IntersightClient::ComputeApi.new(api_client)
        _system = compute_api.get_compute_physical_summary_by_moid(server.ems_ref)

        # Get the related ComputeServerSettings:
        # This only works for servers that are Intersight-managed and have a directly related IntersightClient::ComputeServerSetting object
        compute_server_settings_list = compute_api.get_compute_server_setting_list({:filter => "(Server.Moid eq '#{server.ems_ref}')"}).results

        if compute_server_settings_list.empty?
          raise MiqException::Error, "No IntersightClient::ComputeServerSetting object found for ems_ref #{server.ems_ref} . Server might not be Intersight-managed."
        end

        compute_server_settings = compute_server_settings_list.first

        previous_admin_power_state = compute_server_settings.admin_power_state

        # Use of PATCH method to change the attribute admin_power_state in IntersightClient::ComputeServerSetting object
        compute_server_setting_updated = IntersightClient::ComputeServerSetting.new(
          {:admin_power_state => power_state}
        )
        begin
          result = compute_api.patch_compute_server_setting(compute_server_settings.moid, compute_server_setting_updated, {})
          _log.info("Updated power_state of the server from #{previous_admin_power_state} to #{result.admin_power_state}")
        rescue IntersightClient::ApiError => e
          _log.error("#{power_state} for #{server.ems_ref} failed.")
          raise MiqException::Error, "#{power_state} failed: #{e.response_body}"
          # Note: errors are not indicated on the MiQ UI
        end
      end
    end
  end
end
