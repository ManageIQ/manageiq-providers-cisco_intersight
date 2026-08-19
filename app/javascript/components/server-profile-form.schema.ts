import { componentTypes, validatorTypes } from "@@ddf";
import type {
  MiqFormSchemaType,
  OptionType,
} from "./server-profile-form-types";

const createSchema = (
  serverProfilesPromise: Promise<OptionType[]>,
  physicalServersPromise: Promise<OptionType[]>,
  serverProfileVisible: boolean,
): MiqFormSchemaType => ({
  fields: [
    ...(serverProfileVisible
      ? [
          {
            component: componentTypes.SELECT,
            id: "server_profile",
            name: "server_profile",
            label: __("Server Profile"),
            placeholder: __("Select a Server Profile"),
            initialValue: null,
            isRequired: true,
            includeEmpty: true,
            validate: [
              {
                type: validatorTypes.REQUIRED,
                message: __("Required"),
              },
            ],
            loadOptions: () => serverProfilesPromise,
          },
        ]
      : [
          {
            component: componentTypes.SELECT,
            id: "physical_server",
            name: "physical_server",
            label: __("Physical Server"),
            placeholder: __("Select a Physical Server"),
            initialValue: ManageIQ.record.recordId,
            isRequired: true,
            includeEmpty: true,
            validate: [
              {
                type: validatorTypes.REQUIRED,
                message: __("Required"),
              },
            ],
            loadOptions: () => physicalServersPromise,
          },
        ]),
  ],
});

export default createSchema;
