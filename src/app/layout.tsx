import type { Metadata } from 'next';
import './globals.css';
export const metadata: Metadata = { title: 'Mocodex LaunchPad — Discover what’s next', description: 'Discover independent apps, games, and tools made by ambitious creators.' };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) { return <html lang="en"><body>{children}</body></html>; }
