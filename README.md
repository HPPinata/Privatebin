# Privatebin

Benötigte Pakete:
 - Docker
 - Docker-Compose
 - curl

Je nach Anwendungsfall müssen der ACME Staging Link und/oder Lokale (self signed) Zertifikate auskommentiert werden (Zeile 15/16).  
Der Server muss auf Ports 80 und 443 erreichbar sein

```
curl -O https://raw.githubusercontent.com/HPPinata/Privatebin/main/setup.bash
cat setup.bash
bash setup.bash
rm setup.bash
```
