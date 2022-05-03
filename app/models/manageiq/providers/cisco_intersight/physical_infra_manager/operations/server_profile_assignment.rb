module ManageIQ::Providers::CiscoIntersight
  module PhysicalInfraManager::Operations::ServerProfileAssignment
    def assign_server(server_profile, options)
      _log.info("Requesting server assignment on server profile #{server_profile.id} (ems_ref #{server_profile.ems_ref}), server ID #{options[:server_id]}")

      server = PhysicalServer.find_by(:id => options[:server_id], :ems_id => id)
      if server.nil?
        raise MiqException::Error, "Server with ID #{options[:server_id]} does not exist in EMS with ID #{id}"
      end

      source_object_type = nil
      with_provider_connection(:service => "ComputeApi") do |compute_api|
        ems_server = compute_api.get_compute_physical_summary_by_moid(server.ems_ref)
        source_object_type = ems_server.source_object_type
      end

      with_provider_connection(:service => "ServerApi") do |server_api|
        server_profile_updated = IntersightClient::ServerProfile.new(
          {
            :assigned_server        => {"Moid" => server.ems_ref, "ObjectType" => source_object_type},
            :server_assignment_mode => "Static",
            :target_platform        => nil,
            :uuid_address_type      => nil
          }
        )

        begin
          result = server_api.patch_server_profile(server_profile.ems_ref, server_profile_updated, {})
          _log.info("Server profile successfully assigned with server #{server.id} (ems_ref #{result.assigned_server.moid})")
        rescue IntersightClient::ApiError => e
          _log.error("Assign server failed for server profile (ems_ref #{server_profile.ems_ref}) server (ems_ref #{server.ems_ref})")
          raise MiqException::Error, "Assign server failed: #{e.response_body}"
        end
      end
    end

    def deploy_server(server_profile, _options)
      simple_action(server_profile, "Deploy")
    end

    def unassign_server(server_profile, _options)
      simple_action(server_profile, "Unassign")
    end

    private

    def simple_action(server_profile, action)
      _log.info("Requesting #{action} server profile #{server_profile.id} (ems_ref #{server_profile.ems_ref})")

      with_provider_connection(:service => "ServerApi") do |server_api|
        server_profile_updated = {"Action": action}

        begin
          result = server_api.patch_server_profile(server_profile.ems_ref, server_profile_updated, {})
          _log.info("Server profile #{result.config_context.control_action} initiated successfully")
        rescue IntersightClient::ApiError => e
          _log.error("#{action} server failed for server profile (ems_ref #{server_profile.ems_ref})")
          raise MiqException::Error, "#{action} server failed: #{e.response_body}"
        end
      end
    end
  end
end
