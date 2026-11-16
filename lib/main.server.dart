/// The entrypoint for the **server** environment (static pre-rendering).
library;

import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';

import 'app.dart';
import 'main.server.options.dart';
import 'site.dart';

void main() {
  Jaspr.initializeApp(options: defaultServerOptions);

  runApp(
    Document(
      title: siteTitle,
      lang: 'en',
      base: '/',
      meta: const {'description': siteDescription},
      head: [
        meta(attributes: {'property': 'og:type'}, content: 'website'),
        meta(attributes: {'property': 'og:site_name'}, content: siteTitle),
        meta(attributes: {'property': 'og:description'}, content: siteDescription),
        meta(attributes: {'property': 'og:image'}, content: '$siteUrl/images/weirdnet-mark.svg'),
        meta(name: 'theme-color', content: '#001B3D'),
        link(
          href: '/fonts/InterVariable.woff2',
          rel: 'preload',
          attributes: {'as': 'font', 'type': 'font/woff2', 'crossorigin': ''},
        ),
        link(href: '/styles.css', rel: 'stylesheet'),
        link(href: '/favicon.svg', rel: 'icon', type: 'image/svg+xml'),
      ],
      body: const App(),
    ),
  );
}
