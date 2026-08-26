import React, { useMemo } from "react";
import { useMiqDispatch } from "@@miq-redux/miq-hooks";
import MiqFormRenderer from "@@ddf";

import createSchema from "./server-profile-form.schema";
import type {
  ApiErrorType,
  ApiResultsResponseType,
  FormOptions,
  OptionType,
  PhysicalServerDetailsResponseType,
  ResourcesResponseType,
  ServerProfileFormProps,
  ServerProfileFormValues,
} from "./server-profile-form-types";

const fetchServerProfiles = (): Promise<OptionType[]> =>
  API.get<ResourcesResponseType>(
    "/api/physical_server_profiles?expand=resources&attributes=id,name",
  ).then(({ resources }) =>
    resources.map(({ id, name }) => ({ value: id, label: name })),
  );

const fetchPhysicalServers = (): Promise<OptionType[]> =>
  API.get<ResourcesResponseType>(
    "/api/physical_servers?expand=resources&attributes=id,name",
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

const ServerProfileForm: React.FC<ServerProfileFormProps> = ({ modalData }) => {
  const dispatch = useMiqDispatch();
  const serverProfilesPromise = useMemo(() => fetchServerProfiles(), []);
  const physicalServersPromise = useMemo(() => fetchPhysicalServers(), []);

  const serverProfileVisible = modalData.action === "assign_server";

  let submitLabel = __("Unassign");
  if (serverProfileVisible) {
    submitLabel = __("Assign");
  } else if (modalData.action === "deploy_server") {
    submitLabel = __("Deploy");
  }

  const initialize = (formOptions: FormOptions) => {
    // TODO: Modernize Redux - Convert form-buttons-reducer.js to Redux Toolkit slice
    // This would replace manual action types with auto-generated action creators:
    // dispatch(init({ saveable: true }));
    // dispatch(customLabel(submitLabel));
    // dispatch(callbacks({ saveClicked: () => formOptions.submit() }));
    dispatch({ type: "FormButtons.init", payload: { saveable: true } });
    dispatch({ type: "FormButtons.customLabel", payload: submitLabel });
    dispatch({
      type: "FormButtons.callbacks",
      payload: { saveClicked: () => formOptions.submit() },
    });
  };

  const submitValues = (values: ServerProfileFormValues) => {
    if (serverProfileVisible) {
      API.post<ApiResultsResponseType>("/api/physical_server_profiles", {
        action: modalData.action,
        resources: [
          {
            id: values.server_profile,
            server_id: ManageIQ.record.recordId,
          },
        ],
      })
        .then(addResultsFlash)
        .catch(addErrorFlash);

      return;
    }

    API.get<PhysicalServerDetailsResponseType>(
      `/api/physical_servers/${ManageIQ.record.recordId}?attributes=assigned_server_profile.id`,
    )
      .then((data) =>
        API.post<ApiResultsResponseType>("/api/physical_server_profiles", {
          action: modalData.action,
          resources: [
            {
              id: data.assigned_server_profile.id,
            },
          ],
        }),
      )
      .then(addResultsFlash)
      .catch(addErrorFlash);
  };

  return (
    <MiqFormRenderer
      schema={createSchema(
        serverProfilesPromise,
        physicalServersPromise,
        serverProfileVisible,
      )}
      onSubmit={submitValues}
      showFormControls={false}
      initialize={initialize}
    />
  );
};

export default ServerProfileForm;
