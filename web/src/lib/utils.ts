import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatMinutes(minutes: number): string {
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  return `${h}h ${m}m`;
}

/**
 * Strip timezone offset from Supabase timestamp strings so JavaScript
 * treats the value as local time (all DB values are stored as local time).
 */
function stripTzOffset(dateStr: string): string {
  return dateStr.replace(/[+-]\d{2}(:\d{2})?$/, '').replace(/Z$/, '');
}

export function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleDateString();
}

export function formatDateTime(dateStr: string): string {
  return new Date(stripTzOffset(dateStr)).toLocaleString([], { hour12: false });
}

export function formatTime(dateStr: string): string {
  return new Date(stripTzOffset(dateStr)).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: false });
}

export function getWorkDayLabels(days: number[], t: (key: string) => string): string {
  const dayKeys = ['', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
  return days.map(d => t(`days.${dayKeys[d]}Short`)).join(', ');
}
