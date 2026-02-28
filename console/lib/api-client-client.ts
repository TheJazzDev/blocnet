import { contentApi } from "./api-client-content";
import { edgeApi } from "./api-client-edge";
import { governanceApi } from "./api-client-governance";
import { miningApi } from "./api-client-mining";
import { notificationsApi } from "./api-client-notifications";
import { rolesAndTagsApi } from "./api-client-roles-tags";
import { securityApi } from "./api-client-security";
import { tipsApi } from "./api-client-tips";
import { usersApi } from "./api-client-users";
import { walletApi } from "./api-client-wallet";

export const clientApi = {
  ...usersApi,
  ...contentApi,
  ...governanceApi,
  ...edgeApi,
  ...rolesAndTagsApi,
  ...walletApi,
  ...tipsApi,
  ...miningApi,
  ...notificationsApi,
  ...securityApi,
};
