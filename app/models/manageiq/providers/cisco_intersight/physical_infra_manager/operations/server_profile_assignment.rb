module ManageIQ::Providers::CiscoIntersight
  module PhysicalInfraManager::Operations::ServerProfileAssignment
    def assign_server(server_profile, options)
      _log.info("Requesting server assignment on server profile #{server_profile.id} (ems_ref #{server_profile.ems_ref})")

      with_provider_connection do |_client|
        server = PhysicalServer.find_by(:id => options[:server_id], :ems_id => id)
        if server.nil?
          raise MiqException::Error, "Server with ID #{options[:server_id]} does not exist in EMS with ID #{id}"
        end

        server_api = IntersightClient::ServerApi.new
        compute_api = IntersightClient::ComputeApi.new

        ems_server = compute_api.get_compute_physical_summary_by_moid(server.ems_ref)

        server_profile_updated = IntersightClient::ServerProfile.new(
          {
            :assigned_server => {"Moid" => server.ems_ref, "ObjectType" => ems_server.source_object_type},
            :server_assignment_mode => "Static",
            :target_platform => nil,
            :uuid_address_type => nil
          }
        )

        begin
          result = server_api.patch_server_profile(server_profile.ems_ref, server_profile_updated, {})
          _log.info("Server profile assigned with server #{server.id} (ems_ref #{result.assigned_server.moid})")
        rescue IntersightClient::ApiError => e
          _log.error("Assign server failed for server profile (ems_ref #{server_profile.ems_ref}) server (ems_ref #{server.ems_ref})")
          raise MiqException::Error, "Assign server failed: #{e.response_body}"
        end
      end
    end

    def deploy_server(server_profile, _options)
      # TODO
      raise "not implemented"
    end

    def unassign_server(server_profile, _options)
      # TODO
      raise "not implemented"
    end
  end
end