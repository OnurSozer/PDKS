import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { supabase } from '../../lib/supabase';
import { LanguageSwitcher } from '../../components/shared/LanguageSwitcher';

export function ResetPasswordPage() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (password !== confirmPassword) {
      setError(t('auth.passwordsDoNotMatch'));
      return;
    }

    if (password.length < 6) {
      setError(t('common.required'));
      return;
    }

    setLoading(true);

    const { error } = await supabase.auth.updateUser({ password });

    setLoading(false);
    if (error) {
      setError(error.message);
    } else {
      setSuccess(true);
      // Sign out so they can log in fresh with new password
      await supabase.auth.signOut();
      setTimeout(() => navigate('/login', { replace: true }), 3000);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-zinc-950 bg-dot-grid bg-[size:24px_24px] py-12 px-4 sm:px-6 lg:px-8 relative overflow-hidden">
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,_rgba(245,158,11,0.08)_0%,_transparent_70%)]" />

      <div className="absolute top-4 right-4 z-10">
        <LanguageSwitcher />
      </div>

      <div className="relative max-w-md w-full space-y-8">
        <div className="bg-zinc-900/80 backdrop-blur-sm border border-zinc-800 rounded-2xl p-8 shadow-xl relative overflow-hidden">
          <div className="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-amber-500 via-amber-400 to-amber-500" />

          <div className="text-center mb-8">
            <h1 className="text-3xl font-bold font-display text-amber-500">
              {t('app.name')}
            </h1>
            <h2 className="mt-2 text-xl text-white font-display">
              {t('auth.resetPassword')}
            </h2>
          </div>

          {success ? (
            <div className="space-y-6">
              <div className="bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 px-4 py-3 rounded-lg text-sm">
                {t('auth.passwordUpdated')}
              </div>
              <Link
                to="/login"
                className="block w-full text-center py-2.5 px-4 bg-zinc-800 hover:bg-zinc-700 text-white font-medium rounded-lg border border-zinc-700 transition-colors"
              >
                {t('auth.backToLogin')}
              </Link>
            </div>
          ) : (
            <form className="space-y-6" onSubmit={handleSubmit}>
              {error && (
                <div className="bg-rose-500/10 border border-rose-500/20 text-rose-400 px-4 py-3 rounded-lg text-sm">
                  {error}
                </div>
              )}
              <div>
                <label htmlFor="password" className="block text-sm font-medium text-zinc-300">
                  {t('auth.newPassword')}
                </label>
                <input
                  id="password"
                  type="password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="mt-1 block w-full px-3 py-2.5 bg-zinc-800 border border-zinc-700 rounded-lg text-white placeholder-zinc-500 focus:outline-none focus:border-amber-500 focus:ring-1 focus:ring-amber-500/20 transition-colors"
                />
              </div>
              <div>
                <label htmlFor="confirmPassword" className="block text-sm font-medium text-zinc-300">
                  {t('auth.confirmPassword')}
                </label>
                <input
                  id="confirmPassword"
                  type="password"
                  required
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  className="mt-1 block w-full px-3 py-2.5 bg-zinc-800 border border-zinc-700 rounded-lg text-white placeholder-zinc-500 focus:outline-none focus:border-amber-500 focus:ring-1 focus:ring-amber-500/20 transition-colors"
                />
              </div>
              <button
                type="submit"
                disabled={loading}
                className="w-full flex justify-center py-2.5 px-4 bg-amber-500 hover:bg-amber-400 text-black font-semibold rounded-lg shadow-lg shadow-amber-500/20 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {loading ? t('common.loading') : t('auth.updatePassword')}
              </button>
            </form>
          )}
        </div>
      </div>
    </div>
  );
}
