# AESTHETIC WAY — تقرير تحليل الباك اند والجاهزية للربط مع فلاتر
**تاريخ التحليل:** 2026-09-18  
**الحالة:** تحليل مكتمل وتوصيات تشغيل (بدون تعديل كود)

---

## 1) تأكيد جذر الباك اند
**نعم، مجلد `backend/` هو جذر الباك اند الصحيح 100%**.  
يحتوي مباشرة على:
- `manage.py`
- `config/` (ملفات الإعدادات: `base.py`, `development.py`, `production.py`, `urls.py`, `celery.py`, `wsgi.py`, `asgi.py`)
- `apps/` (التطبيقات الموزعة: `accounts`, `clinics`, `practitioners`, `treatments`, `offers`, `products`, `articles`, `leads`, `referrals`, `analytics`, `notifications`, `app_config`, `admin_portal`, `home`, `media`)
- `core/` (الاستثناءات، الصلاحيات، الترقيم Pagination، الفحص الصحي)
- `api/` (مسارات النسخة الأولى `api/v1/urls.py`)
- `requirements.txt`, `pytest.ini`, `docker-compose.yml`, `.env.example`
- وثائق المواصفات الرسمية: `README.md` و `AESTHETIC_WAY_Backend_Spec_v1.md`

---

## 2) حالة ملفات التوثيق والإعدادات
- **`backend/README.md`**: تم فحصه، ويحتوي على دليل تشغيل ومعمارية تفصيلية مطابقة للنسخة الأولى v1.
- **`backend/AESTHETIC_WAY_Backend_Spec_v1.md`**: تم فحصه بالكامل، وهو وثيقة المواصفات المرجعية الأساسية للمشروع.
- **`FRONTEND_API_GUIDE.md`**: **غير موجود في المشروع كملف منفصل** (المرجع الفعلي للواجهة هو كود الباك اند، وثيقة `AESTHETIC_WAY_Backend_Spec_v1.md`، ومخطط Swagger/OpenAPI).
- **إعدادات `config/` و `apps/`**: تم فحص إعدادات التوثيق، OTP، CORS، قاعدة البيانات، والـ Seed.

---

## 3) التقرير التفصيلي المنظم

### A) أوامر التشغيل المحلي بالضبط
> **ملاحظة حول Docker:** بيئة نظام التشغيل الحالية لا تحتوي على أمر `docker` في مسار النظام (%PATH%). لحسن الحظ، تم إعداد الباك اند بحيث يدعم بيئة التطوير المحلية بـ `SQLite` وذاكرة تخزين مؤقت داخلية `LocMemCache` دون الحاجة الإجبارية لتشغيل Docker أو Redis أو PostgreSQL أثناء التطوير المحلي.

لتشغيل السيرفر محلياً عبر بايثون (Windows PowerShell):
```powershell
# 1. الدخول إلى مجلد الباك اند
cd backend

# 2. إنشاء البيئة الافتراضية وتفعيلها
python -m venv .venv
.venv\Scripts\Activate.ps1

# 3. تثبيت الاعتماديات
pip install -r requirements.txt

# 4. إنشاء ملف البيئة من النموذج (مهم جداً لأن decouple يتطلب وجود SECRET_KEY)
Copy-Item .env.example .envCopy-Item .env.example .env

# 5. تطبيق ترحيل قاعدة البيانات (تنشئ db_dev.sqlite3 تلقائياً)
python manage.py migrate

# 6. تعبئة البيانات التجريبية للمنصة
python manage.py seed_data

# 7. تشغيل السيرفر (مع الاستماع على 0.0.0.0 لتتمكن أجهزة المحاكي والشبكة من الاتصال)
python manage.py runserver 0.0.0.0:8000
```

---

### B) Base URL المحلي والـ Trailing Slash
- **الـ Base URL الموحد للـ API**:
  - من المتصفح أو تطبيق سطح المكتب: `http://127.0.0.1:8000/api/v1/`
  - من محاكي أندرويد (Android Emulator): `http://10.0.2.2:8000/api/v1/`
  - من محاكي آيفون (iOS Simulator): `http://127.0.0.1:8000/api/v1/`
  - من جهاز فيزيائي متصل على نفس شبكة الـ Wi-Fi: `http://<YOUR_LOCAL_IP>:8000/api/v1/`
