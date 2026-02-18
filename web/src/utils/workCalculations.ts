/**
 * Pure calculation functions for the work time calculation system.
 * These mirror the logic used in the backend edge functions
 * (toggle-boss-call, recalculate-daily-summary, get-monthly-summary).
 *
 * Extracted here so they can be unit-tested without database dependencies.
 */

// ─── Boss Call Rounding ──────────────────────────────────────────────

/**
 * Apply boss-call rounding logic and multiplier.
 *
 * | Worked              | Rounds up to |
 * |---------------------|-------------|
 * | < half day          | half day    |
 * | half day – full day | full day    |
 * | > full day          | actual      |
 *
 * Then multiply by boss_call_multiplier.
 */
export function calculateBossCallEffective(
  workedMinutes: number,
  expectedDailyMinutes: number,
  bossCallMultiplier: number
): number {
  const halfDay = Math.round(expectedDailyMinutes / 2);

  let roundedMinutes: number;
  if (workedMinutes <= 0) {
    roundedMinutes = halfDay;
  } else if (workedMinutes < halfDay) {
    roundedMinutes = halfDay;
  } else if (workedMinutes <= expectedDailyMinutes) {
    roundedMinutes = expectedDailyMinutes;
  } else {
    roundedMinutes = workedMinutes; // no rounding for > full day
  }

  return Math.round(roundedMinutes * bossCallMultiplier);
}

// ─── Special Day Effective ───────────────────────────────────────────

export interface SpecialDayTypeConfig {
  calculation_mode: 'rounding' | 'fixed_hours';
  multiplier: number;
  base_minutes: number;
  extra_minutes: number;
  extra_multiplier: number;
}

/**
 * Calculate effective work minutes for a special day type.
 * Dispatches to rounding or fixed_hours formula based on calculation_mode.
 *
 * - rounding: same as boss call (half/full day rounding × multiplier)
 * - fixed_hours: base_minutes + extra_minutes × extra_multiplier
 */
export function calculateSpecialDayEffective(
  workedMinutes: number,
  expectedDailyMinutes: number,
  dayType: SpecialDayTypeConfig
): number {
  if (dayType.calculation_mode === 'fixed_hours') {
    return Math.round(
      dayType.base_minutes + dayType.extra_minutes * dayType.extra_multiplier
    );
  }

  // rounding mode — same as calculateBossCallEffective
  return calculateBossCallEffective(workedMinutes, expectedDailyMinutes, dayType.multiplier);
}

// ─── Deficit ─────────────────────────────────────────────────────────

/**
 * Calculate deficit (undertime) minutes.
 * Deficit = max(0, expected - actual)
 */
export function calculateDeficit(
  expectedMinutes: number,
  actualMinutes: number
): number {
  return Math.max(0, expectedMinutes - actualMinutes);
}

// ─── Work Day Type ───────────────────────────────────────────────────

/**
 * Determine the work day type for a given date.
 */
export function determineWorkDayType(
  dateStr: string,
  scheduledWorkDays: number[], // ISO days: 1=Mon, 7=Sun
  holidayDates: Set<string>
): 'regular' | 'weekend' | 'holiday' {
  if (holidayDates.has(dateStr)) return 'holiday';

  const dateObj = new Date(dateStr + 'T00:00:00');
  const dayOfWeek = dateObj.getDay(); // 0=Sun
  const isoDay = dayOfWeek === 0 ? 7 : dayOfWeek;

  if (!scheduledWorkDays.includes(isoDay)) return 'weekend';

  return 'regular';
}

// ─── Monthly Summary ─────────────────────────────────────────────────

export interface DaySummaryInput {
  /** Total raw worked minutes for the day */
  totalWorkMinutes: number;
  /** Expected work minutes from the schedule */
  expectedWorkMinutes: number;
  /** If special day or boss call, the effective_work_minutes (already has formula applied) */
  effectiveWorkMinutes: number;
  /** Is this a boss-call day? (backward compat) */
  isBossCall: boolean;
  /** Does this day have any special day type applied? */
  hasSpecialDay?: boolean;
  /** Is this a scheduled work day? */
  isWorkDay: boolean;
  /** Work day type: regular, weekend, or holiday */
  workDayType?: 'regular' | 'weekend' | 'holiday';
}

