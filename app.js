const phases = [
  { name: 'Breathe In', duration: 4, frequency: 660 },
  { name: 'Hold', duration: 7, frequency: 880 },
  { name: 'Breathe Out', duration: 8, frequency: 520 }
];

const dot = document.getElementById('dot');
const phaseName = document.getElementById('phase-name');
const remainingText = document.getElementById('remaining');
const cycleCountText = document.getElementById('cycle-count');
const startBtn = document.getElementById('start-btn');
const stopBtn = document.getElementById('stop-btn');

let currentPhase = 0;
let intervalId = null;
let elapsed = 0;
let cyclesCompleted = 0;
let totalDuration = phases.reduce((sum, phase) => sum + phase.duration, 0);
let phaseStartTime = null;
let phaseEndTime = null;

function updateLabel() {
  phaseName.textContent = phases[currentPhase].name;
  remainingText.textContent = Math.ceil(Math.max(0, phaseEndTime ? (phaseEndTime - performance.now()) / 1000 : phases[currentPhase].duration));
}

function updateCycleCount() {
  cycleCountText.textContent = `Cycles: ${cyclesCompleted}`;
}

function updateDot() {
  const progressAngle = (elapsed / totalDuration) * 360;
  dot.style.transform = `translate(-50%, -50%) rotate(${progressAngle}deg) translate(0, -148px)`;
  dot.style.backgroundColor = 'white';
}

function playTone(frequency) {
  const AudioContext = window.AudioContext || window.webkitAudioContext;
  if (!AudioContext) return;
  const context = new AudioContext();
  const oscillator = context.createOscillator();
  const gain = context.createGain();
  oscillator.type = 'sine';
  oscillator.frequency.value = frequency;
  oscillator.connect(gain);
  gain.connect(context.destination);
  gain.gain.value = 0.15;
  oscillator.start();
  oscillator.stop(context.currentTime + 0.12);
  oscillator.onended = () => context.close();
}

function startPhase(index) {
  currentPhase = index;
  phaseStartTime = performance.now();
  phaseEndTime = phaseStartTime + phases[index].duration * 1000;
  playTone(phases[index].frequency);
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

function startSession() {
  clearInterval(intervalId);
  currentPhase = 0;
  cyclesCompleted = 0;
  elapsed = 0;
  updateCycleCount();
  startPhase(0);
  intervalId = setInterval(tick, 50);
}

function stopSession() {
  clearInterval(intervalId);
  intervalId = null;
}

startBtn.addEventListener('click', startSession);
stopBtn.addEventListener('click', stopSession);

window.addEventListener('load', () => {
  updateLabel();
  updateCycleCount();
  updateDot();
});
