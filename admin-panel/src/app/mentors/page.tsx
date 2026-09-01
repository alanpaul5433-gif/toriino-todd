'use client';

import { useEffect, useState } from 'react';
import AdminShell from '@/components/AdminShell';
import { api, Mentor } from '@/lib/api';
import { CheckCircle, XCircle } from 'lucide-react';

export default function MentorsPage() {
  const [mentors, setMentors] = useState<Mentor[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);

  async function load() {
    setLoading(true);
    const data = await api.mentors.list().catch(() => ({ mentors: [], total: 0 }));
    setMentors(data.mentors);
    setTotal(data.total);
    setLoading(false);
  }

  useEffect(() => { load(); }, []);

  async function setApproval(mentorId: string, approved: boolean) {
    await api.mentors.setApproval(mentorId, approved);
    load();
  }

  return (
    <AdminShell>
      <div className="space-y-6">
        <div>
          <h1 className="page-title">Mentors</h1>
          <p className="text-gray-500 mt-1">{total} mentor profiles</p>
        </div>

        <div className="bg-white rounded-xl border border-gray-100 overflow-hidden shadow-sm">
          {loading ? (
            <div className="py-16 text-center text-gray-400">Loading mentors...</div>
          ) : mentors.length === 0 ? (
            <div className="py-16 text-center text-gray-400">No mentor profiles found</div>
          ) : (
            <table>
              <thead>
                <tr>
                  <th>Mentor</th>
                  <th>Specializations</th>
                  <th>Rate</th>
                  <th>Reviews</th>
                  <th>Avg Rating</th>
                  <th>Approval</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {mentors.map(m => (
                  <tr key={m.mentorId}>
                    <td>
                      <div className="flex items-center gap-3">
                        <div className="h-8 w-8 rounded-full bg-green-100 flex items-center justify-center text-green-700 text-sm font-bold shrink-0">
                          {m.userProfile?.name?.[0]?.toUpperCase() || 'M'}
                        </div>
                        <div>
                          <p className="font-medium">{m.userProfile?.name || '—'}</p>
                          <p className="text-xs text-gray-400">{m.mentorId.slice(0, 10)}...</p>
                        </div>
                      </div>
                    </td>
                    <td>
                      <div className="flex flex-wrap gap-1">
                        {m.specializations?.slice(0, 3).map((s, i) => (
                          <span key={i} className="badge-gray text-xs">{s}</span>
                        )) || <span className="text-gray-400">—</span>}
                      </div>
                    </td>
                    <td>{m.hourlyRate ? `$${m.hourlyRate}/hr` : '—'}</td>
                    <td>{m.reviewCount}</td>
                    <td>{m.averageRating ? `⭐ ${m.averageRating}` : '—'}</td>
                    <td>
                      <span className={m.approved ? 'badge-green' : 'badge-yellow'}>
                        {m.approved ? 'Approved' : 'Pending'}
                      </span>
                    </td>
                    <td>
                      <div className="flex gap-1.5">
                        {!m.approved && (
                          <button onClick={() => setApproval(m.mentorId, true)} className="p-1.5 text-green-600 hover:bg-green-50 rounded-lg" title="Approve">
                            <CheckCircle size={16} />
                          </button>
                        )}
                        {m.approved && (
                          <button onClick={() => setApproval(m.mentorId, false)} className="p-1.5 text-red-500 hover:bg-red-50 rounded-lg" title="Revoke">
                            <XCircle size={16} />
                          </button>
                        )}
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
