import * as React from "react";
import { Button } from "blocnet-admin";
import { ArrowRight, Loader2, Plus, RefreshCw, Trash2 } from "lucide-react";

export const Variants = () => (
  <div className="flex flex-wrap items-center gap-3">
    <Button>Approve project</Button>
    <Button variant="secondary">Save draft</Button>
    <Button variant="outline">Cancel</Button>
    <Button variant="ghost">View details</Button>
    <Button variant="destructive">Suspend user</Button>
    <Button variant="link">Learn more</Button>
  </div>
);

export const Sizes = () => (
  <div className="flex flex-wrap items-center gap-3">
    <Button size="sm">Small</Button>
    <Button>Default</Button>
    <Button size="lg">Large</Button>
    <Button size="icon" aria-label="Refresh">
      <RefreshCw />
    </Button>
  </div>
);

export const WithIcons = () => (
  <div className="flex flex-wrap items-center gap-3">
    <Button>
      <Plus /> New project
    </Button>
    <Button variant="outline">
      Continue <ArrowRight />
    </Button>
    <Button variant="destructive" size="sm">
      <Trash2 /> Delete
    </Button>
  </div>
);

export const States = () => (
  <div className="flex flex-wrap items-center gap-3">
    <Button disabled>
      <Loader2 className="animate-spin" /> Processing…
    </Button>
    <Button variant="outline" disabled>
      Disabled
    </Button>
    <Button variant="secondary" disabled>
      Disabled
    </Button>
  </div>
);
