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

  const inputClasses = "mt-1 block w-full px-3 py-2 bg-zinc-800 border border-zinc-700 rounded-lg text-white focus:outline-none focus:border-amber-500 focus:ring-1 focus:ring-amber-500/20 text-sm";

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="fixed inset-0 bg-black/60 backdrop-blur-sm" onClick={onClose} />
      <div className="relative bg-zinc-900 border border-zinc-800 rounded-xl shadow-xl max-w-md w-full mx-4">
        <div className="flex items-center justify-between p-4 border-b border-zinc-800">
          <h2 className="text-lg font-semibold text-white">{t('sessions.editSession')}</h2>
          <button onClick={onClose} className="text-zinc-400 hover:text-white transition-colors">
            <X className="w-5 h-5" />
          </button>
        </div>
        <form onSubmit={handleSubmit} className="p-4 space-y-4">
          {error && (
            <div className="bg-rose-500/10 border border-rose-500/20 text-rose-400 px-3 py-2 rounded-lg text-sm">
              {error}
            </div>
          )}
          <div>
            <label className="block text-sm font-medium text-zinc-300">
              {t('sessions.clockIn')}
            </label>
            <input
              type="datetime-local"
              value={clockIn}
              onChange={(e) => setClockIn(e.target.value)}
              className={inputClasses}
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-zinc-300">
              {t('sessions.clockOut')}
            </label>
            <input
              type="datetime-local"
              value={clockOut}
              onChange={(e) => setClockOut(e.target.value)}
              className={inputClasses}
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-zinc-300">
              {t('common.notes')}
            </label>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              rows={3}
              className={inputClasses}
            />
          </div>
          <div className="flex justify-end gap-3 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-sm font-medium text-zinc-300 bg-zinc-800 border border-zinc-700 rounded-lg hover:bg-zinc-700 transition-colors"
            >
              {t('common.cancel')}
            </button>
            <button
              type="submit"
              disabled={editSession.isPending}
              className="px-4 py-2 text-sm font-semibold text-black bg-amber-500 rounded-lg hover:bg-amber-400 shadow-lg shadow-amber-500/20 disabled:opacity-50 transition-all"
            >
              {editSession.isPending ? t('common.loading') : t('common.save')}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
