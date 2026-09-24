# Generate, Track, Improve — project page

Static page (plain HTML/CSS/JS, no build step), served by GitHub Pages.

```
python3 tools/serve.py 8000    # no-cache preview; then open http://localhost:8000
```

## Layout

| path | what |
|---|---|
| `index.html` | the page |
| `css/main.css`, `js/site.js` | styles (light/dark), tab/chip video players, BibTeX copy |
| `media/figures/` | figures cropped at 300 dpi from the final paper PDF |
| `media/video/`, `media/poster/` | web clips (720p, H.264, silent) and their poster frames |
| `paper/` | compressed copy of the paper |
| `tools/make_media.sh` | rebuilds every clip and poster from the original footage |

`tools/make_media.sh` only *reads* the originals and refuses to write anywhere outside
`media/`. Hardware in/out points are the ones from `videos/paper_video_v2/paper_video_v2.kdenlive`.
Existing outputs are skipped; `FORCE=1` rebuilds them.

## Before publishing

- `TODO(youtube)` — swap the stand-in `<video>` in `#video` for the YouTube embed
  (`media/video/full-standin.mp4` is git-ignored).
- `TODO(arxiv)`, `TODO(code)`, `TODO(venue)` in `index.html`.
- Update the BibTeX once there is an arXiv ID or venue.