- **هل المسارات تحتاج Trailing Slash؟**:
  - **نعم، إلزامي ومهم جداً!**
  - جميع مسارات Django معرّفة بـ `/` في النهاية (مثل `/api/v1/auth/register/` و `/api/v1/home/feed/`).
  - إذا أرسل تطبيق فلاتر طلب `POST` أو `PATCH` أو `PUT` بدون السلاش الأخير، سيقوم Django بعمل إعادة توجيه `301 Redirect` مما يؤدي تلقائياً إلى تحويل الطلب أو إسقاط الـ Body وفشل العملية.

---

### C) نظام الـ OTP: كود ثابت أم SMS؟ وأين مكانه
- **طبيعة الكود**: كود **عشوائي مولد برمجياً** (Cryptographically Random).
- **عدد الخانات**: **6 أرقام** (مثل `482910`).
- **مزود الـ SMS محلياً**:
  - الملف المسؤول: `apps/accounts/services/sms.py`
  - الإعداد: `SMS_PROVIDER = "console"` في `config/settings/base.py`
  - **كيف يتم استلامه محلياً؟** يتم طباعة الكود فور إرساله مباشرة داخل شاشة الـ Terminal/Console التي يعمل فيها السيرفر بالشكل التالي:
    ```text
    ============================================================
    [DEV SMS] OTP for +971501234567 (registration): 629401
    ============================================================
    ```
- **هل يوجد كود ديمو ثابت (Bypass) في الكود؟**:
  - **لا يوجد كود ثابت** (مثل 000000 أو 123456). الدالة `verify_otp` في `apps/accounts/services/otp.py` تتحقق حصراً من تطابق الـ Hash مع الكود المخزن في الذاكرة.
- **حدود وقيود الـ OTP**:
  - صلاحية الكود: 10 دقائق (`OTP_TTL_SECONDS = 600`).
  - إعادة الإرسال: مسموح مرة كل 60 ثانية (`OTP_RESEND_COOLDOWN = 60`).
  - الإغلاق بعد الفشل: 5 محاولات خاطئة كحد أقصى ثم إغلاق لمدة 30 دقيقة.

---

### D) الـ Seed والـ Fixtures وكيفية تشغيله
- **نعم، يوجد سكربت متكامل وشامل ومحمي (Idempotent)** مبني كـ Django Management Command:
  - الملف: `apps/clinics/management/commands/seed_data.py`
  - أمر التشغيل:
    ```powershell
    python manage.py seed_data
    ```
  - خيار تصفير البيانات وإعادة بنائها:
    ```powershell
    python manage.py seed_data --reset
    ```
- **البيانات التي يقوم بتوليدها**:
  - عيادات في دبي وأبوظبي بمختلف باقات الاشتراك (VIP, Featured, Basic).
  - فروع العيادات مع إحداثيات GPS وروابط خرائط Google.
  - أطباء وممارسون بتصنيفاتهم الطبية.
  - تصنيفات التجميل الـ 8 المعتمدة والخدمات المرتبطة.
  - عروض نشطة بأسعار أصلية ومخفضة، ومنتجات، ومقالات طبية.
  - طلبات Leads تجريبية بحالات مختلفة.
  - نظام إحالات ونقاط وأكواد خصم 15% (`AW-15-XXXX`).
- **حسابات الدخول الجاهزة بعد الـ Seed (كلمة المرور الموحدة لجميع الحسابات: `StagingPassword123!`)**:
  - **Super Admin**: `super_admin@aestheticway.ae` أو الهاتف `+971500000001`
  - **Clinic Admin (Downtown)**: `admin.downtown@aestheticway.ae` أو الهاتف `+971500000002`
  - **Clinic Admin (Capital)**: `admin.capital@aestheticway.ae` أو الهاتف `+971500000003`
  - **Clinic Staff**: `staff.downtown@aestheticway.ae` أو الهاتف `+971500000004`
  - **Patients**: الهواتف `+971501111111` و `+971502222222`

