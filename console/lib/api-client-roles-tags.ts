import { apiFetch } from "./api-client-http";
import type { Tag } from "./api";

export const rolesAndTagsApi = {
  promoteToAdmin: (userId: string, note?: string) =>
    apiFetch(`/roles/admins/${userId}/promote`, {
      method: "POST",
      body: JSON.stringify({ note }),
    }),

  demoteAdmin: (userId: string) =>
    apiFetch(`/roles/admins/${userId}`, {
      method: "DELETE",
    }),

  promoteToDev: (userId: string, note?: string) =>
    apiFetch(`/roles/devs/${userId}/promote`, {
      method: "POST",
      body: JSON.stringify({ note }),
    }),

  demoteDev: (userId: string) =>
    apiFetch(`/roles/devs/${userId}`, {
      method: "DELETE",
    }),

  promoteToOwner: (userId: string, note?: string) =>
    apiFetch(`/roles/owners/${userId}/promote`, {
      method: "POST",
      body: JSON.stringify({ note }),
    }),

  demoteOwner: (userId: string) =>
    apiFetch(`/roles/owners/${userId}`, {
      method: "DELETE",
    }),

  promoteToCommunityAdmin: (userId: string, note?: string) =>
    apiFetch(`/roles/community-admins/${userId}/promote`, {
      method: "POST",
      body: JSON.stringify({ note }),
    }),

  demoteCommunityAdmin: (userId: string) =>
    apiFetch(`/roles/community-admins/${userId}`, {
      method: "DELETE",
    }),

  promoteToCommunityModerator: (userId: string, note?: string) =>
    apiFetch(`/roles/community-moderators/${userId}/promote`, {
      method: "POST",
      body: JSON.stringify({ note }),
    }),

  demoteCommunityModerator: (userId: string) =>
    apiFetch(`/roles/community-moderators/${userId}`, {
      method: "DELETE",
    }),

  promoteToCoreTeam: (userId: string, note?: string) =>
    apiFetch(`/roles/core-teams/${userId}/promote`, {
      method: "POST",
      body: JSON.stringify({ note }),
    }),

  demoteCoreTeam: (userId: string) =>
    apiFetch(`/roles/core-teams/${userId}`, {
      method: "DELETE",
    }),

  promoteToHunter: (userId: string, note?: string) =>
    apiFetch(`/roles/hunters/${userId}/promote`, {
      method: "POST",
      body: JSON.stringify({ note }),
    }),

  demoteHunter: (userId: string) =>
    apiFetch(`/roles/hunters/${userId}`, {
      method: "DELETE",
    }),

  listPrimaryTags: () => apiFetch<Tag[]>("/tags/primary"),

  listSecondaryTags: () => apiFetch<Tag[]>("/tags/secondary"),

  createPrimaryTag: (body: { name: string }) =>
    apiFetch<Tag>("/tags/primary", {
      method: "POST",
      body: JSON.stringify(body),
    }),

  createSecondaryTag: (body: { name: string }) =>
    apiFetch<Tag>("/tags/secondary", {
      method: "POST",
      body: JSON.stringify(body),
    }),

  updatePrimaryTag: (id: string, body: { name: string }) =>
    apiFetch<Tag>(`/tags/primary/${id}`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),

  updateSecondaryTag: (id: string, body: { name: string }) =>
    apiFetch<Tag>(`/tags/secondary/${id}`, {
      method: "PATCH",
      body: JSON.stringify(body),
    }),
};
