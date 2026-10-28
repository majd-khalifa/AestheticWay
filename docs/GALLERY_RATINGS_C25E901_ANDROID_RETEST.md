# Android physical retest — gallery and ratings

2026-10-27 · PR #13. Record the **final commit/build** from the PR. These checks
are not performed on a physical device by this execution.

1. Open Clinic Media as the actual clinic admin. Select one gallery photo,
   several photos and a camera photo. Return from each native picker: images
   remain queued and **Upload selected photos** stays visible. Cancel selection:
   no new queued image. Normal background/foreground still refreshes permissions.
2. Tap Save once. Check progress and exact201 asset acknowledgment, fresh saved
   gallery and private profile verification. Do not infer saving from local
   preview. Repeat JPG/PNG/WebP within5MiB/25MP. No gallery-array/profile PATCH.
3. Refresh/reopen, force-close/restart, then verify the same images in Clinic
   Media and the approved public Patient clinic. Verify actual HTTPS/CDN image
   delivery independently. An asset row can exist while image delivery fails.
4. Remove one saved image; refresh/restart and confirm absence. Cover and the
   already working VIP showcase must remain independent.
5. Test denied permission, cancelled selection, unsupported/oversized/missing
   file, lost response and partial success. Keep failed queued files; no fake
   success or automatic uncertain POST replay. Review saved state before an
   explicitly confirmed retry. Normal refresh and save cannot overlap.
6. If any failure occurs, open **Gallery troubleshooting details** and share only
   build, stage, HTTP/upload_HTTP, API code, field names, ACK/read flags and UTC
   time. For image delivery, note imageLoad HTTP/kind. No credentials, filenames,
   private URLs, phone numbers or patient data. Ask Ali to correlate server logs.
7. Google: inspect the exact real clinic name/address in Maps. **Unlink an
   unrelated salon/test business; never use its rating as the clinic's.** For
   the correct association, refresh private status and capture sanitized public
   rating/count fields. Pending is not success and Refresh does not start sync.
   Ask Ali to verify eligibility/job/provider and identity approval from the
   handoff. A fixture badge or open Maps deep link is not live rating evidence.
8. Repeat representative EN/AR, Light/Dark and RTL/large-text layouts. Recheck
   Nurse without portrait, consultation/My Requests, location editing, VIP large
   upload→freshGET→restart/play→delete and cover preservation. GPS distance and
   verified-email deletion remain separate, previously unverified device checks.

**عربي:** ابدأ باختيار الصور والعودة من المعرض/الكاميرا: يجب بقاؤها في قائمة الرفع
قبل الحفظ. بعده تحقق من201 والقراءة الخاصة والعامة وإعادة التشغيل والتسليم الفعلي.
شارك فقط معلومات التشخيص الآمنة ووقتUTC، ولا تنشر بيانات خاصة. ألغِ ربط أي صالون
غير تابع للعيادة؛ ظهور تقييم تجريبي أو فتح الخرائط لا يثبت صحة تقييم العيادة.
