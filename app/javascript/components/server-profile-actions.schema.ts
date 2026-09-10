import { componentTypes, validatorTypes } from "@@ddf";
import type {
  MiqFormSchemaType,
  OptionType,
} from "./server-profile-actions-types";

const createSchema = (
  loadOptions: Promise<OptionType[]>,
  isAssignAction: boolean,
): MiqFormSchemaType => ({
  fields: [
    ...(isAssignAction
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
            loadOptions: () => loadOptions,
          },
        ]
      : [
          {
            component: componentTypes.SELECT,
            id: "physical_server",
            name: "physical_server",
            label: __("Physical Server"),
            placeholder: __("Select a Physical Server"),
            isRequired: true,
            includeEmpty: true,
            validate: [
              {
                type: validatorTypes.REQUIRED,
                message: __("Required"),
              },
            ],
            loadOptions: () => loadOptions,
          },
        ]),
  ],
});

export default createSchema;
