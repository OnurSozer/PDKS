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
    'not_clocked_in': 'Not clocked in',
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
