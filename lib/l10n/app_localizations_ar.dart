// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'شجرة';

  @override
  String get tagline => 'شجرة عائلتك';

  @override
  String get welcomeBack => 'مرحباً بعودتك';

  @override
  String get enterPhone => 'أدخل رقم هاتفك';

  @override
  String get phoneHint => '+966 5XX XXX XXXX';

  @override
  String get continueBtn => 'متابعة';

  @override
  String get enterOtp => 'أدخل رمز التحقق';

  @override
  String otpSentTo(String phone) {
    return 'تم إرسال الرمز إلى $phone';
  }

  @override
  String get verify => 'تحقق';

  @override
  String get resendCode => 'إعادة إرسال الرمز';

  @override
  String get adminLogin => 'تسجيل دخول المشرف';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get login => 'دخول';

  @override
  String get logout => 'خروج';

  @override
  String get setupProfile => 'إعداد ملفك الشخصي';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get fullNameAr => 'الاسم الكامل بالعربية';

  @override
  String get save => 'حفظ';

  @override
  String get familyTree => 'شجرة العائلة';

  @override
  String get members => 'الأعضاء';

  @override
  String get search => 'بحث';

  @override
  String get searchHint => 'ابحث بالاسم...';

  @override
  String get relationships => 'العلاقات';

  @override
  String get findRelationship => 'اكتشف صلة القرابة';

  @override
  String get selectFirstMember => 'اختر الشخص الأول';

  @override
  String get selectSecondMember => 'اختر الشخص الثاني';

  @override
  String get find => 'بحث';

  @override
  String get addMember => 'إضافة عضو';

  @override
  String get editMember => 'تعديل العضو';

  @override
  String get gender => 'الجنس';

  @override
  String get male => 'ذكر';

  @override
  String get female => 'أنثى';

  @override
  String get birthDate => 'تاريخ الميلاد';

  @override
  String get deathDate => 'تاريخ الوفاة';

  @override
  String get birthPlace => 'مكان الميلاد';

  @override
  String get phone => 'رقم الهاتف';

  @override
  String get notes => 'ملاحظات';

  @override
  String get addPhoto => 'إضافة صورة';

  @override
  String get parents => 'الوالدان';

  @override
  String get children => 'الأبناء';

  @override
  String get spouse => 'الزوج/الزوجة';

  @override
  String get siblings => 'الإخوة والأخوات';

  @override
  String get addParent => 'إضافة والد';

  @override
  String get addChild => 'إضافة ابن';

  @override
  String get addSpouse => 'إضافة زوج/زوجة';

  @override
  String get noMembersYet => 'لا يوجد أعضاء بعد';

  @override
  String get addFirstMember => 'أضف أول عضو في شجرة عائلتك';

  @override
  String get relationshipPath => 'مسار القرابة';

  @override
  String get noRelationshipFound => 'لم يتم العثور على صلة قرابة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'الإنجليزية';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get errorOccurred => 'حدث خطأ';

  @override
  String get tryAgain => 'حاول مجدداً';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get confirmDelete => 'هل أنت متأكد من الحذف؟';

  @override
  String get alive => 'حي';

  @override
  String get deceased => 'متوفى';

  @override
  String get age => 'العمر';

  @override
  String get years => 'سنة';

  @override
  String get noResultsFound => 'لا توجد نتائج';

  @override
  String get familyCreatedBy => 'العائلة أنشأها';

  @override
  String get createFamily => 'إنشاء عائلة';

  @override
  String get familyName => 'اسم العائلة';

  @override
  String get joinFamily => 'الانضمام لعائلة موجودة';

  @override
  String get familyCode => 'رمز العائلة';
}
