import {
  calculateBossCallEffective,
  calculateSpecialDayEffective,
  calculateDeficit,
  determineWorkDayType,
  calculateMonthlySummary,
  DaySummaryInput,
  SpecialDayTypeConfig,
} from '../workCalculations';

// =====================================================================
// Boss Call Rounding
// =====================================================================
describe('calculateBossCallEffective', () => {
  // Company example: expected daily = 510 min (8h30m), multiplier = 1.5
  const EXPECTED = 510;
  const MULTIPLIER = 1.5;
  const HALF_DAY = Math.round(EXPECTED / 2); // 255

  test('zero worked → rounds to half day × multiplier', () => {
    const result = calculateBossCallEffective(0, EXPECTED, MULTIPLIER);
    expect(result).toBe(Math.round(HALF_DAY * MULTIPLIER)); // 255 × 1.5 = 383
  });

  test('worked 1 minute → rounds to half day × multiplier', () => {
    const result = calculateBossCallEffective(1, EXPECTED, MULTIPLIER);
    expect(result).toBe(Math.round(HALF_DAY * MULTIPLIER));
  });

  test('worked < half day (120 min) → rounds to half day × multiplier', () => {
    const result = calculateBossCallEffective(120, EXPECTED, MULTIPLIER);
    expect(result).toBe(Math.round(HALF_DAY * MULTIPLIER)); // 383
  });

  test('worked exactly half day → rounds to full day × multiplier', () => {
    // worked == halfDay → falls into (halfDay..expectedDaily] → rounds to full day
    const result = calculateBossCallEffective(HALF_DAY, EXPECTED, MULTIPLIER);
    expect(result).toBe(Math.round(EXPECTED * MULTIPLIER)); // 510 × 1.5 = 765
  });

  test('worked between half day and full day (400 min) → full day × multiplier', () => {
    const result = calculateBossCallEffective(400, EXPECTED, MULTIPLIER);
    expect(result).toBe(Math.round(EXPECTED * MULTIPLIER)); // 765
  });

  test('worked exactly full day → full day × multiplier', () => {
    const result = calculateBossCallEffective(EXPECTED, EXPECTED, MULTIPLIER);
    expect(result).toBe(Math.round(EXPECTED * MULTIPLIER)); // 765
  });

  test('worked MORE than full day (600 min) → actual × multiplier (no rounding)', () => {
    const result = calculateBossCallEffective(600, EXPECTED, MULTIPLIER);
    expect(result).toBe(Math.round(600 * MULTIPLIER)); // 900
  });

  test('works with 480-min (8h) expected and 1.5x multiplier', () => {
    const halfDay480 = Math.round(480 / 2); // 240
    expect(calculateBossCallEffective(100, 480, 1.5)).toBe(Math.round(halfDay480 * 1.5)); // 360
    expect(calculateBossCallEffective(300, 480, 1.5)).toBe(Math.round(480 * 1.5));        // 720
    expect(calculateBossCallEffective(500, 480, 1.5)).toBe(Math.round(500 * 1.5));        // 750
  });

  test('works with 2.0x multiplier', () => {
    const result = calculateBossCallEffective(300, 510, 2.0);
    // 300 is between half-day (255) and full-day (510) → rounds to 510
    expect(result).toBe(Math.round(510 * 2.0)); // 1020
  });

  test('negative worked minutes treated as 0 → half day', () => {
    const result = calculateBossCallEffective(-10, 510, 1.5);
    expect(result).toBe(Math.round(HALF_DAY * 1.5));
  });
});

