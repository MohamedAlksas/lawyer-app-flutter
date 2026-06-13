import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class S {
  final Locale locale;
  S._(this.locale);

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  static Future<S> load(Locale locale) async {
    final code = locale.languageCode;
    final jsonStr = await rootBundle.loadString('assets/i18n/$code.json');
    final map = Map<String, dynamic>.from(jsonDecode(jsonStr));
    return S._(locale).._map = map;
  }

  late Map<String, dynamic> _map;

  String t(String key, [List<String>? args]) {
    var value = _map[key];
    if (value == null) {
      try {
        value = _map[key] ?? key;
      } catch (_) {
        return key;
      }
    }
    var s = value.toString();
    if (args != null) {
      for (var i = 0; i < args.length; i++) {
        s = s.replaceAll('{$i}', args[i]);
      }
    }
    return s;
  }

  String get appTitle => t('appTitle');
  String get login => t('login');
  String get email => t('email');
  String get password => t('password');
  String get loginButton => t('loginButton');
  String get logout => t('logout');
  String get dashboard => t('dashboard');
  String get clients => t('clients');
  String get cases => t('cases');
  String get calendar => t('calendar');
  String get notifications => t('notifications');
  String get settings => t('settings');
  String get users => t('users');
  String get search => t('search');
  String get add => t('add');
  String get edit => t('edit');
  String get delete => t('delete');
  String get save => t('save');
  String get cancel => t('cancel');
  String get confirm => t('confirm');
  String get noData => t('noData');
  String get loading => t('loading');
  String get error => t('error');
  String get success => t('success');
  String get fullName => t('fullName');
  String get fullNameAr => t('fullNameAr');
  String get nationalId => t('nationalId');
  String get phone => t('phone');
  String get alternatePhone => t('alternatePhone');
  String get address => t('address');
  String get notes => t('notes');
  String get caseNumber => t('caseNumber');
  String get caseYear => t('caseYear');
  String get courtName => t('courtName');
  String get circuitNumber => t('circuitNumber');
  String get caseType => t('caseType');
  String get subject => t('subject');
  String get opposingParty => t('opposingParty');
  String get assignedLawyer => t('assignedLawyer');
  String get status => t('status');
  String get filingDate => t('filingDate');
  String get limitationDeadline => t('limitationDeadline');
  String get agreedFee => t('agreedFee');
  String get sessionDate => t('sessionDate');
  String get sessionTime => t('sessionTime');
  String get result => t('result');
  String get nextSessionDate => t('nextSessionDate');
  String get attendedBy => t('attendedBy');
  String get amount => t('amount');
  String get paidAt => t('paidAt');
  String get paymentNote => t('paymentNote');
  String get totalFee => t('totalFee');
  String get totalPaid => t('totalPaid');
  String get remaining => t('remaining');
  String get activeCases => t('activeCases');
  String get todaySessions => t('todaySessions');
  String get upcomingDeadlines => t('upcomingDeadlines');
  String get noSessions => t('noSessions');
  String get clientDetail => t('clientDetail');
  String get caseDetail => t('caseDetail');
  String get linkedCases => t('linkedCases');
  String get financialSummary => t('financialSummary');
  String get sessions => t('sessions');
  String get actions => t('actions');
  String get documents => t('documents');
  String get payments => t('payments');
  String get uploadDocument => t('uploadDocument');
  String get selectFile => t('selectFile');
  String get docCategory => t('docCategory');
  String get poa => t('poa');
  String get memorandum => t('memorandum');
  String get judgment => t('judgment');
  String get appeal => t('appeal');
  String get contract => t('contract');
  String get other => t('other');
  String get civil => t('civil');
  String get criminal => t('criminal');
  String get family => t('family');
  String get commercial => t('commercial');
  String get administrative => t('administrative');
  String get labor => t('labor');
  String get active => t('active');
  String get closed => t('closed');
  String get suspended => t('suspended');
  String get won => t('won');
  String get lost => t('lost');
  String get postponed => t('postponed');
  String get judgmentIssued => t('judgmentIssued');
  String get appealFiled => t('appealFiled');
  String get all => t('all');
  String get language => t('language');
  String get arabic => t('arabic');
  String get english => t('english');
  String get markAsRead => t('markAsRead');
  String get markAllRead => t('markAllRead');
  String get unread => t('unread');
  String get sessionReminder24h => t('sessionReminder24h');
  String get sessionReminder2h => t('sessionReminder2h');
  String get limitationAlert => t('limitationAlert');
  String get offline => t('offline');
  String get online => t('online');
  String get addClient => t('addClient');
  String get addCase => t('addCase');
  String get addSession => t('addSession');
  String get addPayment => t('addPayment');
  String get editClient => t('editClient');
  String get editCase => t('editCase');
  String get caseInfo => t('caseInfo');
  String get sessionResult => t('sessionResult');
  String get noInternet => t('noInternet');
  String get cachedData => t('cachedData');
  String get actionsLog => t('actionsLog');
  String get paymentHistory => t('paymentHistory');
  String get lawyer => t('lawyer');
  String get readOnly => t('readOnly');
  String get admin => t('admin');
  String get addUser => t('addUser');
  String get userManagement => t('userManagement');
  String get isActive => t('isActive');
  String get deactivate => t('deactivate');
  String get activate => t('activate');
  String get upload => t('upload');
  String get checkUpdates => t('checkUpdates');
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<S> load(Locale locale) => S.load(locale);

  @override
  bool shouldReload(_SDelegate old) => false;
}
