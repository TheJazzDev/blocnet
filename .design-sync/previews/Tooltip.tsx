import * as React from "react";
import { Button, Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "blocnet-admin";
import { RefreshCw } from "lucide-react";

export const OnIconButton = () => (
  <div className="flex h-full items-center justify-center">
    <TooltipProvider>
      <Tooltip open>
        <TooltipTrigger asChild>
          <Button variant="ghost" size="icon" aria-label="Refresh">
            <RefreshCw />
          </Button>
        </TooltipTrigger>
        <TooltipContent>Refresh leaderboard</TooltipContent>
      </Tooltip>
    </TooltipProvider>
  </div>
);

export const Below = () => (
  <div className="flex h-full items-center justify-center">
    <TooltipProvider>
      <Tooltip open>
        <TooltipTrigger asChild>
          <Button variant="outline" size="sm">
            Edge score 87
          </Button>
        </TooltipTrigger>
        <TooltipContent side="bottom">Computed 2 hours ago from 14 signals</TooltipContent>
      </Tooltip>
    </TooltipProvider>
  </div>
);
