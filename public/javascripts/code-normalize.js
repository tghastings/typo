// Normalize indentation in code blocks
// Allows HTML source to be nicely indented while displaying correctly
document.addEventListener('DOMContentLoaded', function() {
  document.querySelectorAll('pre code').forEach(function(code) {
    var lines = code.innerHTML.split('\n');

    // Skip if single line or empty
    if (lines.length <= 1) return;

    // Remove empty first/last lines (from HTML formatting)
    while (lines.length && lines[0].trim() === '') lines.shift();
    while (lines.length && lines[lines.length - 1].trim() === '') lines.pop();

    if (lines.length === 0) return;

    // Find minimum indentation (ignoring empty lines)
    var minIndent = Infinity;
    lines.forEach(function(line) {
      if (line.trim() === '') return;
      var match = line.match(/^(\s*)/);
      if (match && match[1].length < minIndent) {
        minIndent = match[1].length;
      }
    });

    // Strip minimum indentation from all lines
    if (minIndent > 0 && minIndent < Infinity) {
      lines = lines.map(function(line) {
        return line.slice(minIndent);
      });
      code.innerHTML = lines.join('\n');
    }
  });
});
