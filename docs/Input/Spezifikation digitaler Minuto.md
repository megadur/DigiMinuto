Eine Spezifikation für einen digitalen Minuto muss die Kernphilosophie (Dezentralität, Vertrauen, Schöpfung durch Bürgen) beibehalten, aber die Schwachstellen des Papiers (Fälschung, mangelnde Teilbarkeit, fehlende Transparenz bei Missbrauch) technologisch lösen.  
Da das System ohne zentrale Bank auskommen soll, bietet sich ein **lokal-erstes, kryptografisch abgesichertes Peer-to-Peer-System** an.  
Hier ist der Entwurf für die technische und funktionale Spezifikation:

## **Technische & Funktionale Spezifikation: „DigiMinuto“**

### **1\. Architektur & Datenhaltung**

* **Lokal-First & P2P:** Keine zentrale Cloud-Datenbank. Die Daten liegen verschlüsselt auf den Smartphones der Teilnehmer. Der Abgleich erfolgt direkt von Gerät zu Gerät (via Bluetooth/WLAN bei Treffen) oder über ein dezentrales, leichtgewichtiges Netzwerk (z. B. Nostr-Protokoll oder ein privates IPFS-Netzwerk).  
* **Gruppen & Communities:** Das System ist in isolierte, sichere Netzwerke (Gruppen) unterteilt. Die Teilnahme erfordert ein kryptografisch signiertes Einladungs-Ticket ("Web of Trust"), sodass Communities wie ein lokales Dorf oder ein Tauschring unter sich bleiben.
* **Kryptografie (Schlüsselpaare):** Jeder Teilnehmer generiert bei der Einrichtung ein Schlüsselpaar (Public Key \= Kontonummer/ID; Private Key \= Digitale Unterschrift).

### **2\. Der digitale Gutschein (Token-Schöpfung)**

Im Gegensatz zu Bitcoin wird Geld hier nicht durch Rechenleistung (Mining) geschöpft, sondern durch ein **kryptografisches Drei-Parteien-Versprechen** (*Web of Trust*).

* **Guthaben-Generierung:** Ein Nutzer erstellt in seiner App ein Schöpfungs-Zertifikat über z. B. $180 \\text{ DigiMinutos}$ (3 Stunden).  
* **Die digitale Bürgschaft:** Das Zertifikat ist so lange gesperrt (Wert: 0), bis **zwei verifizierte Bürgen** aus dem Netzwerk den Datensatz mit ihrem Private Key digital signieren.  
* **Schöpfungslimit (Hard Cap):** Die Software erlaubt hardcodiert maximal die Schöpfung von $1.800 \\text{ DigiMinutos}$ (30 Stunden) pro Nutzer und Kalenderjahr.

### **3\. Transaktionen & Validierung**

* **Offline-Fähigkeit (Wichtig für den ländlichen Raum):** Transaktionen müssen per QR-Code direkt zwischen zwei Handys ohne Internetverbindung funktionieren. Die Geräte tauschen kryptografisch signierte Quittungen aus. Sobald eines der Geräte wieder Netz hat, wird die Transaktion ins dezentrale Logbuch übertragen.  
* **Teilbarkeit:** 1 DigiMinuto ist die kleinste Einheit (entspricht 1 Minute). Keine Nachkommastellen nötig.

### **4\. Das Reputations-Register (Ersatz für soziale Kontrolle)**

Um das Problem von Trittbrettfahrern digital zu lösen, ohne eine zentrale Sperrliste zu führen:

* **Bürgen-Verknüpfung:** Jeder DigiMinuto-Token behält im Datensatz die Information, *wer* ihn ursprünglich geschöpft und *wer* dafür gebürgt hat.  
* **Der „Ramsch-Filter“:** Verweigert ein Nutzer dauerhaft die Gegenleistung, können Geschädigte dies im Netzwerk markieren. Die Wallet-Apps der anderen Teilnehmer erkennen dann automatisch: *„Achtung, dieser angebotene DigiMinuto wurde von Nutzer X geschöpft, der als unzuverlässig gilt. Akzeptieren?“* Der Wert des Tokens reguliert sich über die digitale Reputation der Bürgen.

### **5\. Technische Komponenten (Mindestanforderung)**

| Komponente | Technologie (Beispiel) | Funktion |
| :---- | :---- | :---- |
| **Frontend** | Flutter oder React Native | Leichtgewichtige App für Android/iOS, läuft auch auf älteren Smartphones. |
| **P2P-Abgleich** | Nostr (Relays) / Libp2p | Synchronisation der Transaktions-Logbücher ohne zentralen Server. |
| **Verschlüsselung** | Ed25519 (Signaturen) | Erzeugung sicherer digitaler Unterschriften für Transaktionen und Bürgschaften. |
| **Datenbank (Lokal)** | SQLite / Hive | Verschlüsselte Speicherung des eigenen Kontostands und der bekannten Kontakte auf dem Gerät. |

### **Sicherheits- und Datenschutz-Richtlinie (Privacy by Design)**

* **Keine Klarnamenpflicht auf Protokollebene:** Das System arbeitet nur mit IDs (Public Keys). Die Verknüpfung zu echten Personen (wer ist mein Nachbar?) erfolgt ausschließlich lokal im Adressbuch des jeweiligen Nutzers.  
* **Schutz vor Überwachung:** Da es keine zentrale Stelle gibt, kann das System nicht zentral abgeschaltet, zensiert oder vom Finanzamt automatisiert ausgelesen werden. Jede Gemeinschaft (z. B. ein Dorf) bleibt Herr über ihre eigenen Daten.

