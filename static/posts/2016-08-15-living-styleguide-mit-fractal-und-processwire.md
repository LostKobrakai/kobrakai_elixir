---
title: Living Styleguide mit Fractal und ProcessWire
tags: 
  - blog
  - design
  - programmierung
language: DE
---

Bei der Thematik von Styleguides und Pattern-Bibliotheken sind sich heutzutage wohl die meisten Entwickler darin einig, dass sie ein wertvolles Tool sind, um ein Projekt auch von Seiten des Interfaces modular zu gestalten. Trotz meines Interesse an der Thematik hat sich jedoch bisher das Anlegen solch einer Bibliothek nie voll in meinen Workflow integriert.

Die Hauptschuld dafür hat — zumindest für meine Anwendungsfälle — vor allem der Zusatzaufwand, der in die Pflege einer solchen Bibliothek fließt. Da viele Styleguide Generatoren auf Node basieren werden in den meisten Fällen auch JavaScript Templating Sprachen verwendet. Eine direkte Verwendung von der PHP Seite ist daher meist nicht direkt möglich. Damit bleibt erstmal nur das manuelle Abgleichen von Library und Live-Umgebung.

Mein zweiter Kritikpunkt an einigen Systemen ist zudem die Datenstruktur. Diese ist meist eher starr aufgebaut, als wäre der Styleguide ein geschlossenes Projekt. Möchte man einen Living Styleguide ist jedoch genau das nicht von Vorteil und man müsste zwischen dem eigentlichen Projekt und dem Styleguide einige Ordner und Strukturen querverlinken. Manche Systeme gehen sogar soweit, dass Templates oder Metadaten komplett als JSON Dateien abgespeichert werden, was eine potentielle externe Nutzung noch komplexer macht.

---

