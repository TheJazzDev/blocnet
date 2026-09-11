import * as React from "react";
import {
  Badge,
  Table,
  TableBody,
  TableCaption,
  TableCell,
  TableFooter,
  TableHead,
  TableHeader,
  TableRow,
} from "blocnet-admin";

const rows = [
  ["Nebula Swap", "@ada", "Pending", "secondary", 87],
  ["Orbit Lend", "@satoshi", "Published", "default", 92],
  ["Photon Bridge", "@vitalik", "Draft", "outline", 64],
  ["Quasar Pay", "@grace", "Suspended", "destructive", 41],
] as const;

export const ProjectsList = () => (
  <Table>
    <TableCaption>Projects awaiting review</TableCaption>
    <TableHeader>
      <TableRow>
        <TableHead>Project</TableHead>
        <TableHead>Hunter</TableHead>
        <TableHead>Status</TableHead>
        <TableHead className="text-right">Edge score</TableHead>
      </TableRow>
    </TableHeader>
    <TableBody>
      {rows.map(([name, hunter, status, variant, score]) => (
        <TableRow key={name}>
          <TableCell className="font-medium">{name}</TableCell>
          <TableCell className="text-muted-foreground">{hunter}</TableCell>
          <TableCell>
            <Badge variant={variant}>{status}</Badge>
          </TableCell>
          <TableCell className="text-right tabular-nums">{score}</TableCell>
        </TableRow>
      ))}
    </TableBody>
  </Table>
);

export const WithFooterAndSelection = () => (
  <Table>
    <TableHeader>
      <TableRow>
        <TableHead>Miner</TableHead>
        <TableHead>Level</TableHead>
        <TableHead className="text-right">Mined (BLOC)</TableHead>
      </TableRow>
    </TableHeader>
    <TableBody>
      <TableRow data-state="selected">
        <TableCell className="font-medium">@ada</TableCell>
        <TableCell>12</TableCell>
        <TableCell className="text-right tabular-nums">4,210.55</TableCell>
      </TableRow>
      <TableRow>
        <TableCell className="font-medium">@grace</TableCell>
        <TableCell>9</TableCell>
        <TableCell className="text-right tabular-nums">2,980.10</TableCell>
      </TableRow>
      <TableRow>
        <TableCell className="font-medium">@linus</TableCell>
        <TableCell>7</TableCell>
        <TableCell className="text-right tabular-nums">1,204.00</TableCell>
      </TableRow>
    </TableBody>
    <TableFooter>
      <TableRow>
        <TableCell colSpan={2}>Total</TableCell>
        <TableCell className="text-right tabular-nums">8,394.65</TableCell>
      </TableRow>
    </TableFooter>
  </Table>
);
