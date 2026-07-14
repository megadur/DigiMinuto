# DigiMinuto: Prozess-Visualisierungen

In diesem Dokument findest du die wichtigsten Abläufe innerhalb der DigiMinuto-App grafisch als Sequenz- und Flussdiagramme dargestellt. Diese eignen sich hervorragend für Präsentationen oder das Architektur-Verständnis im Team.

---

## 1. Gruppeneinladung (Community Onboarding)

Da DigiMinuto auf dezentralen, isolierten Gruppen ("Communities" wie z.B. das Ökodorf *Golchen*) basiert, muss jeder Nutzer kryptografisch eingeladen werden. Dies verhindert globalen Spam.

```mermaid
sequenceDiagram
    participant Invitee as Neues Mitglied
    participant Inviter as Gruppen-Gründer (oder Mitglied)
    participant Group as Gruppe "Golchen"

    Note over Invitee, Inviter: Schritt 1: Kontakt-Identifikation
    Invitee->>Inviter: Zeigt Profil QR-Code (Public Key)
    Inviter->>Invitee: Scannt QR-Code mit Scanner-App
    
    Note over Inviter: Schritt 2: Einladung ausstellen
    Inviter->>Inviter: Klickt "In Gruppe einladen" & wählt "Golchen"
    Inviter->>Inviter: Signiert Einladungs-Ticket mit eigenem Private Key
    
    Note over Inviter, Invitee: Schritt 3: Ticket-Übergabe
    Inviter->>Invitee: Zeigt generiertes Einladungs-Ticket (QR-Code)
    Invitee->>Inviter: Scannt Einladungs-Ticket
    
    Note over Invitee: Schritt 4: Gruppe beitreten
    Invitee->>Invitee: Verifiziert kryptografische Signatur des Inviters
    Invitee->>Group: Speichert Zugehörigkeit lokal
    Note right of Invitee: Kann nun in "Golchen" posten & schöpfen!
```

---

## 2. Minuto schöpfen & Bürgen (Web of Trust)

Geld wird bei DigiMinuto nicht durch Mining oder Banken geschöpft, sondern durch die Nutzer selbst – abgesichert durch das Vertrauen von zwei Bürgen.

```mermaid
sequenceDiagram
    participant Creator as Schöpfer
    participant App as DigiMinuto App
    participant Guarantor1 as Bürge 1
    participant Guarantor2 as Bürge 2

    Note over Creator, App: 1. Gutschein erstellen
    Creator->>App: Erstellt 100 Minutos (z.B. für "Gartenarbeit")
    App->>App: Erzeugt Token (Status: "Pending")
    
    Note over Creator, Guarantor1: 2. Erste Bürgschaft einholen
    Creator->>Guarantor1: Zeigt "Bürgen"-QR-Code des Tokens
    Guarantor1->>Creator: Scannt Token
    Guarantor1->>Guarantor1: Prüft Angebot ("Ist die Person vertrauenswürdig?")
    Guarantor1->>Creator: Erzeugt Signatur-QR-Code & Creator scannt ihn
    App->>App: Speichert Signatur 1
    
    Note over Creator, Guarantor2: 3. Zweite Bürgschaft einholen
    Creator->>Guarantor2: Zeigt "Bürgen"-QR-Code des Tokens
    Guarantor2->>Creator: Scannt Token
    Guarantor2->>Guarantor2: Prüft Angebot
    Guarantor2->>Creator: Erzeugt Signatur-QR-Code & Creator scannt ihn
    App->>App: Speichert Signatur 2
    
    Note over App: 4. Gutschein aktivieren
    App->>App: Ändert Status auf "Aktiv"
    Note right of App: Die 100 Minutos können nun ausgegeben werden.
```

---

## 3. Bezahlvorgang / Transfer (Offline & P2P)

Der Austausch von Minutos findet direkt zwischen zwei Personen statt. Eine zentrale Bank zur Verifikation gibt es nicht.

```mermaid
sequenceDiagram
    participant Sender as Käufer (Sender)
    participant Receiver as Verkäufer (Empfänger)
    
    Note over Receiver, Sender: 1. Empfänger identifizieren
    Receiver->>Sender: Zeigt Public Key (Profil-QR)
    Sender->>Receiver: Scannt QR-Code
    
    Note over Sender: 2. Zahlung vorbereiten
    Sender->>Sender: Wählt aktive Minuto-Tokens aus
    Sender->>Sender: Erzeugt Transaktions-Paket (inkl. Timestamp)
    Sender->>Sender: Signiert Transaktion mit Private Key
    
    Note over Sender, Receiver: 3. Geldübergabe (Offline)
    Sender->>Receiver: Zeigt Zahlungs-QR-Code
    Receiver->>Sender: Scannt Zahlungs-QR-Code
    
    Note over Receiver: 4. Verifikation & Buchung
    Receiver->>Receiver: Prüft kryptografische Signatur des Senders
    Receiver->>Receiver: Prüft Token-Historie (Ramsch-Filter)
    Receiver->>Receiver: Bucht Minutos auf lokales Guthaben
    Note right of Receiver: Zahlung abgeschlossen!
```

---

## 4. Marktplatz & Synchronisation (Nostr Netzwerk)

Um Angebote und Gesuche gruppenweit (nicht nur von Angesicht zu Angesicht) zu verteilen, nutzt DigiMinuto das dezentrale Nostr-Protokoll.

```mermaid
flowchart TD
    A[Alice (Gruppe 'Golchen')] -->|Erstellt Gesuch| B(Lokale App)
    B -->|Hängt Einladungs-Ticket an| C{Nostr Relays (Cloud)}
    C -->|Broadcast an Abonnenten| D(Lokale App von Bob)
    
    D --> E{Prüfe Ticket}
    E -->|Ungültig / Falsche Gruppe| F[Verwerfen (Spam-Schutz)]
    E -->|Gültig & Gruppe 'Golchen'| G[Zeige auf Pinnwand an]
    
    style C fill:#f9f,stroke:#333,stroke-width:2px
```
