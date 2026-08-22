import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "DSA612S Library System - Learning Project",
  description: "A student demonstration of IPC between a web client and a Ballerina REST service.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}
