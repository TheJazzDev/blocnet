/**
 * Flip to `true` once the Activity, Social and System tabs (and the Projects
 * and Lifecycle tiles) are backed by real data. While `false` the stub
 * components stay in the tree but admins never see "will be available here"
 * placeholders. See F-05.
 */
export const UNIMPLEMENTED_SECTIONS_VISIBLE = false;

export type UserDetailTab = {
  value: string;
  label: string;
  /** `false` marks a tab whose content is still a placeholder. */
  implemented: boolean;
};

const ALL_USER_DETAIL_TABS: UserDetailTab[] = [
  { value: "overview", label: "Overview", implemented: true },
  { value: "roles-badges", label: "Roles & Badges", implemented: true },
  { value: "financial", label: "Financial", implemented: true },
  { value: "mining-quests", label: "Mining & Quests", implemented: true },
  { value: "activity", label: "Activity", implemented: false },
  { value: "social", label: "Social", implemented: false },
  { value: "system", label: "System", implemented: false },
];

export const USER_DETAIL_TABS: UserDetailTab[] = ALL_USER_DETAIL_TABS.filter(
  (tab) => tab.implemented || UNIMPLEMENTED_SECTIONS_VISIBLE,
);

export function isUserDetailTabVisible(value: string): boolean {
  return USER_DETAIL_TABS.some((tab) => tab.value === value);
}
