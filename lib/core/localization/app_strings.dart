// lib/core/localization/app_strings.dart

class AppStrings {
  static String locale = 'en';
  static bool get isArabic => locale == 'ar';

  // ── App-wide ──
  static String get appName => isArabic ? 'عقار' : 'AQAR';
  static String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  static String get save => isArabic ? 'حفظ' : 'Save';
  static String get delete => isArabic ? 'حذف' : 'Delete';
  static String get confirm => isArabic ? 'تأكيد' : 'Confirm';
  static String get yes => isArabic ? 'نعم' : 'Yes';
  static String get no => isArabic ? 'لا' : 'No';
  static String get ok => isArabic ? 'موافق' : 'OK';
  static String get error => isArabic ? 'خطأ' : 'Error';
  static String get success => isArabic ? 'نجاح' : 'Success';
  static String get loading => isArabic ? 'جاري التحميل...' : 'Loading...';
  static String get retry => isArabic ? 'إعادة المحاولة' : 'Retry';
  static String get noData => isArabic ? 'لا توجد بيانات' : 'No data available';
  static String get search => isArabic ? 'بحث' : 'Search';
  static String get submit => isArabic ? 'إرسال' : 'Submit';
  static String get next => isArabic ? 'التالي' : 'Next';
  static String get back => isArabic ? 'رجوع' : 'Back';
  static String get done => isArabic ? 'تم' : 'Done';
  static String get clear => isArabic ? 'مسح' : 'Clear';
  static String get filter => isArabic ? 'تصفية' : 'Filter';
  static String get sort => isArabic ? 'ترتيب' : 'Sort';
  static String get viewAll => isArabic ? 'عرض الكل' : 'View All';
  static String get noResults =>
      isArabic ? 'لا توجد نتائج' : 'No results found';
  static String get noResultsDesc => isArabic
      ? 'حاول تعديل معايير البحث'
      : 'Try adjusting your search criteria';
  static String get openInMaps =>
      isArabic ? 'فتح في خرائط جوجل' : 'Open in Google Maps';
  static String get price => isArabic ? 'السعر' : 'Price';
  static String get location => isArabic ? 'الموقع' : 'Location';
  static String get phone => isArabic ? 'الهاتف' : 'Phone';
  static String get email => isArabic ? 'البريد الإلكتروني' : 'Email';
  static String get password => isArabic ? 'كلمة المرور' : 'Password';
  static String get confirmPassword =>
      isArabic ? 'تأكيد كلمة المرور' : 'Confirm Password';
  static String get type => isArabic ? 'النوع' : 'Type';
  static String get size => isArabic ? 'المساحة' : 'Size';
  static String get furnished => isArabic ? 'مفروش' : 'Furnished';
  static String get verified => isArabic ? 'موثق' : 'Verified';
  static String get notVerified => isArabic ? 'غير موثق' : 'Not Verified';
  static String get bedrooms => isArabic ? 'غرف النوم' : 'Bedrooms';
  static String get bathrooms => isArabic ? 'الحمامات' : 'Bathrooms';
  static String get beds => isArabic ? 'الأسرة' : 'Beds';
  static String get ratings => isArabic ? 'التقييمات' : 'Ratings & Reviews';
  static String get noReviews =>
      isArabic ? 'لا توجد تقييمات مكتوبة بعد' : 'No written reviews yet';
  static String get share => isArabic ? 'مشاركة' : 'Share';

  // ── Auth ──
  static String get login => isArabic ? 'تسجيل الدخول' : 'Login';
  static String get signup => isArabic ? 'إنشاء حساب' : 'Sign Up';
  static String get logout => isArabic ? 'تسجيل الخروج' : 'Logout';
  static String get logoutConfirm => isArabic
      ? 'هل أنت متأكد من تسجيل الخروج؟'
      : 'Are you sure you want to logout?';
  static String get forgotPassword =>
      isArabic ? 'نسيت كلمة المرور؟' : 'Forgot Password?';
  static String get resetPassword =>
      isArabic ? 'إعادة تعيين كلمة المرور' : 'Reset Password';
  static String get sendResetLink =>
      isArabic ? 'إرسال رابط إعادة التعيين' : 'Send Reset Link';
  static String get otp => isArabic ? 'رمز التحقق' : 'OTP';
  static String get verifyOtp => isArabic ? 'تأكيد رمز التحقق' : 'Verify OTP';
  static String get profileInfo =>
      isArabic ? 'معلومات الملف الشخصي' : 'Profile Information';
  static String get editProfile =>
      isArabic ? 'تعديل الملف الشخصي' : 'Edit Profile';
  static String get changePassword =>
      isArabic ? 'تغيير كلمة المرور' : 'Change Password';
  static String get firstName => isArabic ? 'الاسم الأول' : 'First Name';
  static String get secondName => isArabic ? 'الاسم الثاني' : 'Second Name';
  static String get fullName => isArabic ? 'الاسم الكامل' : 'Full Name';
  static String get loginRequired =>
      isArabic ? 'يجب تسجيل الدخول للتواصل' : 'You must log in to contact';
  static String get loginToContact =>
      isArabic ? 'تسجيل الدخول للتواصل' : 'Log in to contact';
  static String get verifyRequired =>
      isArabic ? 'يرجى توثيق الحساب أولاً' : 'Please verify your account first';
  static String get verifyAccountPrompt => isArabic
      ? 'عذراً، يجب تسجيل الدخول وتوثيق الحساب أولاً\nلاتخاذ هذا الإجراء.'
      : 'Sorry, you must log in and verify\nyour account to proceed.';

