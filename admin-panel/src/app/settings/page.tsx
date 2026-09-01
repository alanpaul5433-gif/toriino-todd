'use client';

import AdminShell from '@/components/AdminShell';
import { Server, Database, Key, Globe } from 'lucide-react';

const API_BASE = process.env.NEXT_PUBLIC_API_BASE || 'https://pq8cu94cfd.execute-api.us-east-1.amazonaws.com/prod';
const REGION = process.env.NEXT_PUBLIC_COGNITO_REGION || 'us-east-1';

const endpoints = [
  { label: 'Users', path: '/users' },
  { label: 'Courses', path: '/courses' },
  { label: 'Sessions', path: '/sessions' },
  { label: 'Mentors', path: '/mentors' },
  { label: 'Earnings', path: '/earnings' },
  { label: 'Reviews', path: '/reviews' },
  { label: 'Notifications', path: '/notifications' },
  { label: 'AI Chat', path: '/ai/chat/{userId}' },
  { label: 'AI Twins', path: '/ai/twins/{userId}' },
  { label: 'AI Memory', path: '/ai/memory/{userId}' },
  { label: 'Transcripts', path: '/sessions/{id}/transcript' },
  { label: 'Summaries', path: '/sessions/{id}/summary' },
  { label: 'Admin', path: '/admin/**' },
];

const tables = [
  'toriino-users', 'toriino-courses', 'toriino-course-lessons', 'toriino-enrollments',
  'toriino-sessions', 'toriino-mentors', 'toriino-availability',
  'toriino-earnings', 'toriino-reviews', 'toriino-notifications',
  'toriino-transcripts', 'toriino-session-summaries', 'toriino-ai-chat',
  'toriino-ai-twins', 'toriino-ai-memory', 'toriino-knowledge-graph',
];

export default function SettingsPage() {
  return (
    <AdminShell>
      <div className="space-y-6">
        <div>
          <h1 className="page-title">Settings</h1>
          <p className="text-gray-500 mt-1">Platform configuration and infrastructure overview</p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* API Config */}
          <div className="stat-card">
            <div className="flex items-center gap-2 mb-4">
              <Globe size={18} className="text-primary-600" />
              <h2 className="text-base font-semibold text-gray-900">API Gateway</h2>
            </div>
            <div className="space-y-2">
              <div>
                <p className="text-xs text-gray-500">Base URL</p>
                <p className="text-sm font-mono text-gray-700 break-all mt-0.5">{API_BASE}</p>
              </div>
              <div>
                <p className="text-xs text-gray-500">Region</p>
                <p className="text-sm font-mono text-gray-700 mt-0.5">{REGION}</p>
              </div>
              <div>
                <p className="text-xs text-gray-500">Gateway ID</p>
                <p className="text-sm font-mono text-gray-700 mt-0.5">pq8cu94cfd</p>
              </div>
            </div>
          </div>

          {/* Auth */}
          <div className="stat-card">
            <div className="flex items-center gap-2 mb-4">
              <Key size={18} className="text-primary-600" />
              <h2 className="text-base font-semibold text-gray-900">Authentication</h2>
            </div>
            <div className="space-y-2">
              <div>
                <p className="text-xs text-gray-500">Provider</p>
                <p className="text-sm text-gray-700 mt-0.5">AWS Cognito</p>
              </div>
              <div>
                <p className="text-xs text-gray-500">Admin Group</p>
                <p className="text-sm font-mono text-gray-700 mt-0.5">Admins</p>
              </div>
              <div>
                <p className="text-xs text-gray-500">Auth Flow</p>
                <p className="text-sm font-mono text-gray-700 mt-0.5">USER_PASSWORD_AUTH</p>
              </div>
              <p className="text-xs text-gray-400 mt-3">Set NEXT_PUBLIC_COGNITO_CLIENT_ID and NEXT_PUBLIC_COGNITO_USER_POOL_ID in .env.local</p>
            </div>
          </div>
        </div>

        {/* Endpoints */}
        <div className="stat-card">
          <div className="flex items-center gap-2 mb-4">
            <Server size={18} className="text-primary-600" />
            <h2 className="text-base font-semibold text-gray-900">API Endpoints ({endpoints.length})</h2>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
            {endpoints.map(e => (
              <div key={e.path} className="flex items-center gap-2 text-sm">
                <div className="h-1.5 w-1.5 rounded-full bg-green-400 shrink-0" />
                <span className="text-gray-500 w-24 shrink-0">{e.label}</span>
                <span className="font-mono text-xs text-gray-400">{e.path}</span>
              </div>
            ))}
          </div>
        </div>

        {/* DynamoDB Tables */}
        <div className="stat-card">
          <div className="flex items-center gap-2 mb-4">
            <Database size={18} className="text-primary-600" />
            <h2 className="text-base font-semibold text-gray-900">DynamoDB Tables ({tables.length})</h2>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
            {tables.map(t => (
              <div key={t} className="flex items-center gap-2">
                <div className="h-1.5 w-1.5 rounded-full bg-blue-400 shrink-0" />
                <span className="font-mono text-xs text-gray-600">{t}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="rounded-xl bg-blue-50 border border-blue-200 p-4 text-sm text-blue-800">
          <strong>To configure credentials:</strong> Create <code className="font-mono bg-blue-100 px-1 rounded">admin-panel/.env.local</code> with:
          <pre className="mt-2 text-xs bg-white rounded p-3 border border-blue-200 overflow-x-auto">{`NEXT_PUBLIC_API_BASE=https://pq8cu94cfd.execute-api.us-east-1.amazonaws.com/prod
NEXT_PUBLIC_COGNITO_REGION=us-east-1
NEXT_PUBLIC_COGNITO_USER_POOL_ID=us-east-1_XXXXXXXX
NEXT_PUBLIC_COGNITO_CLIENT_ID=YOUR_APP_CLIENT_ID`}</pre>
        </div>
      </div>
    </AdminShell>
  );
}