---

### E) عقود الـ Auth الأساسية وشكل Body لـ Refresh

1. **إنشاء حساب مريض (`POST /api/v1/auth/register/`)**:
   - Headers: `Content-Type: application/json`
   - Request Body:
     ```json
     {
       "full_name": "Sara Al Mansoori",
       "phone": "+971501234567",
       "email": "sara@example.com",
       "password": "StrongPassword123!",
       "referral_code": "AW-XXXX-XXXX",
       "device_platform": "ios"
     }
     ```
   - Response (`201 Created`):
     ```json
     {
       "user_id": "99645228-...",
       "message": "Account created. Please verify your phone number.",
       "otp_purpose": "registration",
       "expires_in": 600
     }
     ```

2. **التحقق من كود الـ OTP (`POST /api/v1/auth/verify-otp/`)**:
   - Request Body:
     ```json
     {
       "phone": "+971501234567",
       "otp_code": "629401",
       "purpose": "registration"
     }
     ```
     *(الخيارات المتاحة لـ `purpose`: `"registration"` أو `"login"` أو `"password_reset"`)*
   - Response (`200 OK` للـ registration والـ login):
     ```json
     {
       "token_type": "Bearer",
       "access_token": "eyJhbGciOi...",
       "refresh_token": "eyJhbGciOi...",
       "expires_in": 3600,
       "user": {
         "id": "uuid",
         "full_name": "Sara Al Mansoori",
         "phone": "+971501234567",
         "email": "sara@example.com",
         "role": "patient",
         "is_verified": true,
         "device_platform": "ios",
         "created_at": "2026-09-18T..."
       }
     }
     ```

3. **تسجيل الدخول (`POST /api/v1/auth/login/`)**:
   - Request Body:
     ```json
     {
       "identifier": "+971501234567",
       "password": "StrongPassword123!"
     }
     ```
     *(يدعم إدخال الهاتف أو الإيميل في `identifier`، كما يدعم مفتاح `"phone"` القديم)*
   - Response (`200 OK`): نفس صيغة التوكن وبيانات الـ user أعلاه.

4. **تجديد التوكن (`POST /api/v1/auth/refresh/`)**:
   - **انتبه لشكل الـ Body**: المفتاح المطلوب هو **`refresh`** (وليس `refresh_token`):
     ```json
     {
       "refresh": "<your_refresh_token_string>"
     }
     ```
   - Response (`200 OK`):
     ```json
     {
       "token_type": "Bearer",
       "access_token": "<new_access_token>",
       "refresh_token": "<new_rotated_refresh_token>"
     }
     ```
     *(يتم تطبيق Token Rotation تلقائياً في الباك اند وإلغاء الـ refresh القديم)*

5. **تسجيل الخروج (`POST /api/v1/auth/logout/`)**:
   - Headers: `Authorization: Bearer <access_token>` (يتطلب توكن مسجل)
   - Request Body: المفتاح هنا هو **`refresh_token`**:
     ```json
     {
       "refresh_token": "<your_refresh_token_string>"
     }
     ```
   - Response: `204 No Content`

6. **إعادة إرسال OTP (`POST /api/v1/auth/resend-otp/`)**:
   - Request Body:
     ```json
     {
       "phone": "+971501234567",
       "purpose": "registration"
     }
     ```

7. **الملف الشخصي للمستخدم الحالي (`GET /api/v1/auth/me/`)**:
   - Headers: `Authorization: Bearer <access_token>`

---

### F) فروقات مهمة بين الوثائق والواقع الفعلي في الكود
1. **طول كود OTP (4 مقابل 6 أرقام)**:
   - في وثيقة المواصفات (`AESTHETIC_WAY_Backend_Spec_v1.md` السطر 78): ذُكر "4-digit OTP".
   - في شاشة فلاتر الحالية (`otp_screen.dart:L40-L41`): الواجهة مبنية على **4 مربعات إدخال** فقط (`List.generate(4, ...)`).
   - في كود الباك اند الفعلي (`apps/accounts/serializers.py:L211`): الكود **6 أرقام إجبارياً** (`min_length=6, max_length=6`). إرسال 4 أرقام سيؤدي لرفض فوري `422 Unprocessable Entity`.