// =====================================================================
// Special Day Effective (calculateSpecialDayEffective)
// =====================================================================
describe('calculateSpecialDayEffective', () => {
  test('rounding mode matches calculateBossCallEffective', () => {
    const dayType: SpecialDayTypeConfig = {
      calculation_mode: 'rounding',
      multiplier: 1.5,
      base_minutes: 0,
      extra_minutes: 0,
      extra_multiplier: 1.5,
    };
    // Should match boss call behavior
    expect(calculateSpecialDayEffective(300, 510, dayType)).toBe(
      calculateBossCallEffective(300, 510, 1.5)
    );
    expect(calculateSpecialDayEffective(0, 510, dayType)).toBe(
      calculateBossCallEffective(0, 510, 1.5)
    );
    expect(calculateSpecialDayEffective(600, 510, dayType)).toBe(
      calculateBossCallEffective(600, 510, 1.5)
    );
  });

  test('fixed_hours mode: base + extra × extra_multiplier', () => {
    const dayType: SpecialDayTypeConfig = {
      calculation_mode: 'fixed_hours',
      multiplier: 1.5,
      base_minutes: 600, // 10h
      extra_minutes: 240, // 4h
      extra_multiplier: 1.5,
    };
    // 600 + 240 × 1.5 = 600 + 360 = 960
    expect(calculateSpecialDayEffective(0, 510, dayType)).toBe(960);
    // Same regardless of worked minutes
    expect(calculateSpecialDayEffective(300, 510, dayType)).toBe(960);
    expect(calculateSpecialDayEffective(600, 510, dayType)).toBe(960);
  });

  test('fixed_hours mode: different parameters', () => {
    const dayType: SpecialDayTypeConfig = {
      calculation_mode: 'fixed_hours',
      multiplier: 1,
      base_minutes: 480,
      extra_minutes: 120,
      extra_multiplier: 2.0,
    };
    // 480 + 120 × 2.0 = 480 + 240 = 720
    expect(calculateSpecialDayEffective(100, 480, dayType)).toBe(720);
  });

  test('fixed_hours with zero extra → just base', () => {
    const dayType: SpecialDayTypeConfig = {
      calculation_mode: 'fixed_hours',
      multiplier: 1,
      base_minutes: 600,
      extra_minutes: 0,
      extra_multiplier: 1.5,
    };
    expect(calculateSpecialDayEffective(0, 510, dayType)).toBe(600);
  });
});

// =====================================================================
// Deficit
// =====================================================================
describe('calculateDeficit', () => {
  test('no deficit when worked more than expected', () => {
    expect(calculateDeficit(510, 600)).toBe(0);
  });

  test('no deficit when worked exactly expected', () => {
    expect(calculateDeficit(510, 510)).toBe(0);
  });

  test('deficit when worked less than expected', () => {
    expect(calculateDeficit(510, 400)).toBe(110);
  });

  test('full deficit when absent (0 worked)', () => {
    expect(calculateDeficit(510, 0)).toBe(510);
  });

  test('0 expected → no deficit', () => {
    expect(calculateDeficit(0, 0)).toBe(0);
  });
});

// =====================================================================
// Work Day Type
// =====================================================================
describe('determineWorkDayType', () => {
  const monFri = [1, 2, 3, 4, 5]; // Mon-Fri

  test('regular weekday → regular', () => {
    // 2026-02-16 is a Monday (ISO day 1)
    expect(determineWorkDayType('2026-02-16', monFri, new Set())).toBe('regular');
  });

  test('Saturday → weekend', () => {
    // 2026-02-21 is a Saturday (ISO day 6)
    expect(determineWorkDayType('2026-02-21', monFri, new Set())).toBe('weekend');
  });

  test('Sunday → weekend', () => {
    // 2026-02-22 is a Sunday (ISO day 7)
    expect(determineWorkDayType('2026-02-22', monFri, new Set())).toBe('weekend');
  });

  test('holiday on weekday → holiday (takes precedence)', () => {
    const holidays = new Set(['2026-02-16']);
    expect(determineWorkDayType('2026-02-16', monFri, holidays)).toBe('holiday');
  });

  test('holiday on weekend → holiday', () => {
    const holidays = new Set(['2026-02-21']);
    expect(determineWorkDayType('2026-02-21', monFri, holidays)).toBe('holiday');
  });

  test('Sun-Thu schedule: Friday → weekend', () => {
    const sunThu = [7, 1, 2, 3, 4]; // Sun, Mon, Tue, Wed, Thu
    // 2026-02-20 is a Friday (ISO day 5)
    expect(determineWorkDayType('2026-02-20', sunThu, new Set())).toBe('weekend');
  });

  test('Sun-Thu schedule: Sunday → regular', () => {
    const sunThu = [7, 1, 2, 3, 4];
    // 2026-02-22 is a Sunday (ISO day 7)
    expect(determineWorkDayType('2026-02-22', sunThu, new Set())).toBe('regular');
  });
});

