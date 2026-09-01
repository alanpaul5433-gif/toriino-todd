import Link from 'next/link';

export default function NotFound() {
  return (
    <div className="flex h-screen items-center justify-center">
      <div className="text-center">
        <p className="text-6xl font-bold text-gray-200">404</p>
        <p className="text-lg font-semibold text-gray-700 mt-2">Page not found</p>
        <Link href="/" className="btn-primary inline-block mt-4">Back to Dashboard</Link>
      </div>
    </div>
  );
}
