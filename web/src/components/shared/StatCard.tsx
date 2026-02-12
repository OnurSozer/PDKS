import React from 'react';
import { cn } from '../../lib/utils';
import { LucideIcon } from 'lucide-react';

interface StatCardProps {
  title: string;
  value: string | number;
  icon: LucideIcon;
  color?: 'blue' | 'green' | 'yellow' | 'red' | 'purple';
  subtitle?: string;
}

const colorMap = {
  blue: 'bg-sky-500/10 text-sky-400',
  green: 'bg-emerald-500/10 text-emerald-400',
  yellow: 'bg-amber-500/10 text-amber-400',
  red: 'bg-rose-500/10 text-rose-400',
  purple: 'bg-violet-500/10 text-violet-400',
};

export function StatCard({ title, value, icon: Icon, color = 'blue', subtitle }: StatCardProps) {
  return (
    <div className="bg-zinc-900/80 backdrop-blur-sm rounded-xl border border-zinc-800 p-6">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm font-medium text-zinc-400">{title}</p>
          <p className="mt-1 text-3xl font-semibold font-mono text-white">{value}</p>
          {subtitle && (
            <p className="mt-1 text-sm text-zinc-500">{subtitle}</p>
          )}
        </div>
        <div className={cn('p-3 rounded-lg', colorMap[color])}>
          <Icon className="w-6 h-6" />
        </div>
      </div>
    </div>
  );
}
