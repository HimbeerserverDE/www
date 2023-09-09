---
title: IPv6 mit Vodafone DSL
---

Einführung
==========

Seit kurzem (2023) habe ich einen DSL-Anschluss bei Vodafone.
Leider wurde auf diesem nur IPv4 geschaltet.
Wie verbreitet diese Anschlussart ist oder warum sie bei Neuverträgen
noch vergeben wird ist mir leider nicht bekannt. Allerdings lässt sich IPv6
am DSL-Anschluss von Vodafone ohne große Probleme freischalten.

Anschlussarten
==============

Im Festnetzbereich für Privatkunden gibt es bei Vodafone drei verbreitete
Anschlusstypen: IPv4 only, Dual Stack und DS-Lite. Dabei wird Dual Stack
nie automatisch geschaltet. Ob man IPv4 only oder DS-Lite bekommt
ist bei Vertragsabschluss leider nicht ersichtlich.

Sollte IPv4 only nicht der Standard sein, ist die Ursache bei mir
wahrscheinlich entweder der Vertragsabschluss über ein Vergleichsportal
oder die Wahl der Option "Eigenhardware Kunde" bei der Routerwahl.
Letzteres kommt deshalb in Frage, weil es auf im Kabel-Segment
zu einer anderen Art der Adressvergabe führt.

Anschlussart prüfen
===================

Welche Protokolle geschaltet werden, lässt sich im alten Kundenportal einsehen.
Dazu meldet man sich auf https://dsl.vodafone.de an und navigiert zu
`Meine Produkte > Internet`. Dort steht unter dem Punkt "Konfiguration",
wie man angebunden ist. Ist dort "IPv4" zu sehen, so bekommt man zwar
eine dynamische, öffentliche IPv4-Adresse, aber keinen IPv6-Zugang.

Technische Informationen zur Nichtverfügbarkeit
===============================================

Der Verbindungsaufbau erfolgt per PPPoE. Dabei handeln beide Seiten
die Protokolle aus, die sie verwenden möchten, und tauschen dabei
Konfigurationen aus. Hierzu kommen IPCP (für natives IPv4)
und IPv6CP (für IPv6) zum Einsatz.

An einem IPv4 only-Anschluss sendet der Access Concentrator keine
Anfrage zur IPv6CP-Aushandlung. Sendet der eigene Router eine,
so gibt es eine LCP Protocol-Reject als Antwort. Dementsprechend
können keine IPv6-Pakete ausgetauscht werden.

Interessant ist, dass falsche Zugangsdaten zumindest vorübergehend
zu Dual Stack führen. Davon ist mehrfach im Forum zu lesen
und ich selbst konnte das an meinem Anschluss auch reproduzieren.
Falsche Zugangsdaten führen nicht dazu, dass die Verbindung abgelehnt wird.
Stattdessen bekommt man Dual Stack, wird allerdings von den Providerseitigen
Firewalls nicht ins Internet gelassen. Unverschlüsseltes HTTP
wird auf eine Fehlerseite umgeleitet.

Dies zu testen ermöglicht es, die potenzielle Verfügbarkeit von IPv6
an seinem Anschluss zu überprüfen.

IPv6 freischalten lassen
========================

Die Aktivierung von IPv6 kann man leider nicht selbst vornehmen.
Hierzu kontaktiert man die Hotline unter `0800 172 1212`.
Falls man gefragt wird, ob es um die Rufnummer geht, von der man anruft,
antwortet man mit "Nein". Stattdessen wird die Kundennummer angegeben.
Beim Thema wählt man zuerst "Anderes", anschließend "Vertrag"
und dann "Technische Frage". Dann schildert man, dass aktuell nur IPv4
im Kundenportal eingestellt ist, und dass man auf Dual Stack umgestellt
werden möchte. Falls die Frage nach "öffentlich" oder "privat" gestellt wird,
sollte man diese mit "öffentlich" beantworten. Ansonsten bekommt man DS-Lite,
was allein schon aus Performance-Gründen meistens die schlechtere Wahl ist.

(Kundenseitige) Aktivierung
===========================

Die Umstellung des Adressierungstyps erfolgt erst in der Nacht.
Danach sollte an der zuvor genannten Stelle im Kundenportal
unter Konfiguration der Wert "IPv6/v4 public" stehen, es sei denn, man hat sich
für etwas anderes (z.B. "IPv6/v4 private" für DS-Lite) entschieden.

Um diese Änderung tatsächlich anzuwenden, muss die Verbindung einmal neu
aufgebaut werden. Im Zweifel geschieht dies durch einen manuellen
Neustart des Routers. Selbstverständlich muss dazu natives IPv6 vom Router
unterstützt werden und eingeschaltet sein.

Router-Konfiguration
====================

Bei gängigen Modellen sollten die Standardeinstellungen bereits ausreichen.
Folgende Einstellungen sind für Bastlerfirmwares oder im Fehlerfall zu setzen:

* DHCPv6 Rapid Commit: Ein
* Bestimmte Präfixlänge anfordern: Ja, /56 (alternativ sollte auch Nein funktionieren)
* DS-Lite: Aus (public) / Ein (private)
* AFTR für DS-Lite: per DHCPv6 beziehen

Rapid Commit ist vermutlich am wichtigsten. Ob auch ohne Rapid Commit
eine Verbindung über IPv6 zustande kommt, habe ich nicht überprüft.

Was bekommt man?
================

Es werden IPv6 Router Advertisements verwendet, um das Default-Gateway einzurichten.
Allerdings ist das bei einem Point-to-Point-Tunnel eigentlich egal, da eine Route
ohne Gateway über die PPP-Schnittstelle ebenso funktioniert.

Per DHCPv6 wird maximal ein /56-Präfix und zwei DNS-Server zugewiesen.
Bei DS-Lite gibt es zusätzlich einen AFTR.

Ob das zugewiesene Präfix statisch ist, konnte ich noch nicht feststellen.
Vermutlich ist dies nur bedingt der Fall.

Bemerkenswert ist, dass keine einzelne WAN-Adresse an den Router selbst
vergeben wird, anders als es bei Kabel-Internet der Fall ist.
Dies lässt sich umgehen, indem man ein Subnetz der WAN-Schnittstelle zuweist.
Ich verwende dazu das erste /64-Netz und nutze `::1` als Interface Identifier.
Es sollte außerdem möglich sein, eine der LAN-Adressen des Routers
für diesen Zweck mitzunutzen.

VoIP
====

Anders als bei Kabel unterstützen die SIP-Registrars Dual Stack.
Ist der Client (bzw. die Telefonanlage) auch dazu fähig, sollte man beides
einrichten. In meinem Fall wird clientseitig nur IPv4 unterstützt,
sodass sich nichts ändert. Sollte diese Möglichkeit eines Tages verschwinden,
ist die Nutzung eines einfachen L4-Proxys ein funktionierender Workaround.

[Return to Guide List](/md/guides.md)

[Return to Index Page](/md/index.md)
