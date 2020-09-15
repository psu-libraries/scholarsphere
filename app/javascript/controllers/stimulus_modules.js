// Cross-site forgery protection is disabled in Rails' test environment and there are no tokens included in any
// pages. Here we just send an empty string; however, if this were to outside the test environment, the protection
// would be active and it would prevent the request.
export function csrfToken () {
  const node = document.querySelector('meta[name=csrf-token]')
  if (node === null) {
    return ''
  } else {
    return node.content
  }
}
