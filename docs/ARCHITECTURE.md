# Architektur & Design: DigiMinuto

Die Architektur von DigiMinuto folgt dem Prinzip der **Clean Architecture** (Trennung von Geschäftslogik und UI). Da das System ohne zentrale Server auskommen muss, basiert es auf kryptografischen Beweisen und lokalen Datenbanken.

## 1. Systemkomponenten

Das System wird in zwei strikt voneinander getrennte Bereiche unterteilt:

### 1.1 DigiMinuto Core Engine
Die Core Engine enthält die reine Geschäftslogik. Sie weiß nichts von Benutzeroberflächen, Plattformen (iOS/Android) oder Kameras.

* **Kryptografie-Modul:** 
  * Generierung von asymmetrischen Schlüsselpaaren (Ed25519).
  * Signieren von Daten (Zertifikate, Transaktionen).
  * Verifizieren von fremden Signaturen.
* **Ledger & Token-Regeln (Web of Trust):**
  * **Schöpfungs-Limit:** Ein Nutzer darf maximal 1800 Minutos pro Kalenderjahr schöpfen.
  * **2-Bürgen-Regel:** Ein Schöpfungs-Zertifikat ist erst gültig, wenn es von exakt zwei verifizierten anderen Teilnehmern signiert wurde.
* **Storage-Abstraktion (Repository-Pattern):**
  * Schnittstellen für das Speichern und Laden von Profilen, Tokens und Transaktions-Logs. Die tatsächliche Implementierung (z.B. SQLite) wird später injiziert.
* **Netzwerk-Abstraktion (P2P):**
  * Logik zur Konvertierung lokaler Transaktionen in Formate, die über das Nostr-Protokoll synchronisiert werden können.
* **Gruppen- & Community-Management:**
  * Verwaltung von Mitgliedschaften in isolierten Netzwerken (Gruppen), um Vertrauen lokal zu bündeln und globale Spam-Probleme zu vermeiden.

### 1.2 DigiMinuto UI (Client App)
Die Benutzeroberfläche nutzt die Core Engine. (Das Framework - Flutter oder Angular/Ionic - wird noch final festgelegt).

* **QR-Code Handling:** Generierung von QR-Codes für Public Keys, Signatur-Anfragen und Transaktionen. Scannen von Codes anderer Nutzer.
* **Lokale Datenbank:** Implementierung der Storage-Interfaces aus der Core Engine (z.B. mittels lokaler SQLite DB auf dem Smartphone).
* **Nostr-Sync:** Ausführung des asynchronen Abgleichs mit Relays, sobald das Gerät online ist.

## 2. Datenmodelle (Entwurf)

Die Persistenz erfolgt lokal auf dem Gerät. Wir benötigen folgende Kern-Entitäten:

### 2.1 Identity (Profil)
* Eigene Identität: `PrivateKey` (Sicher verwahrt), `PublicKey` (Kontonummer/ID).
* Kontakte: `PublicKey` (bekannter Nutzer), lokaler Name, Reputations-Metadaten.

### 2.2 GroupMembership (Community-Zugehörigkeit)
* Isoliert Transaktionen und Marktplatz-Anfragen auf eine vertrauenswürdige Gruppe.
* `GroupId`: Eindeutige ID der Gruppe.
* `GroupName`: Name der Gemeinschaft (z.B. "Ökodorf XYZ").
* `MemberPubKey` & `InviterPubKey`: Dokumentiert, wer wen in die Gruppe eingeladen hat.
* `Signature`: Kryptografischer Beweis der Einladung (Einlass-Ticket).

### 2.2 Token (Gutschein/Zertifikat)
Repräsentiert einen geschöpften Wert (in der Regel 1 Token = 1 Minuto).
* `TokenID`: Kryptografischer Hash aus den Metadaten.
* `CreatorPubKey`: Der Schöpfer des Gutscheins.
* `Amount`: Der Wert (max. 1800).
* `CreationYear`: Zur Prüfung des Hard-Caps.
* `Guarantor1_Signature`: Signatur des ersten Bürgen.
* `Guarantor2_Signature`: Signatur des zweiten Bürgen.
* `Status`: Pending (wartet auf Bürgen), Active (nutzbar), Burned (eingelöst).

### 2.3 Transaction (Logbuch)
Jede Bewegung eines Tokens wird als Transaktion erfasst.
* `TxID`: Eindeutige ID.
* `TokenID`: Welcher Token (oder Teilbetrag) bewegt wird.
* `SenderPubKey`: Absender.
* `ReceiverPubKey`: Empfänger.
* `Timestamp`: Zeitpunkt.
* `Signature`: Digitale Unterschrift des Senders über den gesamten Transaktions-Datensatz.

## 3. Sicherheits- und Datenschutz-Richtlinie
* **Privacy by Design:** Das System arbeitet auf Protokollebene ausschließlich mit IDs (Public Keys). Keine Klarnamenpflicht, keine zentrale Datenbank.
* **Offline-Fähigkeit:** Der kritische Austausch (Zahlung) findet lokal von Gerät zu Gerät (via QR-Code) statt. Das System ist somit zensurresistent und ausfallsicher.
* **Reputation (Der Ramsch-Filter):** Jeder Token ist unveränderlich an seinen Schöpfer und seine Bürgen gebunden. Werden diese im dezentralen Netzwerk als "unzuverlässig" markiert, warnt die lokale App künftig vor der Annahme ihrer Tokens.
