export type {
  FormOptions,
  MiqFormSchemaType,
  OptionType,
} from "@@miq-types/forms";

export type ModalActionType =
  | "assign_server"
  | "deploy_server"
  | "unassign_server";

export type ModalDataType = {
  action: ModalActionType;
};

export type DirectActionProps = {
  action: ModalActionType;
  onModalClose: () => void;
};

export type ServerProfileActionsProps = {
  onModalClose: () => void;
  modalData: ModalDataType;
};

export type ApiErrorType = {
  data?: {
    error?: {
      message?: string;
    };
  };
};

type ResourceType = {
  id: string;
  name: string;
};

export type ResourcesResponseType = {
  resources: ResourceType[];
};

export type ServerProfileActionsValuesType = {
  server_profile?: string;
  physical_server?: string;
};

type ApiResultType = {
  message: string;
  success: boolean;
  task_id: string;
};

export type ApiResultsResponseType = {
  results: ApiResultType[];
};

export type PhysicalServerDetailsResponseType = {
  assigned_server_profile?: {
    id: string;
  };
};
