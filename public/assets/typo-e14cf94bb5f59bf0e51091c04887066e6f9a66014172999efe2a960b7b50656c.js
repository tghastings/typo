window._lang = window._lang || "default";
window._l10s = window._l10s || {};
window._l10s[_lang] = window._l10s[_lang] || {};

function _(string_to_localize) {
  var args = [];
  var string_to_localize = arguments[0];
  for (var i = 1; i < arguments.length; i++) {
    args.push(arguments[i]);
  }
  var translated = _l10s[_lang][string_to_localize] || string_to_localize;
  if (typeof translated == 'function') {
    return translated.apply(window, args);
  }
  if (Array.isArray(translated)) {
    if (translated.length == 3) {
      translated = translated[args[0] == 0 ? 0 : (args[0] > 1 ? 2 : 1)];
    } else {
      translated = translated[args[0] > 1 ? 1 : 0];
    }
  }
  // Simple interpolation: replace #{0}, #{1}, etc.
  return translated.replace(/#\{(\d+)\}/g, function(match, index) {
    return args[parseInt(index)] !== undefined ? args[parseInt(index)] : match;
  });
}

function register_onload(func) {
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', func);
  } else {
    func();
  }
}

function show_dates_as_local_time() {
  document.querySelectorAll('span.typo_date').forEach(function(e) {
    var classname = e.className;
    var gmtdate = '';
    var res = classname.match(/gmttimestamp-(\d+)/);
    if (!res) {
      gmtdate = e.title;
    } else {
      gmtdate = new Date();
      gmtdate.setTime(parseInt(res[1]) * 1000);
    }
    e.textContent = get_local_time_for_date(gmtdate);
  });
}

function get_local_time_for_date(time) {
  var system_date;
  if (time instanceof Date) {
    system_date = time;
  } else {
    system_date = new Date(time);
  }
  var user_date = new Date();
  var delta_minutes = Math.floor((user_date - system_date) / (60 * 1000));
  if (Math.abs(delta_minutes) <= (8 * 7 * 24 * 60)) {
    var distance = distance_of_time_in_words(delta_minutes);
    if (delta_minutes < 0) {
      return _("#{0} from now", distance);
    } else {
      return _("#{0} ago", distance);
    }
  } else {
    return _('on #{0}', system_date.toLocaleDateString());
  }
}

function distance_of_time_in_words(minutes) {
  if (isNaN(minutes)) return "";
  minutes = Math.abs(minutes);
  if (minutes < 1) return _('less than a minute');
  if (minutes < 50) return _('#{0} minute' + (minutes == 1 ? '' : 's'), minutes);
  if (minutes < 90) return _('about one hour');
  if (minutes < 1080) return _("#{0} hours", Math.round(minutes / 60));
  if (minutes < 1440) return _('one day');
  if (minutes < 2880) return _('about one day');
  return _("#{0} days", Math.round(minutes / 1440));
}

function commentAdded(request) {
  var commentList = document.getElementById('commentList');
  if (commentList && commentList.lastElementChild) {
    commentList.lastElementChild.style.display = 'block';
  }
  var dummy = document.getElementById('dummy_comment');
  if (dummy) dummy.remove();
  var form = document.getElementById('commentform');
  if (form) {
    var bodyField = form.elements["comment_body"];
    if (bodyField) {
      bodyField.value = '';
      bodyField.focus();
    }
  }
}

function failure(request) {
  var errors = document.getElementById('errors');
  if (errors) {
    errors.innerHTML = request.responseText;
    errors.style.backgroundColor = '#ffff99';
  }
}

function loading() {
  var submitBtn = document.getElementById('form-submit-button');
  if (submitBtn) submitBtn.disabled = true;
  var loadingEl = document.getElementById('comment_loading');
  if (loadingEl) loadingEl.style.display = 'block';
  var preview = document.getElementById('preview');
  if (preview) preview.style.display = 'none';
}

function complete(request) {
  var loadingEl = document.getElementById('comment_loading');
  if (loadingEl) loadingEl.style.display = 'none';
  var form = document.getElementById('commentform');
  if (form) form.style.display = 'block';
  var submitBtn = document.getElementById('form-submit-button');
  if (submitBtn) submitBtn.disabled = false;

  if (request && request.status == 200) {
    commentAdded();
  }
}

function popup(mylink, windowname) {
  if (!window.focus) return true;
  window.open(mylink, windowname, 'width=400,height=500,scrollbars=yes');
  return false;
}

function check_all(checkbox) {
  var form = checkbox.form;
  for (var z = 0; z < form.length; z++) {
    if (form[z].type == 'checkbox' && form[z].name != 'checkall') {
      form[z].checked = checkbox.checked;
    }
  }
}

register_onload(function() {
  var form = document.getElementById('commentform');
  if (form) {
    var _author = getCookie('author');
    var _url = getCookie('url');

    if (_author != null && form.elements['comment[author]']) {
      form.elements['comment[author]'].value = _author;
    }
    if (_url != null && form.elements['comment[url]']) {
      form.elements['comment[url]'].value = _url;
    }

    var urlField = form.elements['comment[url]'];
    var emailField = form.elements['comment[email]'];
    if ((urlField && urlField.value != '') || (emailField && emailField.value != '')) {
      var guestUrl = document.getElementById('guest_url');
      var guestEmail = document.getElementById('guest_email');
      if (guestUrl) guestUrl.style.display = 'block';
      if (guestEmail) guestEmail.style.display = 'block';
    }
  }
});

register_onload(function() {
  var q = document.getElementById('q');
  if (q) q.setAttribute('autocomplete', 'off');
});

register_onload(show_dates_as_local_time);
