"use client";

import { Plus } from "lucide-react";
import { useAdminSession } from "@/components/admin-shell";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { CredentialsTable } from "./CredentialsTable";
import { CredentialFormDialog } from "./CredentialFormDialog";
import { DeleteCredentialDialog } from "./DeleteCredentialDialog";
import { useSocialCredentials } from "../_hooks/use-social-credentials";

export default function SocialCredentialsPageClient() {
  const session = useAdminSession();
  const state = useSocialCredentials(session.effectiveRoles, session.realRoles);

  return (
    <div className="space-y-6">
      <PageHeader
        title="Social Credentials"
        description="Owner-only encrypted vault for social media account credentials."
      >
        {state.isOwner && (
          <Button onClick={state.openCreateDialog}>
            <Plus className="h-4 w-4" />
            Add Credential
          </Button>
        )}
      </PageHeader>

      {!state.isOwner ? (
        <Card className="border-amber-500/30 bg-amber-500/5">
          <CardContent className="pt-6 text-sm text-amber-200">
            Owner role is required to view or mutate social credentials.
          </CardContent>
        </Card>
      ) : (
        <>
          <Card className="border-primary/20 bg-primary/5">
            <CardHeader className="pb-3">
              <CardTitle className="text-base">Vault Controls</CardTitle>
              <CardDescription>
                Passwords are encrypted at rest and masked by default.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-2 text-xs text-muted-foreground">
              <p>Use View to reveal an entry temporarily.</p>
              <p>Create, update, or delete entries as credentials rotate.</p>
            </CardContent>
          </Card>

          {state.error && (
            <Card className="border-destructive/40 bg-destructive/10">
              <CardContent className="pt-6 text-sm text-destructive">
                {state.error}
              </CardContent>
            </Card>
          )}

          {state.status && (
            <Card className="border-emerald-500/30 bg-emerald-500/10">
              <CardContent className="pt-6 text-sm text-emerald-300">
                {state.status}
              </CardContent>
            </Card>
          )}

          <CredentialsTable
            rows={state.rows}
            loading={state.loading}
            revealed={state.revealed}
            busyId={state.busyId}
            onToggleReveal={state.toggleReveal}
            onEdit={state.openEditDialog}
            onDelete={state.openDeleteDialog}
          />
        </>
      )}

      <CredentialFormDialog
        mode="create"
        open={state.createOpen}
        onOpenChange={state.setCreateOpen}
        saving={state.createSaving}
        form={state.createForm}
        setForm={state.setCreateForm}
        onSubmit={(event) => void state.submitCreate(event)}
      />

      <CredentialFormDialog
        mode="edit"
        open={state.editOpen}
        onOpenChange={state.setEditOpen}
        saving={state.editSaving}
        form={state.editForm}
        setForm={state.setEditForm}
        onSubmit={(event) => void state.submitEdit(event)}
      />

      <DeleteCredentialDialog
        open={state.deleteOpen}
        onOpenChange={state.setDeleteOpen}
        target={state.deleteTarget}
        deleting={state.deleteSaving}
        onConfirm={state.confirmDelete}
      />
    </div>
  );
}
