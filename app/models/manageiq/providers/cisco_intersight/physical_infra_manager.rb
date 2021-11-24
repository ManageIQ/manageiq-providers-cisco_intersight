module ManageIQ::Providers::CiscoIntersight
  class PhysicalInfraManager < ManageIQ::Providers::PhysicalInfraManager
    require_nested :MetricsCapture
    require_nested :MetricsCollectorWorker
    require_nested :Refresher
    require_nested :RefreshWorker
    require_nested :Vm
    require_nested :EventCatcher
    require_nested :EventParser
    require_nested :PhysicalServer


    include Vmdb::Logging
    include ManagerMixin
    include_concern "Operations"

    # TODO: This class represents a fake Ruby SDK with sample data.
    #       Remove this and use a real Ruby SDK in the raw_connect method
    class MyRubySDK
      def vms
        [
          OpenStruct.new(
            :id       => '1',
            :name     => 'funky',
            :location => 'dc-1',
            :vendor   => 'unknown'
          ),
          OpenStruct.new(
            :id       => '2',
            :name     => 'bunch',
            :location => 'dc-1',
            :vendor   => 'unknown'
          ),
        ]
      end

      def find_vm(id)
        vms.find { |v| v.id == id.to_s }
      end

      def events
        [
          OpenStruct.new(
            :name       => %w(instance_power_on instance_power_off).sample,
            :id         => Time.zone.now.to_i,
            :timestamp  => Time.zone.now,
            :vm_ems_ref => [1, 2].sample
          ),
          OpenStruct.new(
            :name       => %w(instance_power_on instance_power_off).sample,
            :id         => Time.zone.now.to_i + 1,
            :timestamp  => Time.zone.now,
            :vm_ems_ref => [1, 2].sample
          )
        ]
      end

      def metrics(start_time, end_time)
        timestamp = start_time
        metrics = {}
        while timestamp < end_time
          metrics[timestamp] = {
            'cpu_usage_rate_average'  => rand(100).to_f,
            'disk_usage_rate_average' => rand(100).to_f,
            'mem_usage_rate_average'  => rand(100).to_f,
            'net_usage_rate_average'  => rand(100).to_f,
          }
          timestamp += 20.seconds
        end
        metrics
      end
    end
  end

end
