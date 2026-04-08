import 'package:get/get_navigation/get_navigation.dart';

class Language extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    //English
    'en_US': {
      'title': 'Hellow World',
      'email': 'Enter your email',
      'internet_exception':
          "We'er unale to show results.\nplease check yoour data\nconenction",
      'general_exception':
          "We'er unale to process your request.\nplease try again later.",
      'Welcome_Massage': 'Welcome to the app',
      'login': 'Login',
      'sginup': 'Sginup',
      'password': 'Enter your password',
      'email_required': 'Email is Required',
      'password_required': 'Password is Required',
      'password_lenght': 'Password must be 6 characters'
      
    },

    //urdu
    'ur_PK': {
      'title': 'ہیلو ورلڈ',
      'email': 'اپنا ای میل درج کریں۔',
      'internet_exception':
          'ہم نتائج دکھانے سے قاصر ہیں۔\nبراہ کرم اپنے ڈیٹا کو چیک کریں\nکنکشن',
      'Welcome_Massage': 'ایپ میں خوش آمدید',
      'password': 'اپنا پاس ورڈ درج کریں۔',
      'login': 'لاگ ان',
      'sginup': 'لسائن اپ کریں',
      'email_required': 'ای میل درکار ہے۔',
      'password_required': 'پاس ورڈ درکار ہے۔',
      'password_lenght': 'پاس ورڈ 6 حروف کا ہونا چاہیے۔'
    },
  };
}
