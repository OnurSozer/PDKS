import React, { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../../hooks/useAuth';
import { LanguageSwitcher } from '../../components/shared/LanguageSwitcher';
import { supabase } from '../../lib/supabase';
import { Profile } from '../../types';

export function LoginPage() {
  const { t } = useTranslation();
  const { signIn, profile, session } = useAuth();
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  // If already logged in, redirect based on role
  useEffect(() => {
    if (session && profile) {
      redirectByRole(profile.role);
    }
  }, [session, profile]); // eslint-disable-line react-hooks/exhaustive-deps

  const redirectByRole = (role: string) => {
    if (role === 'super_admin') {
      navigate('/admin/dashboard', { replace: true });
    } else if (role === 'operator') {
      navigate('/operator/dashboard', { replace: true });
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    const { error: signInError } = await signIn(email, password);

    if (signInError) {
      setLoading(false);
      setError(t('auth.invalidCredentials'));
      return;
    }

    // Fetch profile to determine role for redirect
    const { data: { user } } = await supabase.auth.getUser();
    if (user) {
      const { data: prof } = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();
      setLoading(false);
      if (prof) {
        redirectByRole((prof as Profile).role);
      }
    } else {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-zinc-950 bg-dot-grid bg-[size:24px_24px] py-12 px-4 sm:px-6 lg:px-8 relative overflow-hidden">
      {/* Radial amber gradient */}
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,_rgba(245,158,11,0.08)_0%,_transparent_70%)]" />

      {/* Language switcher */}
      <div className="absolute top-4 right-4 z-10">
        <LanguageSwitcher />
      </div>

      <div className="relative max-w-md w-full space-y-8">
        {/* Glass card */}
        <div className="bg-zinc-900/80 backdrop-blur-sm border border-zinc-800 rounded-2xl p-8 shadow-xl relative overflow-hidden">
          {/* Amber accent bar */}
          <div className="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-amber-500 via-amber-400 to-amber-500" />

          <div className="text-center mb-8">
            <h1 className="text-3xl font-bold font-display text-amber-500">
              {t('app.name')}
            </h1>
            <h2 className="mt-2 text-xl text-white font-display">
              {t('auth.loginTitle')}
            </h2>
            <p className="mt-1 text-sm text-zinc-400">
              {t('auth.loginSubtitle')}
            </p>
          </div>

          <form className="space-y-6" onSubmit={handleSubmit}>
            {error && (
              <div className="bg-rose-500/10 border border-rose-500/20 text-rose-400 px-4 py-3 rounded-lg text-sm">
                {error}
              </div>
            )}
            <div className="space-y-4">
              <div>
                <label htmlFor="email" className="block text-sm font-medium text-zinc-300">
                  {t('auth.email')}
                </label>
                <input
                  id="email"
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="mt-1 block w-full px-3 py-2.5 bg-zinc-800 border border-zinc-700 rounded-lg text-white placeholder-zinc-500 focus:outline-none focus:border-amber-500 focus:ring-1 focus:ring-amber-500/20 transition-colors"
                  placeholder="ornek@sirket.com"
                />
              </div>
              <div>
                <label htmlFor="password" className="block text-sm font-medium text-zinc-300">
                  {t('auth.password')}
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
            </div>
            <button
              type="submit"
              disabled={loading}
              className="w-full flex justify-center py-2.5 px-4 bg-amber-500 hover:bg-amber-400 text-black font-semibold rounded-lg shadow-lg shadow-amber-500/20 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed animate-glow"
            >
              {loading ? t('common.loading') : t('auth.login')}
            </button>
            <div className="text-center">
              <Link
                to="/forgot-password"
                className="text-sm text-zinc-400 hover:text-amber-400 transition-colors"
              >
                {t('auth.forgotPassword')}
              </Link>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
