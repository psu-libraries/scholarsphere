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

