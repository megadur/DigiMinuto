# DigiMinuto

DigiMinuto ist ein lokaler, dezentraler und kryptografisch abgesicherter Peer-to-Peer-Gutschein, basierend auf der Philosophie des "Minuto" (Schöpfung durch Bürgen). 

Das Ziel dieses Projekts ist es, die Schwachstellen von physischem Papiergeld (Fälschung, mangelnde Teilbarkeit, fehlende Transparenz) zu lösen, ohne dabei eine zentrale Cloud oder Bank zu benötigen.

## Kern-Konzepte

1. **Lokal-First & P2P:** Daten liegen verschlüsselt auf den Geräten der Nutzer.
2. **Web of Trust (3-Parteien-Schöpfung):** Ein Nutzer kann maximal 1800 "DigiMinutos" pro Jahr schöpfen. Die Schöpfung ist erst gültig, wenn zwei andere Nutzer aus dem Netzwerk digital dafür bürgen (kryptografische Signatur).
3. **Offline-Tausch:** Transaktionen finden primär direkt zwischen zwei Smartphones statt, bevorzugt über QR-Codes.
4. **Reputation:** Jeder Token trägt die Historie seines Schöpfers und der Bürgen mit sich. 

Für detaillierte Informationen zur geplanten Architektur, siehe [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

Damit haben wir jetzt ein absolut rundes und sehr mächtiges Werkzeug:

 * Die Basis: Kryptografisch sichere Tokens und Bürgschaften (Web of Trust).
* Die Erweiterung: Der Marktplatz für lokale Angebote und Gesuche.
* Die Struktur: Sichere, einladungsbasierte Gruppen, um das Netzwerk überschaubar und vertrauenswürdig zu halten.
* Die Verfügbarkeit: Als installierbare App oder komplett ohne Installation als Web-App direkt im Browser.