  // ── Home ──
  static String get forSale => isArabic ? 'للبيع' : 'For Sale';
  static String get forRent => isArabic ? 'للإيجار' : 'For Rent';
  static String get sponsored => isArabic ? 'معلن' : 'Sponsored';
  static String get nearby => isArabic ? 'قريب منك' : 'Near You';
  static String get featured => isArabic ? 'مميز' : 'Featured';
  static String get noProperties =>
      isArabic ? 'لا توجد عقارات' : 'No properties available';

  // ── Property Detail ──
  static String get propertyInfo =>
      isArabic ? 'معلومات العقار' : 'Property Info';
  static String get aboutProperty =>
      isArabic ? 'عن العقار' : 'About this property';
  static String get noDescription =>
      isArabic ? 'لا يوجد وصف متاح' : 'No description available.';
  static String get salePrice => isArabic ? 'سعر البيع' : 'Sale Price';
  static String get perMonth => isArabic ? '/ شهرياً' : '/ month';
  static String get perDay => isArabic ? '/ يومياً' : '/ day';
  static String get monthlyRent => isArabic ? 'الإيجار الشهري' : 'Monthly Rent';
  static String get dailyRent => isArabic ? 'الإيجار اليومي' : 'Daily Rent';
  static String get total => isArabic ? 'الإجمالي' : 'Total';
  static String get installmentCalc =>
      isArabic ? 'حاسبة الأقساط' : 'Installment Calculator';
  static String get downPayment => isArabic ? 'المقدم' : 'Down Payment';
  static String get numberOfYears =>
      isArabic ? 'عدد السنوات' : 'Number of Years';
  static String get monthlyPayment =>
      isArabic ? 'الدفعة الشهرية' : 'Monthly Payment';
  static String get totalPayment =>
      isArabic ? 'الدفعة الكلية' : 'Total Payment';
  static String get fromDate => isArabic ? 'من' : 'From';
  static String get toDate => isArabic ? 'إلى' : 'To';
  static String get daysCount => isArabic ? 'عدد الأيام' : 'Number of Days';
  static String get totalCost => isArabic ? 'التكلفة الإجمالية' : 'Total Cost';
  static String get moveInDate => isArabic ? 'تاريخ الانتقال' : 'Move-in Date';
  static String get selectDate => isArabic ? 'اختر التاريخ' : 'Select Date';
  static String get contactOwner =>
      isArabic ? 'تواصل مع المالك' : 'Contact Owner';
  static String get chat => isArabic ? 'محادثة' : 'Chat';
  static String get sendMessage => isArabic ? 'إرسال رسالة' : 'Send Message';
  static String get editProperty => isArabic ? 'تعديل العقار' : 'Edit Property';
  static String get promote =>
      isArabic ? 'ترقية العقار (250 ج.م)' : 'Promote (250 EGP)';
  static String get unlist => isArabic ? 'إلغاء النشر' : 'Unlist';
  static String get unlistConfirm => isArabic
      ? 'هل أنت متأكد من إلغاء نشر هذا العقار؟'
      : 'Are you sure you want to unlist this property?';
  static String get deleteConfirm => isArabic
      ? 'هل أنت متأكد من حذف هذا العقار؟ لا يمكن التراجع عن هذا الإجراء.'
      : 'Are you sure you want to delete this property? This cannot be undone.';
  static String get sold => isArabic ? 'تم البيع' : 'Sold';
  static String get rented => isArabic ? 'تم التأجير' : 'Rented';
  static String get propertyUnavailable => isArabic
      ? 'هذا العقار غير متاح حالياً'
      : 'This property is currently unavailable';
  static String get notAvailable => isArabic ? 'غير متاح' : 'Not Available';
  static String get active => isArabic ? 'نشط' : 'Active';
  static String get inactive => isArabic ? 'غير نشط' : 'Inactive';
  static String get fixedPrice => isArabic ? 'سعر ثابت' : 'Fixed Price';
  static String get yourProperty => isArabic ? 'عقارك' : 'Your Property';
  static String get perNight => isArabic ? '/ ليلة' : '/ night';
  static String get sendRentRequest =>
      isArabic ? 'إرسال طلب إيجار' : 'Send Rent Request';
  static String get viewLease => isArabic ? 'عرض العقود' : 'View My Leases';