2. **اسم حقل التجديد (Refresh Token)**:
   - عند تجديد التوكن عبر `/auth/refresh/` يتوقع السيرفر مفتاح `{"refresh": "..."}`. بينما عند تسجيل الخروج `/auth/logout/` يتوقع `{"refresh_token": "..."}`.
3. **عدم وجود `FRONTEND_API_GUIDE.md`**:
   - الملف غير موجود، وتفاصيل الـ Payloads تم استخراجها مباشرة من كود الـ Serializers وفحوصات الـ Pytest.
4. **مسارات الـ Leads**:
   - بالإضافة إلى المسار الرئيسي المعتمد `/api/v1/leads/` و `/api/v1/leads/my/`، هناك مسار فرعي إضافي معرف في `api/v1/urls.py` هو `/api/v1/patient/leads/`. المسار الرئيسي `/api/v1/leads/` هو المطابق للمواصفة.

---

### G) إعدادات CORS و ALLOWED_HOSTS
- في بيئة التطوير (`config/settings/development.py`):
  - `ALLOWED_HOSTS = ["*"]` (يسمح بأي Host).
  - `CORS_ALLOW_ALL_ORIGINS = True` (مفتوح بالكامل لجميع المصادر).
- **التوصية الحاسمة عند تشغيل السيرفر**:
  - إذا شغلت السيرفر بالأمر الافتراضي `python manage.py runserver` سيرتبط فقط بـ `127.0.0.1:8000` ولن يستطيع محاكي الأندرويد أو أي جوال خارجي الوصول إليه.
  - **يجب دائماً التشغيل هكذا**:
    ```powershell
    python manage.py runserver 0.0.0.0:8000
    ```
  - على Android Emulator يتم الاتصال بـ: `http://10.0.2.2:8000/api/v1/`
  - على جهاز حقيقي على نفس الشبكة: `http://192.168.x.x:8000/api/v1/`

---

### H) إتاحة Swagger و OpenAPI محلياً
- **نعم، متاح محلياً بالكامل ومجهز بواسطة `drf-spectacular` دون الحاجة لأي تسجيل دخول**:
  - **واجهة Swagger التفاعلية**: `http://127.0.0.1:8000/api/docs/`
  - **واجهة ReDoc**: `http://127.0.0.1:8000/api/redoc/`
  - **مخطط OpenAPI بصيغة JSON/YAML**: `http://127.0.0.1:8000/api/schema/`
  - يمكن فتح Swagger في المتصفح فور تشغيل السيرفر وتجربة كافة الـ Endpoints والاطلاع على Schemas الاستجابة والطلبات بدقة.

---

### I) ترتيب مقترح لربط تطبيق Flutter لاحقاً
1. **تجهيز البنية التحتية للشبكة في فلاتر (Network Core)**:
   - إضافة مكتبتي `dio` و `flutter_secure_storage` إلى `pubspec.yaml` (المشروع لا يحتوي عليهما حالياً ويعتمد على `mock_data.dart`).
   - بناء `ApiClient` بـ Base URL ديناميكي، مع إضافة `trailing slash` تلقائياً لكل المسارات.
   - إضافة `AuthInterceptor` لحقن `Authorization: Bearer <token>`، ولغة التطبيق `Accept-Language: ar|en`، والتعامل الذاتي مع التجديد `Token Refresh` عند استلام `401`.
2. **المرحلة 1: المصادقة (Auth Flow)**:
   - تحديث واجهة `otp_screen.dart` لتستقبل 6 أرقام بدلاً من 4.
   - ربط التسجيل (`register`) والتحقق (`verify-otp`) وتسجيل الدخول (`login`) وحفظ التوكن في التخزين الآمن.
   - ربط استعادة كلمة المرور (`forgot-password` و `reset-password`).
