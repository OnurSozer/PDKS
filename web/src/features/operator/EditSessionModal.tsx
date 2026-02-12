import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useEditSession } from '../../hooks/useSessions';
import { WorkSession } from '../../types';
import { X } from 'lucide-react';

interface EditSessionModalProps {
  session: WorkSession;
  onClose: () => void;
}

export function EditSessionModal({ session, onClose }: EditSessionModalProps) {
  const { t } = useTranslation();
  const editSession = useEditSession();

  const formatForInput = (isoStr?: string) => {
    if (!isoStr) return '';
    const d = new Date(isoStr);
    // Format as YYYY-MM-DDTHH:MM for datetime-local input
    return d.toISOString().slice(0, 16);
  };

  const [clockIn, setClockIn] = useState(formatForInput(session.clock_in));
  const [clockOut, setClockOut] = useState(formatForInput(session.clock_out));
  const [notes, setNotes] = useState(session.notes || '');
  const [error, setError] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    editSession.mutate(
      {
        session_id: session.id,
        clock_in: clockIn ? new Date(clockIn).toISOString() : undefined,
        clock_out: clockOut ? new Date(clockOut).toISOString() : undefined,
        notes: notes || undefined,
      },
      {
        onSuccess: () => onClose(),
        onError: (err: any) => setError(err.message || t('common.error')),
      }
    );
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="fixed inset-0 bg-black bg-opacity-50" onClick={onClose} />
      <div className="relative bg-white rounded-lg shadow-xl max-w-md w-full mx-4">
        <div className="flex items-center justify-between p-4 border-b border-gray-200">
          <h2 className="text-lg font-semibold">{t('sessions.editSession')}</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600">
            <X className="w-5 h-5" />
          </button>
        </div>
        <form onSubmit={handleSubmit} className="p-4 space-y-4">
          {error && (
            <div className="bg-red-50 border border-red-200 text-red-700 px-3 py-2 rounded text-sm">
              {error}
            </div>
          )}
          <div>
            <label className="block text-sm font-medium text-gray-700">
              {t('sessions.clockIn')}
            </label>
            <input
              type="datetime-local"
              value={clockIn}
              onChange={(e) => setClockIn(e.target.value)}
              className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 text-sm"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">
              {t('sessions.clockOut')}
            </label>
            <input
              type="datetime-local"
              value={clockOut}
              onChange={(e) => setClockOut(e.target.value)}
              className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 text-sm"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">
              {t('common.notes')}
            </label>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              rows={3}
              className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 text-sm"
            />
          </div>
          <div className="flex justify-end gap-3 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50"
            >
              {t('common.cancel')}
            </button>
            <button
              type="submit"
              disabled={editSession.isPending}
              className="px-4 py-2 text-sm font-medium text-white bg-primary-600 rounded-md hover:bg-primary-700 disabled:opacity-50"
            >
              {editSession.isPending ? t('common.loading') : t('common.save')}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
