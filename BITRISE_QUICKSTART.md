# ⚡ Швидкий чеклист налаштування Bitrise

## 📋 Що потрібно додати в Bitrise Secrets:

### 1. FIREBASE_APP_ID_ANDROID
```
Де взяти: Firebase Console > Project Settings > Your apps > Android app
Формат: 1:123456789:android:abc123def456
```

### 2. FIREBASE_TOKEN
```
Команда: firebase login:ci
Скопіювати весь токен що виведеться
```

### 3. GOOGLE_SERVICES_JSON
```
1. Завантажити: Firebase Console > Project Settings > Download google-services.json
2. Відкрити файл у текстовому редакторі
3. Скопіювати ВЕСЬ вміст (від { до })
4. Вставити в Bitrise Secret
```

**Приклад початку GOOGLE_SERVICES_JSON:**
```json
{
  "project_info": {
    "project_number": "123456789",
    "project_id": "your-project-id",
    ...
```

---

## ✅ Перевірка перед першим білдом:

- [ ] Репозиторій підключений до Bitrise
- [ ] Гілка `main` вибрана як primary
- [ ] Додано FIREBASE_APP_ID_ANDROID в Secrets
- [ ] Додано FIREBASE_TOKEN в Secrets  
- [ ] Додано GOOGLE_SERVICES_JSON в Secrets (повний JSON!)
- [ ] Створена група "testers" у Firebase App Distribution
- [ ] Додані email тестерів у групу

---

## 🚀 Запуск білда:

```bash
git add .
git commit -m "Trigger Bitrise build"
git push origin main
```

Build запуститься автоматично! 🎉

---

## 📱 Результат:

- APK у Bitrise Artifacts: `QuoteGallery-{BUILD_NUMBER}.apk`
- Email тестерам з посиланням на Firebase App Tester
- Логи білда в Bitrise Dashboard

---

**Час налаштування:** ~10 хвилин  
**Час білда:** ~5-7 хвилин
