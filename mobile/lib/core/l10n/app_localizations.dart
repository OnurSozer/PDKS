import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('tr'),
    Locale('en'),
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': _en,
    'tr': _tr,
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  // ---- General ----
  String get appTitle => get('app_title');
  String get loading => get('loading');
  String get error => get('error');
  String get retry => get('retry');
  String get cancel => get('cancel');
  String get save => get('save');
  String get confirm => get('confirm');
  String get ok => get('ok');
  String get yes => get('yes');
  String get no => get('no');
  String get noData => get('no_data');
  String get networkError => get('network_error');

  // ---- Auth ----
  String get login => get('login');
  String get logout => get('logout');
  String get email => get('email');
  String get password => get('password');
  String get loginTitle => get('login_title');
  String get loginSubtitle => get('login_subtitle');
  String get loginButton => get('login_button');
  String get logoutConfirm => get('logout_confirm');
  String get loginError => get('login_error');

  // ---- Home ----
  String get home => get('home');
  String get clockIn => get('clock_in');
  String get clockOut => get('clock_out');
  String get clockedInSince => get('clocked_in_since');
  String get notClockedIn => get('not_clocked_in');
  String get todaySessions => get('today_sessions');
  String get todaySummary => get('today_summary');
  String get totalHours => get('total_hours');
  String get regularHours => get('regular_hours');
  String get overtimeHours => get('overtime_hours');
  String get noSessionsToday => get('no_sessions_today');
  String get mealReady => get('meal_ready');
  String get mealReadyConfirm => get('meal_ready_confirm');
  String get mealReadySent => get('meal_ready_sent');
  String get clockInSuccess => get('clock_in_success');
  String get clockOutSuccess => get('clock_out_success');
  String get alreadyClockedIn => get('already_clocked_in');
  String get clockInButtonTitle => get('clock_in_button_title');
  String get clockOutButtonTitle => get('clock_out_button_title');
  String get clockInButtonSubtitle => get('clock_in_button_subtitle');
  String get clockOutButtonSubtitle => get('clock_out_button_subtitle');

  // ---- Sessions ----
  String get sessions => get('sessions');
  String get sessionHistory => get('session_history');
  String get sessionDetail => get('session_detail');
  String get date => get('date');
  String get clockInTime => get('clock_in_time');
  String get clockOutTime => get('clock_out_time');
  String get duration => get('duration');
  String get status => get('status');
  String get active => get('active');
  String get completed => get('completed');
  String get edited => get('edited');
  String get cancelled => get('cancelled');
  String get noSessions => get('no_sessions');

  // ---- Calendar & Records ----
  String get calendar => get('calendar');
  String get records => get('records');
  String get recentRecords => get('recent_records');
  String get attendance => get('attendance');
  String get hoursWorked => get('hours_worked');
  String get onTime => get('on_time');
  String get lateLabel => get('late');
  String get absent => get('absent');
  String get holiday => get('holiday');
  String get halfDayHoliday => get('half_day_holiday');
  String get missing => get('missing');
  String get extra => get('extra');

  // ---- Missed Clock-Out ----
  String get missedClockOut => get('missed_clock_out');
  String get missedClockOutTitle => get('missed_clock_out_title');
  String get missedClockOutMessage => get('missed_clock_out_message');
  String get selectDepartureTime => get('select_departure_time');
  String get submitMissedClockOut => get('submit_missed_clock_out');

  // ---- Leave ----
  String get leave => get('leave');
  String get leaveBalance => get('leave_balance');
  String get leaveHistory => get('leave_history');
  String get recordLeave => get('record_leave');
  String get leaveType => get('leave_type');
  String get startDate => get('start_date');
  String get endDate => get('end_date');
  String get totalDays => get('total_days');
  String get reason => get('reason');
  String get reasonOptional => get('reason_optional');
  String get usedDays => get('used_days');
  String get remainingDays => get('remaining_days');
  String get noLeaveRecords => get('no_leave_records');
  String get leaveRecorded => get('leave_recorded');
  String get cancelLeave => get('cancel_leave');
  String get cancelLeaveConfirm => get('cancel_leave_confirm');
  String get noLeaveTypes => get('no_leave_types');
  String get myLeave => get('my_leave');

  // ---- Profile ----
  String get profile => get('profile');
  String get editProfile => get('edit_profile');
  String get firstName => get('first_name');
  String get lastName => get('last_name');
  String get phone => get('phone');
  String get startDateLabel => get('start_date_label');
  String get mySchedule => get('my_schedule');
  String get changePassword => get('change_password');
  String get language => get('language');
  String get turkish => get('turkish');
  String get english => get('english');
  String get profileUpdated => get('profile_updated');
  String get passwordChanged => get('password_changed');
  String get currentPassword => get('current_password');
  String get newPassword => get('new_password');
  String get confirmPassword => get('confirm_password');

  // ---- Extra ----
  String get multiplier => get('multiplier');
  String get notes => get('notes');
  String get passwordsDoNotMatch => get('passwords_do_not_match');

  // ---- UI ----
  String get welcomeBack => get('welcome_back');
  String get recentActivity => get('recent_activity');
  String get today => get('today');
  String get yesterday => get('yesterday');

  // ---- Schedule ----
  String get schedule => get('schedule');
  String get shiftName => get('shift_name');
  String get shiftStart => get('shift_start');
  String get shiftEnd => get('shift_end');
  String get breakDuration => get('break_duration');
  String get workDays => get('work_days');
  String get noScheduleAssigned => get('no_schedule_assigned');
  String get monday => get('monday');
  String get tuesday => get('tuesday');
  String get wednesday => get('wednesday');
  String get thursday => get('thursday');
  String get friday => get('friday');
  String get saturday => get('saturday');
  String get sunday => get('sunday');

  // ---- Statistics ----
  String get statistics => get('statistics');
  String get monthlyWork => get('monthly_work');
  String get details => get('details');
  String get workedDays => get('worked_days');
  String get totalDuration => get('total_duration');
  String get dailyAverage => get('daily_average');
  String get usedLeave => get('used_leave');
  String get longestDay => get('longest_day');
  String get shortestSession => get('shortest_session');
  String get statusLabel => get('status_label');
  String get complete => get('complete');
  String get hoursAbbrev => get('hours_abbrev');
  String get minutesAbbrev => get('minutes_abbrev');
  String get expectedHours => get('expected_hours');
  String get netHours => get('net_hours');
  String get overtimeHoursTotal => get('overtime_hours_total');
  String get deficitHours => get('deficit_hours');
  String get otPercent => get('ot_percent');
  String get otDays => get('ot_days');
  String get lateDays => get('late_days');
  String get absentDays => get('absent_days');
  String get none => get('none');
  String get annualLeaveUsage => get('annual_leave_usage');
  String get sickLeaveUsage => get('sick_leave_usage');
  String get hoursFull => get('hours_full');
  String get minutesFull => get('minutes_full');
  String get daysFull => get('days_full');

  // ---- Calendar (new) ----
  String get fullShift => get('full_shift');
  String get overtimeShift => get('overtime_shift');
  String get addSession => get('add_session');
  String get markLeaveDay => get('mark_leave_day');
  String get entryTime => get('entry_time');
  String get exitTime => get('exit_time');
  String get sessionType => get('session_type');
  String get normalShift => get('normal_shift');
  String get create => get('create');

  // ---- Calendar actions ----
  String get addSessionSubtitle => get('add_session_subtitle');
  String get markLeaveDaySubtitle => get('mark_leave_day_subtitle');
  String get manualSessionTitle => get('manual_session_title');
  String get selectLeaveType => get('select_leave_type');
  String get normalLeave => get('normal_leave');
  String get sickLeave => get('sick_leave');
  String get normalLeaveSubtitle => get('normal_leave_subtitle');
  String get sickLeaveSubtitle => get('sick_leave_subtitle');
  String get fullDay => get('full_day');
  String get deductionInfo => get('deduction_info');
  String get halfDayDeductionInfo => get('half_day_deduction_info');
  String get noDeductionInfo => get('no_deduction_info');
  String get markButton => get('mark_button');
  String get creatingSession => get('creating_session');
  String get savingLeave => get('saving_leave');
  String get success => get('success');
  String get sessionCreated => get('session_created');
  String get leaveMarked => get('leave_marked');
  String get calledByBoss => get('called_by_boss');
  String get overtimeSession => get('overtime_session');
  String get exitBeforeEntry => get('exit_before_entry');
  String get editSession => get('edit_session');
  String get sessionEdited => get('session_edited');
  String get deleteSession => get('delete_session');
  String get deleteSessionConfirm => get('delete_session_confirm');
  String get sessionDeleted => get('session_deleted');
  String get deleting => get('deleting');

  // ---- Leave day ----
  String get onLeaveToday => get('on_leave_today');
  String get onSickLeaveToday => get('on_sick_leave_today');
  String get cancelLeaveDay => get('cancel_leave_day');

  // ---- Settings ----
  String get firstDayOfWeek => get('first_day_of_week');
  String get sundayOption => get('sunday_option');
  String get mondayOption => get('monday_option');

  // ---- Profile (new) ----
  String get remainingLeaveShort => get('remaining_leave_short');
  String get thisMonth => get('this_month');
  String get dayUnit => get('day_unit');

  // ---- Month names (short) ----
  String get monthJan => get('month_jan');
  String get monthFeb => get('month_feb');
  String get monthMar => get('month_mar');
  String get monthApr => get('month_apr');
  String get monthMay => get('month_may');
  String get monthJun => get('month_jun');
  String get monthJul => get('month_jul');
  String get monthAug => get('month_aug');
  String get monthSep => get('month_sep');
  String get monthOct => get('month_oct');
  String get monthNov => get('month_nov');
  String get monthDec => get('month_dec');

  // ---- Day abbreviations ----
  String get dayMon => get('day_mon');
  String get dayTue => get('day_tue');
  String get dayWed => get('day_wed');
  String get dayThu => get('day_thu');
  String get dayFri => get('day_fri');
  String get daySat => get('day_sat');
  String get daySun => get('day_sun');

  List<String> get shortMonthNames => [
    monthJan, monthFeb, monthMar, monthApr,
    monthMay, monthJun, monthJul, monthAug,
    monthSep, monthOct, monthNov, monthDec,
  ];

  List<String> get shortDayNames => [
    dayMon, dayTue, dayWed, dayThu, dayFri, daySat, daySun,
  ];

  // ---- English translations ----
  static const Map<String, String> _en = {
    'app_title': 'PDKS',
    'loading': 'Loading...',
    'error': 'Error',
    'retry': 'Retry',
    'cancel': 'Cancel',
    'save': 'Save',
    'confirm': 'Confirm',
    'ok': 'OK',
    'yes': 'Yes',
    'no': 'No',
    'no_data': 'No data available',
    'network_error': 'No internet connection. Please check your network.',

    'login': 'Login',
    'logout': 'Logout',
    'email': 'Email',
    'password': 'Password',
    'login_title': 'Welcome',
    'login_subtitle': 'Sign in to your account',
    'login_button': 'Sign In',
    'logout_confirm': 'Are you sure you want to logout?',
    'login_error': 'Invalid email or password',

    'home': 'Home',
    'clock_in': 'Clock In',
    'clock_out': 'Clock Out',
    'clocked_in_since': 'Clocked in since',
    'not_clocked_in': 'You are clocked out',
    'clock_in_button_title': 'Start',
    'clock_out_button_title': 'Stop',
    'clock_in_button_subtitle': 'CHECK IN',
    'clock_out_button_subtitle': 'CHECK OUT',
    'today_sessions': "Today's Sessions",
    'today_summary': "Today's Summary",
    'total_hours': 'Total',
    'regular_hours': 'Regular',
    'overtime_hours': 'Overtime',
    'no_sessions_today': 'No sessions today',
    'meal_ready': 'Meal is Ready!',
    'meal_ready_confirm': 'Notify all employees that the meal is ready?',
    'meal_ready_sent': 'Meal ready notification sent!',
    'clock_in_success': 'Successfully clocked in',
    'clock_out_success': 'Successfully clocked out',
    'already_clocked_in': 'You already have an active session',

    'sessions': 'Sessions',
    'session_history': 'Session History',
    'session_detail': 'Session Detail',
    'date': 'Date',
    'clock_in_time': 'Clock In',
    'clock_out_time': 'Clock Out',
    'duration': 'Duration',
    'status': 'Status',
    'active': 'Active',
    'completed': 'Completed',
    'edited': 'Edited',
    'cancelled': 'Cancelled',
    'no_sessions': 'No sessions found',

    'calendar': 'Calendar',
    'records': 'Records',
    'recent_records': 'Recent Records',
    'attendance': 'Attendance',
    'hours_worked': 'Hours Worked',
    'on_time': 'ON TIME',
    'late': 'LATE',
    'absent': 'Absent',
    'holiday': 'Holiday',
    'half_day_holiday': 'Half-Day Holiday',
    'missing': 'Missing',
    'extra': 'Extra',

    'missed_clock_out': 'Missed Clock-Out',
    'missed_clock_out_title': 'Open Session Found',
    'missed_clock_out_message':
        'You have an open session from a previous day. Please enter your actual departure time.',
    'select_departure_time': 'Select Departure Time',
    'submit_missed_clock_out': 'Submit',

    'leave': 'Leave',
    'leave_balance': 'Leave Balance',
    'leave_history': 'Leave History',
    'record_leave': 'Record Leave',
    'leave_type': 'Leave Type',
    'start_date': 'Start Date',
    'end_date': 'End Date',
    'total_days': 'Total Days',
    'reason': 'Reason',
    'reason_optional': 'Reason (optional)',
    'used_days': 'Used',
    'remaining_days': 'Remaining',
    'no_leave_records': 'No leave records',
    'leave_recorded': 'Leave recorded successfully',
    'cancel_leave': 'Cancel Leave',
    'cancel_leave_confirm': 'Are you sure you want to cancel this leave record?',
    'no_leave_types': 'No leave types configured for your company',
    'my_leave': 'My Leave',

    'profile': 'Profile',
    'edit_profile': 'Edit Profile',
    'first_name': 'First Name',
    'last_name': 'Last Name',
    'phone': 'Phone',
    'start_date_label': 'Start Date',
    'my_schedule': 'My Schedule',
    'change_password': 'Change Password',
    'language': 'Language',
    'turkish': 'Turkish',
    'english': 'English',
    'profile_updated': 'Profile updated successfully',
    'password_changed': 'Password changed successfully',
    'current_password': 'Current Password',
    'new_password': 'New Password',
    'confirm_password': 'Confirm Password',

    'multiplier': 'Multiplier',
    'notes': 'Notes',
    'passwords_do_not_match': 'Passwords do not match',

    'welcome_back': 'Welcome back',
    'recent_activity': 'Your recent activity log.',
    'today': 'Today',
    'yesterday': 'Yesterday',

    'schedule': 'Schedule',
    'shift_name': 'Shift',
    'shift_start': 'Start',
    'shift_end': 'End',
    'break_duration': 'Break',
    'work_days': 'Work Days',
    'no_schedule_assigned': 'No schedule assigned',
    'monday': 'Mon',
    'tuesday': 'Tue',
    'wednesday': 'Wed',
    'thursday': 'Thu',
    'friday': 'Fri',
    'saturday': 'Sat',
    'sunday': 'Sun',

    // Statistics
    'statistics': 'Statistics',
    'monthly_work': 'Monthly Work',
    'details': 'Details',
    'worked_days': 'Worked Days',
    'total_duration': 'Total Duration',
    'daily_average': 'Daily Average',
    'used_leave': 'Used Leave',
    'longest_day': 'Longest Day',
    'shortest_session': 'Shortest Session',
    'status_label': 'Status',
    'complete': 'Complete',
    'hours_abbrev': 'h',
    'minutes_abbrev': 'm',
    'expected_hours': 'Expected',
    'net_hours': 'Net Hours',
    'overtime_hours_total': 'Overtime',
    'deficit_hours': 'Deficit',
    'ot_percent': 'OT %',
    'ot_days': 'OT Days',
    'late_days': 'Late Days',
    'absent_days': 'Absent Days',
    'none': 'None',
    'annual_leave_usage': 'Annual Leave',
    'sick_leave_usage': 'Sick Leave',
    'hours_full': 'Hours',
    'minutes_full': 'Minutes',
    'days_full': 'Days',

    // Calendar (new)
    'full_shift': 'Full Shift',
    'overtime_shift': 'Overtime',
    'add_session': 'Add Session',
    'mark_leave_day': 'Mark Leave Day',
    'entry_time': 'Entry Time',
    'exit_time': 'Exit Time',
    'session_type': 'Session Type',
    'normal_shift': 'Normal Shift',
    'create': 'Create',

    // Calendar actions
    'add_session_subtitle': 'Set entry and exit time',
    'mark_leave_day_subtitle': 'Mark this day as leave',
    'manual_session_title': 'Add Manual Session',
    'select_leave_type': 'Select Leave Type',
    'normal_leave': 'Normal Leave',
    'sick_leave': 'Sick Leave',
    'normal_leave_subtitle': 'Deducted from leave balance',
    'sick_leave_subtitle': 'Not deducted from balance',
    'full_day': 'Full Day',
    'deduction_info': '1 day will be deducted from balance.',
    'half_day_deduction_info': '0.5 days will be deducted from balance.',
    'no_deduction_info': 'Not deducted from balance.',
    'mark_button': 'Mark',
    'creating_session': 'Creating...',
    'saving_leave': 'Saving...',
    'success': 'Success',
    'session_created': 'Session created',
    'leave_marked': 'Leave day marked',
    'called_by_boss': 'Called by Boss',
    'overtime_session': 'Overtime',
    'exit_before_entry': 'Exit time cannot be before entry time',
    'edit_session': 'Edit Session',
    'session_edited': 'Session updated',
    'delete_session': 'Delete Session',
    'delete_session_confirm': 'Are you sure you want to delete this session?',
    'session_deleted': 'Session deleted',
    'deleting': 'Deleting...',

    // Leave day
    'on_leave_today': 'You are on leave.',
    'on_sick_leave_today': 'You are on sick leave.',
    'cancel_leave_day': 'Cancel leave for this day',

    // Profile (new)
    'remaining_leave_short': 'Remaining Leave',
    'this_month': 'This Month',
    'day_unit': 'day',

    // Month names (short)
    'month_jan': 'Jan',
    'month_feb': 'Feb',
    'month_mar': 'Mar',
    'month_apr': 'Apr',
    'month_may': 'May',
    'month_jun': 'Jun',
    'month_jul': 'Jul',
    'month_aug': 'Aug',
    'month_sep': 'Sep',
    'month_oct': 'Oct',
    'month_nov': 'Nov',
    'month_dec': 'Dec',

    // Day abbreviations
    'day_mon': 'Mon',
    'day_tue': 'Tue',
    'day_wed': 'Wed',
    'day_thu': 'Thu',
    'day_fri': 'Fri',
    'day_sat': 'Sat',
    'day_sun': 'Sun',

    // Settings
    'first_day_of_week': 'First Day of Week',
    'sunday_option': 'Sunday',
    'monday_option': 'Monday',
  };

  // ---- Turkish translations ----
  static const Map<String, String> _tr = {
    'app_title': 'PDKS',
    'loading': 'Yükleniyor...',
    'error': 'Hata',
    'retry': 'Tekrar Dene',
    'cancel': 'İptal',
    'save': 'Kaydet',
    'confirm': 'Onayla',
    'ok': 'Tamam',
    'yes': 'Evet',
    'no': 'Hayır',
    'no_data': 'Veri bulunamadı',
    'network_error': 'İnternet bağlantısı yok. Lütfen ağınızı kontrol edin.',

    'login': 'Giriş',
    'logout': 'Çıkış',
    'email': 'E-posta',
    'password': 'Şifre',
    'login_title': 'Hoş Geldiniz',
    'login_subtitle': 'Hesabınıza giriş yapın',
    'login_button': 'Giriş Yap',
    'logout_confirm': 'Çıkış yapmak istediğinizden emin misiniz?',
    'login_error': 'Geçersiz e-posta veya şifre',

    'home': 'Ana Sayfa',
    'clock_in': 'Giriş Yap',
    'clock_out': 'Çıkış Yap',
    'clocked_in_since': 'Giriş saati',
    'not_clocked_in': 'Giriş yapılmadı',
    'clock_in_button_title': 'Başlat',
    'clock_out_button_title': 'Durdur',
    'clock_in_button_subtitle': 'GİRİŞ YAP',
    'clock_out_button_subtitle': 'ÇIKIŞ YAP',
    'today_sessions': 'Bugünün Oturumları',
    'today_summary': 'Bugünün Özeti',
    'total_hours': 'Toplam',
    'regular_hours': 'Normal',
    'overtime_hours': 'Mesai',
    'no_sessions_today': 'Bugün oturum yok',
    'meal_ready': 'Yemek Hazır!',
    'meal_ready_confirm': 'Tüm çalışanlara yemeğin hazır olduğunu bildir?',
    'meal_ready_sent': 'Yemek hazır bildirimi gönderildi!',
    'clock_in_success': 'Giriş başarılı',
    'clock_out_success': 'Çıkış başarılı',
    'already_clocked_in': 'Zaten aktif bir oturumunuz var',

    'sessions': 'Oturumlar',
    'session_history': 'Oturum Geçmişi',
    'session_detail': 'Oturum Detayı',
    'date': 'Tarih',
    'clock_in_time': 'Giriş',
    'clock_out_time': 'Çıkış',
    'duration': 'Süre',
    'status': 'Durum',
    'active': 'Aktif',
    'completed': 'Tamamlandı',
    'edited': 'Düzenlendi',
    'cancelled': 'İptal Edildi',
    'no_sessions': 'Oturum bulunamadı',

    'calendar': 'Takvim',
    'records': 'Kayıtlar',
    'recent_records': 'Son Kayıtlar',
    'attendance': 'Katılım',
    'hours_worked': 'Çalışma Saati',
    'on_time': 'ZAMANINDA',
    'late': 'GEÇ',
    'absent': 'Devamsız',
    'holiday': 'Tatil',
    'half_day_holiday': 'Yarım Gün Tatil',
    'missing': 'Eksik',
    'extra': 'Fazla',

    'missed_clock_out': 'Unutulan Çıkış',
    'missed_clock_out_title': 'Açık Oturum Bulundu',
    'missed_clock_out_message':
        'Önceki günden açık bir oturumunuz var. Lütfen gerçek çıkış saatinizi girin.',
    'select_departure_time': 'Çıkış Saatini Seçin',
    'submit_missed_clock_out': 'Gönder',

    'leave': 'İzin',
    'leave_balance': 'İzin Bakiyesi',
    'leave_history': 'İzin Geçmişi',
    'record_leave': 'İzin Kaydet',
    'leave_type': 'İzin Türü',
    'start_date': 'Başlangıç Tarihi',
    'end_date': 'Bitiş Tarihi',
    'total_days': 'Toplam Gün',
    'reason': 'Neden',
    'reason_optional': 'Neden (isteğe bağlı)',
    'used_days': 'Kullanılan',
    'remaining_days': 'Kalan',
    'no_leave_records': 'İzin kaydı yok',
    'leave_recorded': 'İzin başarıyla kaydedildi',
    'cancel_leave': 'İzni İptal Et',
    'cancel_leave_confirm': 'Bu izin kaydını iptal etmek istediğinizden emin misiniz?',
    'no_leave_types': 'Şirketiniz için izin türü tanımlanmamış',
    'my_leave': 'İzinlerim',

    'profile': 'Profil',
    'edit_profile': 'Profili Düzenle',
    'first_name': 'Ad',
    'last_name': 'Soyad',
    'phone': 'Telefon',
    'start_date_label': 'Başlangıç Tarihi',
    'my_schedule': 'Vardiyam',
    'change_password': 'Şifre Değiştir',
    'language': 'Dil',
    'turkish': 'Türkçe',
    'english': 'İngilizce',
    'profile_updated': 'Profil başarıyla güncellendi',
    'password_changed': 'Şifre başarıyla değiştirildi',
    'current_password': 'Mevcut Şifre',
    'new_password': 'Yeni Şifre',
    'confirm_password': 'Şifre Tekrar',

    'multiplier': 'Çarpan',
    'notes': 'Notlar',
    'passwords_do_not_match': 'Şifreler uyuşmuyor',

    'welcome_back': 'Tekrar hoş geldin',
    'recent_activity': 'Son aktivite kaydınız.',
    'today': 'Bugün',
    'yesterday': 'Dün',

    'schedule': 'Vardiya',
    'shift_name': 'Vardiya',
    'shift_start': 'Başlangıç',
    'shift_end': 'Bitiş',
    'break_duration': 'Mola',
    'work_days': 'Çalışma Günleri',
    'no_schedule_assigned': 'Atanmış vardiya yok',
    'monday': 'Pzt',
    'tuesday': 'Sal',
    'wednesday': 'Çar',
    'thursday': 'Per',
    'friday': 'Cum',
    'saturday': 'Cmt',
    'sunday': 'Paz',

    // Statistics
    'statistics': 'İstatistik',
    'monthly_work': 'Aylık Çalışma',
    'details': 'Detaylar',
    'worked_days': 'Çalışılan Gün',
    'total_duration': 'Toplam Süre',
    'daily_average': 'Ortalama Günlük',
    'used_leave': 'Kullanılan İzin',
    'longest_day': 'En Uzun Gün',
    'shortest_session': 'En Kısa Mesai',
    'status_label': 'Durum',
    'complete': 'Tamamlandı',
    'hours_abbrev': 's',
    'minutes_abbrev': 'dk',
    'expected_hours': 'Beklenen',
    'net_hours': 'Net Saat',
    'overtime_hours_total': 'Fazla Mesai',
    'deficit_hours': 'Eksik',
    'ot_percent': 'FM %',
    'ot_days': 'FM Gün',
    'late_days': 'Geç Kalma',
    'absent_days': 'Devamsızlık',
    'none': 'Yok',
    'annual_leave_usage': 'Yıllık İzin',
    'sick_leave_usage': 'Hastalık İzni',
    'hours_full': 'Saat',
    'minutes_full': 'Dakika',
    'days_full': 'Gün',

    // Calendar (new)
    'full_shift': 'Tam Mesai',
    'overtime_shift': 'Fazla Mesai',
    'add_session': 'Seans Ekle',
    'mark_leave_day': 'İzin Günü İşaretle',
    'entry_time': 'Giriş Saati',
    'exit_time': 'Çıkış Saati',
    'session_type': 'Seans Türü',
    'normal_shift': 'Normal Mesai',
    'create': 'Oluştur',

    // Calendar actions
    'add_session_subtitle': 'Giriş ve çıkış saati belirle',
    'mark_leave_day_subtitle': 'Bu günü izinli olarak kaydet',
    'manual_session_title': 'Manuel Seans Ekle',
    'select_leave_type': 'İzin Türü Seçin',
    'normal_leave': 'Normal İzin',
    'sick_leave': 'Hastalık İzni',
    'normal_leave_subtitle': 'İzin bakiyesinden düşülür',
    'sick_leave_subtitle': 'İzin bakiyesinden düşülmez',
    'full_day': 'Tam Gün',
    'deduction_info': 'İzin bakiyesinden 1 gün düşülecek.',
    'half_day_deduction_info': 'İzin bakiyesinden 0.5 gün düşülecek.',
    'no_deduction_info': 'İzin bakiyesinden düşülmeyecek.',
    'mark_button': 'İşaretle',
    'creating_session': 'Oluşturuluyor...',
    'saving_leave': 'Kaydediliyor...',
    'success': 'Başarılı',
    'session_created': 'Seans oluşturuldu',
    'leave_marked': 'İzin günü kaydedildi',
    'called_by_boss': 'Patron Çağırdı',
    'overtime_session': 'Ek Mesai',
    'exit_before_entry': 'Çıkış saati giriş saatinden önce olamaz',
    'edit_session': 'Seansı Düzenle',
    'session_edited': 'Seans güncellendi',
    'delete_session': 'Seansı Sil',
    'delete_session_confirm': 'Bu seansı silmek istediğinizden emin misiniz?',
    'session_deleted': 'Seans silindi',
    'deleting': 'Siliniyor...',

    // Leave day
    'on_leave_today': 'Bugün izinlisiniz.',
    'on_sick_leave_today': 'Bugün hastalık iznindesiniz.',
    'cancel_leave_day': 'Bu günün iznini iptal et',

    // Profile (new)
    'remaining_leave_short': 'Kalan İzin',
    'this_month': 'Bu Ay',
    'day_unit': 'gün',

    // Month names (short)
    'month_jan': 'Oca',
    'month_feb': 'Şub',
    'month_mar': 'Mar',
    'month_apr': 'Nis',
    'month_may': 'May',
    'month_jun': 'Haz',
    'month_jul': 'Tem',
    'month_aug': 'Ağu',
    'month_sep': 'Eyl',
    'month_oct': 'Eki',
    'month_nov': 'Kas',
    'month_dec': 'Ara',

    // Day abbreviations
    'day_mon': 'Pzt',
    'day_tue': 'Sal',
    'day_wed': 'Çar',
    'day_thu': 'Per',
    'day_fri': 'Cum',
    'day_sat': 'Cmt',
    'day_sun': 'Paz',

    // Settings
    'first_day_of_week': 'Haftanın İlk Günü',
    'sunday_option': 'Pazar',
    'monday_option': 'Pazartesi',
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'tr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
