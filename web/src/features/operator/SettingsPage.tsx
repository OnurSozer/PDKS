import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../hooks/useAuth';
import { NotificationSettings } from '../../types';
import { Save, Check } from 'lucide-react';

export function SettingsPage() {
  const { t } = useTranslation();
  const { profile } = useAuth();
  const companyId = profile?.company_id || undefined;
  const queryClient = useQueryClient();

  const [forgotClockoutEnabled, setForgotClockoutEnabled] = useState(true);
  const [forgotClockoutTime, setForgotClockoutTime] = useState('18:30');
  const [forgotClockoutOffset, setForgotClockoutOffset] = useState(30);
  const [saved, setSaved] = useState(false);

  const { data: settings } = useQuery({
    queryKey: ['notification-settings', companyId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('notification_settings')
        .select('*')
        .eq('company_id', companyId!)
        .single();
      if (error && error.code !== 'PGRST116') throw error; // PGRST116 = no rows
      return data as NotificationSettings | null;
    },
    enabled: !!companyId,
  });

  useEffect(() => {
    if (settings) {
      setForgotClockoutEnabled(settings.forgot_clockout_enabled);
      setForgotClockoutTime(settings.forgot_clockout_time);
      setForgotClockoutOffset(settings.forgot_clockout_offset_minutes);
    }
  }, [settings]);

  const saveMutation = useMutation({
    mutationFn: async () => {
      const payload = {
        company_id: companyId!,
        forgot_clockout_enabled: forgotClockoutEnabled,
        forgot_clockout_time: forgotClockoutTime,
        forgot_clockout_offset_minutes: forgotClockoutOffset,
      };

      if (settings) {
        const { error } = await supabase
          .from('notification_settings')
          .update(payload)
          .eq('id', settings.id);
        if (error) throw error;
      } else {
        const { error } = await supabase
          .from('notification_settings')
          .insert(payload);
        if (error) throw error;
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notification-settings'] });
      setSaved(true);
      setTimeout(() => setSaved(false), 2000);
    },
  });

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">{t('settings.title')}</h1>

      <div className="max-w-2xl">
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <h2 className="text-lg font-semibold mb-4">
            {t('settings.notificationSettings')}
          </h2>

          <div className="space-y-6">
            {/* Forgot clock-out toggle */}
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-900">
                  {t('settings.forgotClockoutEnabled')}
                </p>
                <p className="text-xs text-gray-500 mt-1">
                  {t('settings.forgotClockoutOffset')}
                </p>
              </div>
              <button
                onClick={() => setForgotClockoutEnabled(!forgotClockoutEnabled)}
                className={`relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2 ${
                  forgotClockoutEnabled ? 'bg-primary-600' : 'bg-gray-200'
                }`}
              >
                <span
                  className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${
                    forgotClockoutEnabled ? 'translate-x-5' : 'translate-x-0'
                  }`}
                />
              </button>
            </div>

            {forgotClockoutEnabled && (
              <>
                {/* Reminder time */}
                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    {t('settings.forgotClockoutTime')}
                  </label>
                  <input
                    type="time"
                    value={forgotClockoutTime}
                    onChange={(e) => setForgotClockoutTime(e.target.value)}
                    className="mt-1 block w-48 px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 text-sm"
                  />
                </div>

                {/* Offset minutes */}
                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    {t('settings.forgotClockoutOffset')}
                  </label>
                  <input
                    type="number"
                    value={forgotClockoutOffset}
                    onChange={(e) => setForgotClockoutOffset(Number(e.target.value))}
                    min={0}
                    max={180}
                    className="mt-1 block w-48 px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 text-sm"
                  />
                  <p className="mt-1 text-xs text-gray-500">min</p>
                </div>
              </>
            )}

            {/* Save button */}
            <div className="pt-4 border-t border-gray-200">
              <button
                onClick={() => saveMutation.mutate()}
                disabled={saveMutation.isPending}
                className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-primary-600 rounded-md hover:bg-primary-700 disabled:opacity-50"
              >
                {saved ? (
                  <>
                    <Check className="w-4 h-4" />
                    {t('settings.settingsSaved')}
                  </>
                ) : (
                  <>
                    <Save className="w-4 h-4" />
                    {saveMutation.isPending ? t('common.loading') : t('common.save')}
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
