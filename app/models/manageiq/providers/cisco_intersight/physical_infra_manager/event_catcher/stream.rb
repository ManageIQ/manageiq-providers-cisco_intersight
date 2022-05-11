module ManageIQ::Providers::CiscoIntersight
  class PhysicalInfraManager::EventCatcher::Stream
    class ProviderUnreachable < ManageIQ::Providers::BaseManager::EventCatcher::Runner::TemporaryFailure
    end

    def initialize(ems, options = {})
      @ems = ems
      @last_activity = nil
      @stop_polling = false
      @poll_sleep = options[:poll_sleep] || 20.seconds
    end

    def start
      @stop_polling = false
    end

    def stop
      @stop_polling = true
    end

    def poll(&block)
      since = @ems.ems_events.order(:timestamp).pluck(:timestamp).last&.utc&.iso8601 || Time.new(2000).utc.iso8601
      loop do
        @ems.with_provider_connection do |api_client|
          catch(:stop_polling) do
            cond_api_opts = {
              :filter => "CreateTime gt #{since}",
            }
            events = IntersightClient::CondApi.new(api_client).get_cond_alarm_list(cond_api_opts).results
            workflow_api_opts = {
              :filter  => "ModTime gt #{since}",
              # Use only selected attributes. Validation of other within the SDK lib might fail:
              :select  => '$select=CreateTime,ModTime,Name,Status,Email,WorkflowCtx,ClassId,Message',
              :orderby => 'ModTime' # Orders elements in ascending order based on atribute ModTime
            }
            workflow_infos = IntersightClient::WorkflowApi.new(api_client).get_workflow_workflow_info_list(workflow_api_opts).results
            since = workflow_infos.last&.mod_time || since # Detect the most recently caught event and use that timestamp for since
            break if @stop_polling

            # Yield the events
            events.each(&block)
            workflow_infos.each(&block)
          rescue => exception
            raise ProviderUnreachable, exception.message
          end
        end
        sleep(@poll_sleep)
      end
    end
  end
end
