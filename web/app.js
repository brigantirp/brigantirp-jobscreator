const sections = [
  {
    id: 'base',
    title: 'Dati principali',
    description: 'Configura nome, tipo e identità visuale del job.'
  },
  {
    id: 'grades',
    title: 'Gradi e stipendi',
    description: 'Definisci ruoli, paghe, bonus e permessi speciali.'
  },
  {
    id: 'zones',
    title: 'Zone operative',
    description: 'Aggiungi posizioni per armadio, garage e boss menu.'
  },
  {
    id: 'advanced',
    title: 'Impostazioni avanzate',
    description: 'Flags, webhook e opzioni di gameplay evolute.'
  }
];

const defaultJob = {
  name: 'newjob',
  label: 'Nuovo Lavoro',
  description: 'Descrizione premium del tuo job.',
  icon: '💼',
  type: 'legal',
  color: '#7c3aed',
  webhook: '',
  grades: [
    { name: 'Recruit', label: 'Recluta', salary: 500, boss: false },
    { name: 'Manager', label: 'Manager', salary: 1200, boss: true }
  ],
  zones: [
    { type: 'armory', coords: '452.6,-980.0,30.6' },
    { type: 'bossmenu', coords: '447.2,-973.2,30.6' }
  ],
  options: {
    canHandcuff: false,
    canImpound: false,
    dutySystem: true,
    billingEnabled: true,
    whitelistOnly: false
  }
};

const clone = (value) => JSON.parse(JSON.stringify(value));

let state = clone(defaultJob);
let activeSection = 'base';

const app = document.getElementById('app');
const menu = document.getElementById('menu');
const panelContainer = document.getElementById('panelContainer');
const sectionTitle = document.getElementById('sectionTitle');
const sectionDescription = document.getElementById('sectionDescription');
const jobCard = document.getElementById('jobCard');

const notify = (message) => {
  if (window.GetParentResourceName) {
    fetch(`https://${GetParentResourceName()}/notify`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message })
    });
  }
};

const saveLocal = () => localStorage.setItem('jobcreator_state', JSON.stringify(state));
const loadLocal = () => {
  const cached = localStorage.getItem('jobcreator_state');
  if (!cached) return;
  try {
    state = { ...clone(defaultJob), ...JSON.parse(cached) };
  } catch (e) {
    console.warn('Invalid cache', e);
  }
};

const renderMenu = () => {
  menu.innerHTML = sections.map(section => `
    <button class="tab-btn ${section.id === activeSection ? 'active' : ''}" data-section="${section.id}">
      ${section.title}
    </button>
  `).join('');
};

const render = () => {
  renderMenu();
  const current = sections.find(s => s.id === activeSection);
  sectionTitle.textContent = current.title;
  sectionDescription.textContent = current.description;
  panelContainer.innerHTML = renderSection(activeSection);
  renderPreview();
};

const input = (label, key, type = 'text', full = false) => `
  <div class="field ${full ? 'full' : ''}">
    <label>${label}</label>
    <input type="${type}" data-model="${key}" value="${state[key] ?? ''}">
  </div>
`;

const renderSection = (section) => {
  if (section === 'base') {
    return `
      <div class="grid">
        ${input('Nome interno', 'name')}
        ${input('Label', 'label')}
        ${input('Icona (emoji)', 'icon')}
        <div class="field">
          <label>Tipo</label>
          <select data-model="type">
            <option value="legal" ${state.type === 'legal' ? 'selected' : ''}>Legale</option>
            <option value="illegal" ${state.type === 'illegal' ? 'selected' : ''}>Illegale</option>
            <option value="government" ${state.type === 'government' ? 'selected' : ''}>Governativo</option>
          </select>
        </div>
        ${input('Colore tema', 'color', 'color')}
        <div class="field full">
          <label>Descrizione</label>
          <textarea data-model="description">${state.description}</textarea>
        </div>
      </div>
    `;
  }

  if (section === 'grades') {
    return `
      <div class="grid">
        <div class="field full">
          <label>Gestione gradi</label>
          <div class="list-box">
            ${state.grades.map((grade, index) => `
              <div class="list-row">
                <input data-grade="${index}" data-key="name" value="${grade.name}" placeholder="Nome tecnico">
                <input data-grade="${index}" data-key="label" value="${grade.label}">
                <input type="number" min="0" data-grade="${index}" data-key="salary" value="${grade.salary}">
                <select data-grade="${index}" data-key="boss">
                  <option value="false" ${!grade.boss ? 'selected' : ''}>No boss</option>
                  <option value="true" ${grade.boss ? 'selected' : ''}>Boss</option>
                </select>
                <button class="btn" data-remove-grade="${index}">Rimuovi</button>
              </div>
            `).join('')}
            <button class="btn secondary" id="addGradeBtn">Aggiungi grado</button>
          </div>
          <p class="notice">Puoi modificare nome tecnico, label, stipendio e permesso boss direttamente da qui.</p>
        </div>
      </div>
    `;
  }

  if (section === 'zones') {
    return `
      <div class="grid">
        <div class="field full">
          <label>Zone configurate</label>
          <div class="list-box">
            ${state.zones.map((zone, index) => `
              <div class="list-row">
                <select data-zone="${index}" data-key="type">
                  ${['armory', 'garage', 'stash', 'bossmenu', 'crafting'].map(type =>
                    `<option value="${type}" ${zone.type === type ? 'selected' : ''}>${type}</option>`
                  ).join('')}
                </select>
                <input data-zone="${index}" data-key="coords" value="${zone.coords}" placeholder="x,y,z">
                <button class="btn" data-remove-zone="${index}">Rimuovi</button>
              </div>
            `).join('')}
            <button class="btn secondary" id="addZoneBtn">Aggiungi zona</button>
          </div>
        </div>
      </div>
    `;
  }

  return `
    <div class="grid">
      ${input('Webhook Discord', 'webhook', 'text', true)}
      ${checkbox('Sistema di servizio', 'dutySystem')}
      ${checkbox('Fatture abilitate', 'billingEnabled')}
      ${checkbox('Solo whitelist', 'whitelistOnly')}
      ${checkbox('Può ammanettare', 'canHandcuff')}
      ${checkbox('Può sequestrare veicoli', 'canImpound')}
    </div>
  `;
};

