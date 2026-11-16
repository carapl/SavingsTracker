<img src="docs/hero.png" alt="Savings: Overview, Activity și Goals">

O aplicație iOS simplă pentru banii tăi: vezi cât intră, cât iese, cât ai pus deoparte și pe ce se duc banii. Plățile cu Apple Pay se adaugă singure, fără să mai scrii nimic.

<img src="docs/features.png" alt="Grafice, plăți automate, obiective, trackere, istoric și conturi">

## Ce poate

- **Overview**: soldul total, luna curentă dintr-o privire, venituri vs. cheltuieli pe ultimele 6 luni și pe ce categorii cheltui cel mai mult.
- **Activity**: toate tranzacțiile, grupate pe luni, cu căutare și filtre.
- **Goals**: obiective de economisire (laptop, vacanță, fond de urgență) cu progres și cât trebuie să pui deoparte lunar ca să ajungi la timp.
- **Trackers**: secțiuni făcute de tine pentru ce vrei să urmărești, gen 🎮 jocuri sau ☕️ cafea, cu buget lunar opțional.
- **Accounts**: toate conturile la un loc, cu soldul actualizat din tranzacții.
- **Backup & export**: backup complet pe care îl poți restaura oricând, plus export CSV pentru Excel / Numbers / Google Sheets.

## Plăți automate cu Apple Pay

După fiecare plată cu Apple Pay, o automatizare din Shortcuts trimite plata în aplicație. Aplicația:

- recunoaște magazinul și pune singură categoria (Linella → Groceries, Steam → Games, Glovo → Food…);
- o bagă în trackerul potrivit;
- scade suma din contul cardului cu care ai plătit;
- o marchează cu ⚡, ca să știi ce s-a adăugat automat.

**Setup (o singură dată):** Shortcuts → Automatizare → **+** → **Tranzacție** → *Orice card*, cu rulare imediată → acțiunea **Log Expense**, cu câmpurile legate așa:

| Câmp | Variabilă |
|---|---|
| Amount | Valoare |
| Merchant | Comerciant |
| Card | Card sau tichet |

> Merge doar cu Apple Pay (telefon sau ceas). Cu cardul fizic, automatizarea nu pornește.

## Instalare

Ai nevoie de un Mac cu Xcode și de un iPhone cu iOS 18 sau mai nou.

1. Deschide `SavingsTracker.xcodeproj` în Xcode și loghează-te cu Apple ID-ul tău.
2. Conectează iPhone-ul, alege-l ca destinație și apasă **⌘R**.
3. Pe iPhone: **Settings → General → VPN & Device Management → Trust**.

Cu un Apple ID gratuit, aplicația trebuie reinstalată o dată la 7 zile. Datele rămân pe telefon.

## Tech

SwiftUI · SwiftData · Swift Charts · App Intents. Nu are server, nu are dependențe externe, totul stă pe telefon.
