import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ===========================================================================
// APP CONSTANTS + THEME
// ===========================================================================
const String kAppVersion = '1.0.0';
const String kTagline = 'Fast • Simple • Reliable';
const String kDeveloperCredit = 'Developed by SUDATELL';

const String kLogoAsset = 'assets/shazalogo.jpg';
const String kArtAsset = 'assets/shaza.jpg';

// Advertisement banners and service header pictures. These are original,
// non-branded illustrations. Every place that shows one has a fallback, so a
// missing file can never crash the app.
const String kAdAirtimeAsset = 'assets/ads/ad_airtime_data.jpg';
const String kAdUtilityAsset = 'assets/ads/ad_utility_bills.jpg';
const String kAdWalletAsset = 'assets/ads/ad_wallet_security.jpg';
const String kAdDigitalAsset = 'assets/ads/ad_digital_services.jpg';

const Map<String, String> kServiceHeaderAssets = {
  'Education': 'assets/services/service_education.jpg',
  'Electricity': 'assets/services/service_electricity_bill.jpg',
  'Cable TV': 'assets/services/service_cable_tv.jpg',
  'Inverter': 'assets/services/service_inverter_solar.jpg',
};

/// Where an OFFICIAL network logo goes (optional). Add the file and it is used
/// automatically; until then the coloured mark is shown. Examples:
/// assets/networks/network_mtn.png, network_airtel.png, network_glo.png,
/// network_t2mobile.png, network_smile.png
String networkLogoAsset(Network n) => 'assets/networks/network_${n.name}.png';

const fuDark = Color(0xFF0F5B45); // deep green
const fuGreen = Color(0xFF2E8B57); // emerald
const fuAccent = Color(0xFF2FAE6C); // Add Money, highlights
const fuLight = Color(0xFFE8F5E9); // light green
const fuBg = Color(0xFFFDFBF7); // cream
const fuBorder = Color(0xFFDDE7D5);
const fuText = Color(0xFF12372B);
const fuMuted = Color(0xFF6B7F76);
const fuBlue = Color(0xFF2B8CD6);

// Funding account (REAL company bank details: confirm they are correct before
// release. The account name is the registered account holder, so it is kept).
const String kFundingBank = 'OPay';
const String kFundingAccountNumber = '6104123853';
const String kFundingAccountName = 'SUDAWA TECHNOLOGY NIG';

BoxDecoration cardDeco([double r = 16]) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(r),
      border: Border.all(color: fuBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );

String naira(double v) => '₦${v.toStringAsFixed(2)}';

String fmtDate(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}

void openPage(BuildContext context, Widget page) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(tr(message)), behavior: SnackBarBehavior.floating),
    );
}

// ===========================================================================
// LOCALIZATION (merged from translations.dart)
// ===========================================================================

/// Current app language: 'English' or 'Hausa'. Saved on the phone.
final ValueNotifier<String> appLanguage = ValueNotifier<String>('English');
const List<String> kLanguages = ['English', 'Hausa'];

const Map<String, String> kHausa = {
  // Navigation + greetings
  'Home': 'Gida',
  'Profile': 'Bayanina',
  'Settings': 'Saituna',
  'Hello': 'Sannu',
  'Notifications': 'Sanarwa',
  'No new notifications.': 'Babu sabuwar sanarwa.',

  // Services
  'Airtime': 'Katin Waya',
  'Data': 'Data',
  'Electricity': 'Wutar Lantarki',
  'Cable TV': 'Talabijin na Kebul',
  'Wallet Deposit': 'Saka Kuɗi a Wallet',
  'Bills': 'Biyan Kuɗaɗe',
  'Education': 'Ilimi',
  'Bulk SMS': 'Saƙonni Masu Yawa',
  'ePIN': 'ePIN',
  'Contacts': 'Lambobin Waya',
  'Data Card': 'Katin Data',
  'Inverter': 'Inverter',
  'Delivery': 'Isarwa',
  'Support': 'Taimako',
  'History': 'Tarihi',
  'Our Services': 'Ayyukanmu',
  'View All': 'Duba Duka',

  // Wallet
  'Wallet Balance': 'Kuɗin Wallet',
  'Add Money': 'Ƙara Kuɗi',
  'Available': 'Akwai',
  'Total Spend': 'Jimillar Kashewa',
  'Current Balance': 'Kuɗin Yanzu',
  'Funding Bank Account': 'Asusun Banki na Saka Kuɗi',
  'Bank': 'Banki',
  'Account Number': 'Lambar Asusu',
  'Account Name': 'Sunan Asusu',
  'Account number copied.': 'An kwafi lambar asusu.',
  'Insufficient wallet balance.': 'Kuɗin wallet bai isa ba.',
  'Amount': 'Adadi',
  'Enter a valid amount.': 'Shigar da adadi mai kyau.',

  // Transactions / receipt
  'Transaction History': 'Tarihin Mu’amala',
  'No transactions yet.': 'Babu mu’amala tukuna.',
  'Account created': 'An buɗe asusu',
  'Wallet funding': 'Saka kuɗi a wallet',
  'Receipt': 'Rasit',
  'Type': 'Nau’i',
  'Details': 'Bayani',
  'Reference': 'Lambar Bin-diddigi',
  'Date': 'Kwanan Wata',
  'Status': 'Matsayi',
  'Balance After': 'Ragowar Kuɗi',
  'Done': 'An gama',
  'Share Image': 'Aika Hoto',
  'Share PDF': 'Aika PDF',
  'Copy Receipt': 'Kwafi Rasit',
  'Receipt copied to clipboard.': 'An kwafi rasit.',
  'Successful': 'An yi nasara',
  'Pending': 'Ana jira',
  'Failed': 'Ya gaza',
  'Confirm Transaction': 'Tabbatar da Mu’amala',
  'Confirm & Enter PIN': 'Tabbatar & Shigar da PIN',
  'Total': 'Jimilla',
  'Cancel': 'Soke',
  'Confirm': 'Tabbatar',
  'OK': 'To',
  'Add': 'Ƙara',
  'Thank you for using ALSUDAN.': 'Mun gode da amfani da ALSUDAN.',

  // Auth
  'Welcome Back': 'Barka da Dawowa',
  'Create Your Account': 'Buɗe Asusunka',
  'LOGIN': 'SHIGA',
  'REGISTER': 'YI RAJISTA',
  'Login': 'Shiga',
  'Register': 'Yi Rajista',
  "Don't have an account?": 'Ba ka da asusu?',
  'Already have an account?': 'Kana da asusu?',
  'Phone Number or Email': 'Lambar Waya ko Imel',
  'Password': 'Password',
  'Forgot Password / PIN?': 'Ka manta Password / PIN?',
  'Full Name': 'Cikakken Suna',
  'Username': 'Sunan Mai Amfani',
  'Phone Number': 'Lambar Waya',
  'Email Address': 'Adireshin Imel',
  'Address': 'Adireshi',
  'Confirm Password': 'Tabbatar da Password',
  '4-digit Transaction PIN': 'PIN na Mu’amala (lamba 4)',
  'Confirm PIN': 'Tabbatar da PIN',
  'Show passwords': 'Nuna password',
  'Hide passwords': 'Ɓoye password',
  'Required': 'Wajibi ne',
  'At least 8 characters': 'Aƙalla haruffa 8',
  'Use letters and numbers': 'Yi amfani da haruffa da lambobi',
  "Passwords don't match": 'Password ɗin ba iri ɗaya ba ne',
  "PINs don't match": 'PIN ɗin ba iri ɗaya ba ne',
  'PIN must be 4 digits': 'PIN dole ya zama lambobi 4',
  'Choose a PIN that is not easy to guess.':
      'Zaɓi PIN da ba za a iya hasashe cikin sauƙi ba.',
  'Enter a valid email': 'Shigar da imel mai kyau',
  'Enter a valid 11-digit number': 'Shigar da lambar waya mai lambobi 11',
  'This username is already taken.': 'An riga an ɗauki wannan sunan.',
  'Your account has been created successfully!':
      'An buɗe asusunka cikin nasara!',
  'Incorrect phone/email or password.':
      'Lambar waya/imel ko password ba daidai ba ne.',
  'No account found on this device. Please register first.':
      'Babu asusu a wannan wayar. Da fatan ka yi rajista tukuna.',
  'Too many attempts. Try again later.':
      'Ƙoƙari ya yi yawa. Sake gwadawa nan gaba.',
  'Login with fingerprint': 'Shiga da fingerprint',
  'Reset Password / PIN': 'Sake Saita Password / PIN',
  'Logout': 'Fita',
  'LOGOUT': 'FITA',
  'Do you want to logout from ALSUDAN?': 'Kana son fita daga ALSUDAN?',

  // Onboarding
  'Skip': 'Tsallake',
  'Next': 'Gaba',
  'Get Started': 'Fara Yanzu',
  'Your Everyday Services, Made Easy':
      'Ayyukanka na Yau da Kullum, a Sauƙaƙe',
  'Buy airtime and data, pay bills and manage your wallet in one app.':
      'Sayi katin waya da data, biya kuɗaɗe, ka sarrafa wallet ɗinka a app ɗaya.',
  'Simple, Fast Payments': 'Biyan Kuɗi cikin Sauƙi da Sauri',
  'Pick a service, confirm the details and get a receipt you can share.':
      'Zaɓi sabis, tabbatar da bayanai, ka karɓi rasit da za ka iya aikawa.',
  'Protected by PIN and Fingerprint': 'PIN da Fingerprint suna Kare Ka',
  'Every payment is confirmed with your PIN or fingerprint.':
      'Kowane biyan kuɗi ana tabbatar da shi da PIN ko fingerprint.',

  // Banners
  'Welcome to ALSUDAN': 'Barka da zuwa ALSUDAN',
  'Buy Airtime and Data': 'Sayi Katin Waya da Data',
  'Pay Electricity and TV Bills': 'Biya Wutar Lantarki da Talabijin',
  'Wallet and Secure Transactions': 'Wallet da Amintattun Mu’amaloli',
  'Wallet, transaction history, PIN and fingerprint security':
      'Wallet, tarihin mu’amala, PIN da tsaron fingerprint',
  'Digital Services and Offers': 'Ayyukan Dijital da Tayi',
  'Bulk SMS, ePIN, Education and Inverter requests. Offers show here when available.':
      'Bulk SMS, ePIN, Ilimi da buƙatun Inverter. Tayi za su bayyana nan idan akwai.',

  // Services pages
  'Select Network': 'Zaɓi Network',
  'Recipient': 'Mai Karɓa',
  'Select a network.': 'Zaɓi network.',
  'Buy Airtime': 'Sayi Katin Waya',
  'Buy Data': 'Sayi Data',
  'Buy ePIN': 'Sayi ePIN',
  'Data Plan': 'Tsarin Data',
  'Select a data plan.': 'Zaɓi tsarin data.',
  'Choose a network to see its plans.': 'Zaɓi network don ganin tsare-tsarensa.',
  'Enter a valid 11-digit phone number.':
      'Shigar da lambar waya mai lambobi 11.',
  'Provider': 'Mai Bayarwa',
  'Continue': 'Ci gaba',
  'Send SMS': 'Aika SMS',
  'Add Selected': 'Ƙara Waɗanda Aka Zaɓa',
  'Save To Backup': 'Ajiye a Backup',
  'Contacts Backup': 'Backup na Lambobi',
  'Copy Backup': 'Kwafi Backup',
  'Restore': 'Maido',
  'From Backup': 'Daga Backup',
  'Templates': 'Samfura',
  'Message': 'Saƙo',
  'Contact Name': 'Sunan Lamba',
  'No backed-up contacts yet.': 'Babu lambobin da aka yi backup tukuna.',
  'Pick from contacts': 'Zaɓi daga lambobi',

  // PIN + biometrics
  'Create Transaction PIN': 'Ƙirƙiri PIN na Mu’amala',
  'Enter Transaction PIN': 'Shigar da PIN na Mu’amala',
  '4-digit PIN': 'PIN mai lambobi 4',
  'Save PIN': 'Ajiye PIN',
  'PIN must be 4 digits.': 'PIN dole ya zama lambobi 4.',
  'PINs do not match.': 'PIN ɗin ba iri ɗaya ba ne.',
  'Incorrect PIN.': 'PIN ba daidai ba ne.',
  'Use fingerprint': 'Yi amfani da fingerprint',
  'Transaction PIN updated.': 'An sabunta PIN na mu’amala.',
  'Fingerprint authentication failed or was cancelled.':
      'Fingerprint bai yi nasara ba ko an soke shi.',

  // Settings
  'Security': 'Tsaro',
  'Fingerprint Login': 'Shiga da Fingerprint',
  'Use fingerprint on login and to confirm payments':
      'Yi amfani da fingerprint wajen shiga da tabbatar da biyan kuɗi',
  'PIN Security': 'Tsaron PIN',
  'Require your PIN to confirm payments':
      'Buƙaci PIN ɗinka don tabbatar da biyan kuɗi',
  'Transaction PIN': 'PIN na Mu’amala',
  'Create or change your 4-digit PIN.': 'Ƙirƙira ko canza PIN ɗinka mai lambobi 4.',
  'Change or reset your security details.':
      'Canza ko sake saita bayanan tsaronka.',
  'Language': 'Harshe',
  'Notification Preferences': 'Zaɓin Sanarwa',
  'Transaction alerts': 'Sanarwar mu’amala',
  'Show your payments in Notifications': 'Nuna biyan kuɗinka a Sanarwa',
  'Offers and updates': 'Tayi da sabbin labarai',
  'Show ALSUDAN news and offers when available':
      'Nuna labaran ALSUDAN da tayi idan akwai',
  'About': 'Game da Mu',
  'Security & Privacy': 'Tsaro da Sirri',
  'How ALSUDAN protects your account.': 'Yadda ALSUDAN ke kare asusunka.',
  'Customer Support': 'Taimakon Abokan Ciniki',
  'Get help with ALSUDAN services.': 'Samu taimako game da ayyukan ALSUDAN.',
  'Information & Legal': 'Bayani da Doka',
  'About ALSUDAN, privacy and terms.': 'Game da ALSUDAN, sirri da ƙa’idoji.',
  'About ALSUDAN': 'Game da ALSUDAN',
  'App Version': 'Sigar App',
  'Account settings': 'Saitunan asusu',
  'Fingerprint, language and transaction PIN.':
      'Fingerprint, harshe da PIN na mu’amala.',
  'Fingerprint login enabled.': 'An kunna shiga da fingerprint.',
  'Fingerprint login disabled.': 'An kashe shiga da fingerprint.',
  'Fingerprint was not confirmed. Setting unchanged.':
      'Ba a tabbatar da fingerprint ba. Saitin bai canza ba.',
  'No fingerprint is enrolled on this phone. Add one in your phone Settings first.':
      'Babu fingerprint a wannan wayar. Ƙara ɗaya a Settings na waya tukuna.',
  'Fingerprint is not available on this device.':
      'Fingerprint ba ya samuwa a wannan na’urar.',
  'Turn on PIN security first, so your payments stay protected.':
      'Kunna tsaron PIN tukuna, domin biyan kuɗinka su kasance cikin kariya.',
  'Turn on fingerprint first, so your payments stay protected.':
      'Kunna fingerprint tukuna, domin biyan kuɗinka su kasance cikin kariya.',
  'PIN security enabled.': 'An kunna tsaron PIN.',
  'PIN security disabled. Payments will ask for your fingerprint.':
      'An kashe tsaron PIN. Biyan kuɗi zai nemi fingerprint ɗinka.',
  'Fingerprint was not confirmed. Payment cancelled.':
      'Ba a tabbatar da fingerprint ba. An soke biyan kuɗin.',
  'Version': 'Sigar',

  // Support + misc
  'Customer support selected.': 'An zaɓi taimakon abokan ciniki.',
  'WhatsApp Support': 'Taimako ta WhatsApp',
  'Chat with us on WhatsApp.': 'Yi magana da mu a WhatsApp.',
  'WhatsApp link not configured yet.': 'Ba a saita hanyar WhatsApp ba tukuna.',
  'Information': 'Bayani',
  'About ALSUDAN & legal terms.': 'Game da ALSUDAN da ƙa’idojin doka.',
  'Contact Us': 'Tuntuɓe Mu',
  'Send a message to ALSUDAN support.': 'Aika saƙo ga taimakon ALSUDAN.',
  'Contact support selected.': 'An zaɓi tuntuɓar taimako.',
  'Developed by SUDATELL': 'SUDATELL ne ya ƙirƙira',
};

