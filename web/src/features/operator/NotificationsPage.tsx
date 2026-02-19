import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../hooks/useAuth';
import { useEmployees } from '../../hooks/useEmployees';
import { Send } from 'lucide-react';

export function NotificationsPage() {
  const { t } = useTranslation();
  const { profile } = useAuth();
  const queryClient = useQueryClient();
  const companyId = profile?.company_id || undefined;

  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [selectedEmployees, setSelectedEmployees] = useState<string[]>([]);
  const [successMessage, setSuccessMessage] = useState('');

  const { data: employees } = useEmployees(companyId);

  // Notification history
  const { data: logs, isLoading: logsLoading } = useQuery({
    queryKey: ['notification-logs', companyId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('notification_logs')
        .select('*, sender:sent_by(first_name, last_name)')
        .order('created_at', { ascending: false });
      if (error) throw error;
      return data;
    },
    enabled: !!companyId,
  });

  // Send notification mutation
  const sendMutation = useMutation({
    mutationFn: async () => {
      const { data, error } = await supabase.functions.invoke('send-custom-notification', {
        body: {
          title,
          body,
          employee_ids: selectedEmployees.length > 0 ? selectedEmployees : undefined,
        },
      });
      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      setTitle('');
      setBody('');
      setSelectedEmployees([]);
      setSuccessMessage(t('notifications.sentSuccess'));
      setTimeout(() => setSuccessMessage(''), 3000);
      queryClient.invalidateQueries({ queryKey: ['notification-logs'] });
    },
  });

  const inputClasses =
    'block w-full px-3 py-2 bg-zinc-800 border border-zinc-700 rounded-lg text-white focus:outline-none focus:border-amber-500 focus:ring-1 focus:ring-amber-500/20 text-sm';

  const toggleEmployee = (id: string) => {
    setSelectedEmployees((prev) =>
      prev.includes(id) ? prev.filter((e) => e !== id) : [...prev, id]
    );
  };

  return (
    <div>
      <h1 className="text-2xl font-bold font-display text-white mb-6">
        {t('notifications.title')}
      </h1>

      {/* Send Notification Card */}
      <div className="bg-zinc-900/80 backdrop-blur-sm rounded-xl border border-zinc-800 p-6 mb-6">
        <h2 className="text-lg font-semibold text-white mb-4">
          {t('notifications.send')}
        </h2>

        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-zinc-400 mb-1">
              {t('notifications.notificationTitle')}
            </label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className={inputClasses}
              placeholder={t('notifications.notificationTitle')}
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-zinc-400 mb-1">
              {t('notifications.body')}
            </label>
            <textarea
              value={body}
              onChange={(e) => setBody(e.target.value)}
              className={`${inputClasses} min-h-[80px] resize-y`}
              placeholder={t('notifications.body')}
              rows={3}
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-zinc-400 mb-1">
              {t('notifications.selectEmployees')}
            </label>
            <div className="flex flex-wrap gap-2 mt-1">
              {employees?.map((emp) => (
                <button
                  key={emp.id}
                  type="button"
                  onClick={() => toggleEmployee(emp.id)}
                  className={`px-3 py-1.5 text-sm rounded-lg border transition-colors ${
                    selectedEmployees.includes(emp.id)
                      ? 'bg-amber-500/20 border-amber-500 text-amber-400'
                      : 'bg-zinc-800 border-zinc-700 text-zinc-400 hover:border-zinc-600'
                  }`}
                >
                  {emp.first_name} {emp.last_name}
                </button>
              ))}
            </div>
            {selectedEmployees.length === 0 && (
              <p className="text-xs text-zinc-500 mt-1">
                {t('notifications.allEmployees')}
              </p>
            )}
          </div>

          {successMessage && (
            <div className="px-4 py-2 bg-green-500/10 border border-green-500/20 rounded-lg text-green-400 text-sm">
              {successMessage}
            </div>
          )}

          {sendMutation.error && (
            <div className="px-4 py-2 bg-red-500/10 border border-red-500/20 rounded-lg text-red-400 text-sm">
              {(sendMutation.error as Error).message}
            </div>
          )}

          <button
            onClick={() => sendMutation.mutate()}
            disabled={!title.trim() || !body.trim() || sendMutation.isPending}
            className="inline-flex items-center gap-2 px-4 py-2 bg-amber-500 hover:bg-amber-600 text-black font-semibold rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <Send className="w-4 h-4" />
            {sendMutation.isPending ? t('common.loading') : t('notifications.sendButton')}
          </button>
        </div>
      </div>

      {/* Notification History */}
      <div className="bg-zinc-900/80 backdrop-blur-sm rounded-xl border border-zinc-800 overflow-hidden">
        <div className="px-6 py-4 border-b border-zinc-800">
          <h2 className="text-lg font-semibold text-white">
            {t('notifications.history')}
          </h2>
        </div>

        {logsLoading ? (
          <div className="p-8 text-center text-zinc-400">{t('common.loading')}</div>
        ) : !logs || logs.length === 0 ? (
          <div className="p-8 text-center text-zinc-400">{t('notifications.noHistory')}</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-zinc-800">
                  <th className="px-6 py-3 text-left text-xs font-semibold text-zinc-400 uppercase tracking-wider">
                    {t('notifications.date')}
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-zinc-400 uppercase tracking-wider">
                    {t('notifications.notificationTitle')}
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-zinc-400 uppercase tracking-wider">
                    {t('notifications.body')}
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-zinc-400 uppercase tracking-wider">
                    {t('notifications.recipients')}
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-zinc-400 uppercase tracking-wider">
                    {t('notifications.sentBy')}
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-zinc-800/50">
                {logs.map((log: any) => (
                  <tr key={log.id} className="hover:bg-zinc-800/30 transition-colors">
                    <td className="px-6 py-4 text-sm text-zinc-300 whitespace-nowrap">
                      {new Date(log.created_at).toLocaleString()}
                    </td>
                    <td className="px-6 py-4 text-sm text-white font-medium">
                      {log.title}
                    </td>
                    <td className="px-6 py-4 text-sm text-zinc-300 max-w-xs truncate">
                      {log.body}
                    </td>
                    <td className="px-6 py-4 text-sm text-zinc-300">
                      {log.recipient_count}
                    </td>
                    <td className="px-6 py-4 text-sm text-zinc-300 whitespace-nowrap">
                      {log.sender?.first_name} {log.sender?.last_name}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
