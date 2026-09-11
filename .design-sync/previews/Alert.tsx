import * as React from "react";
import { Alert, AlertDescription, AlertTitle } from "blocnet-admin";
import { AlertTriangle, CheckCircle2, Info } from "lucide-react";

export const Default = () => (
  <Alert className="max-w-lg">
    <Info />
    <AlertTitle>Edge Engine sync scheduled</AlertTitle>
    <AlertDescription>Scores refresh every 6 hours. Manual runs are logged in the audit trail.</AlertDescription>
  </Alert>
);

export const Destructive = () => (
  <Alert variant="destructive" className="max-w-lg">
    <AlertTriangle />
    <AlertTitle>Wallet service unreachable</AlertTitle>
    <AlertDescription>Withdrawals are paused until the Turnkey connection recovers.</AlertDescription>
  </Alert>
);

export const TitleOnly = () => (
  <Alert className="max-w-lg">
    <CheckCircle2 />
    <AlertTitle>Season 3 rewards distributed to 48,210 miners.</AlertTitle>
  </Alert>
);
