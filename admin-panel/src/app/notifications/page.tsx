'use client';

import { useState } from 'react';
import AdminShell from '@/components/AdminShell';
import { api } from '@/lib/api';
import { Send, CheckCircle } from 'lucide-react';

const TARGETS = [
  { value: 'all', label: 'All Users' },
  { value: 'Student', label: 'Students only' },
  { value: 'Teacher', label: 'Teachers only' },
  { value: 'Mentor', label: 'Mentors only' },
];

export default function NotificationsPage() {
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [target, setTarget] = useState('all');
  const [sending, setSending] = useState(false);
  const [result, setResult] = useState<{ sentTo: number } | null>(null);
  const [error, setError] = useState('');

  async function send(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setResult(null);
    setSending(true);
    try {
      const r = await api.notifications.broadcast({ title, message, targetRole: target });
      setResult(r);
      setTitle('');
      setMessage('');
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to send');
    } finally {
      setSending(false);
    }
  }

  return (
    <AdminShell>
      <div className="space-y-6 max-w-2xl">
        <div>
          <h1 className="page-title">Notifications</h1>
          <p className="text-gray-500 mt-1">Broadcast announcements to platform users</p>
        </div>

        <div className="bg-white rounded-xl border border-gray-100 p-6 shadow-sm">
          <h2 className="text-base font-semibold text-gray-900 mb-5">Send Broadcast Notification</h2>

          <form onSubmit={send} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Audience</label>
              <div className="flex flex-wrap gap-2">
                {TARGETS.map(t => (
                  <button
                    key={t.value}
                    type="button"
                    onClick={() => setTarget(t.value)}
                    className={`px-3 py-1.5 text-sm font-medium rounded-lg transition-colors ${target === t.value ? 'bg-primary-600 text-white' : 'bg-gray-50 border border-gray-200 text-gray-600 hover:bg-gray-100'}`}
                  >
                    {t.label}
                  </button>
                ))}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Title</label>
              <input
                type="text"
                value={title}
                onChange={e => setTitle(e.target.value)}
                required
                maxLength={100}
                className="w-full rounded-lg border border-gray-200 px-3.5 py-2.5 text-sm outline-none focus:border-primary-500 focus:ring-2 focus:ring-primary-100"
                placeholder="Notification title..."
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Message</label>
              <textarea
                value={message}
                onChange={e => setMessage(e.target.value)}
                required
                maxLength={500}
                rows={4}
                className="w-full rounded-lg border border-gray-200 px-3.5 py-2.5 text-sm outline-none focus:border-primary-500 focus:ring-2 focus:ring-primary-100 resize-none"
                placeholder="Notification message..."
              />
              <p className="text-xs text-gray-400 mt-1 text-right">{message.length}/500</p>
            </div>

            {error && <div className="text-sm text-red-600 bg-red-50 rounded-lg px-4 py-3">{error}</div>}

            {result && (
              <div className="flex items-center gap-3 text-sm text-green-700 bg-green-50 rounded-lg px-4 py-3">
                <CheckCircle size={16} />
                Notification sent to {result.sentTo} users successfully!
              </div>
            )}

            <button
              type="submit"
              disabled={sending}
              className="btn-primary flex items-center gap-2 disabled:opacity-50"
            >
              <Send size={16} />
              {sending ? 'Sending...' : 'Send Notification'}
            </button>
          </form>
        </div>

        <div className="bg-amber-50 rounded-xl border border-amber-200 p-4">
          <p className="text-sm text-amber-800">
            <strong>Note:</strong> Notifications are saved to DynamoDB and delivered to user feeds in the app. Push notifications (FCM/APNs) require Firebase Cloud Messaging integration to be configured.
          </p>
        </div>
      </div>
    </AdminShell>
  );
}
