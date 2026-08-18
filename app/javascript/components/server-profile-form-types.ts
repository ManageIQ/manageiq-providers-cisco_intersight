export type {
  FormOptions,
  MiqFormSchemaType,
  OptionType,
} from "@@miq-types/forms";

type ModalAction = "assign_server" | "deploy_server" | "unassign_server";

type ModalData = {
  action: ModalAction;
};

export type ServerProfileFormProps = {
  modalData: ModalData;
};

export type ApiErrorType = {
  data?: {
    error?: {
      message?: string;
    };
  };
};

type ResourceType = {
  id: string | number;
  name: string;
};

export type ResourcesResponseType = {
  resources: ResourceType[];
};

export type ServerProfileFormValues = {
  server_profile?: string | number | null;
  physical_server?: string | number | null;
};

type ApiResultType = {
  message: string;
  success: boolean;
};

export type ApiResultsResponseType = {
  results: ApiResultType[];
};

export type PhysicalServerDetailsResponseType = {
  assigned_server_profile: {
    id: string | number;
  };
};
