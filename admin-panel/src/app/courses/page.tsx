'use client';

import { useEffect, useState, useCallback } from 'react';
import AdminShell from '@/components/AdminShell';
import { api, Course } from '@/lib/api';
import { CheckCircle, XCircle, Trash2 } from 'lucide-react';

const STATUSES = ['All', 'draft', 'published', 'rejected'];

export default function CoursesPage() {
  const [courses, setCourses] = useState<Course[]>([]);
  const [total, setTotal] = useState(0);
  const [statusFilter, setStatusFilter] = useState('All');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const params = statusFilter !== 'All' ? { status: statusFilter } : {};
      const data = await api.courses.list(params);
      setCourses(data.courses);
      setTotal(data.total);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed');
    } finally {
      setLoading(false);
    }
  }, [statusFilter]);

  useEffect(() => { load(); }, [load]);

  async function setStatus(courseId: string, status: string) {
    await api.courses.setStatus(courseId, status);
    load();
  }

  async function deleteCourse(courseId: string) {
    if (!confirm('Delete this course permanently?')) return;
    await api.courses.delete(courseId);
    load();
  }

  const statusBadge: Record<string, string> = {
    published: 'badge-green',
    draft: 'badge-yellow',
    rejected: 'badge-red',
  };

  return (
    <AdminShell>
      <div className="space-y-6">
        <div>
          <h1 className="page-title">Courses</h1>
          <p className="text-gray-500 mt-1">{total} total courses</p>
        </div>

        <div className="flex gap-2">
          {STATUSES.map(s => (
            <button
              key={s}
              onClick={() => setStatusFilter(s)}
              className={`px-3 py-1.5 text-sm font-medium rounded-lg capitalize transition-colors ${statusFilter === s ? 'bg-primary-600 text-white' : 'bg-white border border-gray-200 text-gray-600 hover:bg-gray-50'}`}
            >
              {s}
            </button>
          ))}
        </div>

        {error && <div className="text-sm text-red-600 bg-red-50 rounded-lg px-4 py-3">{error}</div>}

        <div className="bg-white rounded-xl border border-gray-100 overflow-hidden shadow-sm">
          {loading ? (
            <div className="py-16 text-center text-gray-400">Loading courses...</div>
          ) : courses.length === 0 ? (
            <div className="py-16 text-center text-gray-400">No courses found</div>
          ) : (
            <table>
              <thead>
                <tr>
                  <th>Title</th>
                  <th>Category</th>
                  <th>Price</th>
                  <th>Enrollments</th>
                  <th>Rating</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {courses.map(course => (
                  <tr key={course.courseId}>
                    <td>
                      <div>
                        <p className="font-medium">{course.title}</p>
                        <p className="text-xs text-gray-400">{course.teacherId?.slice(0, 10)}...</p>
                      </div>
                    </td>
                    <td className="text-gray-500">{course.category || '—'}</td>
                    <td>{course.price != null ? `$${course.price}` : 'Free'}</td>
                    <td>{course.enrollmentCount ?? 0}</td>
                    <td>{course.rating ? `⭐ ${course.rating}` : '—'}</td>
                    <td><span className={statusBadge[course.status] || 'badge-gray'}>{course.status}</span></td>
                    <td>
                      <div className="flex gap-1.5">
                        {course.status !== 'published' && (
                          <button onClick={() => setStatus(course.courseId, 'published')} className="p-1.5 text-green-600 hover:bg-green-50 rounded-lg" title="Approve">
                            <CheckCircle size={16} />
                          </button>
                        )}
                        {course.status !== 'rejected' && (
                          <button onClick={() => setStatus(course.courseId, 'rejected')} className="p-1.5 text-red-500 hover:bg-red-50 rounded-lg" title="Reject">
                            <XCircle size={16} />
                          </button>
                        )}
                        <button onClick={() => deleteCourse(course.courseId)} className="p-1.5 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded-lg" title="Delete">
                          <Trash2 size={16} />
                        </button>
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
