"""Generuje VipGym/Core/Localization/Localizable.xcstrings z tabeli PL/EN i sprawdza pokrycie kluczy w kodzie."""
import json, re, pathlib

T = {
 # ogólne
 "common.cancel": ("Cancel", "Anuluj"),
 "common.save": ("Save", "Zapisz"),
 "unit.h": ("h", "godz."),
 "unit.min": ("min", "min"),
 # zakładki
 "tab.workout": ("Workout", "Trening"),
 "tab.exercises": ("Exercises", "Ćwiczenia"),
 "tab.progress": ("Progress", "Progres"),
 "tab.coach": ("Coach", "Trener"),
 "tab.settings": ("Settings", "Ustawienia"),
 "soon.title": ("Coming soon", "Wkrótce"),
 "soon.progress": ("Estimated 1RM, volume, personal records and charts over time.",
                   "Szacowane 1RM, objętość, rekordy życiowe i wykresy w czasie."),
 "soon.coach": ("Your on-device AI coach. Private and works offline.",
                "Twój trener AI działający na urządzeniu. Prywatnie i bez internetu."),
 # ekran główny
 "home.ready": ("Ready to lift?", "Czas na trening?"),
 "home.ready.sub": ("Log sets, RIR and rest times. Everything stays on your phone.",
                    "Zapisuj serie, RIR i przerwy. Wszystko zostaje na Twoim telefonie."),
 "home.start": ("Start workout", "Rozpocznij trening"),
 "home.active": ("Workout in progress", "Trening w toku"),
 "home.resume": ("Continue workout", "Wróć do treningu"),
 "home.sets": ("sets", "serii"),
 "home.stat.sessions": ("Last 7 days", "Ostatnie 7 dni"),
 "home.stat.volume": ("Volume 7 days", "Objętość 7 dni"),
 "home.history": ("History", "Historia"),
 "home.history.empty": ("No workouts yet. Your first one will show up here.",
                        "Brak treningów. Pierwszy pojawi się tutaj."),
 # aktywny trening
 "workout.time": ("Time", "Czas"),
 "workout.sets.done": ("Sets", "Serie"),
 "workout.add.exercise": ("Add exercise", "Dodaj ćwiczenie"),
 "workout.add.set": ("Add set", "Dodaj serię"),
 "workout.finish": ("Finish", "Zakończ"),
 "workout.finish.title": ("Finish workout?", "Zakończyć trening?"),
 "workout.finish.message": ("Sets you did not check off will be removed.",
                            "Serie, których nie zatwierdziłeś, zostaną usunięte."),
 "workout.finish.save": ("Finish and save", "Zakończ i zapisz"),
 "workout.finish.discard": ("Discard workout", "Odrzuć trening"),
 "workout.col.prev": ("Previous", "Poprz."),
 "workout.col.reps": ("Reps", "Powt."),
 "workout.set.type": ("Set type", "Typ serii"),
 "workout.set.delete": ("Delete set", "Usuń serię"),
 "workout.remove.exercise": ("Remove exercise", "Usuń ćwiczenie"),
 "workout.superset": ("Superset", "Superseria"),
 "workout.superset.link": ("Superset with previous", "Superseria z poprzednim"),
 "workout.superset.unlink": ("Remove from superset", "Usuń z superserii"),
 "rest.title": ("Rest", "Przerwa"),
 "rest.ready": ("Ready for next set", "Czas na kolejną serię"),
 "notif.rest.title": ("Rest is over", "Koniec przerwy"),
 "notif.rest.body": ("Time for your next set.", "Czas na kolejną serię."),
 "live.rest": ("Rest", "Przerwa"),
 "live.workout": ("Workout", "Trening"),
 "live.sets": ("sets", "serii"),
 # szczegóły treningu
 "detail.volume": ("Volume", "Objętość"),
 "detail.duration": ("Duration", "Czas trwania"),
 "detail.repeat": ("Repeat this workout", "Powtórz ten trening"),
 "detail.delete": ("Delete", "Usuń"),
 "detail.delete.confirm": ("Delete permanently?", "Usunąć na stałe?"),
 # ćwiczenia
 "picker.title": ("Pick exercise", "Wybierz ćwiczenie"),
 "filter.all": ("All", "Wszystkie"),
 "exercises.search": ("Search exercises", "Szukaj ćwiczeń"),
 "exercises.empty": ("No exercises found", "Nie znaleziono ćwiczeń"),
 "exercise.custom": ("Custom", "Własne"),
 "exercise.deleted": ("Deleted exercise", "Usunięte ćwiczenie"),
 "exercise.delete.confirm": ("Delete this exercise?", "Usunąć to ćwiczenie?"),
 "exercise.secondary": ("Also works", "Pracują także"),
 "exercise.best.1rm": ("Best est. 1RM", "Najlepsze 1RM"),
 "exercise.heaviest": ("Heaviest set", "Najcięższa seria"),
 "exercise.photos": ("Your photos", "Twoje zdjęcia"),
 "exercise.photos.add": ("Add photo", "Dodaj zdjęcie"),
 "exercise.photos.hint": ("Photos are stored only on this phone.", "Zdjęcia są zapisane tylko na tym telefonie."),
 "exercise.rest": ("Rest for this exercise", "Przerwa dla tego ćwiczenia"),
 "exercise.instructions": ("Instructions", "Opis wykonania"),
 "exercise.instructions.en": ("Instructions are available in English only for now.",
                              "Opisy wykonania są na razie tylko po angielsku."),
 "custom.title": ("New exercise", "Nowe ćwiczenie"),
 "custom.name": ("Name", "Nazwa"),
 "custom.name.placeholder": ("e.g. Cable crunch on bench", "np. Brzuszki na wyciągu na ławce"),
 "custom.primary": ("Main muscle", "Główny mięsień"),
 "custom.equipment": ("Equipment", "Sprzęt"),
 "custom.secondary": ("Secondary muscles", "Mięśnie pomocnicze"),
 # ustawienia
 "settings.section.general": ("General", "Ogólne"),
 "settings.section.training": ("Training", "Trening"),
 "settings.section.about": ("About", "O aplikacji"),
 "settings.language": ("Language", "Język"),
 "settings.language.system": ("System", "Systemowy"),
 "settings.appearance": ("Appearance", "Wygląd"),
 "settings.appearance.dark": ("Dark", "Ciemny"),
 "settings.appearance.light": ("Light", "Jasny"),
 "settings.appearance.system": ("System", "Systemowy"),
 "settings.units": ("Weight unit", "Jednostka ciężaru"),
 "settings.rest": ("Default rest", "Domyślna przerwa"),
 "settings.version": ("Version", "Wersja"),
 "settings.privacy": ("All data is stored locally on this device. No account, no servers.",
                      "Wszystkie dane są zapisane lokalnie na tym urządzeniu. Bez konta i bez serwerów."),
}
MUSCLE = {"chest":("Chest","Klatka piersiowa"),"lats":("Lats","Najszersze grzbietu"),"middleBack":("Mid back","Środek pleców"),
 "lowerBack":("Lower back","Dolny odcinek pleców"),"traps":("Traps","Czworoboczne"),"shoulders":("Shoulders","Barki"),
 "biceps":("Biceps","Biceps"),"triceps":("Triceps","Triceps"),"forearms":("Forearms","Przedramiona"),
 "abdominals":("Abs","Brzuch"),"quadriceps":("Quads","Czworogłowe"),"hamstrings":("Hamstrings","Dwugłowe uda"),
 "glutes":("Glutes","Pośladki"),"calves":("Calves","Łydki"),"adductors":("Adductors","Przywodziciele"),
 "abductors":("Abductors","Odwodziciele"),"neck":("Neck","Kark")}
