module ManageIQ::Providers::CiscoIntersight
  class PhysicalInfraManager::PhysicalServerProfileTemplate < ::PhysicalServerProfileTemplate
    def self.display_name(number = 1)
      n_('Physical Server Profile Template (CiscoIntersight)', 'Physical Server Profile Template (CiscoIntersight)', number)
    end

    def provider_object(connection)
      connection.find!(ems_ref)
    end

    def deploy_server_from_template_queue(server_id, profile_name)
      task_opts = {
        :action => "Deploy server from profile template",
      }

      queue_opts = {
        :class_name  => self.class.name,
        :method_name => 'deploy_server_from_template',
        :role        => 'ems_operations',
        :queue_name  => ext_management_system.queue_name_for_ems_operations,
        :zone        => ext_management_system.my_zone,
        :args        => [ems_ref, server_id, profile_name, ext_management_system.id]
      }

      MiqTask.generic_action_with_callback(task_opts, queue_opts)
    end

    def self.deploy_server_from_template(template_id, server_id, profile_name, ext_management_system_id)
      # Load the gem
      require 'intersight_client'

      bulk = ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager.first.connect(:service=>'BulkApi')
      cloner = IntersightClient::BulkMoCloner.new({:sources => [{"Moid" => template_id, "ObjectType" => 'server.ProfileTemplate'}], :targets => [{"Name" => profile_name, :ObjectType => 'server.Profile'}]})

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
      server_api = ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager.first.connect(:service=>'ServerApi')
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
        :target_class   => "ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalServerProfileTemplate",
        :target_id      => nil,
        :ems_id         => ext_management_system_id,
        :native_task_id => new_profile_moid,
        :interval       => 30.seconds,
        :target_option  => "deploy"
      }

      ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::EmsRefreshWorkflow.create_job(options).tap { |job| job.signal(:start) }
    end
  end
end
