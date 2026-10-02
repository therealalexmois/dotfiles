(() => {
  'use strict';
  const data = window.ROADMAP_DATA;
  if (!data) { document.body.innerHTML = '<p>Roadmap data is missing.</p>'; return; }

  const ru = data.meta.language === 'ru';
  const text = {
    en: {
      eyebrow:'Personal learning roadmap', base:'Base route', all:'All branches', deep:'Deep dives',
      export:'Export progress', import:'Import progress', anki:'Download Anki TSV', route:'Current route',
      startTitle:'Where to start', project:'Progressive project', projectOpen:'Open project brief',
      how:['Open the highlighted available node.','Complete its practice and checks.','Mark it completed to unlock the next nodes.','After each stage, implement the project milestone.'],
      start:'Start here', available:'Available', blocked:'Blocked', progress:'In progress', completed:'Completed',
      notStarted:'Not started', after:'After', noPrerequisites:'No prerequisites', prerequisites:'Prerequisites',
      outcomes:'Learning outcomes', completion:'Completion criteria', practice:'Practice', deliverable:'Deliverable',
      constraints:'Constraints', checks:'Checks', assistance:'Allowed assistance', cards:'Anki cards',
      foundation:'Foundation', deepening:'Deepening', reference:'Reference', milestone:'Project milestone',
      exercises:'Exercises', status:'Progress state', system:'System to build', problem:'Problem', requirements:'Functional requirements',
      starter:'Starter scope', finalDeliverables:'Final deliverables', acceptance:'Acceptance criteria', milestones:'Milestones',
      nextStart:name => `Start with “${name}”. It has no prerequisites.`,
      nextContinue:name => `Continue “${name}”, then verify its completion criteria.`,
      nextAvailable:(name,count) => `Next: “${name}”. ${count > 1 ? `${count} base-route nodes are currently available.` : 'It is the next available base-route node.'}`,
      routeDone:'The base route is complete. Verify the final project acceptance criteria.',
      routeBlocked:'No base-route node is available. Check prerequisite completion states.',
      progressLabel:(percent,done,total) => `${percent}% complete (${done}/${total} core nodes)`,
      assumptions:'Assumptions', footer:'Progress is stored in this browser. Export it for a portable backup.',
      projectSummary:(system,problem) => `${system} ${problem}`,
      milestoneAfter:stage => `After stage: ${stage}`, related:'Uses', invalidProgress:'This progress file is not valid for the current roadmap.'
    },
    ru: {
      eyebrow:'Персональный учебный roadmap', base:'Основной маршрут', all:'Все ветки', deep:'Дополнительные ветки',
      export:'Экспортировать прогресс', import:'Импортировать прогресс', anki:'Скачать Anki TSV', route:'Текущий маршрут',
      startTitle:'С чего начать', project:'Сквозной проект', projectOpen:'Открыть постановку',
      how:['Откройте подсвеченный доступный узел.','Выполните практику и проверьте критерии.','Отметьте узел завершенным, чтобы открыть следующие.','После каждого этапа реализуйте milestone проекта.'],
      start:'Начните здесь', available:'Доступен', blocked:'Заблокирован', progress:'В работе', completed:'Завершен',
      notStarted:'Не начат', after:'После', noPrerequisites:'Нет prerequisites', prerequisites:'Prerequisites',
      outcomes:'Результаты обучения', completion:'Критерии завершения', practice:'Практика', deliverable:'Результат',
      constraints:'Ограничения', checks:'Проверки', assistance:'Допустимая помощь', cards:'Карточки Anki',
      foundation:'Основные источники', deepening:'Углубление', reference:'Справочные материалы', milestone:'Milestone проекта',
      exercises:'Проверяемые узлы', status:'Статус прохождения', system:'Что нужно реализовать', problem:'Задача', requirements:'Функциональные требования',
      starter:'Начальный scope', finalDeliverables:'Итоговые артефакты', acceptance:'Критерии приемки', milestones:'Milestones',
      nextStart:name => `Начните с «${name}»: у этого узла нет prerequisites.`,
      nextContinue:name => `Продолжите «${name}», затем проверьте критерии завершения.`,
      nextAvailable:(name,count) => `Следующий шаг: «${name}». ${count > 1 ? `Сейчас доступны ${count} узла основного маршрута.` : 'Это следующий доступный узел основного маршрута.'}`,
      routeDone:'Основной маршрут завершен. Проверьте итоговые критерии приемки проекта.',
      routeBlocked:'Нет доступного узла основного маршрута. Проверьте статусы prerequisites.',
      progressLabel:(percent,done,total) => `${percent}% завершено (${done}/${total} основных узлов)`,
      assumptions:'Допущения', footer:'Прогресс хранится в этом браузере. Экспортируйте его для переноса.',
      projectSummary:(system,problem) => `${system} ${problem}`,
      milestoneAfter:stage => `После этапа: ${stage}`, related:'Связанные темы', invalidProgress:'Файл прогресса не относится к этому roadmap.'
    }
  }[ru ? 'ru' : 'en'];

  const storageKey = `learning-roadmap:${data.meta.id}:progress`;
  const storedStatuses = ['not-started','in-progress','completed'];
  const roadmap = document.querySelector('#roadmap');
  const dialog = document.querySelector('#node-dialog');
  const dialogContent = document.querySelector('#dialog-content');
  let progress = loadProgress();
  let activeFilter = 'base';

  document.documentElement.lang = data.meta.language || 'en';
  document.title = data.meta.title;
  document.querySelector('#roadmap-eyebrow').textContent = text.eyebrow;
  document.querySelector('#roadmap-title').textContent = data.meta.title;
  document.querySelector('#roadmap-goal').textContent = data.meta.goal;
  document.querySelector('.orientation .eyebrow').textContent = text.route;
  document.querySelector('#orientation-title').textContent = text.startTitle;
  document.querySelector('#how-to-use').innerHTML = text.how.map(item => `<li>${escapeHtml(item)}</li>`).join('');
  document.querySelector('footer').textContent = text.footer;
  localizeToolbar();
  renderAssumptions();
  renderProjectBrief();
  renderRoadmap();
  bindToolbar();
  updateProgress();
  window.addEventListener('resize', scheduleConnections);

  function loadProgress() {
    try { const parsed = JSON.parse(localStorage.getItem(storageKey) || '{}'); return parsed && typeof parsed === 'object' ? parsed : {}; }
    catch (_) { return {}; }
  }
  function saveProgress() { try { localStorage.setItem(storageKey,JSON.stringify(progress)); } catch (_) { /* export remains available */ } }
  function localizeToolbar() {
    document.querySelector('[data-filter="base"]').textContent = text.base;
    document.querySelector('[data-filter="all"]').textContent = text.all;
    document.querySelector('[data-filter="deep"]').textContent = text.deep;
    document.querySelector('#export-progress').textContent = text.export;
    document.querySelector('.button-label').childNodes[0].textContent = text.import;
    document.querySelector('#download-anki').textContent = text.anki;
  }
  function renderAssumptions() {
    const section = document.querySelector('#assumptions');
    if (!data.meta.assumptions?.length) return;
    section.hidden = false;
    section.innerHTML = `<strong>${text.assumptions}</strong><ul>${data.meta.assumptions.map(item => `<li>${escapeHtml(item)}</li>`).join('')}</ul>`;
  }
  function renderProjectBrief() {
    const section = document.querySelector('#project-brief');
    if (!data.capstone) return;
    section.hidden = false;
    section.innerHTML = `<div><p class="eyebrow">${text.project}</p><h2>${escapeHtml(data.capstone.title)}</h2><p><strong>${text.system}:</strong> ${escapeHtml(data.capstone.system_to_build)}</p><p>${escapeHtml(data.capstone.problem)}</p></div><button id="open-capstone">${text.projectOpen}</button>`;
    section.querySelector('#open-capstone').addEventListener('click',openCapstone);
  }
  function renderRoadmap() {
    const stages = [...data.stages].sort((a,b) => a.order - b.order);
    const stagesHtml = stages.map((stage,index) => {
      const nodes = data.nodes.filter(node => node.stage === stage.id).map(nodeCard).join('');
      return `<section class="stage" data-stage="${escapeAttr(stage.id)}"><div class="stage-heading"><span class="stage-number">${index + 1}</span><div><h2>${escapeHtml(stage.title)}</h2><p class="stage-description">${escapeHtml(stage.description || '')}</p></div></div><div class="nodes">${nodes}</div>${milestonesForStage(stage)}</section>`;
    }).join('');
    roadmap.innerHTML = `<svg class="connections" aria-hidden="true"><defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M 0 0 L 10 5 L 0 10 z" fill="#667085"></path></marker><marker id="arrow-done" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M 0 0 L 10 5 L 0 10 z" fill="#2e8b57"></path></marker></defs></svg>${stagesHtml}`;
    roadmap.querySelectorAll('.node-open').forEach(button => button.addEventListener('click',() => openNode(button.dataset.id)));
    applyFilter();
  }
  function nodeCard(node) {
    const state = visualState(node);
    const prerequisites = node.prerequisites.map(titleFor).join(', ');
    const start = node.prerequisites.length === 0;
    const depth = isBase(node) ? 'base' : 'deep';
    return `<article class="node" data-id="${escapeAttr(node.id)}" data-kind="${escapeAttr(node.kind)}" data-state="${state}" data-depth="${depth}"><button class="node-open" data-id="${escapeAttr(node.id)}"><span class="badges">${start ? `<span class="badge start">${text.start}</span>` : ''}<span class="badge ${state}">${stateLabel(state)}</span><span class="badge">${kindLabel(node.kind)}</span></span><span class="node-title">${escapeHtml(node.title)}</span>${prerequisites ? `<span class="prerequisite-label">${text.after}: ${escapeHtml(prerequisites)}</span>` : ''}</button></article>`;
  }
  function milestonesForStage(stage) {
    if (!data.capstone?.milestones) return '';
    return data.capstone.milestones.filter(item => item.after_stage === stage.id).map(item => {
      const names = item.related_nodes.map(titleFor).join(', ');
      return `<article class="milestone"><p class="eyebrow">${text.milestone}</p><h3>${escapeHtml(item.title)}</h3><p>${escapeHtml(item.task)}</p><p><strong>${text.deliverable}:</strong> ${escapeHtml(item.deliverable)}</p><p class="milestone-nodes">${text.related}: ${escapeHtml(names)}</p></article>`;
    }).join('');
  }
  function visualState(node) {
    const stored = storedStatuses.includes(progress[node.id]) ? progress[node.id] : 'not-started';
    if (stored === 'completed' || stored === 'in-progress') return stored;
    return node.prerequisites.every(id => progress[id] === 'completed') ? 'available' : 'blocked';
  }
  function stateLabel(state) { return ({available:text.available,blocked:text.blocked,'in-progress':text.progress,completed:text.completed})[state]; }
  function kindLabel(kind) { return ({core:'Core',optional:'Optional','deep-dive':'Deep dive',remediation:'Remediation',reference:'Reference'})[kind] || kind; }
  function titleFor(id) { return data.nodes.find(item => item.id === id)?.title || ''; }
  function isBase(node) { return node.kind === 'core' || node.kind === 'remediation'; }

  function openNode(id) {
    const node = data.nodes.find(item => item.id === id);
    if (!node) return;
    const stored = storedStatuses.includes(progress[node.id]) ? progress[node.id] : 'not-started';
    const prerequisites = node.prerequisites.map(titleFor);
    dialogContent.innerHTML = `<h2>${escapeHtml(node.title)}</h2><p>${escapeHtml(node.summary)}</p><label class="status-control"><strong>${text.status}</strong><select class="status-select" data-id="${escapeAttr(node.id)}">${storedStatuses.map(item => `<option value="${item}" ${item === stored ? 'selected' : ''}>${storedStateLabel(item)}</option>`).join('')}</select></label>${sectionList(text.prerequisites,prerequisites.length ? prerequisites : [text.noPrerequisites])}${sectionList(text.outcomes,node.learning_outcomes)}${sourceSections(node.sources)}${practiceSection(node.practice)}${sectionList(text.completion,node.completion_criteria)}${cardsSection(node.anki_cards)}`;
    dialogContent.querySelector('.status-select').addEventListener('change',event => {
      progress[node.id] = event.target.value;
      saveProgress();
      renderRoadmap();
      updateProgress();
    });
    dialog.showModal();
  }
  function storedStateLabel(state) { return ({'not-started':text.notStarted,'in-progress':text.progress,completed:text.completed})[state]; }
  function openCapstone() {
    const capstone = data.capstone;
    if (!capstone) return;
    const milestones = capstone.milestones.map(item => `<div class="capstone-detail"><strong>${escapeHtml(item.title)}</strong><p>${escapeHtml(item.task)}</p><p><b>${text.milestoneAfter(data.stages.find(stage => stage.id === item.after_stage)?.title || '')}</b></p><p><b>${text.deliverable}:</b> ${escapeHtml(item.deliverable)}</p>${sectionList(text.checks,item.checks)}</div>`).join('');
    dialogContent.innerHTML = `<h2>${escapeHtml(capstone.title)}</h2><section class="detail-section"><h3>${text.problem}</h3><p>${escapeHtml(capstone.problem)}</p></section><section class="detail-section"><h3>${text.system}</h3><p>${escapeHtml(capstone.system_to_build)}</p></section>${sectionList(text.requirements,capstone.functional_requirements)}${sectionList(text.constraints,capstone.constraints)}${sectionList(text.starter,capstone.starter_scope)}${sectionList(text.finalDeliverables,capstone.deliverables)}<section class="detail-section"><h3>${text.milestones}</h3>${milestones}</section>${sectionList(text.acceptance,capstone.acceptance_criteria)}`;
    dialog.showModal();
  }
  function sourceSections(groups) {
    const labels = {foundation:text.foundation,deepening:text.deepening,reference:text.reference};
    return ['foundation','deepening','reference'].map(group => {
      const entries = groups[group] || [];
      if (!entries.length) return '';
      return `<section class="detail-section"><h3>${labels[group]}</h3>${entries.map(source => `<div class="source"><a href="${escapeAttr(source.url)}" target="_blank" rel="noopener noreferrer">${escapeHtml(source.title)}</a><p>${escapeHtml(source.why)}</p><div class="source-meta">${escapeHtml([source.type,source.level,source.language,source.estimated_minutes ? `${source.estimated_minutes} min` : '',source.verified_at].filter(Boolean).join(' · '))}</div></div>`).join('')}</section>`;
    }).join('');
  }
  function practiceSection(items) {
    if (!items?.length) return '';
    return `<section class="detail-section"><h3>${text.practice}</h3>${items.map(item => `<div class="practice"><strong>${escapeHtml(item.title)}</strong><p>${escapeHtml(item.task)}</p>${sectionList(text.constraints,item.constraints)}<p><b>${text.deliverable}:</b> ${escapeHtml(item.deliverable)}</p><p><b>${text.assistance}:</b> ${escapeHtml(item.allowed_assistance)}</p>${sectionList(text.checks,item.checks)}</div>`).join('')}</section>`;
  }
  function cardsSection(cards) {
    if (!cards?.length) return '';
    return `<section class="detail-section"><h3>${text.cards}</h3>${cards.map(card => `<div class="card-preview"><strong>${escapeHtml(card.front)}</strong><p>${escapeHtml(card.back)}</p><small>${escapeHtml(card.type)} · ${escapeHtml(card.tags.join(' '))}</small></div>`).join('')}</section>`;
  }
  function sectionList(title,items) {
    if (!items?.length) return '';
    return `<section class="detail-section"><h3>${escapeHtml(title)}</h3><ul>${items.map(item => `<li>${escapeHtml(item)}</li>`).join('')}</ul></section>`;
  }
  function bindToolbar() {
    document.querySelectorAll('.filter').forEach(button => button.addEventListener('click',() => {
      activeFilter = button.dataset.filter;
      document.querySelectorAll('.filter').forEach(item => item.classList.toggle('active',item === button));
      applyFilter();
    }));
    document.querySelector('#export-progress').addEventListener('click',() => downloadJson(`${data.meta.id}-progress.json`,{roadmap_id:data.meta.id,progress}));
    document.querySelector('#import-progress').addEventListener('change',importProgress);
    document.querySelector('#download-anki').addEventListener('click',() => downloadText('anki-cards.tsv',window.ANKI_TSV || '','text/tab-separated-values;charset=utf-8'));
  }
  async function importProgress(event) {
    const file = event.target.files?.[0];
    if (!file) return;
    try {
      const imported = JSON.parse(await file.text());
      if (imported.roadmap_id !== data.meta.id || !imported.progress) throw new Error('Wrong roadmap');
      progress = Object.fromEntries(Object.entries(imported.progress).filter(([id,status]) => data.nodes.some(node => node.id === id) && storedStatuses.includes(status)));
      saveProgress(); renderRoadmap(); updateProgress();
    } catch (_) { alert(text.invalidProgress); }
    finally { event.target.value = ''; }
  }
  function updateProgress() {
    const core = data.nodes.filter(node => node.kind === 'core');
    const completed = core.filter(node => progress[node.id] === 'completed').length;
    const percent = core.length ? Math.round(completed / core.length * 100) : 0;
    document.querySelector('#progress-label').textContent = text.progressLabel(percent,completed,core.length);
    document.querySelector('#progress-bar').style.width = `${percent}%`;
    const inProgress = core.find(node => progress[node.id] === 'in-progress');
    const available = core.filter(node => visualState(node) === 'available');
    const target = document.querySelector('#next-step');
    if (inProgress) target.textContent = text.nextContinue(inProgress.title);
    else if (available.length) target.textContent = available[0].prerequisites.length ? text.nextAvailable(available[0].title,available.length) : text.nextStart(available[0].title);
    else if (completed === core.length) target.textContent = text.routeDone;
    else target.textContent = text.routeBlocked;
  }
  function applyFilter() {
    roadmap.querySelectorAll('.node').forEach(node => node.classList.toggle('hidden',activeFilter !== 'all' && node.dataset.depth !== activeFilter));
    roadmap.querySelectorAll('.stage').forEach(stage => {
      const visibleNodes = [...stage.querySelectorAll('.node')].some(node => !node.classList.contains('hidden'));
      stage.classList.toggle('hidden',!visibleNodes);
      stage.querySelectorAll('.milestone').forEach(item => item.classList.toggle('hidden',activeFilter === 'deep'));
    });
    scheduleConnections();
  }
  function scheduleConnections() { requestAnimationFrame(drawConnections); }
  function drawConnections() {
    const svg = roadmap.querySelector('.connections');
    if (!svg) return;
    svg.querySelectorAll('.connection').forEach(path => path.remove());
    const roadmapRect = roadmap.getBoundingClientRect();
    data.nodes.forEach(targetNode => {
      const target = roadmap.querySelector(`.node[data-id="${cssEscape(targetNode.id)}"]`);
      if (!target || target.classList.contains('hidden') || target.closest('.stage')?.classList.contains('hidden')) return;
      targetNode.prerequisites.forEach(sourceId => {
        const source = roadmap.querySelector(`.node[data-id="${cssEscape(sourceId)}"]`);
        if (!source || source.classList.contains('hidden') || source.closest('.stage')?.classList.contains('hidden')) return;
        const a = source.getBoundingClientRect(); const b = target.getBoundingClientRect();
        let x1,y1,x2,y2,pathData;
        if (b.top - a.bottom > 24) {
          x1=a.left+a.width/2-roadmapRect.left; y1=a.bottom-roadmapRect.top;
          x2=b.left+b.width/2-roadmapRect.left; y2=b.top-roadmapRect.top;
          const mid=(y1+y2)/2; pathData=`M ${x1} ${y1} C ${x1} ${mid}, ${x2} ${mid}, ${x2} ${y2}`;
        } else {
          const forward=b.left >= a.left;
          x1=(forward ? a.right : a.left)-roadmapRect.left; y1=a.top+a.height/2-roadmapRect.top;
          x2=(forward ? b.left : b.right)-roadmapRect.left; y2=b.top+b.height/2-roadmapRect.top;
          const mid=(x1+x2)/2; pathData=`M ${x1} ${y1} C ${mid} ${y1}, ${mid} ${y2}, ${x2} ${y2}`;
        }
        const path=document.createElementNS('http://www.w3.org/2000/svg','path');
        const done=progress[sourceId] === 'completed';
        path.setAttribute('d',pathData); path.setAttribute('class',`connection${done ? ' completed' : ''}`); path.setAttribute('marker-end',`url(#${done ? 'arrow-done' : 'arrow'})`); svg.appendChild(path);
      });
    });
  }
  function cssEscape(value) { return window.CSS?.escape ? CSS.escape(value) : String(value).replace(/[^a-zA-Z0-9_-]/g,'\\$&'); }
  function escapeHtml(value) { return String(value ?? '').replace(/[&<>"']/g,char => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char])); }
  function escapeAttr(value) { return escapeHtml(value); }
  function downloadJson(name,value) { downloadText(name,JSON.stringify(value,null,2),'application/json;charset=utf-8'); }
  function downloadText(name,value,type) { const url=URL.createObjectURL(new Blob([value],{type})); const link=Object.assign(document.createElement('a'),{href:url,download:name}); link.click(); URL.revokeObjectURL(url); }
})();
