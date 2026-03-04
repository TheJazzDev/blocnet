import { apiFetch } from '@/lib/api-client-http';
import axios from 'axios';
import { extractApiErrorMessage } from '@/lib/api-error';

export interface UserLevel {
  id: string;
  slug: string;
  name: string;
  description: string;
  iconUrl: string;
  level: number;
  requiredBnp: string;
  requiredComments: number;
  requiredDaysActive: number;
  requiredQuests: number;
  requiredUpdates: number;
  requiredProjects: number;
  color: string | null;
  isActive: boolean;
  sortOrder: number;
}

export interface UpdateLevelInput {
  name?: string;
  description?: string;
  iconUrl?: string;
  requiredBnp?: string;
  requiredComments?: number;
  requiredDaysActive?: number;
  requiredQuests?: number;
  requiredUpdates?: number;
  requiredProjects?: number;
  color?: string;
  isActive?: boolean;
  sortOrder?: number;
}

export async function getAllLevels(): Promise<UserLevel[]> {
  return apiFetch<UserLevel[]>('/levels');
}

export async function getLevelById(id: string): Promise<UserLevel> {
  return apiFetch<UserLevel>(`/levels/${id}`);
}

export async function updateLevel(
  id: string,
  data: UpdateLevelInput,
): Promise<UserLevel> {
  return apiFetch<UserLevel>(`/levels/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(data),
    suppressSuccessToast: true,
    suppressErrorToast: true,
  });
}

export async function uploadLevelIcon(
  id: string,
  file: File,
): Promise<UserLevel> {
  const formData = new FormData();
  formData.append('file', file);

  const response = await axios.post<UserLevel>(
    `/api/proxy/levels/${encodeURIComponent(id)}/icon`,
    formData,
    {
      withCredentials: true,
      validateStatus: () => true,
    },
  );

  if (response.status < 200 || response.status >= 300) {
    throw new Error(
      extractApiErrorMessage(
        response.data,
        `Icon upload failed (${response.status})`,
      ),
    );
  }

  return response.data;
}