Vor kurzem bin ich dann auf [Fractal](http://fractal.build/) gestoßen. Fractal läuft, wie so viele andere Libraries auch, unter Node.js. Somit ist das Problem der Templating Sprache ebenso vorhanden. Der Punkt der mich überrascht hatte war der Aufbau der Dateistruktur dahinter. Fractal geht hier einen großen Schritt weiter als andere Systeme. Während die minimal Version einer Komponente nur aus einer einzigen Template Datei besteht lässt sich die Definition auch zu einem Ordner mit folgenden Dateien ausdehnen, wenn nötig.

```
├── components
│   ├── _preview.hbs
│   ├── blockquote
│   │   ├── blockquote.config.yml
│   │   ├── blockquote--fancy.hbs
│   │   ├── blockquote.hbs
│   │   ├── blockquote.scss
│   │   ├── modal-quote.js
│   │   ├── screenshot.png
│   │   └── README.md
```

Diese Struktur ist schon für sich allein sehr übersichtlich und lässt dem Nutzer sehr viele Möglichkeiten eine Komponente umfassend zu beschreiben. Das Frontend setzt hier noch das i-Tüpfelchen, in dem es die verfügbaren Daten noch mit einem angenehmen Interface aufbereitet.

![](/images/blog/fractal-processwire/intro.png)

Bei der Installation von Fractal stellt man auch sofort fest, dass hier im Sinne der Flexibilität einiges anderes läuft als bei Alternativen. Eine der ersten Einstellungen, die man trifft: Wo im Dateisystem sollen Komponenten, Dokumentation oder Assets abgelegt werden. Das macht es einfach das System neben z.B. einer CMS oder anderen Projektstruktur zu integrieren und auf bereits bestehende Ordnerstrukturen zurückzugreifen.

---

Zur Verwendung als Living Styleguide System fehlte nun nur eine Templating Option, die sowohl in Fractal als auch im PHP CMS verfügbar ist. Die einzige Templating Sprache die Node und PHP offiziell supportet ist Mustache, die nicht den Featureumfang bietet den ich benötige.

Geht man nun von PHP aus, dann ist die Templating Sprache der Wahl im Moment eigentlich Twig. Es gibt zwar mit twig.js eine JavaScript Adaption, allerdings ist man hier von davon Abhängig, das Features in beiden Systemen funktionieren. Die Basis-Implementation in Fractal mit twig.js unterstützt zudem keine @component Syntax, die anstelle von Pfadangaben verwendet wird.

Nach einen kurzen Chat mit dem Entwickler von Fractal im eigenen Slack-Channel kam mir dann der Gedanke das man Templates auch direkt in PHP rendern lassen könnte. Ein kurzer Blick auf npm ergab, dass das Packet node-twig genau das tat, fehlte somit nur der [Adapter](https://github.com/LostKobrakai/twig) für Fractal den ich inzwischen erstellt habe. Der Adapter ist nun auf GitHub verfügbar, genauso wie das dazugehörige [composer Packet](https://github.com/LostKobrakai/frctl-twig).

---

Nun kommen wir zum Schluss noch zu dem Punkt ProcessWire, der ja schon in der Überschrift steht, bisher aber nicht angesprochen wurde. Nachdem ich fast ausschließlich mit ProcessWire arbeite ist natürlich auch die [Beispiel-Anbindung mit ProcessWire](https://github.com/LostKobrakai/processwire-fractal) umgesetzt. Ich denke es wäre jedoch durchaus auch in anderen Systemen möglich die nötigen Anpassungen zu treffen.

Im folgenden gehe ich von folgender Struktur aus, wobei diese durchaus auch noch an individuelle Bedürfnisse anpassbar ist.

```
├── project-root
│   ├── docs
│   ├── fractal
│   │   └── docs
│   ├── site
│   │   ├── templates
│   │   │   ├── views
│   │   │   │   └── basic-page.twig
│   │   │   └── basic-page.php
│   │   ├── init.php
│   │   └── fractal-handles.php
│   ├── wire
│   ├── fractal.js
│   ├── composer.json
│   ├── package.json
│   └── index.php
```

`docs/` In diesem Ordner wird die statische Version von Fractal erstellt.

`fractal/` Hier kommen die Quelldaten für die Fractal Dokumentation unter, aber auch Dinge wie Veränderungen am Fractal Theme können hier abgelegt sein.

`site/templates/views/` Das ist der Ordner in dem alle Komponenten abgelegt sind, wie es oben beschrieben ist. Somit sind die Templates, aber auch die Metadaten auch als Teil des CMS zu verstehen.

`site/init.php & site/fractal-handles.php` Hier wird Twig konfiguriert und dafür vorbereitet auch im CMS Kontext mit dem @handle Kontext von Fractal umgehen zu können.

`fractal.js` Die Konfigurations-Datei für Fractal.

`composer.json & package.json` Sorgen dafür, dass die benötigten Bibliotheken und Adapter installiert werden mit composer install sowie npm install.

Mit diesem Setup hat man in ProcessWire sehr einfach die Möglichkeit auf bereits definierte Komponenten zuzugreifen und diese mit den nötigen Daten zu befüllen.

```php
<?php

echo $twig->render('@basic-page', array(
    'title' => $page->title,
    'editable' => $page->editable()
);
```

Gleichzeitig greift Fractal auf die selben Templates zu und rendert diese mit Daten die in den [Kontext-Dateien](http://fractal.build/guide/core-concepts/context-data) definiert sind.

```yaml
name: basic-page
context:
  title: Hello World
  editable: false
```

Das Setup ermöglicht es alle Teile des Interfaces unabhängig von der eigentlichen Applikation anzusehen und zu verwalten. Das Gestalten der einzelnen Module rückt viel mehr in den Vordergrund und das Backend ist im optimalen Fall rein für die Kombination der bereits bestehenden Komponenten zuständig.

---

Um das System auch nicht nur in der Theorie sondern auch an einem praktischen Beispiel zu testen hab ich meine private Homepage komplett auf Twig mit Fractal umgestellt und ein wenig mit Reverse-Engineering die einzelnen Komponenten herausgetrennt. Im Idealfall macht man das natürlich nicht nachträglich ;)

![](/images/blog/fractal-processwire/example.png)

Mit den Änderungen ist nun mein ProcessWire “Template-File” ein reiner Controller, wie man es von MCV Frameworks kennt und von meinem HTML/PHP Spaghetti Code ist nur ein kleiner Block übrig geblieben, der das oben angezeigte Twig Template mit den richtigen Daten befüllt.

```php
<?php
echo $twig->render('@index', array(
 'headline' => $page->headline,
 'subline' => $page->subhead,
 'body' => $page->body,
 'projectsHeadline' => __('Projekte'),
 'projects' => $projects,
 'footerLinks' => $pages->find("template=contact|impressum, sort=sort")->explode(array('title', 'url')),
 'photoUrl' => 'https://foto.kobrakai.de/',
 'photoTitle' => __('Meine Fotografien'),
 'images' => $images,
 'photoJson' => $galleryJSON
));
```

---

Alles in Allem bin ich mit dem System bisher super zufrieden. Fractal bietet neben dem oben Beschriebenen noch einiges mehr an Möglichkeiten zur Anpassung und weitere coole Features. Dadurch, dass die Twig Templates nicht direkt aus ProcessWire geladen und gerendert werden ist man total frei darin wie man die nötigen Daten generiert und an welchem Fleck man dann tatsächlich Markup generiert und ausgibt. Man könnte das System somit sogar ohne Probleme Stück-für-Stück in ein bestehendes Projekt einarbeiten oder auch nur für einige Komponenten und den Rest manuell erstellen. Meine nächsten Projekte werden auf jeden Fall in der Kombination starten und dann wird sich herausstellen, wie gut es sich im Arbeitsalltag schlägt.

---

Links:

Fractal: [http://fractal.build/](http://fractal.build/)
ProcessWire: [http://processwire.com/](http://processwire.com/)

Twig-Adapter: [https://github.com/LostKobrakai/twig](https://github.com/LostKobrakai/twig)
PHP-Companion: [https://github.com/LostKobrakai/frctl-twig](https://github.com/LostKobrakai/frctl-twig)
Bootstraper für ProcessWire: [https://github.com/LostKobrakai/processwire-fractal](https://github.com/LostKobrakai/processwire-fractal)
