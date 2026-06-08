# 🚀 أوامر النشر الدقيقة

## خطوة 1️⃣: الذهاب للـ Folder

```bash
cd c:\FinalProject\opticell
```

---

## خطوة 2️⃣: اختبر التغييرات محلياً

### تحقق من الملفات المعدلة:
```bash
git status
```

### يجب ترى:
```
modified:   opticell-backend/server.js
modified:   lib/screens/root_screen.dart
modified:   lib/screens/common.dart
modified:   android/app/src/main/AndroidManifest.xml
```

### وملفات جديدة:
```
Untracked files:
  android/app/src/main/res/xml/network_security_config.xml
```

---

## خطوة 3️⃣: Add الملفات

```bash
git add .
```

---

## خطوة 4️⃣: Commit الملفات

```bash
git commit -m "Fix: Railway 502 - Simplify backend, add fallback chain, fix Android 9+ HTTPS"
```

---

## خطوة 5️⃣: Push إلى GitHub

```bash
git push origin main
```

### انتظر هنا:
- ✅ GitHub receive the code: ~10 ثوانٍ
- ✅ Railway detect new deploy: ~30 ثانية
- ✅ Railway restart server: ~2 دقائق

---

## خطوة 6️⃣: اختبر الـ API

### أ) قبل Deploy (تحقق من الـ URL):
```bash
# في أي متصفح أو Terminal:
curl https://opticell-backend-production.up.railway.app/api/reports
```

### يجب يرجع:
```json
[
  {
    "id": "1",
    "title": "Sample Report 1",
    "dateTime": "2024-01-01T10:00:00Z",
    "status": "completed",
    "temperature": 25.5,
    "pressure": 1013.25,
    "description": "Sample report data"
  },
  ...
]
```

### ب) إذا رجع error:
```
❌ يعني Railway لم تنتهي من deployment
⏳ انتظر 2-3 دقائق وأعد المحاولة
```

---

## خطوة 7️⃣: بناء APK

```bash
# Clean الـ build القديم
flutter clean

# Get dependencies
flutter pub get

# Build APK
flutter build apk --release
```

### سيكون الـ APK في:
```
build\app\outputs\flutter-apk\app-release.apk
```

---

## خطوة 8️⃣: تثبيت على الجهاز

### أ) عبر ADB:
```bash
# تأكد من توصيل الهاتف
adb devices

# ثبّت الـ APK
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

### ب) أو يدويّاً:
```
1. انسخ APK من المسار أعلاه
2. انقل للهاتف
3. اضغط عليه لتثبيتها
```

---

## خطوة 9️⃣: اختبر التطبيق

### على الهاتف:
```
1. شغّل التطبيق
2. انتظر دقيقة
3. اختبر البيانات (Dashboard يجب يحتوي على بيانات)
```

### في Terminal (اختياري):
```bash
# شوف الـ Logs
adb logcat | grep -E "✅|❌|📡"
```

---

## 🔍 القائمة التحقق

```
☑ git status = معروضة الملفات المعدلة
☑ git add . = تم إضافة الملفات
☑ git commit = message واضح
☑ git push = pushed بنجاح
⏳ Railway deployment = انتظر 2-3 دقائق
☑ curl test = API responding 200
☑ flutter clean = done
☑ flutter build apk = done
☑ adb install = installed
☑ App runs = no crashes
☑ Data visible = البيانات تظهر
```

---

## ⚠️ Troubleshooting

### مشكلة: git push فشل
```
الحل:
git config user.email "your@email.com"
git config user.name "Your Name"
git push origin main
```

### مشكلة: Railway API رجع 502
```
الحل:
1. افتح Railway Dashboard
2. انظر الـ Logs
3. تأكد من "Server running on port 8080"
4. انتظر 2-3 دقائق أخرى
```

### مشكلة: APK لم ينجح
```
الحل:
flutter clean
flutter pub get
flutter build apk --release
```

### مشكلة: App shows "No Data"
```
الحل:
1. تأكد API working (curl test)
2. تأكد من Network connection
3. اعدم تشغيل التطبيق
```

---

## 📝 ملاحظات مهمة

```
✅ git push = السلام على Railway
✅ Railway auto-redeploy = بدون تدخل يدوي
✅ API fallback = دائماً ترجع بيانات
✅ 3-tier chain = API → Firebase → Dummy
✅ Production ready = آمن وموثوق
```

---

## ⏱️ الوقت المتوقع

```
git commands: 1 دقيقة
Railway deploy: 2-3 دقائق
API test: 1 دقيقة
APK build: 5-10 دقائق
Install: 2 دقائق
Test: 2 دقائق

الإجمالي: 15-20 دقيقة
```

---

## 🎯 الخطوة الأولى الآن

```bash
cd c:\FinalProject\opticell
git add .
git commit -m "Fix: Railway 502 - Simplify backend, add fallback"
git push origin main
```

**ثم انتظر Railway deployment (2-3 دقائق)**

---

## ✅ Success Indicator

```
✅ You see in Railway logs:
   "Server running on port 8080"

✅ API returns JSON:
   curl command successful

✅ Flutter app shows data:
   Dashboard has batch reports

✅ No crashes:
   App runs smooth

🎉 You're done!
```
