'use client';

import { useEffect, useState } from 'react';
import AdminShell from '@/components/AdminShell';
import { api, AIStats } from '@/lib/api';
import { MessageSquare, FileText, Mic, User, Database } from 'lucide-react';

function AIStatCard({ icon: Icon, label, value, desc }: {
  icon: React.ElementType; label: string; value: number; desc: string;
}) {
  return (
    <div className="stat-card flex items-start gap-4">
      <div className="rounded-xl p-3 bg-indigo-100">
        <Icon size={20} className="text-indigo-600" />
      </div>
      <div>
        <p className="text-sm text-gray-500">{label}</p>
        <p className="text-2xl font-bold text-gray-900 mt-0.5">{value.toLocaleString()}</p>
        <p className="text-xs text-gray-400 mt-0.5">{desc}</p>
      </div>
    </div>
  );
}

export default function AIPage() {
  const [stats, setStats] = useState<AIStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    api.ai.stats()
      .then(setStats)
      .catch(e => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  return (
    <AdminShell>
      <div className="space-y-6">
        <div>
          <h1 className="page-title">AI Analytics</h1>
          <p className="text-gray-500 mt-1">Platform AI usage and pipeline stats</p>
        </div>

        {error && (
          <div className="rounded-lg bg-amber-50 border border-amber-200 px-4 py-3 text-sm text-amber-700">
            {error} — AI tables may not be deployed yet.
          </div>
        )}

        {loading ? (
          <div className="py-16 text-center text-gray-400">Loading AI stats...</div>
        ) : stats ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            <AIStatCard icon={MessageSquare} label="AI Chat Messages" value={stats.totalChatMessages} desc="Total messages sent to AI chat" />
            <AIStatCard icon={FileText} label="Session Summaries" value={stats.totalSummaries} desc="AI-generated session summaries" />
            <AIStatCard icon={Mic} label="Transcripts" value={stats.totalTranscripts} desc="Sessions with transcription data" />
            <AIStatCard icon={User} label="AI Twins" value={stats.totalTwins} desc="Personalized AI twin profiles" />
            <AIStatCard icon={Database} label="User Memories" value={stats.usersWithMemory} desc="Users with learning memory stored" />
          </div>
        ) : null}

        <div className="stat-card">
          <h2 className="text-base font-semibold text-gray-900 mb-3">AI Pipeline Overview</h2>
          <div className="space-y-3 text-sm text-gray-600">
            <div className="flex items-start gap-3">
              <div className="h-2 w-2 rounded-full bg-green-400 mt-2 shrink-0" />
              <div>
                <p className="font-medium text-gray-800">Transcription Pipeline</p>
                <p className="text-gray-500">Agora Cloud Recording → S3 → AWS Transcribe → Gemini Summary → DynamoDB</p>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <div className="h-2 w-2 rounded-full bg-blue-400 mt-2 shrink-0" />
              <div>
                <p className="font-medium text-gray-800">AI Chat</p>
                <p className="text-gray-500">User message → Gemini 1.5 Flash → rolling history (20 turns) → DynamoDB</p>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <div className="h-2 w-2 rounded-full bg-purple-400 mt-2 shrink-0" />
              <div>
                <p className="font-medium text-gray-800">AI Twins</p>
                <p className="text-gray-500">Bio + session transcripts → Gemini personality profile → stored twin → ask questions</p>
              </div>
            </div>
            <div className="flex items-start gap-3">
              <div className="h-2 w-2 rounded-full bg-orange-400 mt-2 shrink-0" />
              <div>
                <p className="font-medium text-gray-800">Knowledge Graph</p>
                <p className="text-gray-500">User learning data → DynamoDB nodes/edges → Gemini recommendations</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </AdminShell>
  );
}
