'use client';

import { useEffect, useState } from 'react';
import AdminShell from '@/components/AdminShell';
import { api, DashboardStats } from '@/lib/api';
import { Users, BookOpen, Calendar, DollarSign, Star, TrendingUp, Activity, Brain } from 'lucide-react';

function StatCard({ icon: Icon, label, value, sub, color }: {
  icon: React.ElementType; label: string; value: string | number; sub?: string; color: string;
}) {
  return (
    <div className="stat-card flex items-start gap-4">
      <div className={`rounded-xl p-3 ${color}`}>
        <Icon size={20} className="text-white" />
      </div>
      <div>
        <p className="text-sm text-gray-500">{label}</p>
        <p className="text-2xl font-bold text-gray-900 mt-0.5">{value}</p>
        {sub && <p className="text-xs text-gray-400 mt-0.5">{sub}</p>}
      </div>
    </div>
  );
}

export default function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [error, setError] = useState('');

  useEffect(() => {
    api.stats()
      .then(setStats)
      .catch(e => setError(e.message));
  }, []);

  return (
    <AdminShell>
      <div className="space-y-8">
        <div>
          <h1 className="page-title">Dashboard</h1>
          <p className="text-gray-500 mt-1">Platform overview and key metrics</p>
        </div>

        {error && (
          <div className="rounded-lg bg-amber-50 border border-amber-200 px-4 py-3 text-sm text-amber-700">
            Could not load stats: {error}. Make sure the admin Lambda is deployed.
          </div>
        )}

        {/* KPI Grid */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <StatCard icon={Users} label="Total Users" value={stats?.totalUsers ?? '—'} sub={`+${stats?.newUsersThisWeek ?? 0} this week`} color="bg-blue-500" />
          <StatCard icon={BookOpen} label="Courses" value={stats?.totalCourses ?? '—'} sub={`${stats?.publishedCourses ?? 0} published`} color="bg-purple-500" />
          <StatCard icon={Calendar} label="Sessions" value={stats?.totalSessions ?? '—'} sub={`${stats?.activeSessions ?? 0} live now`} color="bg-green-500" />
          <StatCard icon={DollarSign} label="Monthly Revenue" value={stats ? `$${stats.monthlyRevenue.toLocaleString()}` : '—'} sub="This month" color="bg-primary-600" />
        </div>

        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <StatCard icon={Activity} label="Active Sessions" value={stats?.activeSessions ?? '—'} color="bg-orange-500" />
          <StatCard icon={TrendingUp} label="Enrollments" value={stats?.totalEnrollments ?? '—'} color="bg-teal-500" />
          <StatCard icon={Star} label="Avg Rating" value={stats?.averageRating ?? '—'} sub={`${stats?.totalReviews ?? 0} reviews`} color="bg-yellow-500" />
          <StatCard icon={Brain} label="AI Sessions" value={stats?.completedSessions ?? '—'} sub="Completed with AI" color="bg-indigo-500" />
        </div>

        {/* User breakdown */}
        {stats && (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <div className="stat-card">
              <h2 className="text-base font-semibold text-gray-900 mb-4">Users by Role</h2>
              <div className="space-y-3">
                {Object.entries(stats.usersByRole).map(([role, count]) => {
                  const total = stats.totalUsers || 1;
                  const pct = Math.round((count / total) * 100);
                  const colors: Record<string, string> = { Student: 'bg-blue-500', Teacher: 'bg-purple-500', Mentor: 'bg-green-500' };
                  return (
                    <div key={role}>
                      <div className="flex justify-between text-sm mb-1">
                        <span className="font-medium text-gray-700">{role}s</span>
                        <span className="text-gray-500">{count} ({pct}%)</span>
                      </div>
                      <div className="h-2 rounded-full bg-gray-100 overflow-hidden">
                        <div className={`h-full rounded-full ${colors[role]}`} style={{ width: `${pct}%` }} />
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>

            <div className="stat-card">
              <h2 className="text-base font-semibold text-gray-900 mb-4">Session Status</h2>
              <div className="grid grid-cols-2 gap-4">
                {[
                  { label: 'Scheduled', value: stats.totalSessions - stats.activeSessions - stats.completedSessions, color: 'text-blue-600 bg-blue-50' },
                  { label: 'In Progress', value: stats.activeSessions, color: 'text-green-600 bg-green-50' },
                  { label: 'Completed', value: stats.completedSessions, color: 'text-purple-600 bg-purple-50' },
                  { label: 'Total', value: stats.totalSessions, color: 'text-gray-600 bg-gray-50' },
                ].map(({ label, value, color }) => (
                  <div key={label} className={`rounded-xl p-4 ${color.split(' ')[1]}`}>
                    <p className={`text-2xl font-bold ${color.split(' ')[0]}`}>{Math.max(0, value)}</p>
                    <p className="text-sm text-gray-600 mt-1">{label}</p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}
      </div>
    </AdminShell>
  );
}