const checkbox = (label, key) => `
  <div class="field">
    <label>${label}</label>
    <select data-option="${key}">
      <option value="true" ${state.options[key] ? 'selected' : ''}>Sì</option>
      <option value="false" ${!state.options[key] ? 'selected' : ''}>No</option>
    </select>
  </div>
`;

const renderPreview = () => {
  jobCard.style.borderColor = state.color;
  jobCard.innerHTML = `
    <h4>${state.icon} ${state.label}</h4>
    <div class="meta">${state.description}</div>
    <div class="badges">
      <span class="badge">Type: ${state.type}</span>
      <span class="badge">Gradi: ${state.grades.length}</span>
      <span class="badge">Zone: ${state.zones.length}</span>
      <span class="badge">Payroll max: $${Math.max(0, ...state.grades.map(g => Number(g.salary) || 0))}</span>
    </div>
  `;
};

const parseFormEvents = (target) => {
  const model = target.dataset.model;
  if (model) {
    state[model] = target.type === 'number' ? Number(target.value) : target.value;
    return;
  }

  const gradeIndex = target.dataset.grade;
  if (gradeIndex !== undefined) {
    const key = target.dataset.key;
    let value;

    if (key === 'salary') {
      value = Number(target.value);
    } else if (key === 'boss') {
      value = target.value === 'true';
    } else {
      value = target.value;
    }

    state.grades[Number(gradeIndex)][key] = value;
    return;
  }

  const zoneIndex = target.dataset.zone;
  if (zoneIndex !== undefined) {
    state.zones[Number(zoneIndex)][target.dataset.key] = target.value;
    return;
  }

  const optionKey = target.dataset.option;
  if (optionKey) {
    state.options[optionKey] = target.value === 'true';
  }
};

panelContainer.addEventListener('input', (e) => {
  parseFormEvents(e.target);
  saveLocal();
  renderPreview();
});

panelContainer.addEventListener('change', (e) => {
  parseFormEvents(e.target);
  saveLocal();
  renderPreview();
});

panelContainer.addEventListener('click', (e) => {
  if (e.target.id === 'addGradeBtn') {
    state.grades.push({ name: `grade_${state.grades.length}`, label: 'Nuovo grado', salary: 700, boss: false });
    saveLocal();
    render();
  }

  if (e.target.id === 'addZoneBtn') {
    state.zones.push({ type: 'garage', coords: '0.0,0.0,0.0' });
    saveLocal();
    render();
  }

  if (e.target.dataset.removeGrade !== undefined) {
    state.grades.splice(Number(e.target.dataset.removeGrade), 1);
    saveLocal();
    render();
  }

  if (e.target.dataset.removeZone !== undefined) {
    state.zones.splice(Number(e.target.dataset.removeZone), 1);
    saveLocal();
    render();
  }
});

menu.addEventListener('click', (e) => {
  const button = e.target.closest('.tab-btn');
  if (!button) return;
  activeSection = button.dataset.section;
  render();
});

const closeUi = () => {
  app.classList.add('hidden');
  if (window.GetParentResourceName) {
    fetch(`https://${GetParentResourceName()}/close`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
    });
  }
};

document.getElementById('closeBtn').addEventListener('click', closeUi);
document.addEventListener('keydown', (e) => e.key === 'Escape' && closeUi());

document.getElementById('resetBtn').addEventListener('click', () => {
  state = clone(defaultJob);
  saveLocal();
  render();
  notify('Template resettato ai valori di default.');
});

document.getElementById('saveBtn').addEventListener('click', async () => {
  saveLocal();
  notify(`Job ${state.label} salvato.`);

  if (window.GetParentResourceName) {
    await fetch(`https://${GetParentResourceName()}/saveJob`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(state)
    });
  }
});

document.getElementById('copyJsonBtn').addEventListener('click', async () => {
  const data = JSON.stringify(state, null, 2);
  await navigator.clipboard.writeText(data);
  notify('JSON copiato negli appunti.');
});

document.getElementById('downloadJsonBtn').addEventListener('click', () => {
  const blob = new Blob([JSON.stringify(state, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = `${state.name || 'job'}.json`;
  link.click();
  URL.revokeObjectURL(url);
  notify('File JSON scaricato.');
});

document.getElementById('importInput').addEventListener('change', async (e) => {
  const file = e.target.files[0];
  if (!file) return;
  const text = await file.text();
  try {
    const imported = JSON.parse(text);
    state = {
      ...clone(defaultJob),
      ...imported,
      options: { ...clone(defaultJob).options, ...(imported.options || {}) }
    };
    saveLocal();
    render();
    notify('JSON importato correttamente.');
  } catch {
    notify('JSON non valido.');
  }
});

window.addEventListener('message', (event) => {
  const payload = event.data;
  if (payload.action === 'toggle') {
    app.classList.toggle('hidden', !payload.visible);
    if (payload.visible) render();
  }
});

loadLocal();
render();