// =====================================================================
// Monthly Summary Calculation
// =====================================================================
describe('calculateMonthlySummary', () => {
  const OT_MULTIPLIER = 1.5;
  const MONTHLY_CONSTANT = 21.66;

  /**
   * Helper: create a regular work day summary input.
   */
  function regularDay(worked: number, expected: number): DaySummaryInput {
    return {
      totalWorkMinutes: worked,
      expectedWorkMinutes: expected,
      effectiveWorkMinutes: worked,
      isBossCall: false,
      isWorkDay: true,
    };
  }

  /**
   * Helper: create a boss-call day summary input.
   * The effective minutes are pre-calculated (rounded + multiplied).
   */
  function bossCallDay(
    worked: number,
    expected: number,
    effective: number
  ): DaySummaryInput {
    return {
      totalWorkMinutes: worked,
      expectedWorkMinutes: expected,
      effectiveWorkMinutes: effective,
      isBossCall: true,
      isWorkDay: true,
    };
  }

  // ── Basic scenarios ──

  test('all regular days, no overtime → net negative, OT = 0', () => {
    const days: DaySummaryInput[] = [
      regularDay(500, 510),
      regularDay(490, 510),
      regularDay(510, 510),
    ];

    const result = calculateMonthlySummary(days, OT_MULTIPLIER, MONTHLY_CONSTANT);

    expect(result.monthlyTotal).toBe(1500);
    expect(result.monthlyExpected).toBe(1530);
    expect(result.netMinutes).toBe(-30);
    expect(result.overtimeValue).toBe(0);
    expect(result.overtimeDays).toBe(0);
    expect(result.overtimePercentage).toBe(0);
  });

  test('all regular days, with overtime → net positive × multiplier', () => {
    const days: DaySummaryInput[] = [
      regularDay(540, 510), // +30
      regularDay(570, 510), // +60
      regularDay(510, 510), // 0
    ];

    const result = calculateMonthlySummary(days, OT_MULTIPLIER, MONTHLY_CONSTANT);

    expect(result.monthlyTotal).toBe(1620);
    expect(result.monthlyExpected).toBe(1530);
    expect(result.netMinutes).toBe(90);
    // 90 regular surplus × 1.5 = 135
    expect(result.overtimeValue).toBe(135);
    // OT days = 135 / (1530/3) = 135 / 510 = 0.26
    expect(result.overtimeDays).toBe(0.26);
    // OT % = 0.26 / 21.66 × 100 ≈ 1.20-1.22 (floating point)
    expect(result.overtimePercentage).toBeCloseTo(1.2, 0);
  });

  test('single regular day, exact match → zero OT', () => {
    const days = [regularDay(510, 510)];
    const result = calculateMonthlySummary(days, OT_MULTIPLIER, MONTHLY_CONSTANT);
    expect(result.netMinutes).toBe(0);
    expect(result.overtimeValue).toBe(0);
    expect(result.overtimePercentage).toBe(0);
  });

  // ── Boss call scenarios ──

  test('boss call day contributes effective (already multiplied) minutes', () => {
    // Worked 300 min on boss-call day with 510 expected
    // Boss-call rounds 300 → full day (510), × 1.5 = 765
    const days: DaySummaryInput[] = [
      bossCallDay(300, 510, 765),
    ];

    const result = calculateMonthlySummary(days, OT_MULTIPLIER, MONTHLY_CONSTANT);

    expect(result.monthlyTotal).toBe(765);
    expect(result.monthlyExpected).toBe(510);
    expect(result.netMinutes).toBe(255); // 765 - 510
    expect(result.bossCallDays).toBe(1);
    expect(result.bossCallMinutes).toBe(765);
  });

  test('boss call surplus does NOT get double-multiplied', () => {
    // 1 boss call day: worked 300, effective 765 (= 510×1.5)
    // expected = 510
    // net = 765 - 510 = 255
    // boss call surplus = 765 - 510 = 255
    // regular surplus = 255 - 255 = 0
    // OT value = 0 × 1.5 + 255 = 255 (boss-call portion passes through)
    const days = [bossCallDay(300, 510, 765)];

    const result = calculateMonthlySummary(days, OT_MULTIPLIER, MONTHLY_CONSTANT);

    // The 255 surplus comes entirely from boss-call (already 1.5x),
    // so it should NOT be multiplied again
    expect(result.overtimeValue).toBe(255);
  });

  test('mix of regular + boss call days', () => {
    // 2 regular days: each 540 worked, 510 expected → surplus 30 each = 60 total regular surplus
    // 1 boss call day: worked 200, effective 383 (half-day rounded × 1.5), expected 510
    const days: DaySummaryInput[] = [
      regularDay(540, 510),
      regularDay(540, 510),
      bossCallDay(200, 510, 383),
    ];

    const result = calculateMonthlySummary(days, OT_MULTIPLIER, MONTHLY_CONSTANT);

    expect(result.monthlyTotal).toBe(540 + 540 + 383); // 1463
    expect(result.monthlyExpected).toBe(1530);
    expect(result.netMinutes).toBe(1463 - 1530); // -67
    // Net is negative, so no OT at all
    expect(result.overtimeValue).toBe(0);
  });

  // ── Absent / zero-work days ──

  test('absent day (0 worked) counts toward expected', () => {
    const days: DaySummaryInput[] = [
      regularDay(510, 510),
      regularDay(0, 510),   // absent
      regularDay(510, 510),
    ];

    const result = calculateMonthlySummary(days, OT_MULTIPLIER, MONTHLY_CONSTANT);

    expect(result.monthlyTotal).toBe(1020);
    expect(result.monthlyExpected).toBe(1530);
    expect(result.netMinutes).toBe(-510);
    expect(result.overtimeValue).toBe(0);
  });

  test('non-work days with no activity are skipped', () => {
    const weekend: DaySummaryInput = {
      totalWorkMinutes: 0,
      expectedWorkMinutes: 0,
      effectiveWorkMinutes: 0,
      isBossCall: false,
      isWorkDay: false,
    };

    const days: DaySummaryInput[] = [
      regularDay(510, 510),
      weekend,
      weekend,
      regularDay(510, 510),
    ];

    const result = calculateMonthlySummary(days, OT_MULTIPLIER, MONTHLY_CONSTANT);

    expect(result.monthlyTotal).toBe(1020);
    expect(result.monthlyExpected).toBe(1020);
    expect(result.netMinutes).toBe(0);
  });

  // ── Edge cases ──

  test('empty days array → zeroes', () => {
    const result = calculateMonthlySummary([], OT_MULTIPLIER, MONTHLY_CONSTANT);

    expect(result.monthlyTotal).toBe(0);
    expect(result.monthlyExpected).toBe(0);
    expect(result.netMinutes).toBe(0);
    expect(result.overtimeValue).toBe(0);
    expect(result.overtimeDays).toBe(0);
    expect(result.overtimePercentage).toBe(0);
  });

  test('all boss-call days with big surplus → correct OT %', () => {
    // 5 boss-call days, each: worked 600, effective 900 (600×1.5), expected 510
    const days: DaySummaryInput[] = Array.from({ length: 5 }, () =>
      bossCallDay(600, 510, 900)
    );

    const result = calculateMonthlySummary(days, OT_MULTIPLIER, MONTHLY_CONSTANT);

    expect(result.monthlyTotal).toBe(4500); // 5 × 900
    expect(result.monthlyExpected).toBe(2550); // 5 × 510
    expect(result.netMinutes).toBe(1950);
    expect(result.bossCallDays).toBe(5);
    // All surplus from boss call → no double multiply
    expect(result.overtimeValue).toBe(1950);
    // OT days = 1950 / 510 = 3.82
    expect(result.overtimeDays).toBe(3.82);
    // OT % = 3.82 / 21.66 × 100 ≈ 17.64 (floating point)
    expect(result.overtimePercentage).toBeCloseTo(17.64, 0);
  });

  // ── Real-world full month simulation ──

  test('realistic 22 work-day month with 1 boss call + 1 absent', () => {
    const EXPECTED_DAILY = 510;

    const days: DaySummaryInput[] = [];

    // 19 regular days: worked 520 each (10 min OT each)
    for (let i = 0; i < 19; i++) {
      days.push(regularDay(520, EXPECTED_DAILY));
    }

    // 1 boss-call day: worked 200, rounded to half-day(255) × 1.5 = 383
    days.push(bossCallDay(200, EXPECTED_DAILY, 383));

    // 1 absent day (0 worked, still expected)
    days.push(regularDay(0, EXPECTED_DAILY));

    // 1 regular day: worked exactly 510
    days.push(regularDay(510, EXPECTED_DAILY));

    const result = calculateMonthlySummary(days, OT_MULTIPLIER, MONTHLY_CONSTANT);

    // Total: 19×520 + 383 + 0 + 510 = 9880 + 383 + 510 = 10773
    expect(result.monthlyTotal).toBe(10773);
    // Expected: 22 × 510 = 11220
    expect(result.monthlyExpected).toBe(11220);
    // Net: 10773 - 11220 = -447
    expect(result.netMinutes).toBe(-447);
    // Net is negative → no overtime
    expect(result.overtimeValue).toBe(0);
    expect(result.overtimeDays).toBe(0);
    expect(result.overtimePercentage).toBe(0);
    expect(result.bossCallDays).toBe(1);
  });

  test('realistic month with significant overtime', () => {
    const EXPECTED_DAILY = 510;

    const days: DaySummaryInput[] = [];

    // 20 regular days: worked 560 each (50 min OT each = 1000 surplus total)
    for (let i = 0; i < 20; i++) {
      days.push(regularDay(560, EXPECTED_DAILY));
    }

    // 2 boss-call days: worked 600, effective = 600×1.5 = 900 (> full day, no rounding)
    for (let i = 0; i < 2; i++) {
      days.push(bossCallDay(600, EXPECTED_DAILY, 900));
    }

    const result = calculateMonthlySummary(days, OT_MULTIPLIER, MONTHLY_CONSTANT);

    // Total: 20×560 + 2×900 = 11200 + 1800 = 13000
    expect(result.monthlyTotal).toBe(13000);
    // Expected: 22 × 510 = 11220
    expect(result.monthlyExpected).toBe(11220);
    // Net: 13000 - 11220 = 1780
    expect(result.netMinutes).toBe(1780);
    expect(result.bossCallDays).toBe(2);
    expect(result.bossCallMinutes).toBe(1800);

    // OT value should be > 0, OT days and percentage should be reasonable
    expect(result.overtimeValue).toBeGreaterThan(0);
    expect(result.overtimeDays).toBeGreaterThan(0);
    expect(result.overtimePercentage).toBeGreaterThan(0);
  });
});

