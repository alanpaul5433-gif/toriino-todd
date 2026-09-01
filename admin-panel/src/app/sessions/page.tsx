'use client';

import { useEffect, useState, useCallback } from 'react';
import AdminShell from '@/components/AdminShell';
import { api, Session, SessionSummary } from '@/lib/api';
import { Eye, XCircle } from 'lucide-react';

const STATUSES = ['All', 'scheduled', 'in_progress', 'completed', 'cancelled'];

export default function SessionsPage() {
  const [sessions, setSessions] = useState<Session[]>([]);
  const [total, setTotal] = useState(0);
  const [statusFilter, setStatusFilter] = useState('All');
  const [loading, setLoading] = useState(true);
  const [summary, setSummary] = useState<SessionSummary | null>(null);
  const [summaryLoading, setSummaryLoading] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    const params = statusFilter !== 'All' ? { status: statusFilter } : {};
    const data = await api.sessions.list(params).catch(() => ({ sessions: [], total: 0 }));
    setSessions(data.sessions);
    setTotal(data.total);
    setLoading(false);
  }, [statusFilter]);

  useEffect(() => { load(); }, [load]);

  async function viewSummary(sessionId: string) {
    setSummaryLoading(true);
    setSummary(null);
    try {
      const s = await api.sessions.getSummary(sessionId);
      setSummary(s);
    } catch {
      setSummary(null);
      alert('No AI summary available for this session yet.');
    } finally {
      setSummaryLoading(false);
    }
  }

  async function cancelSession(sessionId: string) {
    if (!confirm('Cancel this session?')) return;
    await api.sessions.setStatus(sessionId, 'cancelled');
    load();
  }

  const statusBadge: Record<string, string> = {
    scheduled: 'badge-blue',
    in_progress: 'badge-green',
    completed: 'badge-purple',
    cancelled: 'badge-red',
  };

  return (
    <AdminShell>
      <div className="space-y-6">
        <div>
          <h1 className="page-title">Sessions</h1>
          <p className="text-gray-500 mt-1">{total} total sessions</p>
        </div>

        <div className="flex gap-2 flex-wrap">
          {STATUSES.map(s => (
            <button
              key={s}
              onClick={() => setStatusFilter(s)}
              className={`px-3 py-1.5 text-sm font-medium rounded-lg capitalize transition-colors ${statusFilter === s ? 'bg-primary-600 text-white' : 'bg-white border border-gray-200 text-gray-600 hover:bg-gray-50'}`}
            >
              {s.replace('_', ' ')}
            </button>
          ))}
        </div>

        <div className="bg-white rounded-xl border border-gray-100 overflow-hidden shadow-sm">
          {loading ? (
            <div className="py-16 text-center text-gray-400">Loading sessions...</div>
          ) : sessions.length === 0 ? (
            <div className="py-16 text-center text-gray-400">No sessions found</div>
          ) : (
            <table>
              <thead>
                <tr>
                  <th>Session ID</th>
                  <th>Student</th>
                  <th>Mentor</th>
                  <th>Date & Time</th>
                  <th>Duration</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {sessions.map(s => (
                  <tr key={s.sessionId}>
                    <td className="font-mono text-xs text-gray-400">{s.sessionId.slice(0, 10)}...</td>
                    <td className="text-xs">{s.studentId?.slice(0, 10)}...</td>
                    <td className="text-xs">{s.mentorId?.slice(0, 10)}...</td>
                    <td className="text-xs">{s.dateTime ? new Date(s.dateTime).toLocaleString() : '—'}</td>
                    <td>{s.duration ? `${s.duration} min` : '—'}</td>
                    <td><span className={statusBadge[s.status] || 'badge-gray'}>{s.status.replace('_', ' ')}</span></td>
                    <td>
                      <div className="flex gap-1.5">
                        <button onClick={() => viewSummary(s.sessionId)} className="p-1.5 text-primary-600 hover:bg-primary-50 rounded-lg" title="View AI Summary">
                          <Eye size={16} />
                        </button>
                        {s.status !== 'cancelled' && s.status !== 'completed' && (
                          <button onClick={() => cancelSession(s.sessionId)} className="p-1.5 text-red-500 hover:bg-red-50 rounded-lg" title="Cancel">
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

        {/* Summary modal */}
        {(summaryLoading || summary) && (
          <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50 p-4" onClick={() => setSummary(null)}>
            <div className="bg-white rounded-2xl max-w-lg w-full max-h-[80vh] overflow-y-auto p-6 shadow-xl" onClick={e => e.stopPropagation()}>
              {summaryLoading ? (
                <p className="text-gray-500 text-center py-8">Loading summary...</p>
              ) : summary ? (
                <>
                  <h2 className="text-lg font-semibold text-gray-900 mb-4">AI Session Summary</h2>
                  <p className="text-sm text-gray-700 mb-4">{summary.summary}</p>
                  {summary.keyTopics?.length > 0 && (
                    <div className="mb-3">
                      <p className="text-xs font-semibold text-gray-500 uppercase mb-2">Key Topics</p>
                      <div className="flex flex-wrap gap-2">{summary.keyTopics.map((t, i) => <span key={i} className="badge-blue">{t}</span>)}</div>
                    </div>
                  )}
                  {summary.actionItems?.length > 0 && (
                    <div className="mb-3">
                      <p className="text-xs font-semibold text-gray-500 uppercase mb-2">Action Items</p>
                      <ul className="text-sm text-gray-700 space-y-1">{summary.actionItems.map((a, i) => <li key={i} className="flex gap-2"><span className="text-primary-500">•</span>{a}</li>)}</ul>
                    </div>
                  )}
                  <button onClick={() => setSummary(null)} className="btn-secondary w-full mt-4">Close</button>
                </>
              ) : null}
            </div>
          </div>
        )}
      </div>
    </AdminShell>
  );
}