  // ── Favorites ──
  static String get myFavorites => isArabic ? 'المفضلة' : 'My Favorites';
  static String get noFavorites =>
      isArabic ? 'لا توجد مفضلة بعد' : 'No favorites yet.';
  static String get noFavoritesDesc => isArabic
      ? 'ابدأ بإضافة العقارات التي تعجبك!'
      : 'Start adding properties you like!';

  // ── Profile ──
  static String get myProperty => isArabic ? 'عقاراتي' : 'My Property';
  static String get myPropertySub =>
      isArabic ? 'عقاراتي المسجلة' : 'My saved listings';
  static String get myRequest => isArabic ? 'طلباتي' : 'My Requests';
  static String get myRequestSub => isArabic
      ? 'عرض طلبات الإيجار المرسلة والمستلمة'
      : 'View sent & received requests';
  static String get invoices => isArabic ? 'الفواتير' : 'Invoices';
  static String get invoicesSub =>
      isArabic ? 'عرض فواتيرك' : 'View your invoices';
  static String get wallet => isArabic ? 'المحفظة' : 'Wallet';
  static String get walletSub =>
      isArabic ? 'عرض المحفظة والمعاملات' : 'View wallet & transactions';
  static String get myChats => isArabic ? 'محادثاتي' : 'My Chats';
  static String get myChatsSub => isArabic
      ? 'رسائل مع الملاك والمستأجرين'
      : 'Messages with owners & tenants';
  static String get contactUs => isArabic ? 'اتصل بنا' : 'Contact Us';
  static String get contactUsSub =>
      isArabic ? 'أرسل لنا بريداً إلكترونياً' : 'Send us an email';

  // ── Add Property ──
  static String get addProperty => isArabic ? 'إضافة عقار' : 'Add Property';
  static String get editPropertyTitle =>
      isArabic ? 'تعديل العقار' : 'Edit Property';
  static String get propertyName => isArabic ? 'اسم العقار' : 'Property Name';
  static String get propertyDesc =>
      isArabic ? 'وصف العقار' : 'Property Description';
  static String get propertyType => isArabic ? 'نوع العقار' : 'Property Type';
  static String get apartment => isArabic ? 'شقة' : 'Apartment';
  static String get villa => isArabic ? 'فيلا' : 'Villa';
  static String get studio => isArabic ? 'استوديو' : 'Studio';
  static String get house => isArabic ? 'منزل' : 'House';
  static String get physicalTypeHint =>
      isArabic ? 'اختر نوع العقار' : 'Select property type';
  static String get listingTypeLabel =>
      isArabic ? 'نوع الإعلان' : 'Listing Type';
  static String get pricing => isArabic ? 'السعر' : 'Pricing';
  static String get pricingUnitLabel =>
      isArabic ? 'وحدة السعر' : 'Pricing Unit';
  static String get month => isArabic ? 'شهر' : 'Month';
  static String get day => isArabic ? 'يوم' : 'Day';
  static String get year => isArabic ? 'سنة' : 'Year';
  static String get priceValue => isArabic ? 'السعر' : 'Price';
  static String get pricePerDayLabel =>
      isArabic ? 'السعر لليوم' : 'Price per Day';
  static String get photos => isArabic ? 'الصور' : 'Photos';
  static String get addPhotos => isArabic ? 'إضافة صور' : 'Add Photos';
  static String get ownershipProof =>
      isArabic ? 'مستندات الملكية' : 'Ownership Documents';
  static String get basicInfo =>
      isArabic ? 'المعلومات الأساسية' : 'Basic Information';
  static String get media => isArabic ? 'الوسائط' : 'Media';
  static String get plan => isArabic ? 'الخطة' : 'Plan';
  static String get map => isArabic ? 'الخريطة' : 'Map';
  static String get documents => isArabic ? 'المستندات' : 'Documents';
  static String get invoice => isArabic ? 'الفاتورة' : 'Invoice';
  static String get photosTip => isArabic ? 'نصائح التصوير' : 'Photo Tips';
  static String get step => isArabic ? 'خطوة' : 'Step';

