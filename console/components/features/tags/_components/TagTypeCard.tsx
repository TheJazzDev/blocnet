"use client";

import { Edit2, Loader2, Plus } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import type { Tag } from "@/lib/api-client";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

type TagTypeCardProps = {
  title: string;
  inputValue: string;
  setInputValue: (value: string) => void;
  creating: boolean;
  canMutate: boolean;
  loading: boolean;
  emptyLabel: string;
  tags: Tag[];
  onCreate: (event: React.FormEvent) => Promise<void>;
  onEdit: (tag: Tag) => void;
  formatDate: (date: string) => string;
};

export function TagTypeCard({
  title,
  inputValue,
  setInputValue,
  creating,
  canMutate,
  loading,
  emptyLabel,
  tags,
  onCreate,
  onEdit,
  formatDate,
}: TagTypeCardProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">{title}</CardTitle>
        <form className="mt-3 flex gap-2" onSubmit={(event) => void onCreate(event)}>
          <Input
            value={inputValue}
            onChange={(e) => setInputValue(e.target.value)}
            placeholder={`Add ${title.toLowerCase().replace(" tags", "")} tag`}
            disabled={!canMutate || creating}
          />
          <Button type="submit" disabled={!canMutate || creating}>
            {creating ? <Loader2 className="h-4 w-4 animate-spin" /> : <Plus className="h-4 w-4" />}
            Add
          </Button>
        </form>
      </CardHeader>
      <CardContent>
        {loading ? (
          <LoadingSpinner className="py-10" />
        ) : tags.length === 0 ? (
          <p className="py-8 text-center text-sm text-muted-foreground">{emptyLabel}</p>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Slug</TableHead>
                <TableHead className="text-right">Created</TableHead>
                <TableHead className="w-[40px]" />
              </TableRow>
            </TableHeader>
            <TableBody>
              {tags.map((tag) => (
                <TableRow key={tag.id}>
                  <TableCell>
                    <Badge variant="secondary">{tag.name}</Badge>
                  </TableCell>
                  <TableCell className="text-xs text-muted-foreground">{tag.slug}</TableCell>
                  <TableCell className="text-right text-sm text-muted-foreground">
                    {formatDate(tag.createdAt)}
                  </TableCell>
                  <TableCell>
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-8 w-8"
                      disabled={!canMutate}
                      onClick={() => onEdit(tag)}
                    >
                      <Edit2 className="h-4 w-4" />
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </CardContent>
    </Card>
  );
}