/// Translate [key] into the current language. Unknown text is shown as-is.
String tr(String key) {
  if (appLanguage.value == 'Hausa') {
    return kHausa[key] ?? key;
  }
  return key;
}

/// A Text widget that shows the translated text.
class TrText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const TrText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      tr(text),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Marks every widget dirty so all screens re-run their build methods (and
/// therefore re-translate) without losing navigation or state.
void _rebuildAllElements() {
  final root = WidgetsBinding.instance.rootElement;
  if (root == null) return;
  void rebuild(Element el) {
    el.markNeedsBuild();
    el.visitChildren(rebuild);
  }

  root.visitChildren(rebuild);
}

Future<void> setAppLanguage(String lang) async {
  if (!kLanguages.contains(lang)) return;
  appLanguage.value = lang;
  _rebuildAllElements();
  await AppStore.setString('lang', lang);
}

// ===========================================================================
// PERSISTENT STORAGE (settings in SharedPreferences, secrets in secure storage)
// ===========================================================================
final ValueNotifier<bool> biometricEnabled = ValueNotifier<bool>(false);
final ValueNotifier<bool> pinEnabled = ValueNotifier<bool>(true);
final ValueNotifier<bool> notifTxn = ValueNotifier<bool>(true);
final ValueNotifier<bool> notifPromo = ValueNotifier<bool>(true);
final ValueNotifier<int> notifSeen = ValueNotifier<int>(1);

class AppStore {
  static SharedPreferences? _prefs;
  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      debugPrint('Preferences are unavailable.');
    }
  }

  static bool getBool(String key, bool def) => _prefs?.getBool(key) ?? def;
  static String? getString(String key) => _prefs?.getString(key);

  static Future<void> setBool(String key, bool value) async {
    try {
      await _prefs?.setBool(key, value);
    } catch (_) {
      debugPrint('Could not save a setting.');
    }
  }

  static Future<void> setString(String key, String value) async {
    try {
      await _prefs?.setString(key, value);
    } catch (_) {
      debugPrint('Could not save a setting.');
    }
  }

  static Future<String?> readSecure(String key) async {
    try {
      return await _secure.read(key: key);
    } catch (_) {
      return null;
    }
  }

  static Future<void> writeSecure(String key, String value) async {
    try {
      await _secure.write(key: key, value: value);
    } catch (_) {
      debugPrint('Could not save to secure storage.');
    }
  }
}

/// Loads every saved setting before the first screen is drawn.
Future<void> bootstrapApp() async {
  await AppStore.init();
  final lang = AppStore.getString('lang');
  if (lang != null && kLanguages.contains(lang)) appLanguage.value = lang;
  biometricEnabled.value = AppStore.getBool('bio_enabled', false);
  pinEnabled.value = AppStore.getBool('pin_enabled', true);
  notifTxn.value = AppStore.getBool('notif_txn', true);
  notifPromo.value = AppStore.getBool('notif_promo', true);
  await PinService.load();
  await AccountStore.load();
}

// ===========================================================================
// NETWORKS + PHONE HELPERS
// ===========================================================================
enum Network { mtn, airtel, glo, t2mobile, smile }

extension NetworkInfo on Network {
  String get label => const {
        Network.mtn: 'MTN',
        Network.airtel: 'Airtel',
        Network.glo: 'Glo',
        Network.t2mobile: 'T2mobile',
        Network.smile: 'Smile',
      }[this]!;

  String get mark => const {
        Network.mtn: 'MTN',
        Network.airtel: 'airtel',
        Network.glo: 'glo',
        Network.t2mobile: 'T2',
        Network.smile: 'smile',
      }[this]!;

  Color get color => const {
        Network.mtn: Color(0xFFFFCC00),
        Network.airtel: Color(0xFFE40000),
        Network.glo: Color(0xFF00A650),
        Network.t2mobile: Color(0xFF00796B),
        Network.smile: Color(0xFFA6CE39),
      }[this]!;

  Color get onColor => (this == Network.mtn || this == Network.smile)
      ? Colors.black
      : Colors.white;
}

const Map<Network, List<String>> _prefixes = {
  Network.mtn: [
    '0803', '0806', '0810', '0813', '0814', '0816', '0703', '0706', '0704',
    '0903', '0906', '0913', '0916'
  ],
  Network.airtel: [
    '0802', '0808', '0812', '0701', '0708', '0901', '0902', '0904', '0907',
    '0912'
  ],
  Network.glo: ['0805', '0807', '0811', '0815', '0705', '0905', '0915'],
  Network.t2mobile: ['0809', '0817', '0818', '0908', '0909'],
  Network.smile: ['0702'],
};

/// Only a HINT: numbers can be ported between networks, so the user must
/// always confirm the network manually.
Network? detectNetwork(String phone) {
  if (phone.length < 4) return null;
  final p = phone.substring(0, 4);
  for (final e in _prefixes.entries) {
    if (e.value.contains(p)) return e.key;
  }
  return null;
}

String cleanPhone(String raw) {
  var p = raw.replaceAll(RegExp(r'[^\d+]'), '');
  if (p.startsWith('+234')) {
    p = '0${p.substring(4)}';
  } else if (p.startsWith('234') && p.length == 13) {
    p = '0${p.substring(3)}';
  }
  return p;
}

bool isValidNgPhone(String p) => RegExp(r'^0[789][01]\d{8}$').hasMatch(p);

// ===========================================================================
// TRANSACTIONS, WALLET, PROVIDER
// ===========================================================================
enum TxStatus { success, demo, pending, failed }

extension TxStatusInfo on TxStatus {
  String get label => const {
        TxStatus.success: 'Successful',
        TxStatus.demo: 'Demo (not sent)',
        TxStatus.pending: 'Pending',
        TxStatus.failed: 'Failed',
      }[this]!;

  Color get color => const {
        TxStatus.success: fuAccent,
        TxStatus.demo: Color(0xFFE58E1A),
        TxStatus.pending: Color(0xFFE58E1A),
        TxStatus.failed: Colors.redAccent,
      }[this]!;

  /// Only these statuses actually move wallet money.
  bool get movedMoney => this == TxStatus.success || this == TxStatus.demo;
}

class WalletTransaction {
  final String title;
  final double amount; // negative = debit, positive = credit
  final DateTime date;
  final String reference;
  final String note;
  final double? balanceAfter;
  final TxStatus status;

  WalletTransaction(
    this.title,
    this.amount,
    this.date, {
    this.reference = '',
    this.note = '',
    this.balanceAfter,
    this.status = TxStatus.success,
  });
}

// NOTE: the wallet balance and history are DEMO values kept in memory. Real
// balances must come from your backend / payment provider.
final ValueNotifier<double> walletBalance = ValueNotifier<double>(950.00);

final ValueNotifier<List<WalletTransaction>> transactionsNotifier =
    ValueNotifier<List<WalletTransaction>>([
  WalletTransaction('Account created', 0, DateTime.now()),
]);

int _refCounter = 0;
String newReference() {
  _refCounter++;
  final ms = DateTime.now().millisecondsSinceEpoch.toString();
  return 'FUE${ms.substring(ms.length - 8)}${_refCounter.toString().padLeft(2, '0')}';
}

class TxRequest {
  final String title;
  final double amount;
  final String reference;
  final List<MapEntry<String, String>> lines;
  final String note;
  final Network? network;
  final String? recipient;

  TxRequest({
    required this.title,
    required this.amount,
    required this.reference,
    required this.lines,
    this.note = '',
    this.network,
    this.recipient,
  });
}

class ProviderResult {
  final TxStatus status;
  final String message;
  final String? providerRef;
  const ProviderResult(this.status, this.message, {this.providerRef});
}

/// Plug your REAL provider in here. Call your own backend (never put provider
/// keys or tokens inside the app) and return success / pending / failed
/// honestly. A purchase must only be reported as success after the backend or
/// provider has confirmed it.
abstract class VtuProvider {
  bool get isLive;
  Future<ProviderResult> purchase(TxRequest request);
}

class DemoProvider implements VtuProvider {
  @override
  bool get isLive => false;

  @override
  Future<ProviderResult> purchase(TxRequest request) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return const ProviderResult(
      TxStatus.demo,
      'Demo transaction: no real purchase was made.',
    );
  }
}

VtuProvider vtuProvider = DemoProvider();

// ===========================================================================
// ACCOUNT (stored on this phone in secure storage; replace with your backend)
// ===========================================================================
class UserProfileData {
  String fullName;
  String username;
  String phone;
  String email;
  String address;

  UserProfileData({
    required this.fullName,
    required this.username,
    required this.phone,
    required this.email,
    required this.address,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'username': username,
        'phone': phone,
        'email': email,
        'address': address,
      };

  factory UserProfileData.fromJson(Map<String, dynamic> m) => UserProfileData(
        fullName: (m['fullName'] ?? '') as String,
        username: (m['username'] ?? '') as String,
        phone: (m['phone'] ?? '') as String,
        email: (m['email'] ?? '') as String,
        address: (m['address'] ?? '') as String,
      );
}

class AccountStore {
  static UserProfileData? profile;
  static String? _pwSalt;
  static String? _pwHash;
  static int _fails = 0;
  static DateTime? _lockUntil;

  static bool get exists => profile != null && _pwHash != null && _pwSalt != null;

  static Future<void> load() async {
    final raw = await AppStore.readSecure('account');
    if (raw == null) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      profile = UserProfileData.fromJson(m['p'] as Map<String, dynamic>);
      _pwSalt = m['s'] as String;
      _pwHash = m['h'] as String;
    } catch (_) {
      profile = null;
      _pwSalt = null;
      _pwHash = null;
    }
  }

  static Future<void> save(UserProfileData p, String password) async {
    profile = p;
    _pwSalt = PinService.randomSalt();
    _pwHash = PinService.digest(_pwSalt!, password);
    _fails = 0;
    _lockUntil = null;
    await AppStore.writeSecure(
      'account',
      jsonEncode({'p': p.toJson(), 's': _pwSalt, 'h': _pwHash}),
    );
  }

  static Duration? get lockRemaining {
    final until = _lockUntil;
    if (until == null) return null;
    final d = until.difference(DateTime.now());
    if (d.isNegative) {
      _lockUntil = null;
      _fails = 0;
      return null;
    }
    return d;
  }

  static bool _idMatches(String id) {
    final p = profile;
    if (p == null) return false;
    final t = id.trim();
    if (t.contains('@')) return t.toLowerCase() == p.email.toLowerCase();
    return cleanPhone(t) == p.phone;
  }

  /// Checks the phone/email and password. Counts failures and locks briefly.
  static bool verifyLogin(String id, String password) {
    if (!exists || lockRemaining != null) return false;
    final okId = _idMatches(id);
    final okPw = PinService.safeEquals(
      PinService.digest(_pwSalt!, password),
      _pwHash!,
    );
    if (okId && okPw) {
      _fails = 0;
      return true;
    }
    _fails++;
    if (_fails >= 5) {
      _fails = 0;
      _lockUntil = DateTime.now().add(const Duration(seconds: 30));
    }
    return false;
  }
}

// ===========================================================================
// TRANSACTION PIN (salted + stretched hash, kept in secure storage)
// ===========================================================================
class PinService {
  static String? _salt;
  static String? _hash;
  static int _fails = 0;
  static int _lockRounds = 0;
  static DateTime? _lockUntil;

  static bool get isSet => _hash != null && _salt != null;

  static Future<void> load() async {
    _salt = await AppStore.readSecure('pin_salt');
    _hash = await AppStore.readSecure('pin_hash');
    _fails = int.tryParse(await AppStore.readSecure('pin_fails') ?? '') ?? 0;
    _lockRounds =
        int.tryParse(await AppStore.readSecure('pin_rounds') ?? '') ?? 0;
    final ms = int.tryParse(await AppStore.readSecure('pin_lock') ?? '');
    _lockUntil = ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
    if (_salt == null || _hash == null) {
      _salt = null;
      _hash = null;
    }
  }

  static String randomSalt() {
    final rnd = Random.secure();
    return base64UrlEncode(List<int>.generate(16, (_) => rnd.nextInt(256)));
  }

  /// Salted hash that is repeated many times to slow down guessing.
  static String digest(String salt, String secret) {
    final saltBytes = utf8.encode(salt);
    var bytes = utf8.encode('$salt:$secret');
    for (var i = 0; i < 6000; i++) {
      bytes = Uint8List.fromList(
        sha256.convert([...bytes, ...saltBytes]).bytes,
      );
    }
    return base64UrlEncode(bytes);
  }

  static bool safeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  static void _persistCounters() {
    unawaited(AppStore.writeSecure('pin_fails', '$_fails'));
    unawaited(AppStore.writeSecure('pin_rounds', '$_lockRounds'));
    unawaited(AppStore.writeSecure(
      'pin_lock',
      _lockUntil == null ? '' : '${_lockUntil!.millisecondsSinceEpoch}',
    ));
  }

  static Future<void> set(String pin) async {
    _salt = randomSalt();
    _hash = digest(_salt!, pin);
    _fails = 0;
    _lockRounds = 0;
    _lockUntil = null;
    await AppStore.writeSecure('pin_salt', _salt!);
    await AppStore.writeSecure('pin_hash', _hash!);
    _persistCounters();
  }

  static Duration? get lockRemaining {
    final until = _lockUntil;
    if (until == null) return null;
    final d = until.difference(DateTime.now());
    if (d.isNegative) {
      _lockUntil = null;
      _fails = 0;
      _persistCounters();
      return null;
    }
    return d;
  }

  static bool verify(String pin) {
    if (lockRemaining != null || !isSet) return false;
    if (safeEquals(digest(_salt!, pin), _hash!)) {
      if (_fails != 0 || _lockRounds != 0 || _lockUntil != null) {
        _fails = 0;
        _lockRounds = 0;
        _lockUntil = null;
        _persistCounters();
      }
      return true;
    }
    _fails++;
    if (_fails >= 5) {
      _fails = 0;
      final secs = min(30 * (1 << _lockRounds), 600);
      _lockRounds = min(_lockRounds + 1, 5);
      _lockUntil = DateTime.now().add(Duration(seconds: secs));
    }
    _persistCounters();
    return false;
  }
}

