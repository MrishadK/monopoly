import re

path = r'lib/ui/overlays/hud_overlay.dart'

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

applied = []

# Fix 1: Wrap root Stack in SizedBox.expand with StackFit.expand
old1 = (
    '    return Stack(\r\n'
    '      children: [\r\n'
    '        // ==================== TRANSACTION NOTICE (3-SECOND BANNER) ====================\r\n'
    '        _buildTransactionNotice(context, gameState),\r\n'
)
new1 = (
    '    return SizedBox.expand(\r\n'
    '      child: Stack(\r\n'
    '        fit: StackFit.expand,\r\n'
    '        children: [\r\n'
    '          // ==================== TRANSACTION NOTICE (3-SECOND BANNER) ====================\r\n'
    '          if (gameState.activeTransaction != null)\r\n'
    '            _buildTransactionNotice(context, gameState),\r\n'
)
if old1 in content:
    content = content.replace(old1, new1, 1)
    applied.append('Fix 1: Wrapped in SizedBox.expand')
else:
    print('WARNING: Fix 1 pattern not found')

# Fix 2: Close the SizedBox.expand
old2 = (
    '      ],\r\n'
    '    );\r\n'
    '  }\r\n'
    '\r\n'
    '  Widget _buildTopHeader'
)
new2 = (
    '        ],\r\n'
    '      ),\r\n'
    '    );\r\n'
    '  }\r\n'
    '\r\n'
    '  Widget _buildTopHeader'
)
if old2 in content:
    content = content.replace(old2, new2, 1)
    applied.append('Fix 2: Closed SizedBox.expand')
else:
    print('WARNING: Fix 2 pattern not found')

# Fix 3: Update _buildTransactionNotice fallback
old3 = '    if (notice == null) return const SizedBox.shrink();\r\n'
new3 = '    if (notice == null) return const Positioned(child: SizedBox.shrink());\r\n'
if old3 in content:
    content = content.replace(old3, new3, 1)
    applied.append('Fix 3: Updated _buildTransactionNotice fallback')
else:
    print('WARNING: Fix 3 pattern not found')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print('APPLIED:', ', '.join(applied) if applied else 'Nothing applied')

# Verify
with open(path, 'r', encoding='utf-8') as f:
    verify = f.read()
if 'SizedBox.expand' in verify and 'StackFit.expand' in verify:
    print('VERIFIED: SizedBox.expand with StackFit.expand is present')
else:
    print('ERROR: Fix not present in file!')
