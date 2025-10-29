window.addEventListener('message', function(event) {
    const item = event.data;

    if (item.action === 'update') {
        const data = item.data;
        // Affiche le HUD seulement si les données sont reçues
        document.getElementById('hud-container').style.display = 'flex';

        document.getElementById('name').innerText = `👤 ${data.name}`;
        document.getElementById('job').innerText = `💼 ${data.job}`;
        document.getElementById('time').innerText = `🕒 ${data.time}`;
        document.getElementById('hunger').innerText = `🥩 ${data.hunger}`;
        document.getElementById('thirst').innerText = `💧 ${data.thirst}`;
        document.getElementById('money').innerText = `💰 $${data.money}`;
        document.getElementById('bank').innerText = `🏦 $${data.bank}`;
    }

    if (item.action === 'vitals') {
        const d = item.data || {};
        if (typeof d.health === 'number') {
            document.getElementById('health').innerText = `❤️ ${d.health}`;
        }
        if (typeof d.stamina === 'number') {
            document.getElementById('stamina').innerText = `🔋 ${d.stamina}`;
        }
    }

    if (item.action === 'metabolismUpdate') {
        const d = item.data || {};
        if (typeof d.hunger === 'number') {
            document.getElementById('hunger').innerText = `🥩 ${d.hunger}`;
        }
        if (typeof d.thirst === 'number') {
            document.getElementById('thirst').innerText = `💧 ${d.thirst}`;
        }
    }

    if (item.action === 'progressStart') {
        const d = item.data || {};
        const container = document.getElementById('progress');
        const fill = document.getElementById('progress-fill');
        const label = document.getElementById('progress-text');
        label.innerText = d.message || '';
        if (d.color) fill.style.background = d.color;
        container.style.display = 'block';

        let elapsed = 0;
        const total = Math.max(1, parseInt(d.time || 1000, 10));
        if (window.__hudProgressTimer) clearInterval(window.__hudProgressTimer);
        fill.style.width = '0%';
        window.__hudProgressTimer = setInterval(() => {
            elapsed += 50;
            const pct = Math.min(100, Math.floor((elapsed / total) * 100));
            fill.style.width = pct + '%';
            if (elapsed >= total) {
                clearInterval(window.__hudProgressTimer);
                window.__hudProgressTimer = null;
                fetch(`https://${GetParentResourceName()}/progressFinished`, { method: 'POST', body: '{}' });
            }
        }, 50);
    }

    if (item.action === 'progressCancel') {
        const container = document.getElementById('progress');
        const fill = document.getElementById('progress-fill');
        if (window.__hudProgressTimer) { clearInterval(window.__hudProgressTimer); window.__hudProgressTimer = null; }
        fill.style.width = '0%';
        container.style.display = 'none';
    }

    if (item.action === 'progressFinish') {
        const container = document.getElementById('progress');
        const fill = document.getElementById('progress-fill');
        if (window.__hudProgressTimer) { clearInterval(window.__hudProgressTimer); window.__hudProgressTimer = null; }
        fill.style.width = '100%';
        setTimeout(() => { container.style.display = 'none'; fill.style.width = '0%'; }, 150);
    }
});