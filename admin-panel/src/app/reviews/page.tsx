'use client';

import { useEffect, useState, useCallback } from 'react';
import AdminShell from '@/components/AdminShell';
import { api, Review } from '@/lib/api';
import { Trash2, Star } from 'lucide-react';

const TYPES = ['All', 'mentor', 'teacher', 'course'];

export default function ReviewsPage() {
  const [reviews, setReviews] = useState<Review[]>([]);
  const [total, setTotal] = useState(0);
  const [typeFilter, setTypeFilter] = useState('All');
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    const params = typeFilter !== 'All' ? { type: typeFilter } : {};
    const data = await api.reviews.list(params).catch(() => ({ reviews: [], total: 0 }));
    setReviews(data.reviews);
    setTotal(data.total);
    setLoading(false);
  }, [typeFilter]);

  useEffect(() => { load(); }, [load]);

  async function deleteReview(targetId: string, reviewId: string) {
    if (!confirm('Remove this review permanently?')) return;
    await api.reviews.delete(targetId, reviewId);
    load();
  }

  function stars(rating: number) {
    return '★'.repeat(rating) + '☆'.repeat(5 - rating);
  }

  return (
    <AdminShell>
      <div className="space-y-6">
        <div>
          <h1 className="page-title">Reviews Moderation</h1>
          <p className="text-gray-500 mt-1">{total} reviews</p>
        </div>

        <div className="flex gap-2">
          {TYPES.map(t => (
            <button
              key={t}
              onClick={() => setTypeFilter(t)}
              className={`px-3 py-1.5 text-sm font-medium rounded-lg capitalize transition-colors ${typeFilter === t ? 'bg-primary-600 text-white' : 'bg-white border border-gray-200 text-gray-600 hover:bg-gray-50'}`}
            >
              {t}
            </button>
          ))}
        </div>

        <div className="bg-white rounded-xl border border-gray-100 overflow-hidden shadow-sm">
          {loading ? (
            <div className="py-16 text-center text-gray-400">Loading reviews...</div>
          ) : reviews.length === 0 ? (
            <div className="py-16 text-center text-gray-400">No reviews found</div>
          ) : (
            <table>
              <thead>
                <tr>
                  <th>Reviewer</th>
                  <th>Target</th>
                  <th>Type</th>
                  <th>Rating</th>
                  <th>Comment</th>
                  <th>Date</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {reviews.map(r => (
                  <tr key={`${r.targetId}-${r.reviewId}`}>
                    <td className="text-xs text-gray-400">{r.reviewerId?.slice(0, 10) || '—'}...</td>
                    <td className="text-xs text-gray-400">{r.targetId?.slice(0, 10)}...</td>
                    <td><span className="badge-gray capitalize">{r.targetType}</span></td>
                    <td>
                      <span className={`text-sm font-medium ${r.rating >= 4 ? 'text-yellow-500' : r.rating >= 2 ? 'text-orange-500' : 'text-red-500'}`}>
                        {stars(r.rating)}
                      </span>
                    </td>
                    <td className="max-w-xs">
                      <p className="text-sm text-gray-700 truncate">{r.comment || '—'}</p>
                    </td>
                    <td className="text-xs text-gray-400">
                      {r.createdAt ? new Date(r.createdAt).toLocaleDateString() : '—'}
                    </td>
                    <td>
                      <button onClick={() => deleteReview(r.targetId, r.reviewId)} className="p-1.5 text-red-500 hover:bg-red-50 rounded-lg" title="Remove review">
                        <Trash2 size={16} />
                      </button>
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