// =====================================================================
// Integration: boss call effective → monthly summary pipeline
// =====================================================================
describe('end-to-end: boss call rounding → monthly calculation', () => {
  test('boss call of 120 min in a 510-min day, 1.5x → correct monthly impact', () => {
    const EXPECTED = 510;
    const BC_MULT = 1.5;
    const OT_MULT = 1.5;

    // Step 1: calculate boss-call effective minutes
    const effective = calculateBossCallEffective(120, EXPECTED, BC_MULT);
    // 120 < 255 (half day) → rounds to 255, × 1.5 = 383
    expect(effective).toBe(383);

    // Step 2: use in monthly calculation (single day for simplicity)
    const days: DaySummaryInput[] = [
      {
        totalWorkMinutes: 120,
        expectedWorkMinutes: EXPECTED,
        effectiveWorkMinutes: effective,
        isBossCall: true,
        isWorkDay: true,
      },
    ];

    const result = calculateMonthlySummary(days, OT_MULT, 21.66);

    // 383 - 510 = -127 → net negative → no OT
    expect(result.netMinutes).toBe(-127);
    expect(result.overtimeValue).toBe(0);
  });

  test('boss call of 520 min in a 510-min day → actual × multiplier', () => {
    const EXPECTED = 510;
    const BC_MULT = 1.5;

    // 520 > 510 (full day) → no rounding, 520 × 1.5 = 780
    const effective = calculateBossCallEffective(520, EXPECTED, BC_MULT);
    expect(effective).toBe(780);

    const days: DaySummaryInput[] = [
      {
        totalWorkMinutes: 520,
        expectedWorkMinutes: EXPECTED,
        effectiveWorkMinutes: effective,
        isBossCall: true,
        isWorkDay: true,
      },
    ];

    const result = calculateMonthlySummary(days, 1.5, 21.66);

    // 780 - 510 = 270 surplus (all from boss call, already multiplied)
    expect(result.netMinutes).toBe(270);
    expect(result.overtimeValue).toBe(270);
  });

  test('monthly summary with mixed regular + rounding + fixed_hours special days', () => {
    const EXPECTED = 510;
    const OT_MULT = 1.5;

    // 1 regular day: worked 540 (30 surplus)
    // 1 rounding-type special day: worked 300, effective = 765 (full day × 1.5)
    // 1 fixed_hours-type special day: worked 200, effective = 960 (600 + 240×1.5)
    const days: DaySummaryInput[] = [
      { totalWorkMinutes: 540, expectedWorkMinutes: EXPECTED, effectiveWorkMinutes: 540, isBossCall: false, hasSpecialDay: false, isWorkDay: true },
      { totalWorkMinutes: 300, expectedWorkMinutes: EXPECTED, effectiveWorkMinutes: 765, isBossCall: true, hasSpecialDay: true, isWorkDay: true },
      { totalWorkMinutes: 200, expectedWorkMinutes: EXPECTED, effectiveWorkMinutes: 960, isBossCall: false, hasSpecialDay: true, isWorkDay: true },
    ];

    const result = calculateMonthlySummary(days, OT_MULT, 21.66);

    // Total: 540 + 765 + 960 = 2265
    expect(result.monthlyTotal).toBe(2265);
    // Expected: 3 × 510 = 1530
    expect(result.monthlyExpected).toBe(1530);
    // Net: 2265 - 1530 = 735
    expect(result.netMinutes).toBe(735);
    // Special day days: 2, minutes: 765 + 960 = 1725
    expect(result.specialDayDays).toBe(2);
    expect(result.specialDayMinutes).toBe(1725);
    // Boss call backward compat: only the rounding day
    expect(result.bossCallDays).toBe(1);
    expect(result.bossCallMinutes).toBe(765);
    // OT value should be > 0
    expect(result.overtimeValue).toBeGreaterThan(0);
  });

  test('deficit tracking: worked half a regular day', () => {
    const deficit = calculateDeficit(510, 255);
    expect(deficit).toBe(255); // 4h 15m deficit

    // Monthly impact
    const days: DaySummaryInput[] = [
      { totalWorkMinutes: 255, expectedWorkMinutes: 510, effectiveWorkMinutes: 255, isBossCall: false, isWorkDay: true },
    ];
    const result = calculateMonthlySummary(days, 1.5, 21.66);
    expect(result.netMinutes).toBe(-255);
    expect(result.overtimeValue).toBe(0);
  });
});

