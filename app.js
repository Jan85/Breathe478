const phases = [
  { name: 'INHALE', subtitle: 'Breathe In', duration: 4, frequency: 660, color: '#38bdf8' },    // Sky blue
  { name: 'HOLD', subtitle: 'Hold', duration: 7, frequency: 880, color: '#facc15' },             // Yellow
  { name: 'EXHALE', subtitle: 'Breathe Out', duration: 8, frequency: 520, color: '#4ade80' }     // Green
];

const dot = document.getElementById('dot');
const phaseName = document.getElementById('phase-name');
const phaseSubtitle = document.getElementById('phase-subtitle');
const remainingText = document.getElementById('remaining');
const cycleCountText = document.getElementById('cycle-count');
const toggleBtn = document.getElementById('toggle-btn');

let currentPhase = 0;
let intervalId = null;
let elapsed = 0;
let cyclesCompleted = 0;
let isRunning = false;
let totalDuration = phases.reduce((sum, phase) => sum + phase.duration, 0);
let phaseStartTime = null;
let phaseEndTime = null;
let audioContext = null;

function updateLabel() {
  phaseName.textContent = phases[currentPhase].name;
  phaseSubtitle.textContent = phases[currentPhase].subtitle;
  remainingText.textContent = Math.ceil(Math.max(0, phaseEndTime ? (phaseEndTime - performance.now()) / 1000 : phases[currentPhase].duration));
  // Update dot color to match current phase using CSS variable
  dot.style.setProperty('--dot-color', phases[currentPhase].color);
}

function updateCycleCount() {
  cycleCountText.textContent = `Cycles: ${cyclesCompleted}`;
}

function updateDot() {
  const progressAngle = (elapsed / totalDuration) * 360;
  dot.style.transform = `translate(-50%, -50%) rotate(${progressAngle}deg) translate(0, -125px)`;
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

async function playTone(frequency) {
  const context = await ensureAudioContext();
  if (!context) return;

  const oscillator = context.createOscillator();
  const gain = context.createGain();
  oscillator.type = 'sine';
  oscillator.frequency.value = frequency;
  gain.gain.setValueAtTime(0.15, context.currentTime);
  oscillator.connect(gain);
  gain.connect(context.destination);
  oscillator.start();
  oscillator.stop(context.currentTime + 0.12);
  oscillator.onended = () => {
    oscillator.disconnect();
    gain.disconnect();
  };
}

async function startPhase(index) {
  currentPhase = index;
  phaseStartTime = performance.now();
  phaseEndTime = phaseStartTime + phases[index].duration * 1000;
  await playTone(phases[index].frequency);
  updateLabel();
  updateDot();
}

function tick() {
  const now = performance.now();
  if (!phaseEndTime) return;

  if (now >= phaseEndTime) {
    currentPhase += 1;
    if (currentPhase >= phases.length) {
      cyclesCompleted += 1;
      updateCycleCount();
      currentPhase = 0;
    }
    startPhase(currentPhase);
  }

  const phaseElapsed = Math.min((now - phaseStartTime) / 1000, phases[currentPhase].duration);
  elapsed = phases.slice(0, currentPhase).reduce((sum, phase) => sum + phase.duration, 0) + phaseElapsed;
  updateLabel();
  updateDot();
}

function toggleSession() {
  if (isRunning) {
    // Stop the session
    clearInterval(intervalId);
    intervalId = null;
    isRunning = false;
    toggleBtn.textContent = 'Start';
    toggleBtn.classList.remove('running');
    // Reset UI to initial state
    currentPhase = 0;
    elapsed = 0;
    cyclesCompleted = 0;
    phaseStartTime = null;
    phaseEndTime = null;
    updateLabel();
    updateDot();
    updateCycleCount();
  } else {
    // Start the session
    clearInterval(intervalId);
    currentPhase = 0;
    cyclesCompleted = 0;
    elapsed = 0;
    updateCycleCount();
    ensureAudioContext().then(() => {
      startPhase(0);
      intervalId = setInterval(tick, 50);
    });
    isRunning = true;
    toggleBtn.textContent = 'Stop';
    toggleBtn.classList.add('running');
  }
}

toggleBtn.addEventListener('click', toggleSession);

window.addEventListener('load', () => {
  updateLabel();
  updateCycleCount();
  updateDot();
});
