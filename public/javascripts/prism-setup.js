// Prism.js syntax highlighting setup
document.addEventListener('DOMContentLoaded', function() {
  // Add language class to parent pre element for proper highlighting
  document.querySelectorAll('pre > code[class*="language-"]').forEach(function(code) {
    var pre = code.parentElement;
    var langClass = Array.from(code.classList).find(function(c) {
      return c.startsWith('language-');
    });
    if (langClass && !pre.classList.contains(langClass)) {
      pre.classList.add(langClass);
    }
    pre.classList.add('line-numbers');
  });

  // Add line-numbers to all pre elements with code
  document.querySelectorAll('pre:not(.line-numbers)').forEach(function(pre) {
    if (pre.querySelector('code')) {
      pre.classList.add('line-numbers');
    }
  });

  // Trigger Prism highlighting
  if (typeof Prism !== 'undefined') {
    Prism.highlightAll();
  }

  // Add copy buttons to code blocks
  document.querySelectorAll('pre').forEach(function(pre) {
    var code = pre.querySelector('code');
    if (!code) return;

    // Create copy button
    var btn = document.createElement('button');
    btn.className = 'code-copy-btn';
    btn.setAttribute('aria-label', 'Copy code');
    btn.innerHTML = '<svg viewBox="0 0 24 24" width="16" height="16"><path fill="currentColor" d="M16 1H4c-1.1 0-2 .9-2 2v14h2V3h12V1zm3 4H8c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h11c1.1 0 2-.9 2-2V7c0-1.1-.9-2-2-2zm0 16H8V7h11v14z"/></svg>';

    btn.addEventListener('click', function() {
      var textToCopy = code.textContent;

      navigator.clipboard.writeText(textToCopy).then(function() {
        btn.innerHTML = '<svg viewBox="0 0 24 24" width="16" height="16"><path fill="currentColor" d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/></svg>';
        btn.classList.add('copied');
        setTimeout(function() {
          btn.innerHTML = '<svg viewBox="0 0 24 24" width="16" height="16"><path fill="currentColor" d="M16 1H4c-1.1 0-2 .9-2 2v14h2V3h12V1zm3 4H8c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h11c1.1 0 2-.9 2-2V7c0-1.1-.9-2-2-2zm0 16H8V7h11v14z"/></svg>';
          btn.classList.remove('copied');
        }, 2000);
      });
    });

    pre.style.position = 'relative';
    pre.appendChild(btn);
  });
});
