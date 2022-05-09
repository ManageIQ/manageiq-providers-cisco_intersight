import { componentTypes, validatorTypes } from '@@ddf';

const createSchema = (serverProfilesPromise, physicalServersPromise, serverProfileVisible) => {
  return ({
    fields: [
      ...(serverProfileVisible ? [
          {
            component: componentTypes.SELECT,
            id: 'server_profile',
            name: 'server_profile',
            label: __('Server Profile'),
            placeholder: __('Server Profile'),
            initialValue: null,
            isRequired: true,
            validate: [{
              type: validatorTypes.REQUIRED,
              message: __('Required'),
            }],
            loadOptions: () => serverProfilesPromise,
          }]
        : [
          {
            component: componentTypes.SELECT,
            id: 'physical_server',
            name: 'physical_server',
            label: __('Physical Server'),
            placeholder: __('Physical Server'),
            initialValue: ManageIQ.record.recordId,
            value: null,
            isRequired: true,
            validate: [{
              type: validatorTypes.REQUIRED,
              message: __('Required'),
            }],
            loadOptions: () => physicalServersPromise,
          }]
      )
    ]
  });
};

export default createSchema;