3. **المرحلة 2: الشاشة الرئيسية والاستكشاف (App Config & Home Discovery)**:
   - جلب معلومات الدعم `GET /api/v1/app/support-info/` (رقم الدعم الإلزامي `+971581989252`).
   - ربط خلاصة الرئيسية `GET /api/v1/home/feed/?city=dubai`.
   - ربط التصنيفات `GET /api/v1/categories/`، والعيادات `GET /api/v1/clinics/`، وتفاصيل العيادة والفروع مع روابط خرائط Google.
   - ربط الأطباء `GET /api/v1/practitioners/`، والعروض `GET /api/v1/offers/`، والمنتجات، والمقالات.
4. **المرحلة 3: مسار الطلبات (Leads - Core Flow)**:
   - ربط إرسال الطلب `POST /api/v1/leads/`، والتأكد التام من عرض رسالة النجاح الإلزامية في الواجهة:
     `"تم إرسال طلبك وستتواصل العيادة معك"`.
   - ربط شاشة استعراض طلباتي `GET /api/v1/leads/my/` وعداد الطلبات.
5. **المرحلة 4: برنامج الإحالات والمكافآت (Referral)**:
   - ربط شاشة الإحالات `GET /api/v1/referral/my-status/` (سلم المكافآت 20 / 35 / 50 إحالة، رصيد النقاط).
   - تفعيل استبدال كود الخصم 15% `POST /api/v1/referral/collect-code/` عند وصول الرصيد إلى 500 نقطة.
6. **المرحلة 5: بوابة العيادة (Clinic Portal - حسب الصلاحيات)**:
   - ربط لوحة التحكم `GET /api/v1/clinic-portal/dashboard/`.
   - ربط صندوق الوارد وتحديث حالة الطلب إلى `contacted` أو `closed`.
   - التحقق من كود الخصم واستخدامه (`verify` و `redeem`).
7. **المرحلة 6: بوابة المشرف العام (Admin Portal)**:
   - إدارة العيادات واشتراكاتها والإشراف العام.

---

### J) أهم المخاطر والنواقص قبل بدء الربط
1. **تعارض مربعات OTP في فلاتر (Risk #1)**:
   - واجهة `otp_screen.dart` الحالية في فلاتر تحتوي على 4 مربعات إدخال فقط، بينما الـ Serializer في الباك اند يرفض أي كود لا يتطابق مع 6 خانات. **يجب تعديل الواجهة إلى 6 خانات قبل البدء بالربط**.
2. **عدم وجود كود OTP ثابت (Demo OTP)**:
   - أثناء تطوير واختبار فلاتر، لن تصل رسائل SMS حقيقية. يجب على المطور قراءة الكود العشوائي من نافذة تشغيل سيرفر دجانغو، أو يمكن إضافة إعداد مؤقت في الباك اند لبيئة التطوير يعتمد كوداً ثابتاً (مثل 123456) لتسهيل دورة اختبار الواجهات.
3. **تسمية حقل الـ Refresh**:
   - يجب الانتباه في `AuthInterceptor` داخل فلاتر إلى أن الـ Body المطلوب هو `{"refresh": "token"}` وليس `{"refresh_token": "token"}` لتجنب أخطاء 400 Bad Request.
4. **الـ Trailing Slash**:
   - عدم وضع السلاش `/` في نهاية المسار مع طلبات POST/PATCH في فلاتر سيؤدي إلى فشل الطلبات بسبب إعادة التوجيه.
5. **تنسيق أرقام الهواتف (E.164)**:
   - الباك اند يستخدم مكتبة `phonenumbers` للتحقق الصارم من صحة الرقم الإماراتي (`+971XXXXXXXXX`). أي إرسال لرقم بصيغة غير متوافقة سيعيد خطأ تحقق 422.
6. **الحدود الصارمة للمنتج (Hard Boundaries)**:
   - الباك اند مبني بدون أي مسارات دفع إلكتروني أو سلة تسوق أو حجز تقويم نهائي، ويجب التأكد من خلو واجهات فلاتر من أي محاولة لطلب هذه الوظائف.
7. **نقص مكتبات الشبكة في Flutter**:
   - مشروع فلاتر يحتاج مبدئياً لتثبيت حزم الاتصال والتخزين الآمن (`dio`, `flutter_secure_storage`).
