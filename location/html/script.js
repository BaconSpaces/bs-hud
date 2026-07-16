const hud = document.getElementById('hud');
const streetEl = document.getElementById('street');
const crossingEl = document.getElementById('crossing');
const crossingRow = document.getElementById('crossingRow');
const cardinalEl = document.getElementById('cardinal');
const compassSpin = document.getElementById('compassSpin');

function resourceName() {
    try {
        if (typeof GetParentResourceName === 'function') {
            return GetParentResourceName();
        }
    } catch (e) { /* browser preview */ }
    return 'location';
}

function notifyReady() {
    fetch('https://' + resourceName() + '/ready', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({})
    }).catch(function () { /* ignore when not in FiveM */ });
}

window.addEventListener('message', (event) => {
    const data = event.data || {};

    if (data.action === 'visible') {
        hud.classList.toggle('hidden', !data.show);
        return;
    }

    if (data.action !== 'update') {
        return;
    }

    hud.classList.remove('hidden');

    streetEl.textContent = data.street || 'Unknown Sector';

    const crossing = (data.crossing || '').trim();
    if (crossing) {
        crossingEl.textContent = crossing;
        crossingRow.classList.remove('hidden-cross');
    } else {
        crossingEl.textContent = '—';
        crossingRow.classList.add('hidden-cross');
    }

    cardinalEl.textContent = data.cardinal || 'N';

    const heading = Number(data.heading) || 0;
    compassSpin.style.transform = 'rotate(' + (-heading) + 'deg)';
});

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', notifyReady);
} else {
    notifyReady();
}
