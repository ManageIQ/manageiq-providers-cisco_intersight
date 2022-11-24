module ManageIQ::Providers::CiscoIntersight
  class PhysicalInfraManager::PhysicalServerProfileTemplate < ::PhysicalServerProfileTemplate
    def self.display_name(number = 1)
      n_('Physical Server Profile Template (CiscoIntersight)', 'Physical Server Profile Template (CiscoIntersight)', number)
    end

    def provider_object(connection)
      connection.find!(ems_ref)
    end


    def deploy_server_from_template(server_id, profile_name)
      # Load the gem
      require 'intersight_client'

      bulk = ext_management_system.connect(:service=>'BulkApi')
      cloner = IntersightClient::BulkMoCloner.new({:sources => [{"Moid" => ems_ref, "ObjectType" => 'server.ProfileTemplate'}], :targets => [{"Name" => profile_name, :ObjectType => 'server.Profile'}]})

      # create a new server profile from server profile template

      result = bulk.create_bulk_mo_cloner(cloner)
      new_profile_moid = result.responses[0].body.moid

      server_profile_updated = IntersightClient::ServerProfile.new(
        {
          :assigned_server        => {"Moid" => server_id, "ObjectType" => "compute.Blade"},
          :server_assignment_mode => "Static",
          :target_platform        => nil,
          :uuid_address_type      => nil
        }
      )
      # assign the profile server to the selected server
      server_api = ext_management_system.connect(:service=>'ServerApi')
      begin
        result = server_api.patch_server_profile(new_profile_moid, server_profile_updated, {})
        _log.info("Server profile successfully assigned with server #{server_id} (ems_ref #{result.assigned_server.moid})")
      rescue IntersightClient::ApiError => e
        _log.error("Assign server failed for server profile (ems_ref #{new_profile_moid}) server (ems_ref #{server_id})")
        raise MiqException::Error, "Assign server failed: #{e.response_body}"
      end

      server_profile_updated = {'Action' => "Deploy"}
      # deploy the server
      begin
        result = server_api.patch_server_profile(new_profile_moid, server_profile_updated, {})
        _log.info("Server profile #{result.config_context.control_action} initiated successfully")
      rescue IntersightClient::ApiError => e
        _log.error("#{action} server failed for server profile (ems_ref #{new_profile_moid})")
        raise MiqException::Error, "#Deploy server failed: #{e.response_body}"
      end

      # create a job to refresh the cisco intersight provider after the deployment finished
      options = {
        :target_class   =>self.class.name,
        :target_id      => id,
        :ems_id         => ext_management_system.id,
        :native_task_id => new_profile_moid,
        :interval       => 30.seconds,
        :target_option  => "deploy"
      }

      ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::EmsRefreshWorkflow.create_job(options).tap { |job| job.signal(:start) }
    end
  end
end
