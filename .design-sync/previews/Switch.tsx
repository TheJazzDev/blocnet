import * as React from "react";
import { Label, Switch } from "blocnet-admin";

const Toggle = ({ initial, disabled, id }: { initial: boolean; disabled?: boolean; id: string }) => {
  const [on, setOn] = React.useState(initial);
  return <Switch id={id} checked={on} onCheckedChange={setOn} disabled={disabled} />;
};

export const States = () => (
  <div className="flex items-center gap-6">
    <Toggle id="off" initial={false} />
    <Toggle id="on" initial />
    <Toggle id="dis-off" initial={false} disabled />
    <Toggle id="dis-on" initial disabled />
  </div>
);

export const SettingRow = () => (
  <div className="flex w-96 items-center justify-between rounded-lg border border-border bg-card p-4">
    <div className="space-y-0.5">
      <Label htmlFor="mining">Mining enabled</Label>
      <p className="text-xs text-muted-foreground">Pause to stop new sessions.</p>
    </div>
    <Toggle id="mining" initial />
  </div>
);
