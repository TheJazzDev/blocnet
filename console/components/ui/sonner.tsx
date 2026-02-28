"use client";

import { Toaster as Sonner, type ToasterProps } from "sonner";

export function Toaster(props: ToasterProps) {
  return (
    <Sonner
      expand
      richColors
      closeButton
      position="top-right"
      toastOptions={{
        duration: 4000,
      }}
      {...props}
    />
  );
}
