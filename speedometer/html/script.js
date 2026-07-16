const hud = document.getElementById('hud');
const speedEl = document.getElementById('speed');
const gearEl = document.getElementById('gear');
const rpmFill = document.getElementById('rpmFill');
const engineDot = document.getElementById('engineDot');
const engineText = document.getElementById('engineText');
const speedo = document.querySelector('.speedo');
const indLeft = document.getElementById('indLeft');
const indRight = document.getElementById('indRight');
const indHazard = document.getElementById('indHazard');

const ARC_LEN = 405;
const ARC_VISIBLE = 304;

function setRpm(rpm) {
    const clamped = Math.max(0, Math.min(1, Number(rpm) || 0));
    const offset = ARC_LEN - ARC_VISIBLE * clamped;
    rpmFill.style.strokeDashoffset = String(offset);
    speedo.classList.toggle('redline', clamped >= 0.88);
}

function setIndicators(data) {
    const left = !!data.left;
    const right = !!data.right;
    const hazard = !!data.hazard;

    indLeft.classList.toggle('active', left);
    indRight.classList.toggle('active', right);
    indHazard.classList.toggle('active', hazard);
}

window.addEventListener('message', (event) => {
    const data = event.data || {};

    if (data.action === 'visible') {
        hud.classList.toggle('hidden', !data.show);
        if (!data.show) {
            setIndicators({ left: false, right: false, hazard: false });
        }
        return;
    }

    if (data.action !== 'update') {
        return;
    }

    const speed = Math.max(0, Math.floor(Number(data.speed) || 0));
    speedEl.textContent = String(speed);
    gearEl.textContent = data.gear != null ? String(data.gear) : 'N';
    setRpm(data.rpm);
    setIndicators(data);

    const engineOn = data.engine !== false;
    engineDot.classList.toggle('on', engineOn);
    engineDot.classList.toggle('off', !engineOn);
    engineText.textContent = engineOn ? 'ENGINE' : 'ENGINE OFF';
});

setRpm(0);
setIndicators({ left: false, right: false, hazard: false });
