import * as React from "react";
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectLabel,
  SelectTrigger,
  SelectValue,
} from "blocnet-admin";

export const StatusPicker = () => (
  <div className="flex h-full items-start justify-center pt-4">
    <Select open defaultValue="published">
      <SelectTrigger className="w-48">
        <SelectValue placeholder="Status" />
      </SelectTrigger>
      <SelectContent>
        <SelectGroup>
          <SelectLabel>Status</SelectLabel>
          <SelectItem value="draft">Draft</SelectItem>
          <SelectItem value="published">Published</SelectItem>
          <SelectItem value="archived">Archived</SelectItem>
        </SelectGroup>
      </SelectContent>
    </Select>
  </div>
);

export const Closed = () => (
  <div className="flex flex-wrap gap-3">
    <Select defaultValue="hunter">
      <SelectTrigger className="w-44">
        <SelectValue />
      </SelectTrigger>
      <SelectContent>
        <SelectItem value="hunter">Hunter</SelectItem>
        <SelectItem value="moderator">Moderator</SelectItem>
      </SelectContent>
    </Select>
    <Select>
      <SelectTrigger className="w-44">
        <SelectValue placeholder="Choose a role" />
      </SelectTrigger>
      <SelectContent>
        <SelectItem value="admin">Admin</SelectItem>
      </SelectContent>
    </Select>
    <Select disabled defaultValue="owner">
      <SelectTrigger className="w-44">
        <SelectValue />
      </SelectTrigger>
      <SelectContent>
        <SelectItem value="owner">Owner</SelectItem>
      </SelectContent>
    </Select>
  </div>
);
