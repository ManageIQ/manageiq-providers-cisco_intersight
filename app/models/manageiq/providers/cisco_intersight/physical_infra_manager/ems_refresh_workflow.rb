class ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::EmsRefreshWorkflow < ManageIQ::Providers::EmsRefreshWorkflow
  def run_native_op
    queue_signal(:poll_native_task)
  end
  alias start run_native_op

  def poll_native_task
    wf_api = ext_management_system.connect(:service=>'WorkflowApi')
    native_object_response = wf_api.get_workflow_workflow_info_list({:filter => "Input.workflowContext.WorkflowType eq 'serverconfig' and Input.workflowContext.WorkflowSubtype eq 'Deploy' and Input.workflowContext.InitiatorCtx.InitiatorMoid eq '#{options[:native_task_id]}'", :select => "Status"})
    native_object = native_object_response.results[0]

    case native_object.status
    when "FAILED"
      signal(:abort, "Task failed")
    when "TIME_OUT"
      signal(:abort, "Task time out")
    when "COMPLETED"
      queue_signal(:refresh)
    else
      queue_signal(:poll_native_task, :deliver_on => Time.now.utc + options[:interval])
    end
  rescue => err
    _log.log_backtrace(err)
    signal(:abort, err.message, "error")
  end

  def refresh
    task_ids = EmsRefresh.queue_refresh_task(ext_management_system)
    if task_ids.blank?
      process_error("Failed to queue refresh", "error")
      queue_signal(:error)
    else
      context[:refresh_task_ids] = task_ids
      update!(:context => context)

      queue_signal(:poll_refresh)
    end
  end

  def ext_management_system
    @ext_management_system ||= ExtManagementSystem.find(options[:ems_id])
  end
end
