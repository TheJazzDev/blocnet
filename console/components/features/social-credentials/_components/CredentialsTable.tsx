"use client";

import {
  Eye,
  EyeOff,
  Loader2,
  Pencil,
  Trash2,
} from "lucide-react";
import type { AdminSocialCredential } from "@/lib/api-client";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { prettyProvider } from "../_lib/social-credentials";

type CredentialsTableProps = {
  rows: AdminSocialCredential[];
  loading: boolean;
  revealed: Record<string, string>;
  busyId: string | null;
  onToggleReveal: (row: AdminSocialCredential) => Promise<void>;
  onEdit: (row: AdminSocialCredential) => void;
  onDelete: (row: AdminSocialCredential) => void;
};

export function CredentialsTable({
  rows,
  loading,
  revealed,
  busyId,
  onToggleReveal,
  onEdit,
  onDelete,
}: CredentialsTableProps) {
  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="text-base">Stored Credentials</CardTitle>
        <CardDescription>{rows.length} record(s)</CardDescription>
      </CardHeader>
      <CardContent>
        {loading ? (
          <div className="flex items-center justify-center py-12">
            <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
          </div>
        ) : rows.length === 0 ? (
          <p className="py-8 text-sm text-muted-foreground">
            No credentials added yet.
          </p>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Provider</TableHead>
                <TableHead>Account</TableHead>
                <TableHead>Username</TableHead>
                <TableHead>Password</TableHead>
                <TableHead>Updated</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((row) => {
                const visiblePassword = revealed[row.id];
                return (
                  <TableRow key={row.id}>
                    <TableCell>
                      <Badge variant="outline">{prettyProvider(row.provider)}</Badge>
                    </TableCell>
                    <TableCell>{row.accountLabel || "-"}</TableCell>
                    <TableCell>{row.username || "-"}</TableCell>
                    <TableCell className="font-mono text-xs">
                      {visiblePassword ?? row.passwordMasked}
                    </TableCell>
                    <TableCell className="text-xs text-muted-foreground">
                      {new Date(row.updatedAt).toLocaleString()}
                    </TableCell>
                    <TableCell className="text-right">
                      <div className="flex justify-end gap-2">
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => void onToggleReveal(row)}
                          disabled={busyId === row.id}
                        >
                          {busyId === row.id ? (
                            <Loader2 className="h-4 w-4 animate-spin" />
                          ) : visiblePassword ? (
                            <EyeOff className="h-4 w-4" />
                          ) : (
                            <Eye className="h-4 w-4" />
                          )}
                          {visiblePassword ? "Hide" : "View"}
                        </Button>
                        <Button variant="outline" size="sm" onClick={() => onEdit(row)}>
                          <Pencil className="h-4 w-4" />
                          Edit
                        </Button>
                        <Button variant="destructive" size="sm" onClick={() => onDelete(row)}>
                          <Trash2 className="h-4 w-4" />
                          Delete
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        )}
      </CardContent>
    </Card>
  );
}
