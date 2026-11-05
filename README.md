# חיבור מחשב למערכות של המכללה

## Windows

פותחים PowerShell ומדביקים:

```powershell
irm https://raw.githubusercontent.com/tsamha123-cell/tsamha-setup/main/install.ps1 | iex
```

## Mac או Linux

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/tsamha123-cell/tsamha-setup/main/install.sh)
```

ב-Mac וב-Linux מותקן רק החיבור לשרת. מילוי טיוטות בסמוב וכלי עריכת התמונות מותקנים רק ב-Windows.

## מה קורה

1. נוצר מפתח למחשב, ושורה לאישור מועתקת ללוח.
2. שולחים את השורה לבוט בטלגרם, ומוודאים שטביעת האצבע זהה.
3. ההתקנה ממשיכה לבד, ובסופה נפתחת רשימת התחברויות קצרה.

אפשר להריץ שוב בלי נזק. מה שכבר מותקן נשאר כמו שהוא.

## אבטחה

אין כאן סודות, והריפו הזה לבדו לא נותן גישה לשום דבר. מחשב מקבל גישה רק אחרי אישור מחשבון טלגרם מורשה, ואפשר לבטל אותה בכל רגע עם `/removepc`.
