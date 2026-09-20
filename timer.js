const BEEP_INTERVAL_SECONDS = 5;

const elapsedText = document.getElementById('elapsed');
const startBtn = document.getElementById('start-btn');
const stopBtn = document.getElementById('stop-btn');
const resetBtn = document.getElementById('reset-btn');

let intervalId = null;
let isRunning = false;
let startTime = null; // performance.now() when the timer last started/resumed
let elapsedSeconds = 0; // total seconds counted so far (persists across pauses)
let lastBeepedSecond = 0; // last elapsed second at which a beep played
let audioContext = null;

function formatTime(totalSeconds) {
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
}

function updateDisplay() {
  elapsedText.textContent = formatTime(elapsedSeconds);
}

async function ensureAudioContext() {
  const AudioContext = window.AudioContext || window.webkitAudioContext;
  if (!AudioContext) return null;

  if (!audioContext) {
    audioContext = new AudioContext();
  }

  if (audioContext.state === 'suspended') {
    try {
      await audioContext.resume();
    } catch (error) {
      console.warn('AudioContext resume failed:', error);
    }
  }

  return audioContext;
}

async function playBeep() {
  const context = await ensureAudioContext();
  if (!context) return;

  const oscillator = context.createOscillator();
  const gain = context.createGain();
  oscillator.type = 'sine';
  oscillator.frequency.value = 880;
  gain.gain.setValueAtTime(0.2, context.currentTime);
  oscillator.connect(gain);
  gain.connect(context.destination);
  oscillator.start();
  oscillator.stop(context.currentTime + 0.15);
  oscillator.onended = () => {
    oscillator.disconnect();
    gain.disconnect();
  };
}

function tick() {
  const now = performance.now();
  const newElapsedSeconds = elapsedSeconds + Math.floor((now - startTime) / 1000);

  if (newElapsedSeconds > lastBeepedSecond) {
    for (let second = lastBeepedSecond + 1; second <= newElapsedSeconds; second++) {
      if (second % BEEP_INTERVAL_SECONDS === 0) {
        playBeep();
      }
    }
    lastBeepedSecond = newElapsedSeconds;
  }

  if (newElapsedSeconds !== elapsedSeconds) {
    elapsedSeconds = newElapsedSeconds;
    updateDisplay();
  }
}

function startTimer() {
  if (isRunning) return;
  isRunning = true;
  startTime = performance.now();
  ensureAudioContext();
  intervalId = setInterval(tick, 200);
  startBtn.disabled = true;
  stopBtn.disabled = false;
}

function stopTimer() {
  if (!isRunning) return;
  isRunning = false;
  clearInterval(intervalId);
  intervalId = null;
  startBtn.disabled = false;
  stopBtn.disabled = true;
}

function resetTimer() {
  stopTimer();
  elapsedSeconds = 0;
  lastBeepedSecond = 0;
  updateDisplay();
}

startBtn.addEventListener('click', startTimer);
stopBtn.addEventListener('click', stopTimer);
resetBtn.addEventListener('click', resetTimer);

window.addEventListener('load', updateDisplay);
