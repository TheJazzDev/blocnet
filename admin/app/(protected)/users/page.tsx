import { Search, MoreHorizontal, ShieldCheck, Shield, Pen, User, ChevronUp, ChevronDown } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { PageHeader } from "@/components/page-header";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
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
  DropdownMenuLabel,
} from "@/components/ui/dropdown-menu";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

const mockUsers = [
  {
    id: "1",
    email: "alex@blocnet.io",
    displayName: "Alex Morgan",
    roles: ["owner", "admin"],
    joinedAt: "2025-10-01",
    projectsAssigned: 0,
    updatesPosted: 0,
  },
  {
    id: "2",
    email: "sarah@blocnet.io",
    displayName: "Sarah Chen",
    roles: ["admin"],
    joinedAt: "2025-10-15",
    projectsAssigned: 4,
    updatesPosted: 23,
  },
  {
    id: "3",
    email: "jake@example.com",
    displayName: "Jake Williams",
    roles: ["poster"],
    joinedAt: "2025-11-01",
    projectsAssigned: 3,
    updatesPosted: 45,
  },
  {
    id: "4",
    email: "maria@example.com",
    displayName: "Maria Garcia",
    roles: ["poster"],
    joinedAt: "2025-11-20",
    projectsAssigned: 2,
    updatesPosted: 18,
  },
  {
    id: "5",
    email: "david@example.com",
    displayName: "David Kim",
    roles: ["poster", "user"],
    joinedAt: "2025-12-05",
    projectsAssigned: 1,
    updatesPosted: 7,
  },
  {
    id: "6",
    email: "emily@example.com",
    displayName: "Emily Davis",
    roles: ["user"],
    joinedAt: "2026-01-10",
    projectsAssigned: 0,
    updatesPosted: 0,
  },
  {
    id: "7",
    email: "mike@example.com",
    displayName: "Mike Johnson",
    roles: ["user"],
    joinedAt: "2026-01-25",
    projectsAssigned: 0,
    updatesPosted: 0,
  },
  {
    id: "8",
    email: "lisa@example.com",
    displayName: "Lisa Wang",
    roles: ["user"],
    joinedAt: "2026-02-01",
    projectsAssigned: 0,
    updatesPosted: 0,
  },
];

function roleBadge(role: string) {
  switch (role) {
    case "owner":
      return (
        <Badge className="bg-purple-500/10 text-purple-400 border-purple-500/20" variant="outline">
          <ShieldCheck className="mr-1 h-3 w-3" />
          Owner
        </Badge>
      );
    case "admin":
      return (
        <Badge className="bg-blue-500/10 text-blue-400 border-blue-500/20" variant="outline">
          <Shield className="mr-1 h-3 w-3" />
          Admin
        </Badge>
      );
    case "poster":
      return (
        <Badge className="bg-emerald-500/10 text-emerald-400 border-emerald-500/20" variant="outline">
          <Pen className="mr-1 h-3 w-3" />
          Poster
        </Badge>
      );
    default:
      return (
        <Badge variant="secondary">
          <User className="mr-1 h-3 w-3" />
          User
        </Badge>
      );
  }
}

function getInitials(name: string) {
  return name
    .split(" ")
    .map((w) => w[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);
}

export default function UsersPage() {
  const roleCounts = {
    total: mockUsers.length,
    admins: mockUsers.filter((u) => u.roles.includes("admin")).length,
    posters: mockUsers.filter((u) => u.roles.includes("poster")).length,
    users: mockUsers.filter((u) => u.roles.length === 1 && u.roles[0] === "user").length,
  };

  return (
    <div className="space-y-6">
      <PageHeader
        title="Users & Roles"
        description="Manage user roles and permissions across the platform."
      />

      {/* Role summary cards */}
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Total Users</p>
                <p className="text-2xl font-bold">{roleCounts.total}</p>
              </div>
              <div className="flex h-10 w-10 items-center justify-center rounded-full bg-secondary">
                <User className="h-5 w-5 text-muted-foreground" />
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Admins</p>
                <p className="text-2xl font-bold">{roleCounts.admins}</p>
              </div>
              <div className="flex h-10 w-10 items-center justify-center rounded-full bg-blue-500/10">
                <Shield className="h-5 w-5 text-blue-400" />
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Posters</p>
                <p className="text-2xl font-bold">{roleCounts.posters}</p>
              </div>
              <div className="flex h-10 w-10 items-center justify-center rounded-full bg-emerald-500/10">
                <Pen className="h-5 w-5 text-emerald-400" />
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-muted-foreground">Regular Users</p>
                <p className="text-2xl font-bold">{roleCounts.users}</p>
              </div>
              <div className="flex h-10 w-10 items-center justify-center rounded-full bg-secondary">
                <User className="h-5 w-5 text-muted-foreground" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input placeholder="Search by name or email..." className="pl-9" />
        </div>
        <Select defaultValue="all">
          <SelectTrigger className="w-[140px]">
            <SelectValue placeholder="Role" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Roles</SelectItem>
            <SelectItem value="owner">Owner</SelectItem>
            <SelectItem value="admin">Admin</SelectItem>
            <SelectItem value="poster">Poster</SelectItem>
            <SelectItem value="user">User</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {/* Users table */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base">All Users</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>User</TableHead>
                <TableHead>Roles</TableHead>
                <TableHead className="text-right">Projects</TableHead>
                <TableHead className="text-right">Updates</TableHead>
                <TableHead className="text-right">Joined</TableHead>
                <TableHead className="w-[40px]" />
              </TableRow>
            </TableHeader>
            <TableBody>
              {mockUsers.map((user) => (
                <TableRow key={user.id}>
                  <TableCell>
                    <div className="flex items-center gap-3">
                      <Avatar className="h-8 w-8">
                        <AvatarFallback className="text-xs">
                          {getInitials(user.displayName)}
                        </AvatarFallback>
                      </Avatar>
                      <div>
                        <p className="font-medium">{user.displayName}</p>
                        <p className="text-xs text-muted-foreground">{user.email}</p>
                      </div>
                    </div>
                  </TableCell>
                  <TableCell>
                    <div className="flex flex-wrap gap-1">
                      {user.roles.map((role) => (
                        <span key={role}>{roleBadge(role)}</span>
                      ))}
                    </div>
                  </TableCell>
                  <TableCell className="text-right">{user.projectsAssigned}</TableCell>
                  <TableCell className="text-right">{user.updatesPosted}</TableCell>
                  <TableCell className="text-right text-sm text-muted-foreground">
                    {user.joinedAt}
                  </TableCell>
                  <TableCell>
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button variant="ghost" size="icon" className="h-8 w-8">
                          <MoreHorizontal className="h-4 w-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuLabel>Manage Role</DropdownMenuLabel>
                        <DropdownMenuSeparator />
                        <DropdownMenuItem>
                          <ChevronUp className="h-4 w-4" />
                          Promote to Admin
                        </DropdownMenuItem>
                        <DropdownMenuItem>
                          <ChevronUp className="h-4 w-4" />
                          Promote to Poster
                        </DropdownMenuItem>
                        <DropdownMenuSeparator />
                        <DropdownMenuItem className="text-destructive">
                          <ChevronDown className="h-4 w-4" />
                          Remove Role
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
