import { Plus, Search, MoreHorizontal, ExternalLink, Globe, Pause, Archive } from "lucide-react";
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
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

const mockProjects = [
  {
    id: "1",
    name: "Bitcoin",
    symbol: "BTC",
    status: "active" as const,
    primaryTag: "Layer 1",
    updates: 48,
    followers: 892,
    posters: 5,
    createdAt: "2025-11-12",
  },
  {
    id: "2",
    name: "Ethereum",
    symbol: "ETH",
    status: "active" as const,
    primaryTag: "Layer 1",
    updates: 67,
    followers: 1204,
    posters: 8,
    createdAt: "2025-11-10",
  },
  {
    id: "3",
    name: "Solana",
    symbol: "SOL",
    status: "active" as const,
    primaryTag: "Layer 1",
    updates: 31,
    followers: 564,
    posters: 3,
    createdAt: "2025-12-01",
  },
  {
    id: "4",
    name: "Chainlink",
    symbol: "LINK",
    status: "active" as const,
    primaryTag: "Oracle",
    updates: 22,
    followers: 340,
    posters: 2,
    createdAt: "2025-12-15",
  },
  {
    id: "5",
    name: "Uniswap",
    symbol: "UNI",
    status: "paused" as const,
    primaryTag: "DeFi",
    updates: 15,
    followers: 278,
    posters: 2,
    createdAt: "2026-01-03",
  },
  {
    id: "6",
    name: "Aave",
    symbol: "AAVE",
    status: "active" as const,
    primaryTag: "DeFi",
    updates: 19,
    followers: 215,
    posters: 2,
    createdAt: "2026-01-10",
  },
  {
    id: "7",
    name: "Polygon",
    symbol: "POL",
    status: "archived" as const,
    primaryTag: "Layer 2",
    updates: 8,
    followers: 102,
    posters: 1,
    createdAt: "2026-01-20",
  },
];

function statusBadge(status: "active" | "paused" | "archived") {
  switch (status) {
    case "active":
      return (
        <Badge variant="outline" className="border-emerald-500/20 bg-emerald-500/10 text-emerald-500">
          Active
        </Badge>
      );
    case "paused":
      return (
        <Badge variant="outline" className="border-yellow-500/20 bg-yellow-500/10 text-yellow-500">
          Paused
        </Badge>
      );
    case "archived":
      return (
        <Badge variant="outline" className="border-red-500/20 bg-red-500/10 text-red-400">
          Archived
        </Badge>
      );
  }
}

export default function ProjectsPage() {
  return (
    <div className="space-y-6">
      <PageHeader
        title="Projects"
        description="Manage crypto projects tracked on the platform."
      >
        <Button>
          <Plus className="h-4 w-4" />
          New Project
        </Button>
      </PageHeader>

      {/* Filters */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input placeholder="Search projects..." className="pl-9" />
        </div>
        <div className="flex gap-2">
          <Select defaultValue="all">
            <SelectTrigger className="w-[130px]">
              <SelectValue placeholder="Status" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Status</SelectItem>
              <SelectItem value="active">Active</SelectItem>
              <SelectItem value="paused">Paused</SelectItem>
              <SelectItem value="archived">Archived</SelectItem>
            </SelectContent>
          </Select>
          <Select defaultValue="all">
            <SelectTrigger className="w-[130px]">
              <SelectValue placeholder="Tag" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Tags</SelectItem>
              <SelectItem value="layer-1">Layer 1</SelectItem>
              <SelectItem value="layer-2">Layer 2</SelectItem>
              <SelectItem value="defi">DeFi</SelectItem>
              <SelectItem value="oracle">Oracle</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>

      {/* Projects table */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base">
            All Projects
            <span className="ml-2 text-sm font-normal text-muted-foreground">
              ({mockProjects.length})
            </span>
          </CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Project</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Tag</TableHead>
                <TableHead className="text-right">Updates</TableHead>
                <TableHead className="text-right">Followers</TableHead>
                <TableHead className="text-right">Posters</TableHead>
                <TableHead className="text-right">Created</TableHead>
                <TableHead className="w-[40px]" />
              </TableRow>
            </TableHeader>
            <TableBody>
              {mockProjects.map((project) => (
                <TableRow key={project.id}>
                  <TableCell>
                    <div className="flex items-center gap-3">
                      <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-secondary text-xs font-bold">
                        {project.symbol?.slice(0, 3) ?? project.name.slice(0, 2)}
                      </div>
                      <div>
                        <p className="font-medium">{project.name}</p>
                        <p className="text-xs text-muted-foreground">{project.symbol}</p>
                      </div>
                    </div>
                  </TableCell>
                  <TableCell>{statusBadge(project.status)}</TableCell>
                  <TableCell>
                    <Badge variant="secondary">{project.primaryTag}</Badge>
                  </TableCell>
                  <TableCell className="text-right">{project.updates}</TableCell>
                  <TableCell className="text-right">{project.followers}</TableCell>
                  <TableCell className="text-right">{project.posters}</TableCell>
                  <TableCell className="text-right text-muted-foreground text-sm">
                    {project.createdAt}
                  </TableCell>
                  <TableCell>
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button variant="ghost" size="icon" className="h-8 w-8">
                          <MoreHorizontal className="h-4 w-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem>
                          <ExternalLink className="h-4 w-4" />
                          View Details
                        </DropdownMenuItem>
                        <DropdownMenuItem>
                          <Globe className="h-4 w-4" />
                          Edit Project
                        </DropdownMenuItem>
                        <DropdownMenuSeparator />
                        <DropdownMenuItem>
                          <Pause className="h-4 w-4" />
                          Pause Project
                        </DropdownMenuItem>
                        <DropdownMenuItem className="text-destructive">
                          <Archive className="h-4 w-4" />
                          Archive Project
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
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
