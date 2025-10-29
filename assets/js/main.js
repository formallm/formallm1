(function(){
  const root = document.documentElement;
  const prefersDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
  const savedTheme = localStorage.getItem('theme');
  function applyTheme(theme){
    if(theme === 'light'){
      root.setAttribute('data-theme','light');
    }else{
      root.removeAttribute('data-theme');
    }
  }
  applyTheme(savedTheme || (prefersDark ? 'dark' : 'light'));

  const themeToggle = document.getElementById('themeToggle');
  if(themeToggle){
    themeToggle.addEventListener('click',()=>{
      const isLight = root.getAttribute('data-theme') === 'light';
      const next = isLight ? 'dark' : 'light';
      applyTheme(next);
      localStorage.setItem('theme', next);
    });
  }

  // Scroll progress bar
  let progressBar = document.querySelector('.scroll-progress');
  if(!progressBar){
    progressBar = document.createElement('div');
    progressBar.className = 'scroll-progress';
    document.body.appendChild(progressBar);
  }
  function updateProgress(){
    const h = document.documentElement;
    const scrolled = (h.scrollTop || document.body.scrollTop);
    const height = (h.scrollHeight - h.clientHeight) || 1;
    const w = Math.min(100, Math.max(0, (scrolled / height) * 100));
    progressBar.style.width = w + '%';
    const header = document.querySelector('.site-header');
    if(header){ header.classList.toggle('scrolled', scrolled > 10); }
  }
  window.addEventListener('scroll', updateProgress, {passive:true});
  window.addEventListener('load', updateProgress);

  const navToggle = document.querySelector('.nav-toggle');
  const navMenu = document.getElementById('nav-menu');
  let navOverlay = document.querySelector('.nav-overlay');
  if(!navOverlay){
    navOverlay = document.createElement('div');
    navOverlay.className = 'nav-overlay';
    document.body.appendChild(navOverlay);
  }
  function closeMenu(){
    if(navMenu){ navMenu.classList.remove('open'); }
    if(navToggle){ navToggle.setAttribute('aria-expanded','false'); }
    if(navOverlay){ navOverlay.classList.remove('show'); }
    document.body.classList.remove('no-scroll');
  }
  if(navToggle && navMenu){
    navToggle.addEventListener('click',()=>{
      const expanded = navToggle.getAttribute('aria-expanded') === 'true';
      navToggle.setAttribute('aria-expanded', String(!expanded));
      navMenu.classList.toggle('open');
      navOverlay.classList.toggle('show');
      const nowOpen = navMenu.classList.contains('open');
      document.body.classList.toggle('no-scroll', nowOpen);
      if(nowOpen){
        const firstLink = navMenu.querySelector('a');
        if(firstLink){ firstLink.focus(); }
      }
    });
    navMenu.addEventListener('click',(e)=>{
      if(e.target.closest('a')){ closeMenu(); }
    });
    navOverlay.addEventListener('click', closeMenu);
    document.addEventListener('keydown',(e)=>{
      if(e.key === 'Escape'){ closeMenu(); }
    });
  }

  // Navigation is static; no runtime pruning/insertion

  const backToTop = document.getElementById('backToTop');
  if(backToTop){
    backToTop.addEventListener('click',()=>window.scrollTo({top:0,behavior:'smooth'}));
    window.addEventListener('scroll',()=>{
      if(window.scrollY > 400){
        backToTop.classList.add('show');
      }else{
        backToTop.classList.remove('show');
      }
    });
  }

  const anchors = Array.from(document.querySelectorAll('.nav-menu a[href^="#"]'));
  const sections = anchors.map(a => document.querySelector(a.getAttribute('href'))).filter(Boolean);
  function onScrollSpy(){
    const y = window.scrollY + 120;
    let activeIndex = -1;
    for(let i=0;i<sections.length;i++){
      const el = sections[i];
      if(el && el.offsetTop <= y){ activeIndex = i; }
    }
    anchors.forEach((a,i)=>a.classList.toggle('active', i===activeIndex));
  }
  window.addEventListener('scroll', onScrollSpy, {passive:true});
  window.addEventListener('load', onScrollSpy);

  // Smooth anchor with offset
  anchors.forEach(a=>{
    a.addEventListener('click', (e)=>{
      const href = a.getAttribute('href');
      if(href && href.startsWith('#')){
        e.preventDefault();
        const target = document.querySelector(href);
        if(target){
          const header = document.querySelector('.site-header');
          const offset = (header ? header.offsetHeight : 64) + 12;
          const top = target.getBoundingClientRect().top + window.scrollY - offset;
          window.scrollTo({top, behavior:'smooth'});
        }
      }
    });
  });

  // Current nav activation only
  (function(){
    const navLinks = document.querySelectorAll('.nav-menu a[href]');
    const path = location.pathname.split('/').pop() || 'index.html';
    navLinks.forEach(a=>{
      const href = a.getAttribute('href');
      if(href === path){ a.setAttribute('aria-current','page'); }
    });
  })();

  // Language toggle is static in HTML; no runtime insertion

  // Removed Page TOC generation per design: subpages will use manual subnav when needed

  const countdownEl = document.querySelector('.countdown');
  if(countdownEl){
    const deadline = new Date(countdownEl.dataset.deadline || '').getTime();
    if(!isNaN(deadline)){
      function updateCountdown(){
        const now = Date.now();
        let diff = Math.max(0, deadline - now);
        const days = Math.floor(diff / (24*3600*1000)); diff -= days*24*3600*1000;
        const hours = Math.floor(diff / (3600*1000)); diff -= hours*3600*1000;
        const minutes = Math.floor(diff / (60*1000)); diff -= minutes*60*1000;
        const seconds = Math.floor(diff / 1000);
        const dEl = countdownEl.querySelector('[data-days]');
        const hEl = countdownEl.querySelector('[data-hours]');
        const mEl = countdownEl.querySelector('[data-minutes]');
        if(dEl) dEl.textContent = String(days);
        if(hEl) hEl.textContent = String(hours).padStart(2,'0');
        if(mEl) mEl.textContent = String(minutes).padStart(2,'0');
        let sEl = countdownEl.querySelector('[data-seconds]');
        if(!sEl){
          sEl = document.createElement('span');
          sEl.setAttribute('data-seconds','');
          sEl.style.marginLeft = '2px';
          countdownEl.querySelector('strong').append(' ', sEl);
        }
        sEl.textContent = String(seconds).padStart(2,'0') + '秒';
      }
      updateCountdown();
      setInterval(updateCountdown, 1000);
    }
  }

  const prefersReduced = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  if(!prefersReduced && 'IntersectionObserver' in window){
    const io = new IntersectionObserver(entries=>{
      for(const entry of entries){
        if(entry.isIntersecting){
          entry.target.classList.add('in');
          io.unobserve(entry.target);
        }
      }
    },{threshold:0.12});
    document.querySelectorAll('.reveal').forEach(el=>io.observe(el));
  }else{
    document.querySelectorAll('.reveal').forEach(el=>el.classList.add('in'));
  }

  const subscribeForm = document.querySelector('form.subscribe');
  if(subscribeForm){
    const input = subscribeForm.querySelector('input[type="email"]');
    const hint = subscribeForm.querySelector('[data-subscribe-msg]');
    
    // 实时验证 - 输入时反馈
    let validationTimeout;
    input?.addEventListener('input', (e) => {
      clearTimeout(validationTimeout);
      const value = e.target.value.trim();
      
      // 移除之前的状态
      input.classList.remove('valid', 'invalid');
      
      if(!value) {
        hint.textContent = '获取通告与进展';
        hint.style.color = 'var(--muted)';
        return;
      }
      
      validationTimeout = setTimeout(() => {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        const isValid = emailRegex.test(value);
        
        if(isValid) {
          input.classList.add('valid');
          hint.textContent = '✓ 邮箱格式正确';
          hint.style.color = 'var(--success)';
        } else {
          input.classList.add('invalid');
          hint.textContent = '⚠ 请检查邮箱格式';
          hint.style.color = 'var(--warning)';
        }
      }, 400); // 防抖 400ms
    });
    
    // 提交处理
    subscribeForm.addEventListener('submit',(e)=>{
      e.preventDefault();
      if(!input || !input.value){return;}
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      const ok = emailRegex.test(input.value.trim());
      if(ok){
        hint.textContent = '✓ 订阅成功！通告发布时将邮件通知你。';
        hint.style.color = 'var(--success)';
        input.value = '';
        input.classList.remove('valid', 'invalid');
        // 3秒后恢复提示
        setTimeout(() => {
          hint.textContent = '获取通告与进展';
          hint.style.color = 'var(--muted)';
        }, 3000);
      }else{
        hint.textContent = '✗ 请输入有效邮箱地址';
        hint.style.color = 'var(--danger)';
      }
    });
  }
})();
