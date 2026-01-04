// Convert all <time> elements to user's local timezone
(function() {
  function formatLocalTime(date) {
    const now = new Date();
    const diffMs = now - date;
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);

    // Show relative time for recent dates
    if (diffMins < 1) {
      return 'just now';
    } else if (diffMins < 60) {
      return diffMins === 1 ? '1 minute ago' : diffMins + ' minutes ago';
    } else if (diffHours < 24) {
      return diffHours === 1 ? '1 hour ago' : diffHours + ' hours ago';
    } else if (diffDays < 7) {
      return diffDays === 1 ? 'yesterday' : diffDays + ' days ago';
    }

    // For older dates, show formatted local date and time
    const options = {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      hour12: true
    };
    return date.toLocaleString(undefined, options);
  }

  function convertTimesToLocal() {
    const timeElements = document.querySelectorAll('time[datetime]');
    timeElements.forEach(function(el) {
      const datetime = el.getAttribute('datetime');
      if (datetime) {
        const date = new Date(datetime);
        if (!isNaN(date.getTime())) {
          el.textContent = formatLocalTime(date);
          el.setAttribute('title', date.toLocaleString());
        }
      }
    });
  }

  // Run on DOM ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', convertTimesToLocal);
  } else {
    convertTimesToLocal();
  }
})();
