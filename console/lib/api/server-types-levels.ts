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
