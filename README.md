# Breathe478 Web App

A simple browser-based 4-7-8 breathing exercise app, plus a general-purpose
interval timer.

## Files

- `index.html` — 4-7-8 breathing page
- `timer.html` — interval timer page
- `style.css` — UI styling (shared by both pages)
- `app.js` — breathing timer and sound logic
- `timer.js` — interval timer and sound logic

## How to run locally

1. Open `index.html` in a browser on your iPhone or computer.
2. Tap `Start` to begin the 4-7-8 cycle.
3. Tap `Stop` to pause.
4. Use the nav links at the top to switch to the Interval Timer page.

### Interval Timer

`timer.html` is a simple stopwatch: tap `Start` to begin counting up, `Stop`
to pause, and `Reset` to return to `00:00`. It plays a short beep every 5
seconds (5s, 10s, 15s, ...) while running so you can track elapsed time by
ear.

## Publish on GitHub Pages

1. Create a new GitHub repository and push these files.
2. In the repository settings, enable GitHub Pages using the `main` branch.
3. GitHub will provide a link like `https://<your-username>.github.io/<repo-name>/`.
4. Open that link on your iPhone.

## Notes

- The app uses a small tone at the start of each breathing phase.
- The circle shows three colored sections for inhale, hold, and exhale.
