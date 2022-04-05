module ManageIQ::Providers::CiscoIntersight
  module PhysicalInfraManager::Operations::Lifecycle
    def recommission_server(server, options)
      _log.info("Requesting server recommission #{server.ems_ref}.")

      with_provider_connection do |_client|
        compute_api = IntersightClient::ComputeApi.new

        compute_blade_identity = IntersightClient::ComputeBladeIdentity.new(
          :admin_action            => 'Recommission',
          # Have to set this to nil as they are read-only and should not be present in the request payload.
          :firmware_supportability => nil,
          :presence                => nil,
          :lifecycle               => nil
        )

        begin
          result = compute_api.update_compute_blade_identity(server.ems_ref, compute_blade_identity, {})
          _log.info("Server #{server.ems_ref} recommissioned.")
        rescue IntersightClient::ApiError => e
          _log.error("Recommission of #{server.ems_ref} failed.")
          raise MiqException::Error, "Recommission of #{server.ems_ref} failed: #{e.response_body}"
        end
      end
    end

    def decommission_server(server, options)
      _log.info("Requesting server decommission #{server.ems_ref}.")

      with_provider_connection do |_client|
        compute_api = IntersightClient::ComputeApi.new

        # First, get the blade
        blade = compute_api.get_compute_blade_by_moid(server.ems_ref)

        compute_blade_identity = IntersightClient::ComputeBladeIdentity.new(
          :admin_action            => 'Decommission',
          # Have to set this to nil as they are read-only and should not be present in the request payload.
          :firmware_supportability => nil,
          :presence                => nil,
          :lifecycle               => nil
        )

        begin
          result = compute_api.update_compute_blade_identity(blade.mgmt_identity.moid, compute_blade_identity, {})
          _log.info("Server #{server.ems_ref} decommissioned.")
        rescue IntersightClient::ApiError => e
          _log.error("Recommission of #{server.ems_ref} failed.")
          raise MiqException::Error, "Decommission of #{server.ems_ref} failed: #{e.response_body}"
        end
      end
    end

  end
end