bool isWeakPin(String p) {
  if (p.length != 4) return true;
  if (RegExp(r'^(\d)\1{3}$').hasMatch(p)) return true;
  const weak = {
    '1234', '4321', '0123', '3210', '2345', '5432', '3456', '6543', '4567',
    '7654', '5678', '8765', '6789', '9876', '1212', '2580', '1122'
  };
  return weak.contains(p);
}

String? passwordProblem(String? v) {
  if (v == null || v.isEmpty) return tr('Required');
  if (v.length < 8) return tr('At least 8 characters');
  if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
    return tr('Use letters and numbers');
  }
  return null;
}

// ===========================================================================
// FINGERPRINT (handled by Android; ALSUDAN never sees or stores fingerprints)
// ===========================================================================
enum BioStatus { ok, noHardware, notEnrolled, error }

class BiometricHelper {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<BioStatus> status() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final can = await _auth.canCheckBiometrics;
      if (!supported && !can) return BioStatus.noHardware;
      final types = await _auth.getAvailableBiometrics();
      return types.isEmpty ? BioStatus.notEnrolled : BioStatus.ok;
    } on PlatformException {
      return BioStatus.error;
    } catch (_) {
      return BioStatus.error;
    }
  }

  /// Returns true ONLY when Android confirms the fingerprint.
  static Future<bool> authenticate({
    String reason = 'Authenticate using your fingerprint',
  }) async {
    try {
      if (await status() != BioStatus.ok) return false;
      return await _auth.authenticate(
        localizedReason: reason,
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Biometric Authentication',
            biometricHint: 'Place your finger on the sensor',
            cancelButton: 'Cancel',
          ),
        ],
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }
}

Future<bool> showCreatePinDialog(BuildContext context) async {
  final a = TextEditingController();
  final b = TextEditingController();
  String? error;
  final r = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: const TrText('Create Transaction PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: a,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: tr('4-digit PIN')),
            ),
            TextField(
              controller: b,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: tr('Confirm PIN'),
                errorText: error == null ? null : tr(error!),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const TrText('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (a.text.length != 4) {
                setS(() => error = 'PIN must be 4 digits.');
              } else if (isWeakPin(a.text)) {
                setS(() => error = 'Choose a PIN that is not easy to guess.');
              } else if (a.text != b.text) {
                setS(() => error = 'PINs do not match.');
              } else {
                await PinService.set(a.text);
                if (ctx.mounted) Navigator.pop(ctx, true);
              }
            },
            child: const TrText('Save PIN'),
          ),
        ],
      ),
    ),
  );
  a.dispose();
  b.dispose();
  return r == true;
}

class _PinDialog extends StatefulWidget {
  const _PinDialog();

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final ctrl = TextEditingController();
  String? error;

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final lock = PinService.lockRemaining;
    if (lock != null) {
      setState(() => error =
          '${tr('Too many attempts. Try again later.')} (${lock.inSeconds}s)');
      return;
    }
    if (PinService.verify(ctrl.text)) {
      Navigator.pop(context, true);
    } else {
      ctrl.clear();
      final l = PinService.lockRemaining;
      setState(() => error = l != null
          ? '${tr('Too many attempts. Try again later.')} (${l.inSeconds}s)'
          : tr('Incorrect PIN.'));
    }
  }

  Future<void> _bio() async {
    final ok = await BiometricHelper.authenticate(
      reason: 'Confirm with your fingerprint',
    );
    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const TrText('Enter Transaction PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: ctrl,
            autofocus: true,
            obscureText: true,
            maxLength: 4,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 12),
            decoration: InputDecoration(errorText: error, counterText: ''),
            onChanged: (v) {
              if (v.length == 4) _submit();
            },
          ),
          if (biometricEnabled.value)
            TextButton.icon(
              onPressed: _bio,
              icon: const Icon(Icons.fingerprint, color: fuGreen),
              label: const TrText('Use fingerprint'),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const TrText('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const TrText('Confirm')),
      ],
    );
  }
}

/// Asks for the PIN (creating one first if none exists yet).
Future<bool> requestPin(BuildContext context) async {
  if (!PinService.isSet) {
    final created = await showCreatePinDialog(context);
    if (!created || !context.mounted) return false;
  }
  return verifyExistingPin(context);
}

/// Asks for the existing PIN only (never creates one).
Future<bool> verifyExistingPin(BuildContext context) async {
  final r = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _PinDialog(),
  );
  return r == true;
}

/// Transaction authorization: PIN (with optional fingerprint alternative) or,
/// when PIN security is switched off, the fingerprint. At least one of them is
/// always enforced.
Future<bool> authorizeTransaction(BuildContext context) async {
  if (pinEnabled.value) return requestPin(context);
  if (biometricEnabled.value) {
    final ok = await BiometricHelper.authenticate(
      reason: 'Confirm this payment with your fingerprint',
    );
    if (!ok && context.mounted) {
      showMessage(context, 'Fingerprint was not confirmed. Payment cancelled.');
    }
    return ok;
  }
  return requestPin(context);
}

// ===========================================================================
// TRANSACTION FLOW: validate > confirm > PIN > provider > record > receipt
// ===========================================================================
bool _txBusy = false;
final Set<String> _usedRefs = <String>{};

Future<bool?> _showConfirmSheet(BuildContext context, TxRequest req) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TrText(
              'Confirm Transaction',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: fuDark,
              ),
            ),
            const Divider(height: 24),
            for (final l in req.lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TrText(l.key, style: const TextStyle(color: fuMuted)),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        l.value,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const TrText('Total', style: TextStyle(color: fuMuted)),
                Text(
                  naira(req.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: fuDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${tr('Wallet Balance')}: ${naira(walletBalance.value)}',
              style: const TextStyle(color: fuMuted, fontSize: 12),
            ),
            if (!vtuProvider.isLive) ...[
              const SizedBox(height: 10),
              const InfoBanner(
                'Demo mode: no provider is connected, so nothing real will be delivered.',
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const TrText('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    text: 'Confirm & Enter PIN',
                    onPressed: () => Navigator.pop(ctx, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _statusDialog(BuildContext context, String title, String msg) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(tr(title)),
      content: Text(tr(msg)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const TrText('OK')),
      ],
    ),
  );
}

/// Returns true only when money actually moved (success or demo).
Future<bool> runTransaction(BuildContext context, TxRequest req) async {
  if (_txBusy) {
    showMessage(context, 'Another transaction is in progress.');
    return false;
  }
  if (_usedRefs.contains(req.reference)) {
    showMessage(context, 'This transaction was already submitted.');
    return false;
  }
  _txBusy = true;
  try {
    if (req.amount <= 0) {
      showMessage(context, 'Invalid amount.');
      return false;
    }
    if (req.amount > walletBalance.value) {
      showMessage(context, 'Insufficient wallet balance.');
      return false;
    }

    final confirmed = await _showConfirmSheet(context, req);
    if (confirmed != true || !context.mounted) return false;

    final authed = await authorizeTransaction(context);
    if (!authed || !context.mounted) return false;

    if (req.amount > walletBalance.value) {
      showMessage(context, 'Insufficient wallet balance.');
      return false;
    }

    _usedRefs.add(req.reference);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator(color: fuAccent)),
      ),
    );

    ProviderResult res;
    try {
      res = await vtuProvider
          .purchase(req)
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      res = const ProviderResult(
        TxStatus.pending,
        'No confirmation was received. Your wallet was NOT debited. Check History before trying again.',
      );
    } catch (_) {
      res = const ProviderResult(
        TxStatus.failed,
        'The request could not be completed. Your wallet was NOT debited.',
      );
    }

    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

    final moved = res.status.movedMoney;
    if (moved) walletBalance.value -= req.amount;

    final txn = WalletTransaction(
      req.title,
      -req.amount,
      DateTime.now(),
      reference: req.reference,
      note: req.note,
      balanceAfter: walletBalance.value,
      status: res.status,
    );
    transactionsNotifier.value = [txn, ...transactionsNotifier.value];

    if (!context.mounted) return moved;
    if (moved) {
      openPage(context, ReceiptPage(transaction: txn));
    } else {
      await _statusDialog(
        context,
        res.status == TxStatus.pending ? 'Pending' : 'Failed',
        res.message,
      );
    }
    return moved;
  } finally {
    _txBusy = false;
  }
}

/// Test funding (demo credit). Replace with a real payment confirmation.
void performAddMoney(BuildContext context, double amount) {
  if (amount <= 0) {
    showMessage(context, 'Enter a valid amount.');
    return;
  }
  walletBalance.value += amount;
  final txn = WalletTransaction(
    'Wallet funding',
    amount,
    DateTime.now(),
    reference: newReference(),
    balanceAfter: walletBalance.value,
    status: TxStatus.demo,
  );
  transactionsNotifier.value = [txn, ...transactionsNotifier.value];
  openPage(context, ReceiptPage(transaction: txn));
}

// ===========================================================================
// CONTACTS (picker + backup)
// ===========================================================================
final FlutterNativeContactPicker _contactPicker = FlutterNativeContactPicker();

class BackupContact {
  final String name;
  final String phone;
  BackupContact(this.name, this.phone);
}

final ValueNotifier<List<BackupContact>> contactBackup =
    ValueNotifier<List<BackupContact>>([]);

bool saveContactToBackup(String name, String phone) {
  final p = phone.trim();
  if (p.isEmpty || contactBackup.value.any((c) => c.phone == p)) return false;
  contactBackup.value = [
    ...contactBackup.value,
    BackupContact(name.trim().isEmpty ? p : name.trim(), p),
  ];
  return true;
}

/// Opens the phone's contact picker and returns a cleaned number (or null).
Future<String?> pickPhone(BuildContext context) async {
  try {
    final c = await _contactPicker.selectContact();
    if (c == null) return null; // cancelled
    final nums = (c.phoneNumbers ?? <String>[])
        .map(cleanPhone)
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    if (nums.isEmpty) {
      if (context.mounted) showMessage(context, 'This contact has no phone number.');
      return null;
    }
    var phone = nums.first;
    if (nums.length > 1 && context.mounted) {
      final chosen = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Choose a number'),
          children: [
            for (final n in nums)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, n),
                child: Text(n),
              ),
          ],
        ),
      );
      if (chosen == null) return null;
      phone = chosen;
    }
    saveContactToBackup(c.fullName ?? '', phone);
    return phone;
  } on PlatformException {
    if (context.mounted) {
      showMessage(context, 'Contacts are unavailable or permission was denied.');
    }
    return null;
  } catch (_) {
    if (context.mounted) showMessage(context, 'Could not open contacts.');
    return null;
  }
}

Widget phoneField(
  BuildContext context,
  TextEditingController ctrl, {
  ValueChanged<String>? onChanged,
  String label = 'Phone Number',
}) {
  return TextField(
    controller: ctrl,
    keyboardType: TextInputType.phone,
    onChanged: onChanged,
    decoration: InputDecoration(
      labelText: tr(label),
      prefixIcon: const Icon(Icons.phone_android),
      suffixIcon: IconButton(
        tooltip: tr('Pick from contacts'),
        icon: const Icon(Icons.contacts_outlined, color: fuGreen),
        onPressed: () async {
          final p = await pickPhone(context);
          if (p != null) {
            ctrl.text = p;
            onChanged?.call(p);
          }
        },
      ),
    ),
  );
}

// ===========================================================================
// SHARED WIDGETS
// ===========================================================================

/// Painted two-leaf mark, used when the logo image is missing.
class _LeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()..color = Colors.white;
    final left = Path()
      ..moveTo(w * 0.50, h * 0.90)
      ..quadraticBezierTo(w * 0.05, h * 0.78, w * 0.12, h * 0.22)
      ..quadraticBezierTo(w * 0.52, h * 0.30, w * 0.50, h * 0.90)
      ..close();
    final right = Path()
      ..moveTo(w * 0.54, h * 0.90)
      ..quadraticBezierTo(w * 0.50, h * 0.28, w * 0.92, h * 0.08)
      ..quadraticBezierTo(w * 1.02, h * 0.70, w * 0.54, h * 0.90)
      ..close();
    canvas.drawPath(left, fill);
    canvas.drawPath(right, fill);
    final vein = Paint()
      ..color = fuDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.52, h * 0.82), Offset(w * 0.80, h * 0.22), vein);
    canvas.drawLine(Offset(w * 0.46, h * 0.76), Offset(w * 0.24, h * 0.38), vein);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ALSUDAN logo: uses assets/shazalogo.jpg and falls back to the painted mark if
/// the file is missing.
class FuLogo extends StatelessWidget {
  final double size;
  const FuLogo({super.key, this.size = 64});

  Widget _fallback() => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: fuDark),
        child: SizedBox(
          width: size * 0.56,
          height: size * 0.56,
          child: CustomPaint(painter: _LeafPainter()),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          kLogoAsset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      ),
    );
  }
}

class FuWordmark extends StatelessWidget {
  final double size;
  final Color color;
  const FuWordmark({super.key, this.size = 28, this.color = fuDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      'ALSUDAN',
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: size * 0.04,
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: fuDark,
          foregroundColor: Colors.white,
          disabledBackgroundColor: fuDark.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : TrText(text, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class InfoBanner extends StatelessWidget {
  final String text;
  const InfoBanner(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4DD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF0C877)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFFB36B00)),
          const SizedBox(width: 8),
          Expanded(
            child: TrText(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF7A4A00)),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: TrText(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: fuText,
          ),
        ),
      );
}

class SimpleServicePage extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const SimpleServicePage({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: TrText(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: fuAccent.withOpacity(0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: fuGreen),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TrText(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: fuText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const ServiceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: cardDeco(),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: fuGreen),
        title: TrText(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: TrText(subtitle, style: const TextStyle(color: fuMuted)),
        trailing: const Icon(Icons.chevron_right, color: fuMuted),
      ),
    );
  }
}

class NetworkLogo extends StatelessWidget {
  final Network network;
  final double size;
  const NetworkLogo(this.network, {super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    // Brand-coloured mark, shown until an official logo file is added at
    // assets/networks/network_<name>.png (see networkLogoAsset).
    final mark = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: network.color, shape: BoxShape.circle),
      child: FittedBox(
        child: Text(
          network.mark,
          style: TextStyle(
            color: network.onColor,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.3,
          ),
        ),
      ),
    );
    return ClipOval(
      child: Image.asset(
        networkLogoAsset(network),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => mark,
      ),
    );
  }
}

class NetworkSelector extends StatelessWidget {
  final List<Network>? options;
  final Network? selected;
  final ValueChanged<Network> onSelected;

