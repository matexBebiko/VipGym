# VipGym

Dziennik treningowy dla iPhone (SwiftUI + SwiftData, iOS 26). Dane tylko lokalnie, bez konta i serwerów.

## Uruchomienie (Mac z Xcode 26)

1. `brew install xcodegen`
2. W katalogu projektu: `xcodegen` (powstaje `VipGym.xcodeproj` na podstawie `project.yml`)
3. Otwórz `VipGym.xcodeproj`, dla **obu** targetów (`VipGym` i `VipGymWidgets`) wybierz swój Team w *Signing & Capabilities*
4. Podłącz iPhone'a, Run
5. Na telefonie: Ustawienia > VipGym > upewnij się, że są włączone Powiadomienia i Aktywności na żywo

Bundle ID możesz zmienić w `project.yml` (`com.vipgym.app`), potem uruchom `xcodegen` ponownie.

## Struktura

- `VipGym/Core`: design system (Theme, komponenty), lokalizacja PL/EN
- `VipGym/Domain`: modele SwiftData (Exercise, WorkoutSession, WorkoutEntry, WorkoutSet)
- `VipGym/Services`: silnik progresji (1RM, objętość), seeder bazy ćwiczeń, WorkoutCoordinator (sesja, timer, Live Activity)
- `VipGym/Features`: ekrany
- `VipGymWidgets`: Live Activity (ekran blokady i Dynamic Island)
- `Shared`: kod wspólny dla aplikacji i rozszerzenia
- `tools`: skrypty generujące `exercises.json` i `Localizable.xcstrings`

## Baza ćwiczeń

906 ćwiczeń: 876 z otwartej bazy [free-exercise-db](https://github.com/yuhonas/free-exercise-db) (bez zdjęć, tylko dane) plus 30 własnych uzupełnień. 349 ma polskie nazwy, reszta pokazuje nazwę angielską. Opisy wykonania są po angielsku. **Przed publikacją w App Store sprawdź licencję repozytorium źródłowego.**
Zdjęcia dodaje użytkownik i trafiają tylko do pamięci aplikacji na jego telefonie.

## Udostępnienie znajomym

- Darmowe konto Apple ID: instalacja przez Xcode, aplikacja wygasa po 7 dniach i trzeba ją przeinstalować.
- Płatne konto Apple Developer (99 USD/rok): TestFlight (do 10 000 testerów, bez kabla), później App Store.
