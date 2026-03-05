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
  VERIFICATION_METHODS,
} from "./quest-models";

type QuestCreateDialogProps = {
  open: boolean;
  badges: BadgeOption[];
  submitError: string | null;
  onOpenChange: (open: boolean) => void;
  onSubmit: (event: React.FormEvent<HTMLFormElement>) => Promise<void>;
};

export function QuestCreateDialog({
  open,
  badges,
  submitError,
  onOpenChange,
  onSubmit,
}: QuestCreateDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className='max-w-2xl max-h-[90vh] overflow-y-auto'>
        <DialogHeader>
          <DialogTitle>Create New Quest</DialogTitle>
          <DialogDescription>
            Add a new quest for users to complete and earn rewards.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={(event) => void onSubmit(event)}>
          <div className='grid gap-4 py-4'>
            <QuestSharedFields badges={badges} />
          </div>
          {submitError ? <p className='mb-2 text-sm text-destructive'>{submitError}</p> : null}
          <DialogFooter>
            <Button type='button' variant='outline' onClick={() => onOpenChange(false)}>
              Cancel
            </Button>
            <Button type='submit'>Create Quest</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

export function QuestSharedFields({ badges }: { badges: BadgeOption[] }) {
  return (
    <>
      <div className='grid gap-2'>
        <Label htmlFor='create-title'>Title *</Label>
        <Input id='create-title' name='title' required placeholder='Follow us on X' />
      </div>

      <div className='grid gap-2'>
        <Label htmlFor='create-description'>Description *</Label>
        <Textarea id='create-description' name='description' required placeholder='Follow our official X account to stay updated' rows={3} />
      </div>

      <div className='grid grid-cols-1 sm:grid-cols-2 gap-4'>
        <div className='grid gap-2'>
          <Label htmlFor='create-type'>Type *</Label>
          <Select name='type' defaultValue='external_link' required>
            <SelectTrigger id='create-type'>
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
          <Label htmlFor='create-category'>Category *</Label>
          <Select name='category' defaultValue='social' required>
            <SelectTrigger id='create-category'>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {QUEST_CATEGORIES.map((cat) => (
                <SelectItem key={cat.value} value={cat.value}>
                  {cat.label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
      </div>

      <div className='grid grid-cols-1 sm:grid-cols-2 gap-4'>
        <div className='grid gap-2'>
          <Label htmlFor='create-points'>Reward Points</Label>
          <Input id='create-points' name='rewardPoints' type='number' defaultValue={0} min={0} />
        </div>
        <div className='grid gap-2'>
          <Label htmlFor='create-badge'>Reward Badge (Optional)</Label>
          <Select name='rewardBadgeId' defaultValue={NONE_OPTION_VALUE}>
            <SelectTrigger id='create-badge'>
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
        <Label htmlFor='create-verification'>Verification Method *</Label>
        <Select name='verificationMethod' defaultValue='manual' required>
          <SelectTrigger id='create-verification'>
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
        <Label htmlFor='create-targetUrl'>Target URL (Optional)</Label>
        <Input id='create-targetUrl' name='targetUrl' type='url' placeholder='https://x.com/blocnet' />
      </div>
      <div className='grid gap-2'>
        <Label htmlFor='create-targetAction'>Target Action (Optional)</Label>
        <Input id='create-targetAction' name='targetAction' placeholder='follow_on_x' />
      </div>
      <div className='grid gap-2'>
        <Label htmlFor='create-requiredProof'>Required Proof (Optional)</Label>
        <Textarea id='create-requiredProof' name='requiredProof' placeholder='Provide a screenshot showing you followed our account' rows={2} />
      </div>
      <div className='grid gap-2'>
        <Label htmlFor='create-expiresAt'>Expires At (Optional)</Label>
        <Input id='create-expiresAt' name='expiresAt' type='datetime-local' />
      </div>
    </>
  );
}
