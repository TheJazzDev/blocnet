import * as React from "react";
import {
  Button,
  DropdownMenu,
  DropdownMenuCheckboxItem,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuShortcut,
  DropdownMenuTrigger,
} from "blocnet-admin";
import { ChevronDown } from "lucide-react";

export const ProjectActions = () => (
  <div className="flex h-full items-start justify-center pt-4">
    <DropdownMenu open>
      <DropdownMenuTrigger asChild>
        <Button variant="outline" size="sm">
          Actions <ChevronDown />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="start" className="w-56">
        <DropdownMenuLabel>Project</DropdownMenuLabel>
        <DropdownMenuSeparator />
        <DropdownMenuItem>
          Edit <DropdownMenuShortcut>⌘E</DropdownMenuShortcut>
        </DropdownMenuItem>
        <DropdownMenuItem>Assign hunter</DropdownMenuItem>
        <DropdownMenuCheckboxItem checked>Featured</DropdownMenuCheckboxItem>
        <DropdownMenuSeparator />
        <DropdownMenuItem className="text-destructive">Archive</DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  </div>
);
