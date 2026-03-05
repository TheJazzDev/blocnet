"use client";

import type { Dispatch, FormEvent, SetStateAction } from "react";
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
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import type { CredentialFormState } from "../_lib/social-credentials";

type CredentialFormDialogProps = {
  mode: "create" | "edit";
  open: boolean;
  onOpenChange: (open: boolean) => void;
  saving: boolean;
  form: CredentialFormState;
  setForm: Dispatch<SetStateAction<CredentialFormState>>;
  onSubmit: (e: FormEvent<HTMLFormElement>) => void;
};

export function CredentialFormDialog({
  mode,
  open,
  onOpenChange,
  saving,
  form,
  setForm,
  onSubmit,
}: CredentialFormDialogProps) {
  const isCreate = mode === "create";
  const title = isCreate ? "Create Credential" : "Edit Credential";
  const description = isCreate
    ? "Add a new social account credential record."
    : "Update account details. Leave password empty to keep existing value.";
  const passwordLabel = isCreate ? "Password" : "New Password";
  const passwordPlaceholder = isCreate ? "" : "Leave empty to keep current";
  const submitLabel = isCreate ? "Save Credential" : "Update Credential";

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{title}</DialogTitle>
          <DialogDescription>{description}</DialogDescription>
        </DialogHeader>
        <form className="space-y-4" onSubmit={onSubmit}>
          <div className="space-y-2">
            <Label htmlFor={`${mode}-provider`}>Provider</Label>
            <Input
              id={`${mode}-provider`}
              value={form.provider}
              onChange={(event) =>
                setForm((prev) => ({ ...prev, provider: event.target.value }))
              }
              placeholder="x, instagram, tiktok, playstore"
              required
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor={`${mode}-account-label`}>Account Label</Label>
            <Input
              id={`${mode}-account-label`}
              value={form.accountLabel}
              onChange={(event) =>
                setForm((prev) => ({ ...prev, accountLabel: event.target.value }))
              }
              placeholder="blocnetapp@gmail.com"
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor={`${mode}-username`}>Username</Label>
            <Input
              id={`${mode}-username`}
              value={form.username}
              onChange={(event) =>
                setForm((prev) => ({ ...prev, username: event.target.value }))
              }
              placeholder="@blocnet_app"
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor={`${mode}-password`}>{passwordLabel}</Label>
            <Input
              id={`${mode}-password`}
              type="password"
              value={form.password}
              onChange={(event) =>
                setForm((prev) => ({ ...prev, password: event.target.value }))
              }
              placeholder={passwordPlaceholder}
              required={isCreate}
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor={`${mode}-notes`}>Notes</Label>
            <Textarea
              id={`${mode}-notes`}
              rows={3}
              value={form.notes}
              onChange={(event) =>
                setForm((prev) => ({ ...prev, notes: event.target.value }))
              }
              placeholder="Optional context"
            />
          </div>
          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
              disabled={saving}
            >
              Cancel
            </Button>
            <Button type="submit" disabled={saving}>
              {saving && <Loader2 className="h-4 w-4 animate-spin" />}
              {submitLabel}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
