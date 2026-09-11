import * as React from "react";
import { Card, CardContent, Tabs, TabsContent, TabsList, TabsTrigger } from "blocnet-admin";

export const Default = () => (
  <Tabs defaultValue="overview" className="w-96">
    <TabsList>
      <TabsTrigger value="overview">Overview</TabsTrigger>
      <TabsTrigger value="updates">Updates</TabsTrigger>
      <TabsTrigger value="team">Team</TabsTrigger>
      <TabsTrigger value="audit" disabled>
        Audit
      </TabsTrigger>
    </TabsList>
    <TabsContent value="overview" className="mt-4 text-sm text-muted-foreground">
      Nebula Swap routes trades across 14 venues. Edge score 87, trending up this week.
    </TabsContent>
  </Tabs>
);

export const FullWidth = () => (
  <Tabs defaultValue="updates" className="w-96">
    <TabsList className="grid w-full grid-cols-3">
      <TabsTrigger value="overview">Overview</TabsTrigger>
      <TabsTrigger value="updates">Updates</TabsTrigger>
      <TabsTrigger value="team">Team</TabsTrigger>
    </TabsList>
    <TabsContent value="updates" className="mt-4">
      <Card>
        <CardContent className="pt-6 text-sm">
          <p className="font-medium">Mainnet contracts audited</p>
          <p className="text-muted-foreground">Published 2 hours ago · urgent</p>
        </CardContent>
      </Card>
    </TabsContent>
  </Tabs>
);
