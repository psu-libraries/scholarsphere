# 3. Do Not Create Derivatives

Date: 2019-12-10

## Status

Accepted

## Context

When viewing different file types over the web, large video files or other non-standard files, may not display well in
the browser, so the common solution is to create derivatives for a better user experience. These also include thumbnails
for a sample picture of what the resource looks like.

Managing and creating derivatives can be hard and requires careful architectural considerations.

However, the modern web has adapted to larger files, and generally handles a wider array of file types than it did in
the past. Also, thumbnails only work for image and video formats. Generic icon-based images for any file type can be
more informative.

## Decision

Scholarsphere will not create any derivative files. Icons will be used to represent file types, and the original
uploaded file can be rendered when applicable.

## Consequences

Users may expect thumbnails or other representative imagery, and playback of large A/V files might tax our systems.
