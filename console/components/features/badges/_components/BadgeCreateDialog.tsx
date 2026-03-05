"use client";

import { Loader2 } from "lucide-react";
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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { CATEGORIES, RARITIES, toCategoryLabel, toLabel } from "./badge-models";

type BadgeCreateDialogProps = {
  open: boolean;
  canMutate: boolean;
  creating: boolean;
  name: string;
  description: string;
  imageUrl: string;
  category: string;
  rarity: string;
  points: string;
  onOpenChange: (open: boolean) => void;
  setName: (value: string) => void;
  setDescription: (value: string) => void;
  setImageUrl: (value: string) => void;
  setCategory: (value: string) => void;
  setRarity: (value: string) => void;
  setPoints: (value: string) => void;
  onSubmit: (event: React.FormEvent) => Promise<void>;
};

export function BadgeCreateDialog({
  open,
  canMutate,
  creating,
  name,
  description,
  imageUrl,
  category,
  rarity,
  points,
  onOpenChange,
  setName,
  setDescription,
  setImageUrl,
  setCategory,
  setRarity,
  setPoints,
  onSubmit,
}: BadgeCreateDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl">
        <DialogHeader>
          <DialogTitle>Create New Badge</DialogTitle>
          <DialogDescription>Add a new achievement badge to the system.</DialogDescription>
        </DialogHeader>
        <form onSubmit={(event) => void onSubmit(event)} className="space-y-4">
          <div>
            <label className="text-sm font-medium">Name</label>
            <Input
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Founding Member"
              disabled={!canMutate || creating}
            />
          </div>
          <div>
            <label className="text-sm font-medium">Description</label>
            <Textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Awarded to the first 100 users"
              disabled={!canMutate || creating}
              rows={3}
            />
          </div>
          <div>
            <label className="text-sm font-medium">Image URL</label>
            <Input
              value={imageUrl}
              onChange={(e) => setImageUrl(e.target.value)}
              placeholder="https://example.com/badge.png"
              disabled={!canMutate || creating}
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="text-sm font-medium">Category</label>
              <Select value={category} onValueChange={setCategory}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {CATEGORIES.map((entry) => (
                    <SelectItem key={entry} value={entry}>
                      {toCategoryLabel(entry)}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div>
              <label className="text-sm font-medium">Rarity</label>
              <Select value={rarity} onValueChange={setRarity}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {RARITIES.map((entry) => (
                    <SelectItem key={entry} value={entry}>
                      {toLabel(entry)}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
          <div>
            <label className="text-sm font-medium">Points Requirement</label>
            <Input
              type="number"
              value={points}
              onChange={(e) => setPoints(e.target.value)}
              placeholder="0"
              disabled={!canMutate || creating}
            />
          </div>
          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)} disabled={creating}>
              Cancel
            </Button>
            <Button type="submit" disabled={!canMutate || creating}>
              {creating && <Loader2 className="h-4 w-4 animate-spin" />}
              Create Badge
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
