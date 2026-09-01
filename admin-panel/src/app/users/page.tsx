'use client';

import { useEffect, useState, useCallback } from 'react';
import AdminShell from '@/components/AdminShell';
import { api, User } from '@/lib/api';
import { Search, UserCheck, UserX, Shield } from 'lucide-react';

const ROLES = ['All', 'Student', 'Teacher', 'Mentor'];

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [total, setTotal] = useState(0);
  const [role, setRole] = useState('All');
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const params: { role?: string; search?: string } = {};
      if (role !== 'All') params.role = role;
      if (search) params.search = search;
      const data = await api.users.list(params);
      setUsers(data.users);
      setTotal(data.total);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load');
    } finally {
      setLoading(false);
    }
  }, [role, search]);

  useEffect(() => { load(); }, [load]);

  async function toggleStatus(user: User) {
    const next = user.status === 'disabled' ? 'active' : 'disabled';
    await api.users.setStatus(user.userId, next);
    load();
  }

  async function changeRole(user: User, newRole: string) {
    await api.users.setRole(user.userId, newRole);
    load();
  }

  const roleBadge: Record<string, string> = {
    Student: 'badge-blue',
    Teacher: 'badge-purple',
    Mentor: 'badge-green',
  };

  return (
    <AdminShell>
      <div className="space-y-6">
        <div>
          <h1 className="page-title">Users</h1>
          <p className="text-gray-500 mt-1">{total} total users</p>
        </div>

        {/* Filters */}
        <div className="flex flex-wrap gap-3 items-center">
          <div className="relative flex-1 min-w-48 max-w-sm">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              placeholder="Search by name, email, phone..."
              value={search}
              onChange={e => setSearch(e.target.value)}
              className="w-full pl-9 pr-4 py-2 text-sm border border-gray-200 rounded-lg outline-none focus:border-primary-400"
            />
          </div>
          <div className="flex gap-2">
            {ROLES.map(r => (
              <button
                key={r}
                onClick={() => setRole(r)}
                className={`px-3 py-1.5 text-sm font-medium rounded-lg transition-colors ${role === r ? 'bg-primary-600 text-white' : 'bg-white border border-gray-200 text-gray-600 hover:bg-gray-50'}`}
              >
                {r}
              </button>
            ))}
          </div>
        </div>

        {error && <div className="text-sm text-red-600 bg-red-50 rounded-lg px-4 py-3">{error}</div>}

        <div className="bg-white rounded-xl border border-gray-100 overflow-hidden shadow-sm">
          {loading ? (
            <div className="py-16 text-center text-gray-400">Loading users...</div>
          ) : users.length === 0 ? (
            <div className="py-16 text-center text-gray-400">No users found</div>
          ) : (
            <table>
              <thead>
                <tr>
                  <th>User</th>
                  <th>Role</th>
                  <th>Contact</th>
                  <th>Status</th>
                  <th>Joined</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {users.map(user => (
                  <tr key={user.userId}>
                    <td>
                      <div className="flex items-center gap-3">
                        <div className="h-8 w-8 rounded-full bg-primary-100 flex items-center justify-center text-primary-700 text-sm font-bold shrink-0">
                          {user.name?.[0]?.toUpperCase() || '?'}
                        </div>
                        <div>
                          <p className="font-medium">{user.name || '—'}</p>
                          <p className="text-xs text-gray-400">{user.userId.slice(0, 12)}...</p>
                        </div>
                      </div>
                    </td>
                    <td>
                      <span className={roleBadge[user.role] || 'badge-gray'}>{user.role}</span>
                    </td>
                    <td>
                      <p className="text-sm">{user.email || user.phone || '—'}</p>
                    </td>
                    <td>
                      <span className={user.status === 'disabled' ? 'badge-red' : 'badge-green'}>
                        {user.status === 'disabled' ? 'Disabled' : 'Active'}
                      </span>
                    </td>
                    <td className="text-gray-400 text-xs">
                      {user.createdAt ? new Date(user.createdAt).toLocaleDateString() : '—'}
                    </td>
                    <td>
                      <div className="flex gap-2">
                        <button
                          onClick={() => toggleStatus(user)}
                          title={user.status === 'disabled' ? 'Enable user' : 'Disable user'}
                          className={`p-1.5 rounded-lg transition-colors ${user.status === 'disabled' ? 'text-green-600 hover:bg-green-50' : 'text-red-500 hover:bg-red-50'}`}
                        >
                          {user.status === 'disabled' ? <UserCheck size={16} /> : <UserX size={16} />}
                        </button>
                        <select
                          value={user.role}
                          onChange={e => changeRole(user, e.target.value)}
                          className="text-xs border border-gray-200 rounded px-2 py-1 text-gray-600 outline-none"
                          title="Change role"
                        >
                          <option value="Student">Student</option>
                          <option value="Teacher">Teacher</option>
                          <option value="Mentor">Mentor</option>
                        </select>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </AdminShell>
  );
}
