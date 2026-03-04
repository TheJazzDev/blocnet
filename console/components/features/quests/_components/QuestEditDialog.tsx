"use client";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import {
  BadgeOption,
  NONE_OPTION_VALUE,
  QUEST_CATEGORIES,
  QUEST_TYPES,
  QuestModel,
  VERIFICATION_METHODS,
} from "./quest-models";

type QuestEditDialogProps = {
  open: boolean;
  quest: QuestModel | null;
  badges: BadgeOption[];
  submitError: string | null;
  onOpenChange: (open: boolean) => void;
  onCancel: () => void;
  onSubmit: (event: React.FormEvent<HTMLFormElement>) => Promise<void>;
};

export function QuestEditDialog({
  open,
  quest,
  badges,
  submitError,
  onOpenChange,
  onCancel,
  onSubmit,
}: QuestEditDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className='max-h-[90vh] max-w-2xl overflow-y-auto'>
        <DialogHeader>
          <DialogTitle>Edit Quest</DialogTitle>
          <DialogDescription>Update quest details and rewards.</DialogDescription>
        </DialogHeader>

        {quest ? (
          <form onSubmit={(event) => void onSubmit(event)}>
            <div className='grid gap-4 py-4'>
              <div className='grid gap-2'>
                <Label htmlFor='edit-title'>Title *</Label>
                <Input id='edit-title' name='title' required defaultValue={quest.title} />
              </div>

              <div className='grid gap-2'>
                <Label htmlFor='edit-description'>Description *</Label>
                <Textarea id='edit-description' name='description' required defaultValue={quest.description} rows={3} />
              </div>

              <div className='grid grid-cols-1 gap-4 sm:grid-cols-2'>
                <div className='grid gap-2'>
                  <Label htmlFor='edit-type'>Type *</Label>
                  <Select name='type' defaultValue={quest.type} required>
                    <SelectTrigger id='edit-type'>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {QUEST_TYPES.map((type) => (
                        <SelectItem key={type.value} value={type.value}>
                          {type.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div className='grid gap-2'>
                  <Label htmlFor='edit-category'>Category *</Label>
                  <Select name='category' defaultValue={quest.category} required>
                    <SelectTrigger id='edit-category'>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {QUEST_CATEGORIES.map((category) => (
                        <SelectItem key={category.value} value={category.value}>
                          {category.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <div className='grid grid-cols-1 gap-4 sm:grid-cols-2'>
                <div className='grid gap-2'>
                  <Label htmlFor='edit-points'>Reward Points</Label>
                  <Input id='edit-points' name='rewardPoints' type='number' defaultValue={quest.rewardPoints} min={0} />
                </div>

                <div className='grid gap-2'>
                  <Label htmlFor='edit-badge'>Reward Badge (Optional)</Label>
                  <Select name='rewardBadgeId' defaultValue={quest.rewardBadgeId ?? NONE_OPTION_VALUE}>
                    <SelectTrigger id='edit-badge'>
                      <SelectValue placeholder='None' />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value={NONE_OPTION_VALUE}>None</SelectItem>
                      {badges.map((badge) => (
                        <SelectItem key={badge.id} value={badge.id}>
                          {badge.name}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <div className='grid gap-2'>
                <Label htmlFor='edit-verification'>Verification Method *</Label>
                <Select name='verificationMethod' defaultValue={quest.verificationMethod} required>
                  <SelectTrigger id='edit-verification'>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {VERIFICATION_METHODS.map((method) => (
                      <SelectItem key={method.value} value={method.value}>
                        {method.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className='grid gap-2'>
                <Label htmlFor='edit-targetUrl'>Target URL (Optional)</Label>
                <Input id='edit-targetUrl' name='targetUrl' type='url' defaultValue={quest.targetUrl ?? ""} />
              </div>

              <div className='grid gap-2'>
                <Label htmlFor='edit-targetAction'>Target Action (Optional)</Label>
                <Input id='edit-targetAction' name='targetAction' defaultValue={quest.targetAction ?? ""} />
              </div>

              <div className='grid gap-2'>
                <Label htmlFor='edit-requiredProof'>Required Proof (Optional)</Label>
                <Textarea id='edit-requiredProof' name='requiredProof' defaultValue={quest.requiredProof ?? ""} rows={2} />
              </div>

              <div className='grid gap-2'>
                <Label htmlFor='edit-expiresAt'>Expires At (Optional)</Label>
                <Input
                  id='edit-expiresAt'
                  name='expiresAt'
                  type='datetime-local'
                  defaultValue={quest.expiresAt ? new Date(quest.expiresAt).toISOString().slice(0, 16) : ""}
                />
              </div>

              <div className='grid gap-2'>
                <Label htmlFor='edit-isActive'>Status *</Label>
                <Select name='isActive' defaultValue={quest.isActive ? "true" : "false"} required>
                  <SelectTrigger id='edit-isActive'>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value='true'>Active</SelectItem>
                    <SelectItem value='false'>Inactive</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>

            {submitError ? <p className='mb-2 text-sm text-destructive'>{submitError}</p> : null}

            <DialogFooter>
              <Button type='button' variant='outline' onClick={onCancel}>
                Cancel
              </Button>
              <Button type='submit'>Save Changes</Button>
            </DialogFooter>
          </form>
        ) : null}
      </DialogContent>
    </Dialog>
  );
}