EQUIP = {"barbell":("Barbell","Sztanga"),"dumbbell":("Dumbbell","Hantle"),"machine":("Machine","Maszyna"),
 "smith":("Smith machine","Suwnica Smitha"),"cable":("Cable","Wyciąg"),"bodyweight":("Bodyweight","Masa ciała"),
 "kettlebell":("Kettlebell","Kettlebell"),"bands":("Bands","Gumy"),"ezBar":("EZ bar","Sztanga łamana"),
 "medicineBall":("Medicine ball","Piłka lekarska"),"exerciseBall":("Exercise ball","Piłka gimnastyczna"),
 "foamRoll":("Foam roller","Wałek"),"other":("Other","Inny")}
CATEG = {"strength":("Strength","Siłowe"),"powerlifting":("Powerlifting","Trójbój"),"olympic":("Olympic lifts","Podnoszenie ciężarów"),
 "strongman":("Strongman","Strongman"),"plyometrics":("Plyometrics","Pliometria"),"cardio":("Cardio","Cardio"),"stretching":("Stretching","Rozciąganie")}
LEVEL = {"beginner":("Beginner","Początkujący"),"intermediate":("Intermediate","Średni"),"expert":("Expert","Zaawansowany")}
KIND = {"working":("Working set","Seria robocza"),"warmup":("Warm-up (W)","Rozgrzewkowa (W)"),
 "dropset":("Drop set (D)","Dropset (D)"),"failure":("To failure (F)","Do upadku (F)")}
for pre, d in (("muscle",MUSCLE),("equipment",EQUIP),("category",CATEG),("level",LEVEL),("kind",KIND)):
    for k,v in d.items(): T[f"{pre}.{k}"] = v

cat = {"sourceLanguage":"en","version":"1.0","strings":{}}
for k,(en,pl) in sorted(T.items()):
    cat["strings"][k] = {"extractionState":"manual","localizations":{
        "en":{"stringUnit":{"state":"translated","value":en}},
        "pl":{"stringUnit":{"state":"translated","value":pl}}}}
out = pathlib.Path("VipGym/Core/Localization/Localizable.xcstrings")
out.write_text(json.dumps(cat, ensure_ascii=False, indent=2), encoding="utf-8")

# kontrola pokrycia
used = set()
for f in pathlib.Path("VipGym").rglob("*.swift"):
    used |= set(re.findall(r'L\("([a-zA-Z0-9_.]+)"\)', f.read_text()))
used.add("picker.title")
missing = sorted(k for k in used if k not in T)
print("keys:", len(T), "| used in code:", len(used), "| MISSING:", missing)
