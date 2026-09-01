'use client';

import { useEffect, useState } from 'react';
import AdminShell from '@/components/AdminShell';
import { api, EarningsOverview } from '@/lib/api';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

export default function EarningsPage() {
  const [data, setData] = useState<EarningsOverview | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.earnings.overview()
      .then(setData)
      .catch(() => setData(null))
      .finally(() => setLoading(false));
  }, []);

  return (
    <AdminShell>
      <div className="space-y-6">
        <div>
          <h1 className="page-title">Earnings & Revenue</h1>
          <p className="text-gray-500 mt-1">Platform-wide financial overview</p>
        </div>

        {loading ? (
          <div className="py-16 text-center text-gray-400">Loading earnings data...</div>
        ) : !data ? (
          <div className="py-16 text-center text-gray-400">No earnings data available</div>
        ) : (
          <>
            {/* Total */}
            <div className="stat-card">
              <p className="text-sm text-gray-500">Platform Total Revenue</p>
              <p className="text-4xl font-bold text-gray-900 mt-1">${data.platformTotal.toLocaleString()}</p>
            </div>

            {/* Monthly chart */}
            {data.byMonth.length > 0 && (
              <div className="stat-card">
                <h2 className="text-base font-semibold text-gray-900 mb-4">Monthly Revenue</h2>
                <ResponsiveContainer width="100%" height={240}>
                  <BarChart data={data.byMonth}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                    <XAxis dataKey="month" tick={{ fontSize: 12, fill: '#9ca3af' }} />
                    <YAxis tick={{ fontSize: 12, fill: '#9ca3af' }} tickFormatter={v => `$${v}`} />
                    <Tooltip formatter={(v: number) => [`$${v.toLocaleString()}`, 'Revenue']} />
                    <Bar dataKey="amount" fill="#4f5fff" radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            )}

            {/* Per-user breakdown */}
            <div className="stat-card">
              <h2 className="text-base font-semibold text-gray-900 mb-4">Top Earners</h2>
              <table>
                <thead>
                  <tr>
                    <th>User</th>
                    <th>Sessions</th>
                    <th>Total Earnings</th>
                  </tr>
                </thead>
                <tbody>
                  {data.byUser.slice(0, 20).map(u => (
                    <tr key={u.userId}>
                      <td>
                        <div>
                          <p className="font-medium">{u.name}</p>
                          <p className="text-xs text-gray-400">{u.userId.slice(0, 10)}...</p>
                        </div>
                      </td>
                      <td>{u.sessions}</td>
                      <td className="font-semibold text-green-700">${u.totalEarnings.toLocaleString()}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </>
        )}
      </div>
    </AdminShell>
  );
}
