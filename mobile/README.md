# War Gaming — تطبيق الهاتف (Flutter)

## أول مرة تعمل على هذا المشروع

هذا المجلد يحتوي فقط على كود Dart المشترك (`lib/`) — لم يتم توليد مجلدات
المنصات (`android/`, `ios/`) لأن هذه البيئة لا تملك Flutter SDK. لتشغيل
المشروع فعليًا على جهازك:

```bash
cd mobile
flutter create .          # يولّد android/ و ios/ و web/ إلخ حول lib/ الحالي
flutter pub get
flutter run
```

## أذونات لازمة لوضع البلوتوث (nearby_connections)

بعد `flutter create .`, أضف إلى `android/app/src/main/AndroidManifest.xml`
(داخل `<manifest>`, قبل `<application>`):

```xml
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

ولـ iOS في `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>نحتاج البلوتوث للعب مع لاعبين قريبين بدون إنترنت</string>
<key>NSLocalNetworkUsageDescription</key>
<string>نحتاج الشبكة المحلية للعب مع لاعبين قريبين</string>
```

راجع توثيق حزمة [`nearby_connections`](https://pub.dev/packages/nearby_connections)
لأي تحديثات على الأذونات المطلوبة حسب إصدار Android المستهدف.

## تشغيل الخادم محليًا للتجربة على وضع "أونلاين"

```bash
cd ../server
npm install
npm start   # يستمع على ws://localhost:8080
```

الجهاز الذي يشغّل المحاكي (emulator) على نفس الحاسوب يستطيع الوصول عبر
`ws://10.0.2.2:8080` (أندرويد) بدلاً من `localhost` — عدّل `kDefaultServerUrl`
في `lib/screens/lobby_screen.dart` عند الحاجة. لتجربة حقيقية بين هاتفين
منفصلين، انشر الخادم على مزوّد استضافة (Render, Fly.io, VPS بدور، إلخ) واستخدم
عنوان `wss://` الخاص به.

## ملاحظة مهمة

كود Dart هنا لم يُجمَّع فعليًا في بيئة الإنشاء (لا Flutter SDK متاح)، فرغم
أنه اتُّبِع فيه أسلوب Flame/Flutter القياسي بعناية، شغّل `flutter analyze`
و`flutter test` بعد `flutter pub get` لتصحيح أي خطأ تجميع طفيف قبل الاعتماد
عليه.
