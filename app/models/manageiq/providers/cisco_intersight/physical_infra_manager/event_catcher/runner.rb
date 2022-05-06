module ManageIQ::Providers::CiscoIntersight
  class PhysicalInfraManager::EventCatcher::Runner < ManageIQ::Providers::BaseManager::EventCatcher::Runner
    # This is the main method run in the first thread by the core event catcher runner.
    # It is responsible for retrieving events from the provider and putting them on
    # an internal queue for the core runner thread to parse and put on MiqQueue.
    #
    # Additional comment (Tjaz): All functions except event_monitor_handle are pretty much
    #   the same across all providers. event_monitor_handle and the Stream class need to be changed
    def monitor_events
      event_monitor_handle.start
      event_monitor_running
      event_monitor_handle.poll do |event|
        @queue.enq(event)
      end
    ensure
      stop_event_monitor
    end

    # This method is called by core when shutting down the event catcher
    def stop_event_monitor
      event_monitor_handle.stop
    end

    # This is called by the core runner thread to parse and put the event on the queue.
    def queue_event(event)
      _log.info("#{log_prefix} Caught event [#{event.moid}]")
      event_hash = ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::EventParser.event_to_hash(event, @cfg[:ems_id])
      EmsEvent.add_queue('add', @cfg[:ems_id], event_hash)
    end

    private

    # Stream encapsulates the logic of fetching events from the provider.
    #
    # TODO: Change method poll inside Stream
    def event_monitor_handle
      @event_monitor_handle ||= ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::EventCatcher::Stream.new(
        @ems, :poll_sleep => worker_settings[:poll]
      )
    end
  end
end
