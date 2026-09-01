'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { clearAdminSession, getAdminUser } from '@/lib/auth';
import {
  LayoutDashboard, Users, BookOpen, Calendar, UserCheck,
  DollarSign, Star, Brain, Bell, Settings, LogOut,
} from 'lucide-react';
import clsx from 'clsx';

const nav = [
  { href: '/', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/users', label: 'Users', icon: Users },
  { href: '/courses', label: 'Courses', icon: BookOpen },
  { href: '/sessions', label: 'Sessions', icon: Calendar },
  { href: '/mentors', label: 'Mentors', icon: UserCheck },
  { href: '/earnings', label: 'Earnings', icon: DollarSign },
  { href: '/reviews', label: 'Reviews', icon: Star },
  { href: '/ai', label: 'AI Analytics', icon: Brain },
  { href: '/notifications', label: 'Notifications', icon: Bell },
  { href: '/settings', label: 'Settings', icon: Settings },
];

export default function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const user = getAdminUser();

  function logout() {
    clearAdminSession();
    router.push('/login');
  }

  return (
    <aside className="fixed inset-y-0 left-0 z-40 flex w-60 flex-col bg-white border-r border-gray-200">
      {/* Logo */}
      <div className="flex h-16 items-center px-6 border-b border-gray-200">
        <span className="text-xl font-bold text-primary-600">Toriino</span>
        <span className="ml-1.5 text-xs font-semibold text-gray-400 uppercase tracking-wider">Admin</span>
      </div>

      {/* Nav */}
      <nav className="flex-1 overflow-y-auto py-4 px-3">
        <ul className="space-y-1">
          {nav.map(({ href, label, icon: Icon }) => {
            const active = href === '/' ? pathname === '/' : pathname.startsWith(href);
            return (
              <li key={href}>
                <Link
                  href={href}
                  className={clsx(
                    'flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors',
                    active
                      ? 'bg-primary-50 text-primary-700'
                      : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
                  )}
                >
                  <Icon size={18} className={active ? 'text-primary-600' : 'text-gray-400'} />
                  {label}
                </Link>
              </li>
            );
          })}
        </ul>
      </nav>

      {/* User */}
      <div className="border-t border-gray-200 p-4">
        <div className="flex items-center gap-3">
          <div className="h-8 w-8 rounded-full bg-primary-600 flex items-center justify-center text-white text-sm font-bold">
            {user?.name?.[0]?.toUpperCase() || 'A'}
          </div>
          <div className="min-w-0 flex-1">
            <p className="text-sm font-medium text-gray-900 truncate">{user?.name || 'Admin'}</p>
            <p className="text-xs text-gray-500 truncate">{user?.email}</p>
          </div>
          <button onClick={logout} className="text-gray-400 hover:text-gray-600 transition-colors" title="Logout">
            <LogOut size={18} />
          </button>
        </div>
      </div>
    </aside>
  );
}
