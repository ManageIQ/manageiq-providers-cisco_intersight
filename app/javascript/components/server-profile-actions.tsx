import React, { useEffect, useMemo } from "react";
import { useMiqDispatch } from "@@miq-redux/miq-hooks";
import MiqFormRenderer from "@@ddf";

import createSchema from "./server-profile-actions.schema";
import type {
  ApiErrorType,
  ApiResultsResponseType,
  FormOptions,
  OptionType,
  DirectActionProps,
  PhysicalServerDetailsResponseType,
  ResourcesResponseType,
  ModalActionType,
  ModalDataType,
  ServerProfileActionsProps,
  ServerProfileActionsValuesType,
} from "./server-profile-actions-types";

const fetchServerProfiles = (): Promise<OptionType[]> =>
  API.get<ResourcesResponseType>(
    "/api/physical_server_profiles?expand=resources&attributes=id,name",
  ).then(({ resources }) =>
    resources.map(({ id, name }) => ({ value: id, label: name })),
  );

const addResultsFlash = ({ results }: ApiResultsResponseType) => {
  results.forEach((result) =>
    add_flash(result.message, result.success ? "success" : "error"),
  );
};

const addErrorFlash = (error: ApiErrorType) => {
  add_flash(error.data?.error?.message || __("Unknown API error"), "error");
};

const handleActionResponse = (response: ApiResultsResponseType) => {
  if (!response?.results?.length) return;

  addResultsFlash(response);

  const { success, message, task_id: taskId } = response.results[0];
  if (success && taskId) {
    return API.wait_for_task(taskId)
      .then((taskResult) => add_flash(taskResult.message, "success"))
      .catch((error) =>
        add_flash(error?.message || __("Task failed"), "error"),
      );
  }
  add_flash(message, success ? "success" : "error");
};

const deployOrUnassign = (action: ModalActionType, serverId: string) =>
  API.get<PhysicalServerDetailsResponseType>(
    `/api/physical_servers/${serverId}?attributes=assigned_server_profile.id`,
  )
    .then((data) => {
      if (!data.assigned_server_profile?.id) {
        add_flash(
          sprintf(
            __("No server profile is assigned to server with ID %s"),
            serverId,
          ),
          "error",
        );
        return;
      }
      return API.post<ApiResultsResponseType>("/api/physical_server_profiles", {
        action,
        resources: [{ id: data.assigned_server_profile.id }],
      }).then(handleActionResponse);
    })
    .catch(addErrorFlash);

/**
 * In the server detail view, the Deploy/Unassign action doesn’t require server selection,
 * so it should trigger the API call directly without rendering the modal form
 */
const DirectAction: React.FC<DirectActionProps> = ({ action, onModalClose }) => {
  useEffect(() => {
    onModalClose();
    deployOrUnassign(action, `${ManageIQ.record.recordId}`);
  }, []);

  return null;
};

/**
 * Assign action form, rendered only in the server detail view,
 * where users can select a server profile
 */
const AssignForm: React.FC<ModalDataType> = ({ action }) => {
  const dispatch = useMiqDispatch();
  const serverProfilesPromise = useMemo(() => fetchServerProfiles(), []);
  // TODO: Modernize Redux - Convert form-buttons-reducer.js to Redux Toolkit slice
  // This would replace manual action types with auto-generated action creators:
  // dispatch(init({ saveable: true }));
  // dispatch(customLabel(__("Assign")));
  // dispatch(callbacks({ saveClicked: () => formOptions.submit() }));
  const initialize = (formOptions: FormOptions) => {
    dispatch({ type: "FormButtons.init", payload: { saveable: true } });
    dispatch({ type: "FormButtons.customLabel", payload: __("Assign") });
    dispatch({
      type: "FormButtons.callbacks",
      payload: { saveClicked: () => formOptions.submit() },
    });
  };
  const submitValues = (values: ServerProfileActionsValuesType) => {
    API.post<ApiResultsResponseType>("/api/physical_server_profiles", {
      action,
      resources: [
        { id: values.server_profile, server_id: ManageIQ.record.recordId },
      ],
    })
      .then(handleActionResponse)
      .catch(addErrorFlash);
  };

  return (
    <MiqFormRenderer
      schema={createSchema(serverProfilesPromise)}
      onSubmit={submitValues}
      showFormControls={false}
      initialize={initialize}
    />
  );
};

/**
 * Entry point, routes to the right sub-component
 */
const ServerProfileActions: React.FC<ServerProfileActionsProps> = ({
  onModalClose,
  modalData,
}) => {
  const isAssignAction = modalData.action === "assign_server";

  if (isAssignAction) {
    return <AssignForm action={"assign_server"} />;
  }
  return <DirectAction action={modalData.action} onModalClose={onModalClose} />;
};

export default ServerProfileActions;
