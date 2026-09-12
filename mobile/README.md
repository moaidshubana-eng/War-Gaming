# War Gaming — تطبيق الهاتف (Flutter)

## التشغيل

مجلدا `android/` و`ios/` مُولَّدان وجاهزان بالفعل (بما في ذلك أذونات
البلوتوث/الموقع/الشبكة أدناه)، فقط:

```bash
cd mobile
flutter pub get
flutter run
```

تم التحقق من هذا المشروع فعليًا بتثبيت Flutter SDK: `flutter analyze` لا
يُظهر أي مشاكل، و`flutter test` ينجح بالكامل (6/6، منطق التحقق من الإصابات
واختبار واجهة يبني الشاشة الرئيسية). لم يُختبر بعد: بناء APK/IPA فعلي (يحتاج
Android SDK / Xcode)، واللعب الحقيقي عبر بلوتوث بين جهازين (المحاكيات عادة
لا تدعمه).

## أذونات وضع البلوتوث (nearby_connections)

مُضافة مسبقًا في:

- `android/app/src/main/AndroidManifest.xml`: `BLUETOOTH*`,
  `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `ACCESS_WIFI_STATE`,
  `CHANGE_WIFI_STATE`, `INTERNET`.
- `ios/Runner/Info.plist`: `NSBluetoothAlwaysUsageDescription`,
  `NSBluetoothPeripheralUsageDescription`, `NSLocalNetworkUsageDescription`,
  `NSLocationWhenInUseUsageDescription`.

راجع توثيق حزمة [`nearby_connections`](https://pub.dev/packages/nearby_connections)
لأي تحديثات على الأذونات المطلوبة حسب إصدار Android المستهدف مستقبلاً.

## تشغيل الخادم محليًا للتجربة على وضع "أونلاين"

```bash
cd ../server
npm install
npm start   # يستمع على ws://localhost:8080
```

الجهاز الذي يشغّل المحاكي (emulator) على نفس الحاسوب يستطيع الوصول عبر
`ws://10.0.2.2:8080` (أندرويد) بدلاً من `localhost` — عدّل `kDefaultServerUrl`
في `lib/screens/lobby_screen.dart` عند الحاجة. لتجربة حقيقية بين هاتفين
منفصلين، انشر الخادم على مزوّد استضافة (Render, Fly.io, VPS، إلخ) واستخدم
عنوان `wss://` الخاص به.

## ما يحتاج اختبارًا ميدانيًا (على أجهزة حقيقية)

- **البلوتوث**: استدعاءات `nearby_connections` في
  `lib/network/bluetooth_connection.dart` صحيحة من ناحية التحليل الساكن
  (المشروع بأكمله يمر عبر `flutter analyze` بلا أخطاء)، لكن سلوكها الفعلي
  عند التقاء جهازين حقيقيين (اكتشاف، اتصال، فقدان الاتصال) لم يُختبر هنا.
- **تجربة اللعب الفعلية**: التحكم باللمس، سرعة الحركة، ودقة الإصابة تحتاج
  ضبطًا بعد تجربتها على شاشة حقيقية بالحجم واللمس الفعليين.