export interface MonthlyCalculationResult {
  /** Sum of contributed minutes (special day = effective, regular = total) */
  monthlyTotal: number;
  /** Sum of expected minutes across all work days */
  monthlyExpected: number;
  /** monthlyTotal - monthlyExpected */
  netMinutes: number;
  /** Number of boss call days (backward compat) */
  bossCallDays: number;
  /** Total minutes attributed to boss call days (backward compat) */
  bossCallMinutes: number;
  /** Number of special day type days (all types) */
  specialDayDays: number;
  /** Total minutes attributed to special day type days (all types) */
  specialDayMinutes: number;
  /** Total minutes worked on weekends */
  weekendWorkMinutes: number;
  /** Total minutes worked on holidays */
  holidayWorkMinutes: number;
  /** Final OT value after applying multiplier to regular surplus */
  overtimeValue: number;
  /** overtimeValue / expectedDailyMinutes */
  overtimeDays: number;
  /** overtimeDays / monthlyConstant * 100 */
  overtimePercentage: number;
}

/**
 * Calculate the monthly payroll summary from daily summaries.
 *
 * Formula:
 * 1. monthlyTotal = sum of contributed minutes (boss call uses effective_work_minutes)
 * 2. monthlyExpected = sum of expected minutes for all work days
 * 3. net = monthlyTotal - monthlyExpected
 * 4. Regular surplus gets × overtimeMultiplier; boss-call surplus already has multiplier baked in
 * 5. overtimeDays = overtimeValue / expectedDailyMinutes
 * 6. overtimePercentage = overtimeDays / monthlyConstant × 100
 */
export function calculateMonthlySummary(
  days: DaySummaryInput[],
  overtimeMultiplier: number,
  monthlyConstant: number,
  weekendMultiplier?: number,
  holidayMultiplier?: number
): MonthlyCalculationResult {
  const wkndMult = weekendMultiplier ?? overtimeMultiplier;
  const holMult = holidayMultiplier ?? overtimeMultiplier;

  let monthlyTotal = 0;
  let monthlyExpected = 0;
  let bossCallDays = 0;
  let bossCallMinutes = 0;
  let specialDayDays = 0;
  let specialDayMinutes = 0;
  let weekendWorkMins = 0;
  let holidayWorkMins = 0;
  let workDayCount = 0;

  for (const day of days) {
    const isSpecial = day.hasSpecialDay || day.isBossCall;
    if (!day.isWorkDay && day.totalWorkMinutes === 0 && !isSpecial) {
      continue; // skip non-work days with no activity
    }

    workDayCount++;
    monthlyExpected += day.expectedWorkMinutes;

    let contributed = 0;
    if (isSpecial) {
      contributed = day.effectiveWorkMinutes;
      monthlyTotal += contributed;
      specialDayDays++;
      specialDayMinutes += contributed;
      // Backward compat counters
      if (day.isBossCall) {
        bossCallDays++;
        bossCallMinutes += contributed;
      }
    } else {
      contributed = day.totalWorkMinutes;
      monthlyTotal += contributed;
    }

    // Track weekend/holiday work minutes
    if (day.workDayType === 'weekend' && contributed > 0) weekendWorkMins += contributed;
    if (day.workDayType === 'holiday' && contributed > 0) holidayWorkMins += contributed;
  }

  const netMinutes = monthlyTotal - monthlyExpected;

  // Calculate OT value with per-type multipliers
  // Weekend/holiday work is all surplus (expected=0 for those days).
  // Special day contribution to surplus already includes the multiplier.
  let overtimeValue = 0;
  if (netMinutes > 0) {
    const expectedPerDay = workDayCount > 0 ? monthlyExpected / workDayCount : 0;
    const specialDaySurplus = specialDayMinutes - specialDayDays * expectedPerDay;
    const regularSurplus = netMinutes - weekendWorkMins - holidayWorkMins - Math.max(0, specialDaySurplus);

    overtimeValue = 0;
    if (regularSurplus > 0) overtimeValue += regularSurplus * overtimeMultiplier;
    overtimeValue += weekendWorkMins * wkndMult;
    overtimeValue += holidayWorkMins * holMult;
    if (specialDaySurplus > 0) overtimeValue += specialDaySurplus; // already multiplied
  }

  const expectedDailyMinutes = workDayCount > 0 ? monthlyExpected / workDayCount : 0;
  const overtimeDays = expectedDailyMinutes > 0 ? overtimeValue / expectedDailyMinutes : 0;
  const overtimePercentage = monthlyConstant > 0 ? (overtimeDays / monthlyConstant) * 100 : 0;

  return {
    monthlyTotal,
    monthlyExpected,
    netMinutes,
    bossCallDays,
    bossCallMinutes,
    specialDayDays,
    specialDayMinutes,
    weekendWorkMinutes: weekendWorkMins,
    holidayWorkMinutes: holidayWorkMins,
    overtimeValue: Math.round(overtimeValue),
    overtimeDays: Math.round(overtimeDays * 100) / 100,
    overtimePercentage: Math.round(overtimePercentage * 100) / 100,
  };
}
