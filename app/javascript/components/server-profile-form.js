import React, { useEffect, useMemo } from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import MiqFormRenderer from '@@ddf';

import createSchema from './server-profile-form.schema';

const fetchServerProfiles = (serverId) =>
  API.get(
    '/api/physical_server_profiles?expand=resources&attributes=id,name'
  ).then(({ resources }) =>
    resources.map(({ id, name }) => ({ value: id, label: name })));

const fetchPhysicalServers = () =>
  API.get(
    '/api/physical_servers?expand=resources&attributes=id,name'
  ).then(({ resources }) =>
    resources.map(({ id, name }) => ({ value: id, label: name })));

const ServerProfileForm = ({ dispatch, modalData }) => {
  const serverProfilesPromise = useMemo(() => fetchServerProfiles());
  const physicalServersPromise = useMemo(() => fetchPhysicalServers());

  let submitLabel = '';
  let serverProfileVisible = false;
  if (modalData.action === 'assign_server') {
    submitLabel = __('Assign');
    serverProfileVisible = true;
  } else {
    submitLabel = (modalData.action === 'deploy_server' ? __('Deploy') : __('Unassign'));
  }

  const initialize = (formOptions) => {
    dispatch({ type: 'FormButtons.init',        payload: { saveable: true }, });
    dispatch({ type: "FormButtons.customLabel", payload: submitLabel, }); 
    dispatch({ type: 'FormButtons.callbacks',   payload: { saveClicked: () => formOptions.submit() }, });
  };

  const submitValues = (values) => {
    if (modalData.action === 'assign_server') {
      API.post('/api/physical_server_profiles', {
        action: modalData.action,
        resources: [{ 
          id:        values['server_profile'],
          server_id: ManageIQ.record.recordId
        }],
      }).then(({ results }) =>
        results.forEach((res) => window.add_flash(res.message, res.success ? "success" : "error"))
      ).catch((err) => {
        window.add_flash(err.data && err.data.error && err.data.error.message || __('Unknown API error'), "error");
      });
    } else {
      API.get(
        `/api/physical_servers/${ManageIQ.record.recordId}?attributes=assigned_server_profile.id`
      ).then((data) => {
        API.post('/api/physical_server_profiles', {
          action: modalData.action,
          resources: [{ 
            id: data.assigned_server_profile.id,
          }],
        }).then(({ results }) =>
          results.forEach((res) => window.add_flash(res.message, res.success ? "success" : "error"))
        ).catch((err) => {
          window.add_flash(err.data && err.data.error && err.data.error.message || __('Unknown API error'), "error");
        });
      });
    }
  };

  return (
    <MiqFormRenderer
      schema={createSchema(serverProfilesPromise, physicalServersPromise, serverProfileVisible)}
      onSubmit={submitValues}
      showFormControls={false}
      initialize={initialize}
    />
  )
};

ServerProfileForm.propTypes = {
  serverProfileId: PropTypes.string,
  dispatch:        PropTypes.func.isRequired,
};

ServerProfileForm.defaultProps = {
  server_profile_id: undefined
};

export default connect()(ServerProfileForm);
