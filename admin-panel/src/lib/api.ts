const BASE = process.env.NEXT_PUBLIC_API_BASE || '';

function getToken(): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem('admin_token');
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = getToken();
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const r = await fetch(`${BASE}/admin${path}`, { ...options, headers });
  if (!r.ok) {
    const err = await r.json().catch(() => ({ error: r.statusText }));
    throw new Error(err.error || 'Request failed');
  }
  return r.json();
}

export const api = {
  stats: () => request<DashboardStats>('/stats'),

  users: {
    list: (params?: { role?: string; search?: string }) => {
      const qs = new URLSearchParams(params as Record<string, string>).toString();
      return request<{ users: User[]; total: number }>(`/users${qs ? `?${qs}` : ''}`);
    },
    setStatus: (userId: string, status: 'active' | 'disabled') =>
      request(`/users/${userId}/status`, { method: 'PUT', body: JSON.stringify({ status }) }),
    setRole: (userId: string, role: string) =>
      request(`/users/${userId}/role`, { method: 'PUT', body: JSON.stringify({ role }) }),
    delete: (userId: string) => request(`/users/${userId}`, { method: 'DELETE' }),
  },

  courses: {
    list: (params?: { status?: string }) => {
      const qs = new URLSearchParams(params as Record<string, string>).toString();
      return request<{ courses: Course[]; total: number }>(`/courses${qs ? `?${qs}` : ''}`);
    },
    setStatus: (courseId: string, status: string) =>
      request(`/courses/${courseId}/status`, { method: 'PUT', body: JSON.stringify({ status }) }),
    delete: (courseId: string) => request(`/courses/${courseId}`, { method: 'DELETE' }),
  },

  sessions: {
    list: (params?: { status?: string }) => {
      const qs = new URLSearchParams(params as Record<string, string>).toString();
      return request<{ sessions: Session[]; total: number }>(`/sessions${qs ? `?${qs}` : ''}`);
    },
    getSummary: (sessionId: string) => request<SessionSummary>(`/sessions/${sessionId}/summary`),
    setStatus: (sessionId: string, status: string) =>
      request(`/sessions/${sessionId}/status`, { method: 'PUT', body: JSON.stringify({ status }) }),
  },

  mentors: {
    list: () => request<{ mentors: Mentor[]; total: number }>('/mentors'),
    setApproval: (mentorId: string, approved: boolean) =>
      request(`/mentors/${mentorId}/approval`, { method: 'PUT', body: JSON.stringify({ approved }) }),
  },

  earnings: {
    overview: () => request<EarningsOverview>('/earnings'),
  },

  reviews: {
    list: (params?: { rating?: number; type?: string }) => {
      const qs = new URLSearchParams(params as Record<string, string>).toString();
      return request<{ reviews: Review[]; total: number }>(`/reviews${qs ? `?${qs}` : ''}`);
    },
    delete: (targetId: string, reviewId: string) =>
      request(`/reviews/${targetId}/${reviewId}`, { method: 'DELETE' }),
  },

  ai: {
    stats: () => request<AIStats>('/ai/stats'),
  },

  notifications: {
    broadcast: (payload: { title: string; message: string; targetRole?: string }) =>
      request<{ success: boolean; sentTo: number }>('/notifications/broadcast', {
        method: 'POST',
        body: JSON.stringify(payload),
      }),
  },
};

// Types
export interface DashboardStats {
  totalUsers: number;
  usersByRole: { Student: number; Teacher: number; Mentor: number };
  newUsersThisWeek: number;
  totalCourses: number;
  publishedCourses: number;
  totalSessions: number;
  activeSessions: number;
  completedSessions: number;
  totalEnrollments: number;
  monthlyRevenue: number;
  totalReviews: number;
  averageRating: number;
}

export interface User {
  userId: string;
  name: string;
  email?: string;
  phone?: string;
  role: 'Student' | 'Teacher' | 'Mentor';
  bio?: string;
  avatarUrl?: string;
  status?: string;
  createdAt?: string;
}

export interface Course {
  courseId: string;
  teacherId: string;
  title: string;
  category?: string;
  price?: number;
  status: 'draft' | 'published' | 'rejected';
  rating?: number;
  enrollmentCount?: number;
  createdAt?: string;
}

export interface Session {
  sessionId: string;
  studentId: string;
  mentorId: string;
  dateTime: string;
  duration?: number;
  status: 'scheduled' | 'in_progress' | 'completed' | 'cancelled';
  createdAt?: string;
}

export interface SessionSummary {
  sessionId: string;
  summary: string;
  actionItems: string[];
  keyTopics: string[];
  insights: string[];
}

export interface Mentor {
  mentorId: string;
  userProfile?: User;
  approved?: boolean;
  reviewCount: number;
  averageRating: number;
  hourlyRate?: number;
  specializations?: string[];
}

export interface EarningsOverview {
  platformTotal: number;
  byMonth: { month: string; amount: number }[];
  byUser: { userId: string; name: string; totalEarnings: number; sessions: number }[];
}

export interface Review {
  targetId: string;
  reviewId: string;
  rating: number;
  comment?: string;
  targetType: 'mentor' | 'teacher' | 'course';
  reviewerId?: string;
  createdAt?: string;
}

export interface AIStats {
  totalChatMessages: number;
  totalSummaries: number;
  totalTranscripts: number;
  totalTwins: number;
  usersWithMemory: number;
}
