import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Ministry Library Network",
  description: "Manage shared library resources, campus assets, loans, bookings, and schedules.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}