  // ── Sponsor / Payment ──
  static String get promoteProperty =>
      isArabic ? 'ترقية العقار' : 'Promote Property';
  static String get selectPlan => isArabic ? 'اختر الباقة' : 'Select Plan';
  static String get oneMonth => isArabic ? 'شهر واحد' : '1 Month';
  static String get threeMonths => isArabic ? 'ثلاثة أشهر' : '3 Months';
  static String get sixMonths => isArabic ? 'ستة أشهر' : '6 Months';
  static String get egp => isArabic ? 'ج.م' : 'EGP';
  static String get payment => isArabic ? 'الدفع' : 'Payment';
  static String get payNow => isArabic ? 'ادفع الآن' : 'Pay Now';
  static String get paymentSuccess =>
      isArabic ? 'تمت عملية الدفع بنجاح' : 'Payment successful';
  static String get paymentFailed =>
      isArabic ? 'فشلت عملية الدفع' : 'Payment failed';
  static String get transactionId =>
      isArabic ? 'رقم العملية' : 'Transaction ID';
  static String get returnToApp => isArabic ? 'العودة' : 'Return';

  // ── Rent Requests ──
  static String get pending => isArabic ? 'قيد الانتظار' : 'Pending';
  static String get accepted => isArabic ? 'مقبول' : 'Accepted';
  static String get rejected => isArabic ? 'مرفوض' : 'Rejected';
  static String get cancelled => isArabic ? 'ملغي' : 'Cancelled';
  static String get paymentPending =>
      isArabic ? 'في انتظار الدفع' : 'Payment Pending';
  static String get paid => isArabic ? 'مدفوع' : 'Paid';

  // ── Search / Filter ──
  static String get searchProperties =>
      isArabic ? 'بحث في العقارات' : 'Search Properties';
  static String get searchHint =>
      isArabic ? 'ابحث بالموقع...' : 'Search by location...';
  static String get minPrice => isArabic ? 'أقل سعر' : 'Min Price';
  static String get maxPrice => isArabic ? 'أعلى سعر' : 'Max Price';
  static String get apply => isArabic ? 'تطبيق' : 'Apply';
  static String get reset => isArabic ? 'إعادة تعيين' : 'Reset';

  // ── Chat ──
  static String get typeMessage =>
      isArabic ? 'اكتب رسالة...' : 'Type a message...';
  static String get send => isArabic ? 'إرسال' : 'Send';
  static String get noMessages =>
      isArabic ? 'لا توجد رسائل بعد' : 'No messages yet';
  static String get startChatting =>
      isArabic ? 'ابدأ المحادثة' : 'Start chatting';

  // ── AI Assistant ──
  static String get aiAssistant => isArabic ? 'المساعد الذكي' : 'AI Assistant';
  static String get askQuestion =>
      isArabic ? 'اسأل سؤالاً...' : 'Ask a question...';
  static String get aiAssistantSubtitle =>
      isArabic ? 'مساعد العقارات الذكي' : 'AI Property Assistant';
  static String get aiPoweredByAi =>
      isArabic ? 'مدعوم بالذكاء الاصطناعي' : 'Powered by AI';
  static String get aiEmptyPrompt => isArabic
      ? 'مرحباً! ما نوع العقار الذي تبحث عنه؟'
      : 'Hello! What kind of property are you looking for?';
  static String get aiWelcome => isArabic
      ? 'أهلاً بك في مساعد عقار الذكي!'
      : 'Welcome to Aqar AI Assistant!';
  static String get aiStarterPrompt => isArabic
      ? 'إزيك، تقدر تساعدني أختار العقار المناسب ليا؟'
      : 'Hi, can you help me choose the right property for me?';
  static String get aiWelcomeDesc => isArabic
      ? 'ابحث عن عقارك المثالي باللغة العربية\n(مثال: هاتلي شقة في مصر الجديدة)'
      : 'Find your perfect property\n(e.g., "Show me apartments in New Cairo")';
  static String get aiTypeMessage =>
      isArabic ? 'اكتب رسالتك هنا...' : 'Type your message here...';
  static String get aiClearChat => isArabic ? 'مسح المحادثة' : 'Clear Chat';
  static String get aiError => isArabic
      ? 'خدمة المساعد الذكي غير متوفرة حالياً'
      : 'AI assistant is currently unavailable. Please try again later.';

  // ── Errors ──
  static String get failedToLoad =>
      isArabic ? 'فشل في تحميل البيانات' : 'Failed to load data';
  static String get failedToLoadProperty => isArabic
      ? 'فشل في تحميل تفاصيل العقار'
      : 'Failed to load property details';
  static String get failedToLoadFavorites =>
      isArabic ? 'فشل في تحميل المفضلة' : 'Failed to load favorites';
  static String get networkError =>
      isArabic ? 'خطأ في الاتصال بالشبكة' : 'Network error';
  static String get pleaseTryAgain =>
      isArabic ? 'يرجى المحاولة مرة أخرى' : 'Please try again';
  static String get somethingWentWrong =>
      isArabic ? 'حدث خطأ ما' : 'Something went wrong';
}
