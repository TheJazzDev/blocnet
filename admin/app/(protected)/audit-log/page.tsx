import { Download, Search, Filter, Clock } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { PageHeader } from "@/components/page-header";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

const mockAuditLogs = [
  {
    id: "1",
    action: "project.create",
    actor: "admin@blocnet.io",
    resourceType: "project",
    resourceId: "proj_abc123",
    description: 'Created project "Solana Pay Integration"',
    metadata: { projectName: "Solana Pay Integration" },
    createdAt: "2026-02-17 14:32:00",
  },
  {
    id: "2",
    action: "admin_application.review",
    actor: "owner@blocnet.io",
    resourceType: "admin_application",
    resourceId: "app_def456",
    description: "Approved admin application for jake@example.com",
    metadata: { status: "approved", targetRole: "poster" },
    createdAt: "2026-02-17 14:15:00",
  },
  {
    id: "3",
    action: "update.create",
    actor: "poster@blocnet.io",
    resourceType: "update",
    resourceId: "upd_ghi789",
    description: 'Published update "Ethereum Merge — Post-upgrade Analysis"',
    metadata: { urgency: "high" },
    createdAt: "2026-02-17 13:00:00",
  },
  {
    id: "4",
    action: "role.promote",
    actor: "owner@blocnet.io",
    resourceType: "user_role",
    resourceId: "ur_jkl012",
    description: "Promoted sarah@example.com to admin",
    metadata: { role: "admin" },
    createdAt: "2026-02-17 11:00:00",
  },
  {
    id: "5",
    action: "project_proposal.create",
    actor: "poster@blocnet.io",
    resourceType: "project_proposal",
    resourceId: "pp_mno345",
    description: 'Submitted project proposal "Chainlink CCIP"',
    metadata: { proposalName: "Chainlink CCIP" },
    createdAt: "2026-02-17 09:00:00",
  },
  {
    id: "6",
    action: "comment.delete",
    actor: "admin@blocnet.io",
    resourceType: "comment",
    resourceId: "cmt_pqr678",
    description: "Deleted comment on Bitcoin Lightning Update #34",
    metadata: { reason: "spam" },
    createdAt: "2026-02-17 08:00:00",
  },
  {
    id: "7",
    action: "project.update",
    actor: "admin@blocnet.io",
    resourceType: "project",
    resourceId: "proj_stu901",
    description: 'Updated project status for "Polygon" to archived',
    metadata: { field: "status", newValue: "archived" },
    createdAt: "2026-02-16 16:30:00",
  },
  {
    id: "8",
    action: "project_poster.assign",
    actor: "admin@blocnet.io",
    resourceType: "project_poster",
    resourceId: "pp_vwx234",
    description: "Assigned poster maria@example.com to Ethereum project",
    metadata: { projectName: "Ethereum", posterEmail: "maria@example.com" },
    createdAt: "2026-02-16 14:00:00",
  },
  {
    id: "9",
    action: "update.archive",
    actor: "admin@blocnet.io",
    resourceType: "update",
    resourceId: "upd_yza567",
    description: "Archived outdated update on DeFi Summer recap",
    metadata: {},
    createdAt: "2026-02-16 11:00:00",
  },
  {
    id: "10",
    action: "follow.create",
    actor: "user@example.com",
    resourceType: "follow",
    resourceId: "flw_bcd890",
    description: "User followed Bitcoin project",
    metadata: { projectName: "Bitcoin" },
    createdAt: "2026-02-16 09:30:00",
  },
];

function actionBadge(action: string) {
  const [, verb] = action.split(".");
  let variant: "default" | "secondary" | "destructive" | "outline" = "outline";
  if (verb === "create" || verb === "promote" || verb === "assign") variant = "default";
  if (verb === "update" || verb === "review") variant = "secondary";
  if (verb === "delete" || verb === "archive") variant = "destructive";

  return (
    <Badge variant={variant} className="font-mono text-[10px]">
      {action}
    </Badge>
  );
}

function resourceTypeBadge(type: string) {
  return (
    <Badge variant="secondary" className="text-[10px]">
      {type.replace(/_/g, " ")}
    </Badge>
  );
}

export default function AuditLogPage() {
  return (
    <div className="space-y-6">
      <PageHeader
        title="Audit Log"
        description="Complete history of all admin actions on the platform."
      >
        <Button variant="outline">
          <Download className="h-4 w-4" />
          Export
        </Button>
      </PageHeader>

      {/* Filters */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input placeholder="Search by action, actor, or resource..." className="pl-9" />
        </div>
        <div className="flex gap-2">
          <Select defaultValue="all">
            <SelectTrigger className="w-[160px]">
              <SelectValue placeholder="Action Type" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Actions</SelectItem>
              <SelectItem value="create">Create</SelectItem>
              <SelectItem value="update">Update</SelectItem>
              <SelectItem value="delete">Delete</SelectItem>
              <SelectItem value="review">Review</SelectItem>
              <SelectItem value="promote">Promote</SelectItem>
            </SelectContent>
          </Select>
          <Select defaultValue="all">
            <SelectTrigger className="w-[160px]">
              <SelectValue placeholder="Resource" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Resources</SelectItem>
              <SelectItem value="project">Project</SelectItem>
              <SelectItem value="update">Update</SelectItem>
              <SelectItem value="comment">Comment</SelectItem>
              <SelectItem value="admin_application">Application</SelectItem>
              <SelectItem value="user_role">User Role</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>

      {/* Audit log table */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center gap-2 text-base">
            <Filter className="h-4 w-4" />
            Event Log
            <span className="text-sm font-normal text-muted-foreground">
              (showing latest {mockAuditLogs.length} events)
            </span>
          </CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Timestamp</TableHead>
                <TableHead>Action</TableHead>
                <TableHead>Resource</TableHead>
                <TableHead>Description</TableHead>
                <TableHead>Actor</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {mockAuditLogs.map((log) => (
                <TableRow key={log.id}>
                  <TableCell className="whitespace-nowrap">
                    <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
                      <Clock className="h-3 w-3" />
                      {log.createdAt}
                    </div>
                  </TableCell>
                  <TableCell>{actionBadge(log.action)}</TableCell>
                  <TableCell>{resourceTypeBadge(log.resourceType)}</TableCell>
                  <TableCell>
                    <p className="max-w-[300px] truncate text-sm">{log.description}</p>
                  </TableCell>
                  <TableCell>
                    <span className="text-sm text-muted-foreground">{log.actor}</span>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}