  const NetworkSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    this.options,
  });

  @override
  Widget build(BuildContext context) {
    final list = options ?? Network.values;
    return Row(
      children: [
        for (final n in list)
          Expanded(
            child: GestureDetector(
              onTap: () => onSelected(n),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected == n ? fuAccent.withOpacity(0.12) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected == n ? fuAccent : fuBorder,
                    width: selected == n ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        NetworkLogo(n, size: 40),
                        if (selected == n)
                          const Positioned(
                            right: -4,
                            top: -4,
                            child: Icon(Icons.check_circle, size: 16, color: fuAccent),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      n.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: selected == n ? FontWeight.w900 : FontWeight.w600,
                        color: fuText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Widget networkHint(
  String rawPhone,
  Network? current,
  ValueChanged<Network> onUse,
) {
  final d = detectNetwork(cleanPhone(rawPhone));
  if (d == null || d == current) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Align(
      alignment: Alignment.centerLeft,
      child: ActionChip(
        avatar: NetworkLogo(d, size: 20),
        label: Text('Looks like ${d.label}. Tap to use (ported numbers may differ)'),
        onPressed: () => onUse(d),
      ),
    ),
  );
}

// ===========================================================================
// APP + SESSION
// ===========================================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await bootstrapApp();
  } catch (_) {
    debugPrint('Start-up settings could not be loaded; using defaults.');
  }
  runApp(const AlsudanApp());
}

class AlsudanApp extends StatefulWidget {
  const AlsudanApp({super.key});

  @override
  State<AlsudanApp> createState() => _AlsudanAppState();
}

class _AlsudanAppState extends State<AlsudanApp> with WidgetsBindingObserver {
  bool splashDone = false;
  bool onboarded = AppStore.getBool('onboarded', false);
  bool loggedIn = false;
  bool showRegister = false;
  DateTime? _pausedAt;

  UserProfileData user = AccountStore.profile ??
      UserProfileData(
        fullName: 'ALSUDAN User',
        username: 'alsudan_user',
        phone: '08000000000',
        email: 'user@example.com',
        address: 'Kano, Nigeria',
      );

  final List<String> registered = ['admin', 'alsudan', 'user1'];

  bool registerUser(UserProfileData u) {
    final name = u.username.toLowerCase();
    if (registered.contains(name)) return false;
    registered.add(name);
    return true;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Safe session: if the app stays in the background for 5 minutes, the
  /// session ends and the user must log in again.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final p = _pausedAt;
      _pausedAt = null;
      if (loggedIn && p != null &&
          DateTime.now().difference(p) > const Duration(minutes: 5)) {
        setState(() => loggedIn = false);
      }
    }
  }

  void _logout() => setState(() => loggedIn = false);

  @override
  Widget build(BuildContext context) {
    final OutlineInputBorder base = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: fuBorder),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ALSUDAN',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: fuBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: fuGreen,
          primary: fuDark,
          surface: fuBg,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: fuText,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: base,
          enabledBorder: base,
          focusedBorder: base.copyWith(
            borderSide: const BorderSide(color: fuAccent, width: 1.6),
          ),
          errorBorder: base.copyWith(
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: base.copyWith(
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: fuAccent.withOpacity(0.15),
        ),
      ),
      home: !splashDone
          ? SplashPage(onDone: () => setState(() => splashDone = true))
          : !onboarded
              ? OnboardingPage(onDone: () {
                  AppStore.setBool('onboarded', true);
                  setState(() => onboarded = true);
                })
              : loggedIn
                  ? MainNavigation(user: user, onLogout: _logout)
                  : showRegister
                      ? RegisterPage(
                          onBack: () => setState(() => showRegister = false),
                          onCheckAndRegister: registerUser,
                          onRegistered: (u) => setState(() {
                            user = u;
                            loggedIn = true;
                            showRegister = false;
                          }),
                        )
                      : LoginPage(
                          onLogin: (u) => setState(() {
                            user = u;
                            loggedIn = true;
                          }),
                          onCreateAccount: () =>
                              setState(() => showRegister = true),
                        ),
    );
  }
}

