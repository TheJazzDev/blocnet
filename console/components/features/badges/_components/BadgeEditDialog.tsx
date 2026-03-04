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

type BadgeEditDialogProps = {
  open: boolean;
  canMutate: boolean;
  saving: boolean;
  name: string;
  description: string;
  imageUrl: string;
  category: string;
  rarity: string;
  points: string;
  active: boolean;
  onOpenChange: (open: boolean) => void;
  setName: (value: string) => void;
  setDescription: (value: string) => void;
  setImageUrl: (value: string) => void;
  setCategory: (value: string) => void;
  setRarity: (value: string) => void;
  setPoints: (value: string) => void;
  setActive: (value: boolean) => void;
  onSave: () => Promise<void>;
};

export function BadgeEditDialog({
  open,
  canMutate,
  saving,
  name,
  description,
  imageUrl,
  category,
  rarity,
  points,
  active,
  onOpenChange,
  setName,
  setDescription,
  setImageUrl,
  setCategory,
  setRarity,
  setPoints,
  setActive,
  onSave,
}: BadgeEditDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl">
        <DialogHeader>
          <DialogTitle>Edit Badge</DialogTitle>
          <DialogDescription>Update badge details.</DialogDescription>
        </DialogHeader>
        <div className="space-y-4">
          <div>
            <label className="text-sm font-medium">Name</label>
            <Input value={name} onChange={(e) => setName(e.target.value)} disabled={!canMutate || saving} />
          </div>
          <div>
            <label className="text-sm font-medium">Description</label>
            <Textarea value={description} onChange={(e) => setDescription(e.target.value)} disabled={!canMutate || saving} rows={3} />
          </div>
          <div>
            <label className="text-sm font-medium">Image URL</label>
            <Input value={imageUrl} onChange={(e) => setImageUrl(e.target.value)} disabled={!canMutate || saving} />
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
            <Input type="number" value={points} onChange={(e) => setPoints(e.target.value)} disabled={!canMutate || saving} />
          </div>
          <div className="flex items-center gap-2">
            <input type="checkbox" checked={active} onChange={(e) => setActive(e.target.checked)} disabled={!canMutate || saving} id="editActive" />
            <label htmlFor="editActive" className="text-sm font-medium">Active</label>
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={saving}>
            Cancel
          </Button>
          <Button onClick={() => void onSave()} disabled={!canMutate || saving}>
            {saving && <Loader2 className="h-4 w-4 animate-spin" />}
            Save
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