// =====================================================================
// Weekend / Holiday Multiplier Tests
// =====================================================================
describe('weekend and holiday multipliers', () => {
  const OT_MULT = 1.5;
  const WKND_MULT = 1.5;
  const HOL_MULT = 2.0;
  const MONTHLY_CONSTANT = 21.66;

  function weekendDay(worked: number): DaySummaryInput {
    return {
      totalWorkMinutes: worked,
      expectedWorkMinutes: 0, // weekend has 0 expected
      effectiveWorkMinutes: worked,
      isBossCall: false,
      isWorkDay: false,
      workDayType: 'weekend',
    };
  }

  function holidayDay(worked: number): DaySummaryInput {
    return {
      totalWorkMinutes: worked,
      expectedWorkMinutes: 0, // holiday has 0 expected
      effectiveWorkMinutes: worked,
      isBossCall: false,
      isWorkDay: false,
      workDayType: 'holiday',
    };
  }

  function regularDay(worked: number, expected: number): DaySummaryInput {
    return {
      totalWorkMinutes: worked,
      expectedWorkMinutes: expected,
      effectiveWorkMinutes: worked,
      isBossCall: false,
      isWorkDay: true,
      workDayType: 'regular',
    };
  }

  test('weekend work applies weekend multiplier', () => {
    const days: DaySummaryInput[] = [
      regularDay(510, 510), // exact match, no surplus
      weekendDay(300),       // 300 min weekend work → all surplus
    ];

    const result = calculateMonthlySummary(days, OT_MULT, MONTHLY_CONSTANT, WKND_MULT, HOL_MULT);

    expect(result.monthlyTotal).toBe(810);
    expect(result.monthlyExpected).toBe(510);
    expect(result.netMinutes).toBe(300);
    expect(result.weekendWorkMinutes).toBe(300);
    expect(result.holidayWorkMinutes).toBe(0);
    // OT value: weekend 300 × 1.5 = 450, no regular surplus
    expect(result.overtimeValue).toBe(450);
  });

  test('holiday work applies holiday multiplier', () => {
    const days: DaySummaryInput[] = [
      regularDay(510, 510),
      holidayDay(240),
    ];

    const result = calculateMonthlySummary(days, OT_MULT, MONTHLY_CONSTANT, WKND_MULT, HOL_MULT);

    expect(result.monthlyTotal).toBe(750);
    expect(result.netMinutes).toBe(240);
    expect(result.holidayWorkMinutes).toBe(240);
    // OT value: holiday 240 × 2.0 = 480
    expect(result.overtimeValue).toBe(480);
  });

  test('mixed month: regular overtime + weekend + holiday', () => {
    const days: DaySummaryInput[] = [
      regularDay(570, 510),  // +60 regular surplus
      regularDay(540, 510),  // +30 regular surplus
      weekendDay(300),        // 300 weekend
      holidayDay(120),        // 120 holiday
    ];

    const result = calculateMonthlySummary(days, OT_MULT, MONTHLY_CONSTANT, WKND_MULT, HOL_MULT);

    expect(result.monthlyTotal).toBe(1530);
    expect(result.monthlyExpected).toBe(1020);
    expect(result.netMinutes).toBe(510);
    expect(result.weekendWorkMinutes).toBe(300);
    expect(result.holidayWorkMinutes).toBe(120);
    // regular surplus = 510 - 300 - 120 = 90, × 1.5 = 135
    // weekend = 300 × 1.5 = 450
    // holiday = 120 × 2.0 = 240
    // total OT = 135 + 450 + 240 = 825
    expect(result.overtimeValue).toBe(825);
  });

  test('backward compat: calling without weekend/holiday params uses overtimeMultiplier for all', () => {
    const days: DaySummaryInput[] = [
      regularDay(510, 510),
      weekendDay(300),
    ];

    // Without weekend/holiday multiplier params — should fall back to overtimeMultiplier
    const result = calculateMonthlySummary(days, OT_MULT, MONTHLY_CONSTANT);

    expect(result.netMinutes).toBe(300);
    // Falls back to overtimeMultiplier for weekend: 300 × 1.5 = 450
    expect(result.overtimeValue).toBe(450);
  });
});
