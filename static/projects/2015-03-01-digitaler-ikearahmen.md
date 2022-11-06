---
title: Digitaler Ikearahmen
tags: 
  - project
  - featured
  - programmierung 
primary:
  type: image
  source: /images/digitaler-ikearahmen/picture_frame.jpg
  alt: ""
secondary:
  - type: image
    source: /images/digitaler-ikearahmen/internals_01.jpg
    alt: ""
  - type: image
    source: /images/digitaler-ikearahmen/internals_02.jpg
    alt: ""
---
Seit dem Ende meines Studiums und dem Projekt [decrescendo](/projekte/decrescendo/) habe ich nach einer günstigen Möglichkeit gesucht generative Programme und Versuche nicht nur am Arbeitscomputer zu zeigen, sondern diese auch in meine Umgebung zu integrieren. Vor ein paar Wochen bin ich dann im Internet auf einen ähnlichen Aufbau , wie diesen hier, gestoßen. Leider war dort ein iPad mini verbaut, was nicht wirklich meinen Preisvorstellungen entsprach. Die Idee den Ikea Bilderrahmen zu verwenden gefiel mir aber.

Um die Kosten zu senken habe ich mir dann anstatt des iPads einen Raspberry Pi im Model A+ besorgt. Dazu einen 8” Display und einige Kabel und schon war der persönliche Mini-Computer fertig. Leider ist der Respberry Pi nicht gerade die stärkste Computereinheit, daher musste ich von meiner bisher verwendeten Software Processing absehen. Diese läuft gekapselt in einer virtualisierten Java Umgebung, die nicht die beste Performance lieferte. Als Alternative kommt nun [openFrameworks](http://openframeworks.cc/) zum Einsatz. Dieses Framework basiert auf der Scriptsprache C++ und kann daher als ein lauffähiges Programm exportiert werden, dass unabhängig von virtuellen Umgebungen funktioniert. Zusätzlich dazu lässt sich auch die Grafikkarte zur Berechnung von Sketchdaten nutzen, was selbst aufwendigere 3D Darstellungen flüssig ablaufen lässt. 

Das oben gezeigte Bild ist ein Foto einer ersten Anwendung des Rahmens. Dabei wird über die API von Instagram ein Profil, in dem Falle mein eigenes, ausgelesen und die Bilder auf den Computer heruntergeladen. Danach werden sie in einer Slideshow durchrotiert. Eine anderes Testobjekt war die Implementation dieser Webseite [whatcolourisit.scn9a.org](http://whatcolourisit.scn9a.org/). Doch für solch feine Farbabstufungen ist leider der verwendete Bildschirm nicht geeignet.