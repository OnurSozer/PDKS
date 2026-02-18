import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../hooks/useAuth';
import { useWorkSettings, useSaveWorkSettings } from '../../hooks/useWorkSettings';
import { useSpecialDayTypes, useCreateSpecialDayType, useUpdateSpecialDayType, useDeleteSpecialDayType } from '../../hooks/useSpecialDayTypes';
import { NotificationSettings, SpecialDayType } from '../../types';
import { Save, Check, Plus, Pencil, Trash2 } from 'lucide-react';

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

  // Work calculation settings
  const [monthlyWorkDays, setMonthlyWorkDays] = useState(21.66);
  const [overtimeMultiplier, setOvertimeMultiplier] = useState(1.5);
  const [weekendMultiplier, setWeekendMultiplier] = useState(1.5);
  const [holidayMultiplier, setHolidayMultiplier] = useState(2.0);
  const [bossCallMultiplier, setBossCallMultiplier] = useState(1.5);
  const [workSettingsSaved, setWorkSettingsSaved] = useState(false);

  const { data: workSettings } = useWorkSettings(companyId);
  const saveWorkSettingsMutation = useSaveWorkSettings();

  // Special day types
  const { data: specialDayTypes = [] } = useSpecialDayTypes(companyId);
  const createSpecialDayType = useCreateSpecialDayType();
  const updateSpecialDayType = useUpdateSpecialDayType();
  const deleteSpecialDayType = useDeleteSpecialDayType();
  const [showTypeForm, setShowTypeForm] = useState(false);
  const [editingType, setEditingType] = useState<SpecialDayType | null>(null);
  const [typeName, setTypeName] = useState('');
  const [typeCode, setTypeCode] = useState('');
  const [typeCalcMode, setTypeCalcMode] = useState<'rounding' | 'fixed_hours'>('rounding');
  const [typeMultiplier, setTypeMultiplier] = useState(1.5);
  const [typeBaseMinutes, setTypeBaseMinutes] = useState(600);
  const [typeExtraMinutes, setTypeExtraMinutes] = useState(240);
  const [typeExtraMultiplier, setTypeExtraMultiplier] = useState(1.5);
  const [typeAppliesToAll, setTypeAppliesToAll] = useState(true);
  const [typeDisplayOrder, setTypeDisplayOrder] = useState(0);
  const [typeSaved, setTypeSaved] = useState(false);

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

  useEffect(() => {
    if (workSettings) {
      setMonthlyWorkDays(workSettings.monthly_work_days_constant);
      setOvertimeMultiplier(workSettings.overtime_multiplier);
      setWeekendMultiplier(workSettings.weekend_multiplier);
      setHolidayMultiplier(workSettings.holiday_multiplier);
      setBossCallMultiplier(workSettings.boss_call_multiplier);
    }
  }, [workSettings]);

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

  const inputClasses = "mt-1 block w-full px-3 py-2 bg-zinc-800 border border-zinc-700 rounded-lg text-white focus:outline-none focus:border-amber-500 focus:ring-1 focus:ring-amber-500/20 text-sm";

  return (
    <div>
      <h1 className="text-2xl font-bold font-display text-white mb-6">{t('settings.title')}</h1>

      <div className="space-y-6">
        {/* Top row: Notification + Leave side by side */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
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
                <div className="grid grid-cols-2 gap-4">
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
                </div>
              )}

              <div className="pt-2">
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
        </div>

        {/* Second row: Work Calculation + Special Day Types side by side */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Work Calculation Settings */}
        <div className="bg-zinc-900/80 backdrop-blur-sm rounded-xl border border-zinc-800 p-6">
          <h2 className="text-lg font-semibold text-white mb-4">
            {t('workSettings.title')}
          </h2>

          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-zinc-300">
                {t('workSettings.monthlyWorkDays')}
              </label>
              <input
                type="number"
                step="0.01"
                value={monthlyWorkDays}
                onChange={(e) => setMonthlyWorkDays(Number(e.target.value))}
                className={inputClasses}
              />
              <p className="mt-1 text-xs text-zinc-500">{t('workSettings.monthlyWorkDaysHint')}</p>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-zinc-300">
                  {t('workSettings.overtimeMultiplier')}
                </label>
                <input
                  type="number"
                  step="0.01"
                  min="1"
                  max="5"
                  value={overtimeMultiplier}
                  onChange={(e) => setOvertimeMultiplier(Number(e.target.value))}
                  className={inputClasses}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-zinc-300">
                  {t('workSettings.weekendMultiplier')}
                </label>
                <input
                  type="number"
                  step="0.01"
                  min="1"
                  max="5"
                  value={weekendMultiplier}
                  onChange={(e) => setWeekendMultiplier(Number(e.target.value))}
                  className={inputClasses}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-zinc-300">
                  {t('workSettings.holidayMultiplier')}
                </label>
                <input
                  type="number"
                  step="0.01"
                  min="1"
                  max="5"
                  value={holidayMultiplier}
                  onChange={(e) => setHolidayMultiplier(Number(e.target.value))}
                  className={inputClasses}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-zinc-300">
                  {t('workSettings.bossCallMultiplier')}
                </label>
                <input
                  type="number"
                  step="0.01"
                  min="1"
                  max="5"
                  value={bossCallMultiplier}
                  onChange={(e) => setBossCallMultiplier(Number(e.target.value))}
                  className={inputClasses}
                />
                <p className="mt-1 text-xs text-zinc-500">{t('workSettings.bossCallHint')}</p>
              </div>
            </div>
          </div>

          <div className="mt-4">
            <button
              onClick={() => {
                if (!companyId) return;
                saveWorkSettingsMutation.mutate({
                  company_id: companyId,
                  monthly_work_days_constant: monthlyWorkDays,
                  overtime_multiplier: overtimeMultiplier,
                  weekend_multiplier: weekendMultiplier,
                  holiday_multiplier: holidayMultiplier,
                  boss_call_multiplier: bossCallMultiplier,
                }, {
                  onSuccess: () => {
                    setWorkSettingsSaved(true);
                    setTimeout(() => setWorkSettingsSaved(false), 2000);
                  },
                });
              }}
              disabled={saveWorkSettingsMutation.isPending}
              className="inline-flex items-center gap-2 px-4 py-2 text-sm font-semibold text-black bg-amber-500 rounded-lg hover:bg-amber-400 shadow-lg shadow-amber-500/20 disabled:opacity-50 transition-all"
            >
              {workSettingsSaved ? (
                <>
                  <Check className="w-4 h-4" />
                  {t('settings.settingsSaved')}
                </>
              ) : (
                <>
                  <Save className="w-4 h-4" />
                  {saveWorkSettingsMutation.isPending ? t('common.loading') : t('common.save')}
                </>
              )}
            </button>
          </div>
        </div>
        {/* Special Day Types */}
        <div className="bg-zinc-900/80 backdrop-blur-sm rounded-xl border border-zinc-800 p-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-white">
              {t('specialDayTypes.title')}
            </h2>
            <button
              onClick={() => {
                setEditingType(null);
                setTypeName('');
                setTypeCode('');
                setTypeCalcMode('rounding');
                setTypeMultiplier(1.5);
                setTypeBaseMinutes(600);
                setTypeExtraMinutes(240);
                setTypeExtraMultiplier(1.5);
                setTypeAppliesToAll(true);
                setTypeDisplayOrder(specialDayTypes.length);
                setShowTypeForm(true);
              }}
              className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-black bg-amber-500 rounded-lg hover:bg-amber-400 transition-colors"
            >
              <Plus className="w-4 h-4" />
              {t('specialDayTypes.addType')}
            </button>
          </div>

          {/* Type list */}
          {specialDayTypes.length === 0 ? (
            <p className="text-sm text-zinc-500">{t('specialDayTypes.noTypes')}</p>
          ) : (
            <div className="space-y-2 mb-4">
              {specialDayTypes.map((sdt) => (
                <div key={sdt.id} className="flex items-center justify-between p-3 bg-zinc-800/50 rounded-lg">
                  <div>
                    <span className="text-sm font-medium text-white">{sdt.name}</span>
                    <span className="ml-2 text-xs text-zinc-500">({sdt.code})</span>
                    <span className={`ml-2 px-1.5 py-0.5 rounded text-xs ${
                      sdt.calculation_mode === 'rounding'
                        ? 'bg-purple-500/10 text-purple-400'
                        : 'bg-cyan-500/10 text-cyan-400'
                    }`}>
                      {sdt.calculation_mode === 'rounding' ? t('specialDayTypes.modeRounding') : t('specialDayTypes.modeFixedHours')}
                    </span>
                    {!sdt.applies_to_all && (
                      <span className="ml-2 px-1.5 py-0.5 rounded text-xs bg-amber-500/10 text-amber-400">
                        per-employee
                      </span>
                    )}
                  </div>
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => {
                        setEditingType(sdt);
                        setTypeName(sdt.name);
                        setTypeCode(sdt.code);
                        setTypeCalcMode(sdt.calculation_mode);
                        setTypeMultiplier(sdt.multiplier);
                        setTypeBaseMinutes(sdt.base_minutes);
                        setTypeExtraMinutes(sdt.extra_minutes);
                        setTypeExtraMultiplier(sdt.extra_multiplier);
                        setTypeAppliesToAll(sdt.applies_to_all);
                        setTypeDisplayOrder(sdt.display_order);
                        setShowTypeForm(true);
                      }}
                      className="p-1.5 text-zinc-400 hover:text-white transition-colors"
                    >
                      <Pencil className="w-3.5 h-3.5" />
                    </button>
                    {sdt.code !== 'boss_call' && (
                      <button
                        onClick={() => {
                          if (window.confirm(t('common.confirm') + '?')) {
                            deleteSpecialDayType.mutate(sdt.id);
                          }
                        }}
                        className="p-1.5 text-zinc-400 hover:text-rose-400 transition-colors"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* Add/Edit form */}
          {showTypeForm && (
            <div className="border border-zinc-700 rounded-lg p-4 space-y-4">
              <h3 className="text-sm font-semibold text-white">
                {editingType ? t('specialDayTypes.editType') : t('specialDayTypes.addType')}
              </h3>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-zinc-300">{t('specialDayTypes.typeName')}</label>
                  <input type="text" value={typeName} onChange={(e) => setTypeName(e.target.value)} className={inputClasses} />
                </div>
                <div>
                  <label className="block text-sm font-medium text-zinc-300">{t('specialDayTypes.typeCode')}</label>
                  <input
                    type="text"
                    value={typeCode}
                    onChange={(e) => setTypeCode(e.target.value)}
                    disabled={editingType?.code === 'boss_call'}
                    className={inputClasses}
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-zinc-300 mb-2">{t('specialDayTypes.calculationMode')}</label>
                <div className="flex gap-4">
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="radio"
                      checked={typeCalcMode === 'rounding'}
                      onChange={() => setTypeCalcMode('rounding')}
                      className="w-4 h-4 text-amber-500 bg-zinc-800 border-zinc-600"
                    />
                    <span className="text-sm text-zinc-200">{t('specialDayTypes.modeRounding')}</span>
                  </label>
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="radio"
                      checked={typeCalcMode === 'fixed_hours'}
                      onChange={() => setTypeCalcMode('fixed_hours')}
                      className="w-4 h-4 text-amber-500 bg-zinc-800 border-zinc-600"
                    />
                    <span className="text-sm text-zinc-200">{t('specialDayTypes.modeFixedHours')}</span>
                  </label>
                </div>
              </div>

              {typeCalcMode === 'rounding' ? (
                <div>
                  <label className="block text-sm font-medium text-zinc-300">{t('specialDayTypes.multiplier')}</label>
                  <input type="number" step="0.01" min="1" max="5" value={typeMultiplier} onChange={(e) => setTypeMultiplier(Number(e.target.value))} className={inputClasses} />
                </div>
              ) : (
                <div className="grid grid-cols-3 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-zinc-300">{t('specialDayTypes.baseMinutes')}</label>
                    <input type="number" min="0" value={typeBaseMinutes} onChange={(e) => setTypeBaseMinutes(Number(e.target.value))} className={inputClasses} />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-zinc-300">{t('specialDayTypes.extraMinutes')}</label>
                    <input type="number" min="0" value={typeExtraMinutes} onChange={(e) => setTypeExtraMinutes(Number(e.target.value))} className={inputClasses} />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-zinc-300">{t('specialDayTypes.extraMultiplier')}</label>
                    <input type="number" step="0.01" min="1" max="5" value={typeExtraMultiplier} onChange={(e) => setTypeExtraMultiplier(Number(e.target.value))} className={inputClasses} />
                  </div>
                </div>
              )}

              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-white">{t('specialDayTypes.appliesToAll')}</p>
                  <p className="text-xs text-zinc-400">{t('specialDayTypes.appliesToAllHint')}</p>
                </div>
                <button
                  onClick={() => setTypeAppliesToAll(!typeAppliesToAll)}
                  className={`relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ${
                    typeAppliesToAll ? 'bg-amber-500' : 'bg-zinc-700'
                  }`}
                >
                  <span className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${
                    typeAppliesToAll ? 'translate-x-5' : 'translate-x-0'
                  }`} />
                </button>
              </div>

              <div className="flex items-center gap-3">
                <button
                  onClick={() => {
                    if (!companyId || !typeName || !typeCode) return;
                    const payload = {
                      name: typeName,
                      code: typeCode,
                      calculation_mode: typeCalcMode,
                      multiplier: typeMultiplier,
                      base_minutes: typeBaseMinutes,
                      extra_minutes: typeExtraMinutes,
                      extra_multiplier: typeExtraMultiplier,
                      applies_to_all: typeAppliesToAll,
                      display_order: typeDisplayOrder,
                    };

                    if (editingType) {
                      updateSpecialDayType.mutate({ id: editingType.id, ...payload }, {
                        onSuccess: () => {
                          setShowTypeForm(false);
                          setEditingType(null);
                          setTypeSaved(true);
                          setTimeout(() => setTypeSaved(false), 2000);
                        },
                      });
                    } else {
                      createSpecialDayType.mutate({ company_id: companyId, ...payload }, {
                        onSuccess: () => {
                          setShowTypeForm(false);
                          setTypeSaved(true);
                          setTimeout(() => setTypeSaved(false), 2000);
                        },
                      });
                    }
                  }}
                  disabled={createSpecialDayType.isPending || updateSpecialDayType.isPending}
                  className="inline-flex items-center gap-2 px-4 py-2 text-sm font-semibold text-black bg-amber-500 rounded-lg hover:bg-amber-400 shadow-lg shadow-amber-500/20 disabled:opacity-50 transition-all"
                >
                  {typeSaved ? (
                    <>
                      <Check className="w-4 h-4" />
                      {t('common.success')}
                    </>
                  ) : (
                    <>
                      <Save className="w-4 h-4" />
                      {t('common.save')}
                    </>
                  )}
                </button>
                <button
                  onClick={() => { setShowTypeForm(false); setEditingType(null); }}
                  className="px-4 py-2 text-sm font-medium text-zinc-400 hover:text-white transition-colors"
                >
                  {t('common.cancel')}
                </button>
              </div>
            </div>
          )}
        </div>
        </div>{/* close grid */}
      </div>
    </div>
  );
}
