import 'dart:ui_web' as ui;
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:async';

bool _isAdRegistered = false;

void registerWebAd() {
  if (_isAdRegistered) return;
  _isAdRegistered = true;

  try {
    ui.platformViewRegistry.registerViewFactory('ad-view', (int viewId) {
      final adElement = html.Element.html(
        '''
        <ins class="adsbygoogle"
             style="display:inline-block;width:320px;height:50px"
             data-ad-client="ca-pub-8355736208842576"
             data-ad-slot="6096886435"
             data-ad-format="auto"
             data-full-width-responsive="true"></ins>
        ''',
        treeSanitizer: html.NodeTreeSanitizer.trusted,
      );
      
      Timer(const Duration(milliseconds: 200), () {
        try {
          js.context.callMethod('eval', ['(adsbygoogle = window.adsbygoogle || []).push({});']);
        } catch (e) {
          html.window.console.warn('AdSense push warning: $e');
        }
      });

      return html.DivElement()
        ..style.width = '320px'
        ..style.height = '50px'
        ..style.display = 'flex'
        ..style.justifyContent = 'center'
        ..style.alignItems = 'center'
        ..append(adElement);
    });
  } catch (_) {}
}
