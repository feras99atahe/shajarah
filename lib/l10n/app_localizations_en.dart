// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Shajarah';

  @override
  String get tagline => 'Your Family Tree';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get enterPhone => 'Enter your phone number';

  @override
  String get phoneHint => '+966 5XX XXX XXXX';

  @override
  String get continueBtn => 'Continue';

  @override
  String get enterOtp => 'Enter verification code';

  @override
  String otpSentTo(String phone) {
    return 'Code sent to $phone';
  }

  @override
  String get verify => 'Verify';

  @override
  String get resendCode => 'Resend code';

  @override
  String get adminLogin => 'Admin / Auditor Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get setupProfile => 'Setup Your Profile';

  @override
  String get fullName => 'Full name';

  @override
  String get fullNameAr => 'Full name (Arabic)';

  @override
  String get save => 'Save';

  @override
  String get familyTree => 'Family Tree';

  @override
  String get members => 'Members';

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Search by name...';

  @override
  String get relationships => 'Relationships';

  @override
  String get findRelationship => 'Find Relationship';

  @override
  String get selectFirstMember => 'Select first member';

  @override
  String get selectSecondMember => 'Select second member';

  @override
  String get find => 'Find';

  @override
  String get addMember => 'Add Member';

  @override
  String get editMember => 'Edit Member';

  @override
  String get gender => 'Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get birthDate => 'Date of birth';

  @override
  String get deathDate => 'Date of death';

  @override
  String get birthPlace => 'Place of birth';

  @override
  String get phone => 'Phone number';

  @override
  String get notes => 'Notes';

  @override
  String get addPhoto => 'Add Photo';

  @override
  String get parents => 'Parents';

  @override
  String get children => 'Children';

  @override
  String get spouse => 'Spouse';

  @override
  String get siblings => 'Siblings';

  @override
  String get addParent => 'Add parent';

  @override
  String get addChild => 'Add child';

  @override
  String get addSpouse => 'Add spouse';

  @override
  String get noMembersYet => 'No members yet';

  @override
  String get addFirstMember => 'Add the first member of your family tree';

  @override
  String get relationshipPath => 'Relationship path';

  @override
  String get noRelationshipFound => 'No relationship path found';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get arabic => 'Arabic';

  @override
  String get english => 'English';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get tryAgain => 'Try again';

  @override
  String get loading => 'Loading...';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get confirmDelete => 'Are you sure you want to delete?';

  @override
  String get alive => 'Alive';

  @override
  String get deceased => 'Deceased';

  @override
  String get age => 'Age';

  @override
  String get years => 'years';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get familyCreatedBy => 'Family created by';

  @override
  String get createFamily => 'Create Family';

  @override
  String get familyName => 'Family name';

  @override
  String get joinFamily => 'Join existing family';

  @override
  String get familyCode => 'Family code';
}
