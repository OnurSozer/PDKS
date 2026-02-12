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
  const [leaveAccrualMode, setLeaveAccrualMode] = useState<'monthly' | 'yearly'>('monthly');
  const [saved, setSaved] = useState(false);

  const { data: settings } = useQuery({
    queryKey: ['notification-settings', companyId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('notification_settings')
        .select('*')
        .eq('company_id', companyId!)
        .single();
      if (error && error.code !== 'PGRST116') throw error;
      return data as NotificationSettings | null;
    },
    enabled: !!companyId,
  });

  useEffect(() => {
    if (settings) {
      setForgotClockoutEnabled(settings.forgot_clockout_enabled);
      setForgotClockoutTime(settings.forgot_clockout_time);
      setForgotClockoutOffset(settings.forgot_clockout_offset_minutes);
      setLeaveAccrualMode(settings.leave_accrual_mode || 'monthly');
    }
  }, [settings]);

  const saveMutation = useMutation({
    mutationFn: async () => {
      const payload = {
        company_id: companyId!,
        forgot_clockout_enabled: forgotClockoutEnabled,
        forgot_clockout_time: forgotClockoutTime,
        forgot_clockout_offset_minutes: forgotClockoutOffset,
        leave_accrual_mode: leaveAccrualMode,
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

  const inputClasses = "mt-1 block w-48 px-3 py-2 bg-zinc-800 border border-zinc-700 rounded-lg text-white focus:outline-none focus:border-amber-500 focus:ring-1 focus:ring-amber-500/20 text-sm";

  return (
    <div>
      <h1 className="text-2xl font-bold font-display text-white mb-6">{t('settings.title')}</h1>

      <div className="max-w-2xl space-y-6">
        <div className="bg-zinc-900/80 backdrop-blur-sm rounded-xl border border-zinc-800 p-6">
          <h2 className="text-lg font-semibold text-white mb-4">
            {t('settings.notificationSettings')}
          </h2>

          <div className="space-y-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-white">
                  {t('settings.forgotClockoutEnabled')}
                </p>
                <p className="text-xs text-zinc-400 mt-1">
                  {t('settings.forgotClockoutOffset')}
                </p>
              </div>
              <button
                onClick={() => setForgotClockoutEnabled(!forgotClockoutEnabled)}
                className={`relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-amber-500/20 focus:ring-offset-2 focus:ring-offset-zinc-900 ${
                  forgotClockoutEnabled ? 'bg-amber-500' : 'bg-zinc-700'
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
                <div>
                  <label className="block text-sm font-medium text-zinc-300">
                    {t('settings.forgotClockoutTime')}
                  </label>
                  <input
                    type="time"
                    value={forgotClockoutTime}
                    onChange={(e) => setForgotClockoutTime(e.target.value)}
                    className={inputClasses}
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-zinc-300">
                    {t('settings.forgotClockoutOffset')}
                  </label>
                  <input
                    type="number"
                    value={forgotClockoutOffset}
                    onChange={(e) => setForgotClockoutOffset(Number(e.target.value))}
                    min={0}
                    max={180}
                    className={inputClasses}
                  />
                  <p className="mt-1 text-xs text-zinc-500">min</p>
                </div>
              </>
            )}
          </div>
        </div>

        {/* Leave Settings */}
        <div className="bg-zinc-900/80 backdrop-blur-sm rounded-xl border border-zinc-800 p-6">
          <h2 className="text-lg font-semibold text-white mb-4">
            {t('settings.leaveSettings')}
          </h2>

          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-zinc-300 mb-2">
                {t('settings.accrualMode')}
              </label>
              <div className="space-y-2">
                <label className="flex items-center gap-3 cursor-pointer">
                  <input
                    type="radio"
                    name="accrualMode"
                    value="monthly"
                    checked={leaveAccrualMode === 'monthly'}
                    onChange={() => setLeaveAccrualMode('monthly')}
                    className="w-4 h-4 text-amber-500 bg-zinc-800 border-zinc-600 focus:ring-amber-500/20"
                  />
                  <span className="text-sm text-zinc-200">{t('settings.accrualMonthly')}</span>
                </label>
                <label className="flex items-center gap-3 cursor-pointer">
                  <input
                    type="radio"
                    name="accrualMode"
                    value="yearly"
                    checked={leaveAccrualMode === 'yearly'}
                    onChange={() => setLeaveAccrualMode('yearly')}
                    className="w-4 h-4 text-amber-500 bg-zinc-800 border-zinc-600 focus:ring-amber-500/20"
                  />
                  <span className="text-sm text-zinc-200">{t('settings.accrualYearly')}</span>
                </label>
              </div>
            </div>
          </div>
        </div>

        {/* Save button */}
        <div>
          <button
            onClick={() => saveMutation.mutate()}
            disabled={saveMutation.isPending}
            className="inline-flex items-center gap-2 px-4 py-2 text-sm font-semibold text-black bg-amber-500 rounded-lg hover:bg-amber-400 shadow-lg shadow-amber-500/20 disabled:opacity-50 transition-all"
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
  );
}
