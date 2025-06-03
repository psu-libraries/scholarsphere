export function generateUploadedFileData (success) {
  return JSON.stringify({
    id: success.uploadURL.match(/\/cache\/([^?]+)/)[1],
    storage: 'cache',
    metadata: {
      size: success.data.size,
      filename: success.data.name,
      mime_type: success.data.type,
      alt_text: success.meta.alt_text
    }
  })
}

export function simulateEditAndUpload () {
  const editButton = document.querySelector('.uppy-u-reset')

  if (editButton) {
    editButton.click()
    setTimeout(() => {
      document.addEventListener('click', (e) => {
        if (e.target.type === 'submit') {
          setTimeout(() => {
            const uploadButton = document.querySelector('.uppy-StatusBar-actionBtn--upload')
            if (uploadButton) {
              uploadButton.click()
            }
          }, 100)
        }
      })
    }, 100)
  }
}
