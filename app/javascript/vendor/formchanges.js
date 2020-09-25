/*
 * FormChanges(string FormID | DOMelement FormNode)
 * Returns an array of changed form elements.
 * An empty array indicates no changes have been made.
 * NULL indicates that the form does not exist.
 *
 * By Craig Buckler,   http://twitter.com/craigbuckler
 * of OptimalWorks.net http://optimalworks.net/
 * for SitePoint.com   http://sitepoint.com/
 *
 * Refer to http://blogs.sitepoint.com/javascript-form-change-checker/
 *
 * This code can be used without restriction.
 */
function FormChanges (form) {
  // get form
  if (typeof form === 'string') form = document.getElementById(form)
  if (!form || !form.nodeName || form.nodeName.toLowerCase() !== 'form') return null

  // find changed elements
  var changed = []; var n; var c; var def; var o; var ol; var opt
  for (var e = 0, el = form.elements.length; e < el; e++) {
    n = form.elements[e]
    c = false

    switch (n.nodeName.toLowerCase()) {
      // select boxes
      case 'select':
        def = 0
        for (o = 0, ol = n.options.length; o < ol; o++) {
          opt = n.options[o]
          c = c || (opt.selected !== opt.defaultSelected)
          if (opt.defaultSelected) def = o
        }
        if (c && !n.multiple) c = (def !== n.selectedIndex)
        break

        // input / textarea
      case 'textarea':
      case 'input':

        switch (n.type.toLowerCase()) {
          case 'checkbox':
          case 'radio':
            // checkbox / radio
            c = (n.checked !== n.defaultChecked)
            break
          default:
            // standard values
            c = (n.value !== n.defaultValue)
            break
        }
        break
    }

    if (c) changed.push(n)
  }

  return changed
}

export default FormChanges