class SplashPage extends StatefulWidget {
  final VoidCallback onDone;
  const SplashPage({super.key, required this.onDone});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(const Duration(milliseconds: 2200), widget.onDone);
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD7EBC2), Color(0xFF7DBB5C), Color(0xFF2F7D32)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              left: -40,
              child: Icon(Icons.park_rounded, size: 280, color: Colors.white.withOpacity(0.18)),
            ),
            Positioned(
              bottom: 90,
              right: -30,
              child: Icon(Icons.grass_rounded, size: 200, color: Colors.white.withOpacity(0.15)),
            ),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  const FuLogo(size: 120),
                  const SizedBox(height: 12),
                  const FuWordmark(size: 54),
                  const SizedBox(height: 6),
                  const Text(
                    kTagline,
                    style: TextStyle(color: fuDark, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(flex: 4),
                  const TrText(
                    'Your Everyday Services, Made Easy',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 20, height: 1.3),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 6; i++)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == 0 ? fuAccent : Colors.white,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TrText(
                    kDeveloperCredit,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// ONBOARDING (shown once, uses assets/shaza.jpg on the first page)
// ===========================================================================
class _Slide {
  final String title;
  final String body;
  final IconData icon;
  final bool art;
  const _Slide(this.title, this.body, this.icon, {this.art = false});
}

class OnboardingPage extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingPage({super.key, required this.onDone});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pc = PageController();
  int _i = 0;

  static const List<_Slide> _slides = [
    _Slide(
      'Your Everyday Services, Made Easy',
      'Buy airtime and data, pay bills and manage your wallet in one app.',
      Icons.apps_rounded,
      art: true,
    ),
    _Slide(
      'Simple, Fast Payments',
      'Pick a service, confirm the details and get a receipt you can share.',
      Icons.bolt_rounded,
    ),
    _Slide(
      'Protected by PIN and Fingerprint',
      'Every payment is confirmed with your PIN or fingerprint.',
      Icons.verified_user_rounded,
    ),
  ];

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    if (_i >= _slides.length - 1) {
      widget.onDone();
    } else {
      _pc.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _art(_Slide s) {
    final fallback = Container(
      decoration: BoxDecoration(
        color: fuLight,
        borderRadius: BorderRadius.circular(28),
      ),
      alignment: Alignment.center,
      child: Icon(s.icon, size: 96, color: fuGreen),
    );
    if (!s.art) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Image.asset(
        kArtAsset,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final last = _i == _slides.length - 1;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [fuBg, fuLight],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onDone,
                  child: const TrText('Skip', style: TextStyle(color: fuGreen)),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pc,
                  itemCount: _slides.length,
                  onPageChanged: (v) => setState(() => _i = v),
                  itemBuilder: (_, i) {
                    final s = _slides[i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                      child: Column(
                        children: [
                          Expanded(child: _art(s)),
                          const SizedBox(height: 22),
                          TrText(
                            s.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: fuDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TrText(
                            s.body,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: fuMuted, height: 1.4),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: i == _i ? 22 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: i == _i ? fuGreen : fuBorder,
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                child: PrimaryButton(
                  text: last ? 'Get Started' : 'Next',
                  onPressed: _next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthShell extends StatelessWidget {
  final Widget child;
  final VoidCallback? onBack;
  const _AuthShell({required this.child, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [fuBg, fuLight],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: -90,
              left: -70,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fuDark.withOpacity(0.85),
                ),
              ),
            ),
            Positioned(
              bottom: -110,
              right: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fuAccent.withOpacity(0.35),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  if (onBack != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: fuDark),
                        onPressed: onBack,
                      ),
                    ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  final void Function(UserProfileData) onLogin;
  final VoidCallback onCreateAccount;
  const LoginPage({super.key, required this.onLogin, required this.onCreateAccount});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _key = GlobalKey<FormState>();
  final idCtrl = TextEditingController();
  final pwCtrl = TextEditingController();
  bool obscure = true;

  @override
  void dispose() {
    idCtrl.dispose();
    pwCtrl.dispose();
    super.dispose();
  }

  void _login() {
    if (!_key.currentState!.validate()) return;
    if (!AccountStore.exists) {
      showMessage(context, 'No account found on this device. Please register first.');
      return;
    }
    final lock = AccountStore.lockRemaining;
    if (lock != null) {
      showMessage(context,
          '${tr('Too many attempts. Try again later.')} (${lock.inSeconds}s)');
      return;
    }
    if (AccountStore.verifyLogin(idCtrl.text, pwCtrl.text)) {
      pwCtrl.clear();
      widget.onLogin(AccountStore.profile!);
    } else {
      showMessage(context, 'Incorrect phone/email or password.');
    }
  }

  Future<void> _bio() async {
    final p = AccountStore.profile;
    if (p == null) {
      showMessage(context, 'No account found on this device. Please register first.');
      return;
    }
    final st = await BiometricHelper.status();
    if (!mounted) return;
    if (st == BioStatus.noHardware || st == BioStatus.error) {
      showMessage(context, 'Fingerprint is not available on this device.');
      return;
    }
    if (st == BioStatus.notEnrolled) {
      showMessage(context,
          'No fingerprint is enrolled on this phone. Add one in your phone Settings first.');
      return;
    }
    final ok = await BiometricHelper.authenticate(
      reason: 'Log in to ALSUDAN with your fingerprint',
    );
    if (!mounted) return;
    if (ok) {
      widget.onLogin(p);
    } else {
      showMessage(context, 'Fingerprint authentication failed or was cancelled.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthShell(
      child: Form(
        key: _key,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            const FuLogo(size: 120),
            const SizedBox(height: 8),
            const FuWordmark(size: 42),
            const SizedBox(height: 10),
            const TrText(
              'Welcome Back',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: fuText),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: idCtrl,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: tr('Phone Number or Email'),
                prefixIcon: const Icon(Icons.phone_android),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? tr('Required') : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: pwCtrl,
              obscureText: obscure,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: tr('Password'),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => obscure = !obscure),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? tr('Required') : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => openPage(context, const ForgotPasswordPage()),
                child: const TrText('Forgot Password / PIN?', style: TextStyle(color: fuGreen)),
              ),
            ),
            PrimaryButton(text: 'LOGIN', onPressed: _login),
            ValueListenableBuilder<bool>(
              valueListenable: biometricEnabled,
              builder: (_, on, __) => on && AccountStore.exists
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: IconButton(
                        iconSize: 46,
                        icon: const Icon(Icons.fingerprint, color: fuGreen),
                        onPressed: _bio,
                        tooltip: tr('Login with fingerprint'),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const TrText("Don't have an account?"),
                TextButton(
                  onPressed: widget.onCreateAccount,
                  child: const TrText(
                    'Register',
                    style: TextStyle(color: fuGreen, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TrText(
              kDeveloperCredit,
              style: const TextStyle(color: fuMuted, fontSize: 11),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  final VoidCallback onBack;
  final bool Function(UserProfileData) onCheckAndRegister;
  final void Function(UserProfileData) onRegistered;

  const RegisterPage({
    super.key,
    required this.onBack,
    required this.onCheckAndRegister,
    required this.onRegistered,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _key = GlobalKey<FormState>();
  final fullName = TextEditingController();
  final username = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final address = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  final pin = TextEditingController();
  final confirmPin = TextEditingController();
  bool obscure = true;
  bool busy = false;

  @override
  void dispose() {
    for (final c in [fullName, username, phone, email, address, password, confirm, pin, confirmPin]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> register() async {
    if (busy || !_key.currentState!.validate()) return;
    final u = UserProfileData(
      fullName: fullName.text.trim(),
      username: username.text.trim(),
      phone: cleanPhone(phone.text.trim()),
      email: email.text.trim(),
      address: address.text.trim(),
    );
    if (!widget.onCheckAndRegister(u)) {
      showMessage(context, 'This username is already taken.');
      return;
    }
    setState(() => busy = true);
    await AccountStore.save(u, password.text);
    await PinService.set(pin.text);
    if (!mounted) return;
    setState(() => busy = false);
    showMessage(context, 'Your account has been created successfully!');
    widget.onRegistered(u);
  }

  Widget _f(
    TextEditingController c,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
    TextInputType? type,
    bool secret = false,
    int? maxLen,
    bool digits = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        obscureText: secret && obscure,
        enableSuggestions: !secret,
        autocorrect: !secret,
        maxLength: maxLen,
        inputFormatters: digits ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(
          labelText: tr(label),
          prefixIcon: Icon(icon),
          counterText: '',
        ),
        validator: validator ??
            (v) => (v == null || v.trim().isEmpty) ? tr('Required') : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _AuthShell(
      onBack: widget.onBack,
      child: Form(
        key: _key,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            const FuLogo(size: 100),
            const SizedBox(height: 6),
            const FuWordmark(size: 36),
            const SizedBox(height: 6),
            const TrText(
              'Create Your Account',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: fuDark),
            ),
            const SizedBox(height: 18),
            _f(fullName, 'Full Name', Icons.badge_outlined),
            _f(username, 'Username', Icons.person_outline, validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) return tr('Required');
              return RegExp(r'^[A-Za-z0-9_]{3,20}$').hasMatch(t)
                  ? null
                  : '3-20: A-Z, 0-9, _';
            }),
            _f(phone, 'Phone Number', Icons.phone_android,
                type: TextInputType.phone, validator: (v) {
              if (v == null || v.trim().isEmpty) return tr('Required');
              return isValidNgPhone(cleanPhone(v.trim()))
                  ? null
                  : tr('Enter a valid 11-digit number');
            }),
            _f(email, 'Email Address', Icons.email_outlined,
                type: TextInputType.emailAddress, validator: (v) {
              if (v == null || v.trim().isEmpty) return tr('Required');
              return RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(v.trim())
                  ? null
                  : tr('Enter a valid email');
            }),
            _f(address, 'Address', Icons.location_on_outlined),
            _f(password, 'Password', Icons.lock_outline,
                secret: true, validator: passwordProblem),
            _f(confirm, 'Confirm Password', Icons.lock_reset, secret: true,
                validator: (v) =>
                    v != password.text ? tr("Passwords don't match") : null),
            _f(pin, '4-digit Transaction PIN', Icons.pin_outlined,
                secret: true, type: TextInputType.number, maxLen: 4, digits: true,
                validator: (v) {
              if (v == null || v.length != 4) return tr('PIN must be 4 digits');
              if (isWeakPin(v)) return tr('Choose a PIN that is not easy to guess.');
              return null;
            }),
            _f(confirmPin, 'Confirm PIN', Icons.pin_outlined,
                secret: true, type: TextInputType.number, maxLen: 4, digits: true,
                validator: (v) => v != pin.text ? tr("PINs don't match") : null),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => obscure = !obscure),
                icon: Icon(obscure ? Icons.visibility : Icons.visibility_off, size: 18),
                label: TrText(obscure ? 'Show passwords' : 'Hide passwords'),
              ),
            ),
            PrimaryButton(text: 'REGISTER', onPressed: register, loading: busy),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const TrText('Already have an account?'),
                TextButton(
                  onPressed: widget.onBack,
                  child: const TrText(
                    'Login',
                    style: TextStyle(color: fuGreen, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final id = TextEditingController();

  @override
  void dispose() {
    id.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleServicePage(
      title: 'Reset Password / PIN',
      icon: Icons.lock_reset,
      children: [
        const InfoBanner(
          'Password reset needs a server to send a real OTP. This screen is a placeholder until your backend is connected.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: id,
          decoration: InputDecoration(
            labelText: tr('Phone Number or Email'),
            prefixIcon: const Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          text: 'SEND RESET CODE',
          onPressed: () => showMessage(
            context,
            'Not available yet: no reset service is connected.',
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// MAIN NAVIGATION + HOME
// Tabs: 0 Home, 1 Profile, 2 Settings
// ===========================================================================
class MainNavigation extends StatefulWidget {
  final UserProfileData user;
  final VoidCallback onLogout;
  const MainNavigation({super.key, required this.user, required this.onLogout});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(user: widget.user, onTab: (i) => setState(() => index = i)),
      ProfilePage(
        user: widget.user,
        onLogout: widget.onLogout,
        onTab: (i) => setState(() => index = i),
      ),
      SettingsPage(onLogout: widget.onLogout),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home, color: fuGreen),
            label: tr('Home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person, color: fuGreen),
            label: tr('Profile'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings, color: fuGreen),
            label: tr('Settings'),
          ),
        ],
      ),
    );
  }
}

class _Svc {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final String? label; // optional display text (overrides translated title)
  _Svc(this.icon, this.title, this.color, this.onTap, {this.label});
}

/// Every service in the app (nothing removed). Home shows the layout from the
/// reference image; "View All" and "Bills" show the rest.
List<_Svc> buildServices(BuildContext context) {
  return <_Svc>[
    _Svc(Icons.phone_android, 'Airtime', fuGreen,
        () => openPage(context, const AirtimePage())),
    _Svc(Icons.wifi, 'Data', fuBlue, () => openPage(context, const DataPage())),
    _Svc(
      Icons.bolt,
      'Electricity',
      const Color(0xFFF59E0B),
      () => openPage(
        context,
        const BillPage(
          title: 'Electricity',
          icon: Icons.bolt,
          idLabel: 'Meter Number',
          providers: ['AEDC', 'EKEDC', 'IKEDC', 'KEDCO', 'JED'],
        ),
      ),
    ),
    _Svc(
      Icons.live_tv,
      'Cable TV',
      fuBlue,
      () => openPage(context, const CableTvProvidersPage()),
    ),
    _Svc(Icons.account_balance_wallet, 'Wallet Deposit', fuGreen,
        () => openPage(context, const WalletPage())),
    _Svc(Icons.receipt_long, 'Bills', fuBlue,
        () => openPage(context, const BillsPage())),
    _Svc(
      Icons.school,
      'Education',
      fuBlue,
      () => openPage(
        context,
        const BillPage(
          title: 'Education',
          icon: Icons.school,
          idLabel: 'Registration / Exam Number',
        ),
      ),
    ),
    _Svc(Icons.chat_bubble_outline, 'Bulk SMS', fuAccent,
        () => openPage(context, const BulkSmsPage())),
    _Svc(Icons.shield_outlined, 'ePIN', fuGreen,
        () => openPage(context, const EpinPage())),
    _Svc(Icons.person, 'Contacts', fuGreen,
        () => openPage(context, const ContactNumberPage())),
    _Svc(Icons.sd_card, 'Data Card', fuBlue,
        () => openPage(context, const DataCardPage())),
    _Svc(Icons.local_shipping, 'Delivery', fuGreen,
        () => openPage(context, const DeliveryPage())),
    _Svc(
      Icons.solar_power,
      'Inverter',
      fuText,
      () => openPage(
        context,
        const BillPage(
          title: 'Inverter',
          icon: Icons.solar_power,
          idLabel: 'Phone Number',
          packages: {
            'Inverter Consultation': 1000,
            'Installation Request': 1000,
            'Maintenance Request': 1000,
            'Solar/Inverter Quote': 1000,
          },
          packageLabel: 'Service (demo fee)',
        ),
      ),
    ),
    _Svc(Icons.headset_mic, 'Support', fuGreen,
        () => openPage(context, const SupportPage())),
    _Svc(Icons.history, 'History', fuGreen,
        () => openPage(context, const HistoryPage())),
  ];
}

class _ServiceTile extends StatelessWidget {
  final _Svc svc;
  final double height;
  const _ServiceTile({required this.svc, this.height = 104});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      color: fuText,
      height: 1.2,
    );
    return InkWell(
      onTap: svc.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: cardDeco(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: svc.color.withOpacity(0.13),
                shape: BoxShape.circle,
              ),
              child: Icon(svc.icon, color: svc.color, size: 26),
            ),
            const SizedBox(height: 6),
            if (svc.label != null)
              Text(svc.label!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: style)
            else
              TrText(svc.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: style),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// DASHBOARD ADVERTISEMENT CAROUSEL: five offline banners, moves every 6 seconds
// ===========================================================================
class _BannerData {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final bool art;
  final String? image;
  const _BannerData(this.title, this.subtitle, this.icon, this.colors,
      {this.art = false, this.image});
}

const List<_BannerData> _banners = [
  _BannerData(
    'ALSUDAN',
    kTagline,
    Icons.eco_rounded,
    [Color(0xFF0F5B45), Color(0xFF2E8B57)],
    art: true,
  ),
  _BannerData(
    'Buy Airtime and Data',
    'MTN, Airtel, Glo, T2mobile (9mobile) and Smile',
    Icons.phone_android_rounded,
    [Color(0xFF1B7F5B), Color(0xFF3FB27F)],
    image: kAdAirtimeAsset,
  ),
  _BannerData(
    'Pay Electricity and TV Bills',
    'AEDC, EKEDC, IKEDC, KEDCO, JED  •  DSTV, GOtv, Startimes',
    Icons.bolt_rounded,
    [Color(0xFF0F5B45), Color(0xFF4C9F70)],
    image: kAdUtilityAsset,
  ),
  _BannerData(
    'Wallet and Secure Transactions',
    'Wallet, transaction history, PIN and fingerprint security',
    Icons.lock_rounded,
    [Color(0xFF0B4A38), Color(0xFF2E8B57)],
    image: kAdWalletAsset,
  ),
  _BannerData(
    'Digital Services and Offers',
    'Bulk SMS, ePIN, Education and Inverter requests. Offers show here when available.',
    Icons.auto_awesome_rounded,
    [Color(0xFF2E8B57), Color(0xFF86C79E)],
    image: kAdDigitalAsset,
  ),
];

class DashboardCarousel extends StatefulWidget {
  final void Function(int index) onOpen;
  const DashboardCarousel({super.key, required this.onOpen});

  @override
  State<DashboardCarousel> createState() => _DashboardCarouselState();
}

class _DashboardCarouselState extends State<DashboardCarousel>
    with WidgetsBindingObserver {
  // Starting far from 0 (a multiple of 5) lets the pager loop in both
  // directions without a visible jump.
  static const int _startPage = 5000;

  late final PageController _pc = PageController(initialPage: _startPage);
  Timer? _timer;
  int _page = 0;
  bool _touching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || _touching || !_pc.hasClients) return;
      _pc.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pc.dispose();
    super.dispose();
  }

  Widget _card(int i) {
    final b = _banners[i];
    return GestureDetector(
      onTap: () => widget.onOpen(i),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: b.colors,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              if (b.art)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.30,
                    child: Image.asset(
                      kArtAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              if (b.image != null)
                Positioned.fill(
                  child: Image.asset(
                    b.image!,
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                    // If the picture is missing, show the original icon mark.
                    errorBuilder: (_, __, ___) => Align(
                      alignment: Alignment.bottomRight,
                      child: Transform.translate(
                        offset: const Offset(16, 16),
                        child: Icon(
                          b.icon,
                          size: 120,
                          color: Colors.white.withOpacity(0.16),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Positioned(
                  right: -16,
                  bottom: -16,
                  child: Icon(b.icon, size: 120, color: Colors.white.withOpacity(0.16)),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TrText(
                      b.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TrText(
                      b.subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = (w * 0.38).clamp(130.0, 180.0).toDouble();
    return Column(
      children: [
        SizedBox(
          height: h,
          child: Listener(
            onPointerDown: (_) => _touching = true,
            onPointerUp: (_) {
              _touching = false;
              _startTimer();
            },
            onPointerCancel: (_) {
              _touching = false;
              _startTimer();
            },
            child: PageView.builder(
              controller: _pc,
              onPageChanged: (i) => setState(() => _page = i % _banners.length),
              itemBuilder: (_, i) => _card(i % _banners.length),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _banners.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: i == _page ? 20 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  color: i == _page ? fuGreen : fuBorder,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class HomePage extends StatelessWidget {
  final UserProfileData user;
  final ValueChanged<int> onTab;
  const HomePage({super.key, required this.user, required this.onTab});

  Widget _row(List<_Svc> items) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: _ServiceTile(svc: items[i])),
            ],
          ],
        ),
      );

  void _openBanner(BuildContext context, int i) {
    switch (i) {
      case 1:
        openPage(context, const AirtimePage());
        break;
      case 2:
        openPage(context, const BillsPage());
        break;
      case 3:
        openPage(context, const WalletPage());
        break;
      case 4:
        openPage(context, const AllServicesPage());
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = buildServices(context);
    _Svc s(String t) => all.firstWhere((e) => e.title == t);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          children: [
            Row(
              children: [
                const FuLogo(size: 44),
                const SizedBox(width: 10),
                const FuWordmark(size: 26),
                const Spacer(),
                ListenableBuilder(
                  listenable: Listenable.merge([transactionsNotifier, notifSeen, notifTxn]),
                  builder: (_, __) {
                    final unread = notifTxn.value &&
                        transactionsNotifier.value.length > notifSeen.value;
                    return Stack(
                      children: [
                        IconButton(
                          onPressed: () => openPage(context, const NotificationsPage()),
                          icon: const Icon(Icons.notifications_none, color: fuText),
                        ),
                        if (unread)
                          const Positioned(
                            right: 12,
                            top: 12,
                            child: CircleAvatar(radius: 4, backgroundColor: Colors.red),
                          ),
                      ],
                    );
                  },
                ),
                InkWell(
                  onTap: () => onTab(1),
                  customBorder: const CircleBorder(),
                  child: const CircleAvatar(
                    radius: 20,
                    backgroundColor: fuDark,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${tr('Hello')}, ${user.fullName}',
              style: const TextStyle(color: fuMuted),
            ),
            const SizedBox(height: 12),
            const _WalletCard(),
            const SizedBox(height: 12),
            DashboardCarousel(onOpen: (i) => _openBanner(context, i)),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(
                  child: TrText(
                    'Our Services',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: fuDark),
                  ),
                ),
                InkWell(
                  onTap: () => openPage(context, const AllServicesPage()),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Row(
                      children: [
                        TrText('View All',
                            style: TextStyle(color: fuText, fontWeight: FontWeight.w600)),
                        Icon(Icons.chevron_right, color: fuText, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _row([s('Data'), s('Electricity'), s('Cable TV')]),
            _row([s('Wallet Deposit'), s('Bills'), s('Bulk SMS'), s('ePIN')]),
            _row([s('Contacts'), s('Data Card'), s('Delivery')]),
          ],
        ),
      ),
    );
  }
}

/// "View All": every service in the app (Airtime, Education, Inverter,
/// Support, History and the rest).
class AllServicesPage extends StatelessWidget {
  const AllServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final all = buildServices(context);
    return Scaffold(
      appBar: AppBar(title: const TrText('Our Services')),
      body: SafeArea(
        child: GridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.0,
          children: [
            for (final s in all) _ServiceTile(svc: s, height: 110),
          ],
        ),
      ),
    );
  }
}

/// Bills hub: groups the bill-type services.
class BillsPage extends StatelessWidget {
  const BillsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final all = buildServices(context);
    const wanted = ['Airtime', 'Electricity', 'Cable TV', 'Education', 'Inverter'];
    final items = [for (final t in wanted) all.firstWhere((e) => e.title == t)];
    return SimpleServicePage(
      title: 'Bills',
      icon: Icons.receipt_long,
      children: [
        for (final s in items)
          ServiceCard(
            title: s.title,
            subtitle: 'Pay for ${s.title}',
            icon: s.icon,
            onTap: s.onTap,
          ),
      ],
    );
  }
}

/// Delivery (demo fee, goes through the same PIN + receipt flow).
class DeliveryPage extends StatelessWidget {
  const DeliveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BillPage(
      title: 'Delivery',
      icon: Icons.local_shipping,
      idLabel: 'Delivery Address / Phone',
      packages: {
        'Small Package': 1500,
        'Medium Package': 2500,
        'Large Package': 4000,
      },
      packageLabel: 'Package size (demo fee)',
    );
  }
}

class DataCardPage extends StatelessWidget {
  const DataCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BillPage(
      title: 'Data Card',
      icon: Icons.sd_card,
      idLabel: 'Phone Number',
      providers: ['MTN', 'Airtel', 'Glo', 'T2mobile'],
      packages: {'1GB Card': 500, '2GB Card': 900, '5GB Card': 2000, '10GB Card': 3500},
      packageLabel: 'Card (demo)',
    );
  }
}

/// Notifications: built from the transactions made in this app session. Real
/// push notifications need a backend (Firebase Cloud Messaging or similar).
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifSeen.value = transactionsNotifier.value.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const TrText('Notifications')),
      body: ListenableBuilder(
        listenable: Listenable.merge([transactionsNotifier, notifTxn]),
        builder: (_, __) {
          final items = notifTxn.value
              ? transactionsNotifier.value.where((t) => t.amount != 0).toList()
              : <WalletTransaction>[];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.notifications_off_outlined, size: 48, color: fuMuted),
                  SizedBox(height: 8),
                  TrText('No new notifications.', style: TextStyle(color: fuMuted)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final t = items[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: cardDeco(),
                child: ListTile(
                  onTap: () => openPage(context, ReceiptPage(transaction: t)),
                  leading: CircleAvatar(
                    backgroundColor: fuLight,
                    child: Icon(
                      t.amount > 0 ? Icons.arrow_downward : Icons.arrow_upward,
                      color: fuGreen,
                    ),
                  ),
                  title: Text('${tr(t.title)} • ${tr(t.status.label)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${naira(t.amount.abs())}\n${fmtDate(t.date)}'),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _WalletCard extends StatefulWidget {
  const _WalletCard();

  @override
  State<_WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<_WalletCard> {
  bool hide = false;

  Widget _stat(IconData icon, String label, String value) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TrText(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: walletBalance,
      builder: (_, bal, __) => ValueListenableBuilder<List<WalletTransaction>>(
        valueListenable: transactionsNotifier,
        builder: (_, txns, __) {
          final spent = txns
              .where((t) => t.amount < 0 && t.status.movedMoney)
              .fold<double>(0, (s, t) => s + (-t.amount));
          final shownBal = hide ? '₦ ••••••' : naira(bal);
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: fuDark,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: fuDark.withOpacity(0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const TrText(
                                'Wallet Balance',
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => setState(() => hide = !hide),
                                child: Icon(
                                  hide ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              shownBal,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => showAddMoneyDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const TrText('Add Money'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: fuAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _stat(Icons.account_balance_wallet_outlined, 'Available',
                            hide ? '₦ ••••' : naira(bal)),
                      ),
                      Container(width: 1, height: 36, color: Colors.white24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _stat(Icons.lock_outline, 'Total Spend',
                            hide ? '₦ ••••' : naira(spent)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

void showAddMoneyDialog(BuildContext context) {
  final ctrl = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (dctx) => AlertDialog(
      title: const TrText('Add Money'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Transfer to:', style: TextStyle(color: fuMuted, fontSize: 12)),
          Text('$kFundingBank • $kFundingAccountNumber',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(kFundingAccountName, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 12),
          const InfoBanner(
            'Test funding only: the amount below is credited as a DEMO balance. Real funding needs payment confirmation from your provider.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: tr('Amount'), prefixText: '₦ '),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dctx), child: const TrText('Cancel')),
        ElevatedButton(
          onPressed: () {
            final a = double.tryParse(ctrl.text);
            if (a == null || a <= 0) {
              showMessage(context, 'Enter a valid amount.');
              return;
            }
            Navigator.pop(dctx);
            performAddMoney(context, a);
          },
          child: const TrText('Add'),
        ),
      ],
    ),
  );
}

// ===========================================================================
// AIRTIME
// ===========================================================================
class AirtimePage extends StatefulWidget {
  const AirtimePage({super.key});

  @override
  State<AirtimePage> createState() => _AirtimePageState();
}

class _AirtimePageState extends State<AirtimePage> {
  Network? network;
  final phone = TextEditingController();
  final amount = TextEditingController();
  bool busy = false;

  @override
  void dispose() {
    phone.dispose();
    amount.dispose();
    super.dispose();
  }

  Future<void> buy() async {
    if (busy) return;
    final p = cleanPhone(phone.text.trim());
    final v = double.tryParse(amount.text.trim());
    if (network == null) {
      showMessage(context, 'Select a network.');
      return;
    }
    if (!isValidNgPhone(p)) {
      showMessage(context, 'Enter a valid 11-digit phone number.');
      return;
    }
    if (v == null || v < 50 || v > 50000) {
      showMessage(context, 'Enter an amount between ₦50 and ₦50,000.');
      return;
    }
    setState(() => busy = true);
    final net = network!;
    final ok = await runTransaction(
      context,
      TxRequest(
        title: 'Airtime',
        amount: v,
        reference: newReference(),
        network: net,
        recipient: p,
        note: '${net.label} • $p',
        lines: [
          MapEntry('Network', net.label),
          MapEntry('Recipient', p),
          MapEntry('Amount', naira(v)),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => busy = false);
    if (ok) {
      phone.clear();
      amount.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleServicePage(
      title: 'Airtime',
      icon: Icons.phone_android,
      children: [
        const SectionLabel('Select Network'),
        NetworkSelector(
          selected: network,
          onSelected: (n) => setState(() => network = n),
        ),
        const SectionLabel('Recipient'),
        phoneField(context, phone, onChanged: (_) => setState(() {})),
        networkHint(phone.text, network, (n) => setState(() => network = n)),
        const SizedBox(height: 14),
        TextField(
          controller: amount,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: tr('Amount'),
            prefixText: '₦ ',
            prefixIcon: const Icon(Icons.payments_outlined),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final a in [100, 200, 500, 1000])
              ActionChip(label: Text('₦$a'), onPressed: () => amount.text = '$a'),
          ],
        ),
        const SizedBox(height: 20),
        PrimaryButton(text: 'Buy Airtime', onPressed: buy, loading: busy),
      ],
    );
  }
}

// ===========================================================================
// DATA
// ===========================================================================
class DataPlan {
  final String name;
  final double price;
  final String? validity;
  const DataPlan(this.name, this.price, {this.validity});
}

// Plans carried over from your previous app. They are the SAME for every
// network here; replace with live per-network plans from your provider.
const List<DataPlan> _basePlans = [
  DataPlan('500MB', 300),
  DataPlan('1GB', 500),
  DataPlan('2GB', 900),
  DataPlan('5GB', 2000),
  DataPlan('10GB', 3500),
];

final Map<Network, List<DataPlan>> kDataPlans = {
  for (final n in Network.values) n: _basePlans,
};

class DataPage extends StatefulWidget {
  const DataPage({super.key});

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  Network? network;
  DataPlan? plan;
  final phone = TextEditingController();
  bool busy = false;

  @override
  void dispose() {
    phone.dispose();
    super.dispose();
  }

  Future<void> buy() async {
    if (busy) return;
    final p = cleanPhone(phone.text.trim());
    if (network == null) {
      showMessage(context, 'Select a network.');
      return;
    }
    if (plan == null) {
      showMessage(context, 'Select a data plan.');
      return;
    }
    if (!isValidNgPhone(p)) {
      showMessage(context, 'Enter a valid 11-digit phone number.');
      return;
    }
    final net = network!;
    final pl = plan!;
    setState(() => busy = true);
    final ok = await runTransaction(
      context,
      TxRequest(
        title: 'Data',
        amount: pl.price,
        reference: newReference(),
        network: net,
        recipient: p,
        note: '${net.label} • $p • ${pl.name}',
        lines: [
          MapEntry('Network', net.label),
          MapEntry('Recipient', p),
          MapEntry('Plan', pl.name),
          if (pl.validity != null) MapEntry('Validity', pl.validity!),
          MapEntry('Amount', naira(pl.price)),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => busy = false);
    if (ok) {
      phone.clear();
      setState(() => plan = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = network == null ? <DataPlan>[] : kDataPlans[network]!;
    return SimpleServicePage(
      title: 'Data',
      icon: Icons.wifi,
      children: [
        const SectionLabel('Select Network'),
        NetworkSelector(
          selected: network,
          onSelected: (n) => setState(() {
            network = n;
            plan = null;
          }),
        ),
        const SectionLabel('Recipient'),
        phoneField(context, phone, onChanged: (_) => setState(() {})),
        networkHint(phone.text, network, (n) => setState(() {
              network = n;
              plan = null;
            })),
        const SectionLabel('Data Plan'),
        if (!vtuProvider.isLive) ...[
          const InfoBanner(
            'Sample plans only. Connect your provider to load live plans and prices.',
          ),
          const SizedBox(height: 10),
        ],
        if (network == null)
          const TrText('Choose a network to see its plans.', style: TextStyle(color: fuMuted))
        else
          for (final p in plans)
            GestureDetector(
              onTap: () => setState(() => plan = p),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: plan == p ? fuAccent.withOpacity(0.12) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: plan == p ? fuAccent : fuBorder,
                    width: plan == p ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      plan == p ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: plan == p ? fuAccent : fuMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                          if (p.validity != null)
                            Text(p.validity!,
                                style: const TextStyle(color: fuMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(naira(p.price),
                        style: const TextStyle(fontWeight: FontWeight.w900, color: fuDark)),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 16),
        PrimaryButton(text: 'Buy Data', onPressed: buy, loading: busy),
      ],
    );
  }
}

// ===========================================================================
// ePIN (pending provider integration: never generates PINs)
// ===========================================================================
class EpinPage extends StatefulWidget {
  const EpinPage({super.key});

  @override
  State<EpinPage> createState() => _EpinPageState();
}

class _EpinPageState extends State<EpinPage> {
  Network? network;
  final qty = TextEditingController();
  final price = TextEditingController();
  bool busy = false;

  @override
  void dispose() {
    qty.dispose();
    price.dispose();
    super.dispose();
  }

  Future<void> buy() async {
    if (busy) return;
    final q = int.tryParse(qty.text.trim());
    final pr = double.tryParse(price.text.trim());
    if (network == null) {
      showMessage(context, 'Select a category.');
      return;
    }
    if (q == null || pr == null || q <= 0 || pr <= 0) {
      showMessage(context, 'Fill in quantity and price.');
      return;
    }
    final net = network!;
    final total = q * pr;
    setState(() => busy = true);
    final ok = await runTransaction(
      context,
      TxRequest(
        title: 'ePIN',
        amount: total,
        reference: newReference(),
        network: net,
        note: '${net.label} recharge PIN • $q x ${naira(pr)}',
        lines: [
          MapEntry('Category', '${net.label} recharge PIN'),
          MapEntry('Quantity', '$q'),
          MapEntry('Price per PIN', naira(pr)),
          MapEntry('Total', naira(total)),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => busy = false);
    if (ok) {
      qty.clear();
      price.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleServicePage(
      title: 'ePIN',
      icon: Icons.shield_outlined,
      children: [
        const InfoBanner(
          'Pending integration: no ePIN provider is connected, so no PINs are generated or delivered. Purchases here are demo only.',
        ),
        const SectionLabel('Category'),
        NetworkSelector(
          options: const [Network.mtn, Network.airtel, Network.glo, Network.t2mobile],
          selected: network,
          onSelected: (n) => setState(() => network = n),
        ),
        const SectionLabel('Order'),
        TextField(
          controller: qty,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Quantity',
            prefixIcon: Icon(Icons.numbers),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: price,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Price per PIN',
            prefixText: '₦ ',
            prefixIcon: Icon(Icons.payments_outlined),
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(text: 'Buy ePIN', onPressed: buy, loading: busy),
      ],
    );
  }
}

// ===========================================================================
// CABLE TV PROVIDER SELECTOR
// ===========================================================================
class CableTvProvidersPage extends StatelessWidget {
  const CableTvProvidersPage({super.key});

  static const List<_CableProvider> _providers = [
    _CableProvider('DStv', 'assets/networks/cable_dstv.png'),
    _CableProvider('Startimes', 'assets/networks/cable_startimes.png'),
    _CableProvider('GOtv', 'assets/networks/cable_gotv.png'),
    _CableProvider('SLTV', 'assets/networks/cable_sltv.png'),
  ];

  void _openProvider(BuildContext context, String provider) {
    openPage(
      context,
      BillPage(
        title: 'Cable TV',
        icon: Icons.live_tv,
        idLabel: 'Smartcard / IUC Number',
        providers: const ['DStv', 'Startimes', 'GOtv', 'SLTV'],
        initialProvider: provider,
        packages: const {'Compact': 10000, 'Family': 6000, 'Basic': 3500},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SimpleServicePage(
      title: 'Cable TV',
      icon: Icons.live_tv,
      children: [
        const Text(
          'Choose your TV provider',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: fuDark),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.08,
          children: [
            for (final item in _providers)
              InkWell(
                onTap: () => _openProvider(context, item.name),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: cardDeco(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Image.asset(
                          item.asset,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            width: 76,
                            height: 76,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: fuBlue.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.live_tv, size: 42, color: fuBlue),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(item.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: fuText,
                          )),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _CableProvider {
  final String name;
  final String asset;
  const _CableProvider(this.name, this.asset);
}

// ===========================================================================
// GENERIC BILL PAGE (Electricity, Cable TV, Education, Inverter, Delivery,
// Data Card)
// ===========================================================================
class BillPage extends StatefulWidget {
  final String title;
  final IconData icon;
  final String idLabel;
  final List<String>? providers;
  final Map<String, double>? packages;
  final String packageLabel;
  final String? initialProvider;

  const BillPage({
    super.key,
    required this.title,
    required this.icon,
    required this.idLabel,
    this.providers,
    this.packages,
    this.packageLabel = 'Package',
    this.initialProvider,
  });

  @override
  State<BillPage> createState() => _BillPageState();
}

class _BillPageState extends State<BillPage> {
  final idCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  String? provider;
  String? package;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    provider = widget.initialProvider ?? widget.providers?.first;
  }

  @override
  void dispose() {
    idCtrl.dispose();
    amountCtrl.dispose();
    super.dispose();
  }

  Future<void> pay() async {
    if (busy) return;
    final id = idCtrl.text.trim();
    if (id.isEmpty) {
      showMessage(context, 'Enter ${widget.idLabel}.');
      return;
    }
    double? amount;
    if (widget.packages != null) {
      if (package == null) {
        showMessage(context, 'Select a ${widget.packageLabel.toLowerCase()}.');
        return;
      }
      amount = widget.packages![package];
    } else {
      amount = double.tryParse(amountCtrl.text.trim());
    }
    if (amount == null || amount <= 0) {
      showMessage(context, 'Enter a valid amount.');
      return;
    }
    setState(() => busy = true);
    final ok = await runTransaction(
      context,
      TxRequest(
        title: widget.title,
        amount: amount,
        reference: newReference(),
        note: '${widget.idLabel}: $id${provider != null ? ' • $provider' : ''}${package != null ? ' • $package' : ''}',
        lines: [
          MapEntry(widget.idLabel, id),
          if (provider != null) MapEntry('Provider', provider!),
          if (package != null) MapEntry(widget.packageLabel, package!),
          MapEntry('Amount', naira(amount)),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => busy = false);
    if (ok) {
      idCtrl.clear();
      amountCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pk = widget.packages;
    final header = kServiceHeaderAssets[widget.title];
    return SimpleServicePage(
      title: widget.title,
      icon: widget.icon,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                header,
                height: 130,
                width: double.infinity,
                fit: BoxFit.cover,
                // If the picture is missing, simply show nothing.
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        if (!vtuProvider.isLive)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: InfoBanner('Demo mode: no provider is connected yet.'),
          ),
        if (widget.providers != null) ...[
          const SectionLabel('Provider'),
          Wrap(
            spacing: 8,
            children: [
              for (final p in widget.providers!)
                ChoiceChip(
                  label: Text(p),
                  selected: provider == p,
                  selectedColor: fuAccent.withOpacity(0.25),
                  onSelected: (_) => setState(() => provider = p),
                ),
            ],
          ),
        ],
        const SectionLabel('Details'),
        TextField(
          controller: idCtrl,
          decoration: InputDecoration(
            labelText: tr(widget.idLabel),
            prefixIcon: const Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: 14),
        if (pk != null)
          for (final e in pk.entries)
            GestureDetector(
              onTap: () => setState(() => package = e.key),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: package == e.key ? fuAccent.withOpacity(0.12) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: package == e.key ? fuAccent : fuBorder,
                    width: package == e.key ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(e.key,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    Text(naira(e.value),
                        style: const TextStyle(fontWeight: FontWeight.w900, color: fuDark)),
                  ],
                ),
              ),
            )
        else
          TextField(
            controller: amountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: tr('Amount'),
              prefixText: '₦ ',
              prefixIcon: const Icon(Icons.payments_outlined),
            ),
          ),
        const SizedBox(height: 16),
        PrimaryButton(text: 'Continue', onPressed: pay, loading: busy),
      ],
    );
  }
}

// ===========================================================================
// BULK SMS
// ===========================================================================
const List<String> bulkSmsTemplates = [
  'Happy Birthday! Wishing you a blessed year ahead.',
  'Good morning! Wishing you a great day.',
  'Reminder: your payment is due. Please pay today.',
  'Your payment has been received. Thank you.',
  'Thank you for your patronage. We appreciate you.',
  'Our shop is open. Come and see our new products.',
  'Your order is ready. Please come and pick it up.',
  'Meeting today. Please be on time.',
  "Jumma'at Mubarak! May Allah accept our prayers.",
  'Eid Mubarak! Wishing you and your family joy and peace.',
  'Happy New Year! Wishing you success and good health.',
  'Congratulations on your success!',
  'Please call me back when you are free.',
  'Please send your account details for payment.',
];

class BulkSmsPage extends StatefulWidget {
  const BulkSmsPage({super.key});

  @override
  State<BulkSmsPage> createState() => _BulkSmsPageState();
}

class _BulkSmsPageState extends State<BulkSmsPage> {
  final recipients = TextEditingController();
  final message = TextEditingController();
  bool busy = false;

  @override
  void dispose() {
    recipients.dispose();
    message.dispose();
    super.dispose();
  }

  List<String> _numbers() => recipients.text
      .split(RegExp(r'[,\n;]'))
      .map((e) => cleanPhone(e.trim()))
      .where((e) => e.isNotEmpty)
      .toSet()
      .toList();

  Future<void> _addFromPhone() async {
    final p = await pickPhone(context);
    if (p == null || !mounted) return;
    final list = _numbers();
    if (!list.contains(p)) list.add(p);
    setState(() => recipients.text = list.join(', '));
  }

  Future<void> _addFromBackup() async {
    final list = contactBackup.value;
    if (list.isEmpty) {
      showMessage(context, 'No backed-up contacts yet.');
      return;
    }
    final current = _numbers().toSet();
    final sel = <String>{
      for (final c in list)
        if (current.contains(c.phone)) c.phone,
    };
    final res = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final c in list)
                      CheckboxListTile(
                        value: sel.contains(c.phone),
                        activeColor: fuAccent,
                        title: Text(c.name),
                        subtitle: Text(c.phone),
                        onChanged: (v) => setS(() {
                          if (v == true) {
                            sel.add(c.phone);
                          } else {
                            sel.remove(c.phone);
                          }
                        }),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: PrimaryButton(
                  text: 'Add Selected',
                  onPressed: () => Navigator.pop(ctx, Set<String>.from(sel)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (res == null || !mounted) return;
    final merged = _numbers();
    for (final p in res) {
      if (!merged.contains(p)) merged.add(p);
    }
    setState(() => recipients.text = merged.join(', '));
  }

  Future<void> _pickTemplate() async {
    final t = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final t in bulkSmsTemplates)
              ListTile(
                dense: true,
                leading: const Icon(Icons.chat_bubble_outline, color: fuGreen, size: 20),
                title: Text(t, style: const TextStyle(fontSize: 13)),
                onTap: () => Navigator.pop(ctx, t),
              ),
          ],
        ),
      ),
    );
    if (t != null && mounted) setState(() => message.text = t);
  }

  Future<void> send() async {
    if (busy) return;
    final nums = _numbers();
    final msg = message.text.trim();
    if (nums.isEmpty || msg.isEmpty) {
      showMessage(context, 'Fill in recipients and message.');
      return;
    }
    final bad = nums.where((n) => !isValidNgPhone(n)).toList();
    if (bad.isNotEmpty) {
      showMessage(context, 'Invalid number: ${bad.first}');
      return;
    }
    final cost = nums.length * 5.0; // demo rate from the previous app
    setState(() => busy = true);
    final ok = await runTransaction(
      context,
      TxRequest(
        title: 'Bulk SMS',
        amount: cost,
        reference: newReference(),
        note: '${nums.length} recipient(s) • "$msg"',
        lines: [
          MapEntry('Recipients', '${nums.length}'),
          MapEntry('Message', msg.length > 60 ? '${msg.substring(0, 60)}...' : msg),
          MapEntry('Rate', '₦5.00 per recipient'),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => busy = false);
    if (ok) {
      recipients.clear();
      message.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleServicePage(
      title: 'Bulk SMS',
      icon: Icons.chat_bubble_outline,
      children: [
        if (!vtuProvider.isLive)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: InfoBanner('Demo mode: messages are not actually sent.'),
          ),
        TextField(
          controller: recipients,
          maxLines: 3,
          keyboardType: TextInputType.phone,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Recipients (comma separated)',
            prefixIcon: const Icon(Icons.people_outline),
            suffixIcon: IconButton(
              icon: const Icon(Icons.contacts_outlined, color: fuGreen),
              onPressed: _addFromPhone,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text('${_numbers().length} recipient(s)',
              style: const TextStyle(color: fuMuted, fontSize: 11)),
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _addFromBackup,
                icon: const Icon(Icons.backup_outlined, size: 18),
                label: const TrText('From Backup'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickTemplate,
                icon: const Icon(Icons.library_books_outlined, size: 18),
                label: const TrText('Templates'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: message,
          maxLines: 5,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: tr('Message'),
            prefixIcon: const Icon(Icons.message_outlined),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text('${message.text.length} chars',
              style: const TextStyle(color: fuMuted, fontSize: 11)),
        ),
        const SizedBox(height: 14),
        PrimaryButton(text: 'Send SMS', onPressed: send, loading: busy),
      ],
    );
  }
}

// ===========================================================================
// CONTACTS PAGE (manual entry + picker + backup)
// ===========================================================================
class ContactNumberPage extends StatefulWidget {
  const ContactNumberPage({super.key});

  @override
  State<ContactNumberPage> createState() => _ContactNumberPageState();
}

class _ContactNumberPageState extends State<ContactNumberPage> {
  final number = TextEditingController();
  final name = TextEditingController();

  @override
  void dispose() {
    number.dispose();
    name.dispose();
    super.dispose();
  }

  void save() {
    final p = cleanPhone(number.text.trim());
    if (!isValidNgPhone(p)) {
      showMessage(context, 'Enter a valid 11-digit phone number.');
      return;
    }
    final ok = saveContactToBackup(name.text, p);
    showMessage(context, ok ? 'Contact saved to backup.' : 'This number is already in backup.');
    if (ok) name.clear();
  }

  Future<void> restore() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    var added = 0;
    for (final line in (data?.text ?? '').split('\n')) {
      final parts = line.trim().split(',');
      if (parts.first.trim().isEmpty) continue;
      final phone = cleanPhone(parts.last.trim());
      final nm = parts.length >= 2 ? parts.first.trim() : '';
      if (isValidNgPhone(phone) && saveContactToBackup(nm, phone)) added++;
    }
    if (!mounted) return;
    showMessage(context, added == 0 ? 'No valid contacts found in clipboard.' : '$added contacts restored.');
  }

  @override
  Widget build(BuildContext context) {
    return SimpleServicePage(
      title: 'Contacts',
      icon: Icons.person,
      children: [
        TextField(
          controller: name,
          decoration: InputDecoration(
            labelText: tr('Contact Name'),
            prefixIcon: const Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 14),
        phoneField(context, number),
        const SizedBox(height: 14),
        PrimaryButton(text: 'Save To Backup', onPressed: save),
        const SectionLabel('Contacts Backup'),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  if (contactBackup.value.isEmpty) {
                    showMessage(context, 'Nothing to copy yet.');
                    return;
                  }
                  Clipboard.setData(ClipboardData(
                    text: contactBackup.value
                        .map((c) => '${c.name.replaceAll(',', ' ')},${c.phone}')
                        .join('\n'),
                  ));
                  showMessage(context, 'Backup copied to clipboard.');
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const TrText('Copy Backup'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: restore,
                icon: const Icon(Icons.restore, size: 16),
                label: const TrText('Restore'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ValueListenableBuilder<List<BackupContact>>(
          valueListenable: contactBackup,
          builder: (_, list, __) => list.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: TrText('No backed-up contacts yet.', style: TextStyle(color: fuMuted)),
                )
              : Column(
                  children: [
                    for (final c in list)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: cardDeco(),
                        child: ListTile(
                          dense: true,
                          onTap: () {
                            number.text = c.phone;
                            name.text = c.name;
                          },
                          leading: const Icon(Icons.account_circle, color: fuGreen),
                          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(c.phone),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => contactBackup.value =
                                contactBackup.value.where((x) => x != c).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ===========================================================================
// WALLET, HISTORY, RECEIPT
// ===========================================================================
class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleServicePage(
      title: 'Wallet Deposit',
      icon: Icons.account_balance_wallet,
      children: [
        ValueListenableBuilder<double>(
          valueListenable: walletBalance,
          builder: (_, b, __) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: fuDark, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                const TrText('Current Balance', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Text(
                  naira(b),
                  style: const TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: cardDeco(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TrText(
                'Funding Bank Account',
                style: TextStyle(color: fuDark, fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const Divider(height: 22),
              _kv('Bank', kFundingBank),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const TrText('Account Number', style: TextStyle(color: fuMuted)),
                  Row(
                    children: [
                      const Text(
                        kFundingAccountNumber,
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: fuDark),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18, color: fuGreen),
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(text: kFundingAccountNumber));
                          showMessage(context, 'Account number copied.');
                        },
                      ),
                    ],
                  ),
                ],
              ),
              _kv('Account Name', kFundingAccountName),
            ],
          ),
        ),
        const SizedBox(height: 18),
        PrimaryButton(text: 'Add Money', onPressed: () => showAddMoneyDialog(context)),
      ],
    );
  }

  Widget _kv(String k, String v) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TrText(k, style: const TextStyle(color: fuMuted)),
          Flexible(child: Text(v, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      );
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const TrText('Transaction History')),
      body: ValueListenableBuilder<List<WalletTransaction>>(
        valueListenable: transactionsNotifier,
        builder: (_, txns, __) {
          if (txns.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.receipt_long_outlined, size: 48, color: fuMuted),
                  SizedBox(height: 8),
                  TrText('No transactions yet.', style: TextStyle(color: fuMuted)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: txns.length,
            itemBuilder: (_, i) {
              final t = txns[i];
              final credit = t.amount > 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: cardDeco(),
                child: ListTile(
                  onTap: () => openPage(context, ReceiptPage(transaction: t)),
                  leading: CircleAvatar(
                    backgroundColor: (credit ? fuAccent : Colors.redAccent).withOpacity(0.12),
                    child: Icon(
                      credit ? Icons.arrow_downward : Icons.arrow_upward,
                      color: credit ? fuAccent : Colors.redAccent,
                    ),
                  ),
                  title: Text(tr(t.title), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${fmtDate(t.date)}${t.reference.isEmpty ? '' : '\n${t.reference}'}',
                  ),
                  isThreeLine: t.reference.isNotEmpty,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        t.amount == 0
                            ? '—'
                            : '${credit ? '+' : '-'}${naira(t.amount.abs())}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: t.status.movedMoney || t.amount == 0
                              ? (credit ? fuAccent : Colors.redAccent)
                              : fuMuted,
                        ),
                      ),
                      TrText(
                        t.status.label,
                        style: TextStyle(fontSize: 10, color: t.status.color),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

String buildReceiptText(WalletTransaction t) {
  final b = StringBuffer()
    ..writeln('ALSUDAN')
    ..writeln('Transaction Receipt')
    ..writeln('---------------------------')
    ..writeln('Type: ${t.title}')
    ..writeln('Amount: ${naira(t.amount.abs())}');
  if (t.note.isNotEmpty) b.writeln('Details: ${t.note}');
  if (t.reference.isNotEmpty) b.writeln('Reference: ${t.reference}');
  b.writeln('Date: ${fmtDate(t.date)}');
  b.writeln('Status: ${t.status.label}');
  if (t.balanceAfter != null) b.writeln('Balance After: ${naira(t.balanceAfter!)}');
  if (t.status == TxStatus.demo) b.writeln('DEMO: no real purchase was made.');
  b.writeln('---------------------------');
  b.writeln('Thank you for using ALSUDAN.');
  return b.toString();
}

/// The built-in PDF font has no naira sign or fancy symbols, so they are
/// replaced with plain text in the PDF only.
String _pdfSafe(String s) => s
    .replaceAll('₦', 'NGN ')
    .replaceAll('•', '-')
    .replaceAll('—', '-')
    .replaceAll(RegExp(r'[^\x20-\x7E]'), '?');

Future<Uint8List> buildReceiptPdf(WalletTransaction t) async {
  final doc = pw.Document();
  final dark = PdfColor.fromInt(0xFF0F5B45);
  final muted = PdfColor.fromInt(0xFF6B7F76);
  final statusColor = PdfColor.fromInt(t.status.color.value);
  final credit = t.amount > 0;

  String money(double v) => 'NGN ${v.toStringAsFixed(2)}';

  pw.Widget line(String k, String v, {PdfColor? color}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(_pdfSafe(k), style: pw.TextStyle(color: muted, fontSize: 11)),
            pw.SizedBox(width: 16),
            pw.Flexible(
              child: pw.Text(
                _pdfSafe(v),
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      );

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(28),
      build: (_) => pw.Container(
        padding: const pw.EdgeInsets.all(20),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColor.fromInt(0xFFDDE7D5)),
          borderRadius: pw.BorderRadius.circular(12),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Center(
              child: pw.Text(
                'ALSUDAN',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: dark,
                ),
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Center(
              child: pw.Text('Transaction Receipt',
                  style: pw.TextStyle(fontSize: 12, color: muted)),
            ),
            pw.SizedBox(height: 16),
            pw.Center(
              child: pw.Text(
                _pdfSafe(t.status.label),
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text(
                '${credit ? '+' : '-'}${money(t.amount.abs())}',
                style: pw.TextStyle(
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                  color: dark,
                ),
              ),
            ),
            if (t.status == TxStatus.demo) ...[
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'DEMO: no real purchase or delivery was made.',
                  style: pw.TextStyle(fontSize: 10, color: statusColor),
                ),
              ),
            ],
            pw.SizedBox(height: 12),
            pw.Divider(color: PdfColor.fromInt(0xFFDDE7D5)),
            line('Type', t.title),
            if (t.note.isNotEmpty) line('Details', t.note),
            if (t.reference.isNotEmpty) line('Reference', t.reference),
            line('Date', fmtDate(t.date)),
            line('Status', t.status.label, color: statusColor),
            if (t.balanceAfter != null) line('Balance After', money(t.balanceAfter!)),
            pw.Divider(color: PdfColor.fromInt(0xFFDDE7D5)),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text('Thank you for using ALSUDAN.',
                  style: pw.TextStyle(fontSize: 10, color: muted)),
            ),
          ],
        ),
      ),
    ),
  );
  return doc.save();
}

class ReceiptPage extends StatefulWidget {
  final WalletTransaction transaction;
  const ReceiptPage({super.key, required this.transaction});

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool sharing = false;

  String get _fileBase {
    final r = widget.transaction.reference;
    return r.isEmpty ? 'ALSUDAN-receipt' : 'ALSUDAN-$r';
  }

  Widget _line(String label, String value, {Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TrText(label, style: const TextStyle(color: fuMuted)),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
      );

  Future<Uint8List?> _capturePng() async {
    final obj = _boundaryKey.currentContext?.findRenderObject();
    if (obj is! RenderRepaintBoundary) return null;
    final image = await obj.toImage(pixelRatio: 3.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  Future<void> _shareImage() async {
    if (sharing) return;
    setState(() => sharing = true);
    try {
      final bytes = await _capturePng();
      if (bytes == null) {
        if (mounted) showMessage(context, 'Could not create the receipt image.');
        return;
      }
      final dir = Directory.systemTemp;
      final file = File('${dir.path}/$_fileBase.png');
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: 'ALSUDAN receipt',
      );
    } catch (e) {
      if (mounted) showMessage(context, 'Could not share the image.');
    } finally {
      if (mounted) setState(() => sharing = false);
    }
  }

  Future<void> _sharePdf() async {
    if (sharing) return;
    setState(() => sharing = true);
    try {
      final bytes = await buildReceiptPdf(widget.transaction);
      await Printing.sharePdf(bytes: bytes, filename: '$_fileBase.pdf');
    } catch (e) {
      if (mounted) showMessage(context, 'Could not create the PDF.');
    } finally {
      if (mounted) setState(() => sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final credit = t.amount > 0;
    final st = t.status;
    return SimpleServicePage(
      title: 'Receipt',
      icon: Icons.receipt_long,
      children: [
        RepaintBoundary(
          key: _boundaryKey,
          child: Container(
            color: fuBg,
            padding: const EdgeInsets.all(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: cardDeco(20),
              child: Column(
                children: [
                  const FuLogo(size: 56),
                  const SizedBox(height: 6),
                  const FuWordmark(size: 22),
                  const SizedBox(height: 14),
                  Icon(
                    st == TxStatus.success ? Icons.check_circle : Icons.info,
                    color: st.color,
                    size: 38,
                  ),
                  const SizedBox(height: 4),
                  TrText(
                    st.label,
                    style: TextStyle(color: st.color, fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${credit ? '+' : '-'}${naira(t.amount.abs())}',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: credit ? fuAccent : fuText,
                    ),
                  ),
                  if (st == TxStatus.demo) ...[
                    const SizedBox(height: 10),
                    const InfoBanner('Demo transaction: no real purchase or delivery was made.'),
                  ],
                  const Divider(height: 26),
                  _line('Type', tr(t.title)),
                  if (t.note.isNotEmpty) _line('Details', t.note),
                  if (t.reference.isNotEmpty) _line('Reference', t.reference),
                  _line('Date', fmtDate(t.date)),
                  _line('Status', tr(st.label), color: st.color),
                  if (t.balanceAfter != null) _line('Balance After', naira(t.balanceAfter!)),
                  const Divider(height: 26),
                  const TrText(
                    'Thank you for using ALSUDAN.',
                    style: TextStyle(color: fuMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: sharing ? null : _shareImage,
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: const TrText('Share Image'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: sharing ? null : _sharePdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const TrText('Share PDF'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        PrimaryButton(
          text: 'Copy Receipt',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: buildReceiptText(t)));
            showMessage(context, 'Receipt copied to clipboard.');
          },
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const TrText('Done'),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// PROFILE, SETTINGS, SUPPORT, INFORMATION
// ===========================================================================
Future<void> _confirmLogout(BuildContext context, VoidCallback onLogout) {
  return showDialog<void>(
    context: context,
    builder: (dctx) => AlertDialog(
      title: const TrText('Logout'),
      content: const TrText('Do you want to logout from ALSUDAN?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dctx), child: const TrText('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(dctx);
            onLogout();
          },
          child: const TrText('Logout'),
        ),
      ],
    ),
  );
}

class ProfilePage extends StatelessWidget {
  final UserProfileData user;
  final VoidCallback onLogout;
  final ValueChanged<int> onTab;
  const ProfilePage({
    super.key,
    required this.user,
    required this.onLogout,
    required this.onTab,
  });

  Widget _row(IconData i, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(i, size: 18, color: fuGreen),
            const SizedBox(width: 10),
            Text('${tr(k)}: ', style: const TextStyle(color: fuMuted, fontSize: 13)),
            Expanded(
              child: Text(v,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const TrText('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(child: FuLogo(size: 90)),
          const SizedBox(height: 12),
          Center(
            child: Text(user.fullName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: fuText)),
          ),
          Center(
            child: Text('@${user.username}',
                style: const TextStyle(color: fuGreen, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: cardDeco(),
            child: Column(
              children: [
                _row(Icons.badge, 'Name', user.fullName),
                _row(Icons.phone, 'Phone', user.phone),
                _row(Icons.email, 'Email', user.email),
                _row(Icons.location_on, 'Address', user.address),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ServiceCard(
            title: 'Account settings',
            subtitle: 'Fingerprint, language and transaction PIN.',
            icon: Icons.manage_accounts,
            onTap: () => onTab(2),
          ),
          ServiceCard(
            title: 'Transaction History',
            subtitle: 'See your payments and receipts.',
            icon: Icons.history,
            onTap: () => openPage(context, const HistoryPage()),
          ),
          ServiceCard(
            title: 'Customer Support',
            subtitle: 'Get help with ALSUDAN services.',
            icon: Icons.support_agent,
            onTap: () => openPage(context, const SupportPage()),
          ),
          ServiceCard(
            title: 'Information & Legal',
            subtitle: 'About ALSUDAN, privacy and terms.',
            icon: Icons.info_outline,
            onTap: () => openPage(context, const InformationPage()),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _confirmLogout(context, onLogout),
              icon: const Icon(Icons.logout),
              label: const TrText('LOGOUT', style: TextStyle(fontWeight: FontWeight.w900)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  final VoidCallback onLogout;
  const SettingsPage({super.key, required this.onLogout});

  Future<void> _toggleBio(BuildContext context, bool want) async {
    if (want) {
      final st = await BiometricHelper.status();
      if (!context.mounted) return;
      if (st == BioStatus.notEnrolled) {
        showMessage(context,
            'No fingerprint is enrolled on this phone. Add one in your phone Settings first.');
        return;
      }
      if (st != BioStatus.ok) {
        showMessage(context, 'Fingerprint is not available on this device.');
        return;
      }
      final ok = await BiometricHelper.authenticate(
        reason: 'Confirm your fingerprint to turn this on',
      );
      if (!context.mounted) return;
      if (!ok) {
        showMessage(context, 'Fingerprint was not confirmed. Setting unchanged.');
        return;
      }
      biometricEnabled.value = true;
      await AppStore.setBool('bio_enabled', true);
      if (context.mounted) showMessage(context, 'Fingerprint login enabled.');
    } else {
      // Payments must always stay protected by PIN or fingerprint.
      if (!pinEnabled.value) {
        showMessage(context, 'Turn on PIN security first, so your payments stay protected.');
        return;
      }
      if (!PinService.isSet) {
        final created = await showCreatePinDialog(context);
        if (!created || !context.mounted) return;
      }
      biometricEnabled.value = false;
      await AppStore.setBool('bio_enabled', false);
      if (context.mounted) showMessage(context, 'Fingerprint login disabled.');
    }
  }

  Future<void> _togglePin(BuildContext context, bool want) async {
    if (want) {
      if (!PinService.isSet) {
        final created = await showCreatePinDialog(context);
        if (!created || !context.mounted) return;
      }
      pinEnabled.value = true;
      await AppStore.setBool('pin_enabled', true);
      if (context.mounted) showMessage(context, 'PIN security enabled.');
    } else {
      if (!biometricEnabled.value) {
        showMessage(context, 'Turn on fingerprint first, so your payments stay protected.');
        return;
      }
      if (PinService.isSet) {
        final ok = await verifyExistingPin(context);
        if (!ok || !context.mounted) return;
      }
      pinEnabled.value = false;
      await AppStore.setBool('pin_enabled', false);
      if (context.mounted) {
        showMessage(context, 'PIN security disabled. Payments will ask for your fingerprint.');
      }
    }
  }

  Future<void> _changePin(BuildContext context) async {
    if (PinService.isSet && !await verifyExistingPin(context)) return;
    if (!context.mounted) return;
    final ok = await showCreatePinDialog(context);
    if (ok && context.mounted) showMessage(context, 'Transaction PIN updated.');
  }

  void _about(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FuLogo(size: 72),
            const SizedBox(height: 8),
            const FuWordmark(size: 26),
            const SizedBox(height: 4),
            const Text(kTagline, style: TextStyle(color: fuMuted)),
            const SizedBox(height: 10),
            Text('${tr('Version')} $kAppVersion'),
            const SizedBox(height: 4),
            TrText(kDeveloperCredit, style: const TextStyle(color: fuMuted, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx), child: const TrText('OK')),
        ],
      ),
    );
  }

  Widget _switchCard({
    required ValueListenable<bool> listenable,
    required String title,
    required String subtitle,
    required IconData icon,
    required Future<void> Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: cardDeco(),
      child: ValueListenableBuilder<bool>(
        valueListenable: listenable,
        builder: (_, on, __) => SwitchListTile(
          activeColor: fuAccent,
          title: TrText(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: TrText(subtitle),
          secondary: Icon(icon, color: fuGreen),
          value: on,
          onChanged: (v) => onChanged(v),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const TrText('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          const SectionLabel('Security'),
          _switchCard(
            listenable: biometricEnabled,
            title: 'Fingerprint Login',
            subtitle: 'Use fingerprint on login and to confirm payments',
            icon: Icons.fingerprint,
            onChanged: (v) => _toggleBio(context, v),
          ),
          _switchCard(
            listenable: pinEnabled,
            title: 'PIN Security',
            subtitle: 'Require your PIN to confirm payments',
            icon: Icons.pin_outlined,
            onChanged: (v) => _togglePin(context, v),
          ),
          ServiceCard(
            title: 'Transaction PIN',
            subtitle: 'Create or change your 4-digit PIN.',
            icon: Icons.password,
            onTap: () => _changePin(context),
          ),
          ServiceCard(
            title: 'Reset Password / PIN',
            subtitle: 'Change or reset your security details.',
            icon: Icons.lock_reset,
            onTap: () => openPage(context, const ForgotPasswordPage()),
          ),
          const SectionLabel('Language'),
          ValueListenableBuilder<String>(
            valueListenable: appLanguage,
            builder: (_, lang, __) => Wrap(
              spacing: 8,
              children: [
                for (final l in kLanguages)
                  ChoiceChip(
                    label: Text(l),
                    selected: lang == l,
                    selectedColor: fuAccent.withOpacity(0.25),
                    onSelected: (_) => setAppLanguage(l),
                  ),
              ],
            ),
          ),
          const SectionLabel('Notification Preferences'),
          _switchCard(
            listenable: notifTxn,
            title: 'Transaction alerts',
            subtitle: 'Show your payments in Notifications',
            icon: Icons.notifications_active_outlined,
            onChanged: (v) async {
              notifTxn.value = v;
              await AppStore.setBool('notif_txn', v);
            },
          ),
          _switchCard(
            listenable: notifPromo,
            title: 'Offers and updates',
            subtitle: 'Show ALSUDAN news and offers when available',
            icon: Icons.campaign_outlined,
            onChanged: (v) async {
              notifPromo.value = v;
              await AppStore.setBool('notif_promo', v);
            },
          ),
          const SectionLabel('About'),
          ServiceCard(
            title: 'Security & Privacy',
            subtitle: 'How ALSUDAN protects your account.',
            icon: Icons.privacy_tip_outlined,
            onTap: () => openPage(context, const SecurityInfoPage()),
          ),
          ServiceCard(
            title: 'Customer Support',
            subtitle: 'Get help with ALSUDAN services.',
            icon: Icons.support_agent,
            onTap: () => openPage(context, const SupportPage()),
          ),
          ServiceCard(
            title: 'Information & Legal',
            subtitle: 'About ALSUDAN, privacy and terms.',
            icon: Icons.info_outline,
            onTap: () => openPage(context, const InformationPage()),
          ),
          ServiceCard(
            title: 'About ALSUDAN',
            subtitle: 'Version $kAppVersion',
            icon: Icons.eco_outlined,
            onTap: () => _about(context),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _confirmLogout(context, onLogout),
              icon: const Icon(Icons.logout),
              label: const TrText('LOGOUT', style: TextStyle(fontWeight: FontWeight.w900)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TrText(
              kDeveloperCredit,
              style: const TextStyle(color: fuMuted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class SecurityInfoPage extends StatelessWidget {
  const SecurityInfoPage({super.key});

  Widget _item(IconData icon, String text) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: cardDeco(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: fuGreen, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SimpleServicePage(
      title: 'Security & Privacy',
      icon: Icons.privacy_tip_outlined,
      children: [
        _item(Icons.pin_outlined,
            'Your transaction PIN is never saved as plain text. Only a salted, repeated hash is kept in the phone secure storage.'),
        _item(Icons.fingerprint,
            'Fingerprints are handled by Android. ALSUDAN never sees, copies or stores your fingerprint.'),
        _item(Icons.lock_clock,
            'After several wrong PIN or password attempts, ALSUDAN locks for a short time before you can try again.'),
        _item(Icons.timer_outlined,
            'If the app stays in the background for 5 minutes, you are logged out and must sign in again.'),
        _item(Icons.verified_user_outlined,
            'Every payment needs your PIN or fingerprint. At least one of them always stays on.'),
        _item(Icons.visibility_off_outlined,
            'Passwords, PINs and tokens are never written to logs or shown on screen.'),
      ],
    );
  }
}

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const TrText('Support')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ServiceCard(
            title: 'Customer Support',
            subtitle: 'Get help with ALSUDAN services.',
            icon: Icons.support_agent,
            onTap: () => showMessage(context, 'Customer support selected.'),
          ),
          ServiceCard(
            title: 'WhatsApp Support',
            subtitle: 'Chat with us on WhatsApp.',
            icon: Icons.chat,
            onTap: () => showMessage(context, 'WhatsApp link not configured yet.'),
          ),
          ServiceCard(
            title: 'Information',
            subtitle: 'About ALSUDAN & legal terms.',
            icon: Icons.info_outline,
            onTap: () => openPage(context, const InformationPage()),
          ),
          ServiceCard(
            title: 'Contact Us',
            subtitle: 'Send a message to ALSUDAN support.',
            icon: Icons.email_outlined,
            onTap: () => showMessage(context, 'Contact support selected.'),
          ),
        ],
      ),
    );
  }
}

class InformationPage extends StatelessWidget {
  const InformationPage({super.key});

  Widget _section(String title, String body) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: fuDark)),
            const Divider(height: 18),
            Text(body, style: const TextStyle(color: fuText, fontSize: 13, height: 1.5)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SimpleServicePage(
      title: 'Information & Legal',
      icon: Icons.info_outline,
      children: [
        const FuWordmark(size: 26),
        const SizedBox(height: 4),
        const Text('By SUDATELL NIG LIMITED',
            style: TextStyle(color: fuMuted, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _section(
          '1. About Us',
          'ALSUDAN is a technology and digital-services brand operated by SUDATELL NIG LIMITED, providing telecommunications products, digital services, software solutions, solar products and other technology-enabled services.\n\nCAC RC No.: 1738149\nTIN: 23756027-0001\n\nOur goal is to make technology, digital payments and essential services simple, accessible and convenient across Nigeria.',
        ),
        _section(
          '2. Legal & Regulatory Information',
          'Legal Company: SUDATELL NIG LIMITED\nCAC Registration: RC 1738149\nTIN: 23756027-0001\nNCC Class Licence: CL/S&I/190/23 (Category: Sales & Installation)\n\nThe NCC licence is subject to its applicable terms and conditions. It does not mean that the licence independently authorises every service available through the platform.\n\nSome services depend on third-party providers, including telecommunications networks, payment providers, electricity providers, television operators and examination bodies.',
        ),
        _section(
          '3. Privacy Policy',
          'ALSUDAN respects your privacy. We may collect your name, phone number, email, account details and transaction information to create and manage accounts, process transactions, provide support, prevent fraud and comply with legal requirements. We do not sell your personal information for advertising.\n\nPrivacy enquiries: support@sudawa.com',
        ),
        _section(
          '4. Terms & Conditions',
          'By creating an account or using ALSUDAN, you agree to these Terms.\n\nAccount Security: Provide accurate information and keep your credentials and PIN secure.\n\nTransactions: Always verify details before confirming. Transactions processed with incorrect details supplied by customers may not be reversible.\n\nProhibited Use: Fraud, money laundering, impersonation and system attacks are strictly prohibited.\n\nGoverning Law: Federal Republic of Nigeria.',
        ),
        Text('${tr('Version')} $kAppVersion', style: const TextStyle(color: fuMuted)),
        const SizedBox(height: 4),
        TrText(kDeveloperCredit, style: const TextStyle(color: fuMuted, fontSize: 12)),
      ],
    );
  }
}
