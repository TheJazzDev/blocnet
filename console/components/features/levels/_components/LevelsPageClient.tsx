"use client";

import { PageHeader } from "@/components/page-header";
import { useLevelsPage } from "../_hooks/use-levels-page";
import { LevelTierGroup } from "./LevelTierGroup";

export default function LevelsPageClient() {
  const page = useLevelsPage();

  if (page.isLoading) {
    return (
      <div className="flex items-center justify-center py-8">
        <p className="text-sm text-muted-foreground">Loading levels...</p>
      </div>
    );
  }

  if (page.error) {
    return (
      <div className="flex items-center justify-center py-8">
        <p className="text-sm text-destructive">Error loading levels</p>
      </div>
    );
  }

  return (
    <div className="space-y-4 md:space-y-6">
      <PageHeader
        title="User Levels"
        description="Manage the user level system and progression thresholds"
      />

      {page.groups.length === 0 ? (
        <p className="py-8 text-center text-sm text-muted-foreground">No levels configured.</p>
      ) : (
        <div className="space-y-6 md:space-y-8">
          {page.groups.map((group) => (
            <LevelTierGroup
              key={group.tier.name}
              tier={group.tier}
              levels={group.levels}
              canMutate={page.canMutate}
              editingId={page.editingId}
              isSaving={page.isSaving}
              uploadingLevelId={page.uploadingLevelId}
              onSave={page.saveEdit}
              onUploadIcon={page.uploadIcon}
            />
          ))}
        </div>
      )}
    </div>
  );
}
