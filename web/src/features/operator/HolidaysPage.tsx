import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../../hooks/useAuth';
import { useHolidays, useCreateHoliday, useUpdateHoliday, useDeleteHoliday } from '../../hooks/useHolidays';
import { CompanyHoliday } from '../../types';
import { Plus, Trash2, Edit2, X, Calendar, RotateCcw } from 'lucide-react';

export function HolidaysPage() {
  const { t } = useTranslation();
  const { profile } = useAuth();
  const companyId = profile?.company_id || undefined;
  const currentYear = new Date().getFullYear();
  const [selectedYear, setSelectedYear] = useState(currentYear);
  const [showForm, setShowForm] = useState(false);
  const [editingHoliday, setEditingHoliday] = useState<CompanyHoliday | null>(null);

  const [name, setName] = useState('');
  const [holidayDate, setHolidayDate] = useState('');
  const [isRecurring, setIsRecurring] = useState(false);

  const { data: holidays, isLoading } = useHolidays(companyId, selectedYear);
  const createMutation = useCreateHoliday();
  const updateMutation = useUpdateHoliday();
  const deleteMutation = useDeleteHoliday();

  const resetForm = () => {
    setName('');
    setHolidayDate('');
    setIsRecurring(false);
    setEditingHoliday(null);
    setShowForm(false);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!companyId || !name || !holidayDate) return;

    if (editingHoliday) {
      await updateMutation.mutateAsync({
        id: editingHoliday.id,
        name,
        holiday_date: holidayDate,
        is_recurring: isRecurring,
      });
    } else {
      await createMutation.mutateAsync({
        company_id: companyId,
        name,
        holiday_date: holidayDate,
        is_recurring: isRecurring,
      });
    }
    resetForm();
  };

  const handleEdit = (holiday: CompanyHoliday) => {
    setEditingHoliday(holiday);
    setName(holiday.name);
    setHolidayDate(holiday.holiday_date);
    setIsRecurring(holiday.is_recurring);
    setShowForm(true);
  };

  const handleDelete = async (id: string) => {
    if (window.confirm(t('common.confirm'))) {
      await deleteMutation.mutateAsync(id);
    }
  };

  const inputClasses = "mt-1 block w-full px-3 py-2 bg-zinc-800 border border-zinc-700 rounded-lg text-white focus:outline-none focus:border-amber-500 focus:ring-1 focus:ring-amber-500/20 text-sm";

  const years = Array.from({ length: 5 }, (_, i) => currentYear - 2 + i);

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold font-display text-white">{t('holidays.title')}</h1>
        <button
          onClick={() => { resetForm(); setShowForm(true); }}
          className="inline-flex items-center gap-2 px-4 py-2 text-sm font-semibold text-black bg-amber-500 rounded-lg hover:bg-amber-400 shadow-lg shadow-amber-500/20 transition-all"
        >
          <Plus className="w-4 h-4" />
          {t('holidays.addHoliday')}
        </button>
      </div>

      {/* Year Filter */}
      <div className="flex items-center gap-2 mb-6">
        <Calendar className="w-4 h-4 text-zinc-400" />
        <div className="flex gap-1">
          {years.map((year) => (
            <button
              key={year}
              onClick={() => setSelectedYear(year)}
              className={`px-3 py-1.5 text-sm rounded-lg transition-colors ${
                selectedYear === year
                  ? 'bg-amber-500 text-black font-semibold'
                  : 'bg-zinc-800 text-zinc-400 hover:bg-zinc-700 hover:text-white'
              }`}
            >
              {year}
            </button>
          ))}
        </div>
      </div>

      {/* Add/Edit Form */}
      {showForm && (
        <div className="bg-zinc-900/80 backdrop-blur-sm rounded-xl border border-zinc-800 p-6 mb-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-white">
              {editingHoliday ? t('holidays.editHoliday') : t('holidays.addHoliday')}
            </h2>
            <button onClick={resetForm} className="text-zinc-400 hover:text-white">
              <X className="w-5 h-5" />
            </button>
          </div>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <label className="block text-sm font-medium text-zinc-300">
                  {t('holidays.holidayName')}
                </label>
                <input
                  type="text"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  required
                  className={inputClasses}
                  placeholder={t('holidays.holidayName')}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-zinc-300">
                  {t('common.date')}
                </label>
                <input
                  type="date"
                  value={holidayDate}
                  onChange={(e) => setHolidayDate(e.target.value)}
                  required
                  className={inputClasses}
                />
              </div>
              <div className="flex items-end gap-3">
                <label className="flex items-center gap-2 cursor-pointer pb-2">
                  <input
                    type="checkbox"
                    checked={isRecurring}
                    onChange={(e) => setIsRecurring(e.target.checked)}
                    className="w-4 h-4 text-amber-500 bg-zinc-800 border-zinc-600 rounded focus:ring-amber-500/20"
                  />
                  <span className="text-sm text-zinc-200">{t('holidays.recurring')}</span>
                  <RotateCcw className="w-3 h-3 text-zinc-500" />
                </label>
              </div>
            </div>
            <div className="flex gap-2">
              <button
                type="submit"
                disabled={createMutation.isPending || updateMutation.isPending}
                className="inline-flex items-center gap-2 px-4 py-2 text-sm font-semibold text-black bg-amber-500 rounded-lg hover:bg-amber-400 shadow-lg shadow-amber-500/20 disabled:opacity-50 transition-all"
              >
                {editingHoliday ? t('common.save') : t('common.create')}
              </button>
              <button
                type="button"
                onClick={resetForm}
                className="px-4 py-2 text-sm font-medium text-zinc-400 bg-zinc-800 rounded-lg hover:bg-zinc-700 hover:text-white transition-colors"
              >
                {t('common.cancel')}
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Holidays Table */}
      <div className="bg-zinc-900/80 backdrop-blur-sm rounded-xl border border-zinc-800 overflow-hidden">
        {isLoading ? (
          <div className="p-8 text-center text-zinc-400">{t('common.loading')}</div>
        ) : !holidays || holidays.length === 0 ? (
          <div className="p-8 text-center text-zinc-400">{t('common.noData')}</div>
        ) : (
          <table className="w-full">
            <thead>
              <tr className="border-b border-zinc-800">
                <th className="px-6 py-3 text-left text-xs font-semibold text-zinc-400 uppercase tracking-wider">
                  {t('holidays.holidayName')}
                </th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-zinc-400 uppercase tracking-wider">
                  {t('common.date')}
                </th>
                <th className="px-6 py-3 text-left text-xs font-semibold text-zinc-400 uppercase tracking-wider">
                  {t('holidays.recurring')}
                </th>
                <th className="px-6 py-3 text-right text-xs font-semibold text-zinc-400 uppercase tracking-wider">
                  {t('common.actions')}
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-zinc-800/50">
              {holidays.map((holiday) => (
                <tr key={holiday.id} className="hover:bg-zinc-800/30 transition-colors">
                  <td className="px-6 py-4 text-sm text-white font-medium">
                    {holiday.name}
                  </td>
                  <td className="px-6 py-4 text-sm text-zinc-300">
                    {new Date(holiday.holiday_date + 'T00:00:00').toLocaleDateString()}
                  </td>
                  <td className="px-6 py-4 text-sm">
                    {holiday.is_recurring ? (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-amber-500/10 text-amber-400">
                        <RotateCcw className="w-3 h-3" />
                        {t('common.yes')}
                      </span>
                    ) : (
                      <span className="text-zinc-500">{t('common.no')}</span>
                    )}
                  </td>
                  <td className="px-6 py-4 text-right">
                    <div className="flex items-center justify-end gap-2">
                      <button
                        onClick={() => handleEdit(holiday)}
                        className="p-1.5 text-zinc-400 hover:text-amber-400 hover:bg-amber-500/10 rounded-lg transition-colors"
                      >
                        <Edit2 className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => handleDelete(holiday.id)}
                        className="p-1.5 text-zinc-400 hover:text-rose-400 hover:bg-rose-500/10 rounded-lg transition-colors"
                      >
                        <Trash2 className="w-4 h-4" />
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
  );
}
