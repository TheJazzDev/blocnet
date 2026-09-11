import * as React from "react";
import { Avatar, AvatarFallback, AvatarImage } from "blocnet-admin";

const photo =
  "data:image/svg+xml;utf8," +
  encodeURIComponent(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80"><defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#6d7cff"/><stop offset="1" stop-color="#22d3ee"/></linearGradient></defs><rect width="80" height="80" fill="url(#g)"/><circle cx="40" cy="31" r="14" fill="#0b1020" opacity=".85"/><path d="M12 76c4-16 16-24 28-24s24 8 28 24z" fill="#0b1020" opacity=".85"/></svg>',
  );

export const WithImage = () => (
  <div className="flex items-center gap-3">
    <Avatar>
      <AvatarImage src={photo} alt="Ada Lovelace" />
      <AvatarFallback>AL</AvatarFallback>
    </Avatar>
    <div className="text-sm">
      <p className="font-medium">Ada Lovelace</p>
      <p className="text-xs text-muted-foreground">@ada · Hunter</p>
    </div>
  </div>
);

export const Fallbacks = () => (
  <div className="flex items-center gap-3">
    <Avatar>
      <AvatarFallback>AD</AvatarFallback>
    </Avatar>
    <Avatar>
      <AvatarFallback>JD</AvatarFallback>
    </Avatar>
    <Avatar>
      <AvatarFallback>SK</AvatarFallback>
    </Avatar>
  </div>
);

export const Sizes = () => (
  <div className="flex items-end gap-3">
    <Avatar className="h-8 w-8">
      <AvatarFallback className="text-xs">SM</AvatarFallback>
    </Avatar>
    <Avatar>
      <AvatarFallback>MD</AvatarFallback>
    </Avatar>
    <Avatar className="h-14 w-14">
      <AvatarFallback className="text-lg">LG</AvatarFallback>
    </Avatar>
  </div>
);

export const Stacked = () => (
  <div className="flex -space-x-2">
    {["AL", "JD", "SK", "MR"].map((i) => (
      <Avatar key={i} className="ring-2 ring-background">
        <AvatarFallback>{i}</AvatarFallback>
      </Avatar>
    ))}
    <Avatar className="ring-2 ring-background">
      <AvatarFallback className="text-xs text-muted-foreground">+12</AvatarFallback>
    </Avatar>
  </div>
);
