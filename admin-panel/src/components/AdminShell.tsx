'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { isLoggedIn } from '@/lib/auth';
import Sidebar from './Sidebar';

export default function AdminShell({ children }: { children: React.ReactNode }) {
  const router = useRouter();

  useEffect(() => {
    if (!isLoggedIn()) router.replace('/login');
  }, [router]);

  if (typeof window !== 'undefined' && !isLoggedIn()) return null;

  return (
    <div className="flex h-screen">
      <Sidebar />
      <main className="ml-60 flex-1 overflow-y-auto">
        <div className="p-8">{children}</div>
      </main>
    </div>
  );
}
