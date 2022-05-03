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

    def poll
      @ems.with_provider_connection do |api_client|
        catch(:stop_polling) do
          events = IntersightClient::CondApi.new(api_client).get_cond_alarm_list.results
          events.each { |event| yield event }
        rescue => exception
          raise ProviderUnreachable, exception.message
        end
      end
    end
  end
end
