import 'dart:ui_web' as ui;
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:async';

void registerWebAd() {
  ui.platformViewRegistry.registerViewFactory('ad-view', (int viewId) {
    final adElement = html.Element.html(
      '''
      <ins class="adsbygoogle"
           style="display:inline-block;width:320px;height:50px"
           data-ad-client="ca-pub-8355736208842576"
           data-ad-slot="9287383916"></ins>
      ''',
      treeSanitizer: html.NodeTreeSanitizer.trusted,
    );
    
    Timer(const Duration(milliseconds: 100), () {
      try {
        js.context.callMethod('eval', ['(adsbygoogle = window.adsbygoogle || []).push({});']);
      } catch (e) {
        html.window.console.warn('AdSense failed to push: $e');
      }
    });

    return html.DivElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.display = 'flex'
      ..style.justifyContent = 'center'
      ..style.alignItems = 'center'
      ..append(adElement);
  });
}
