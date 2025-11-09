(function(){
  const CACHE_KEY = 'downloads_cache_v1';
  const CACHE_AT = 'downloads_cache_at_v1';
  const ONE_DAY = 24*3600*1000;

  function el(tag, attrs={}, children=[]) {
    const e = document.createElement(tag);
    Object.entries(attrs).forEach(([k,v])=>{
      if(v==null) return;
      if(k==='class') e.className = v; else if(k==='html') e.innerHTML = v; else e.setAttribute(k,v);
    });
    for(const c of children){ e.append(c); }
    return e;
  }

  function readInline(){
    const node = document.getElementById('downloads-data');
    if(!node) return null;
    try{ return JSON.parse(node.textContent || '{}'); }catch(e){ console.error('inline json parse error', e); return null; }
  }

  // 生成候选数据地址，兼容根目录与子目录页面（类似 leaderboard.js）
  function getCandidateDataURLs(){
    const candidates = [];
    // 1) 原始相对路径（适用于子目录页面如 cn/ 或 en/）
    candidates.push('../assets/data/downloads.json');
    // 2) 根目录相对路径（适用于根目录页面）
    candidates.push('assets/data/downloads.json');
    // 3) 推断 GitHub Pages 项目根（/repo-name/）
    const parts = (window.location.pathname || '').split('/').filter(Boolean);
    if(parts.length > 0){
      candidates.push('/' + parts[0] + '/assets/data/downloads.json');
    }
    // 4) 站点根绝对路径（自定义域名场景）
    candidates.push('/assets/data/downloads.json');
    // 去重
    return Array.from(new Set(candidates));
  }

  // 规范化资源链接，兼容 GitHub Pages 子目录（如 /repo/en/）
  function normalizeHref(href){
    if(!href) return href;
    if(/^https?:\/\//i.test(href)) return href;
    if(href.startsWith('/')) return href;
    if(href.startsWith('../')) return href;
    if(href.startsWith('assets/')){
      const parts = (window.location.pathname || '').split('/').filter(Boolean);
      const base = parts.length > 0 ? ('/' + parts[0] + '/') : '/';
      return base + href;
    }
    return href;
  }

  async function fetchData(force=false){
    // file:// 本地预览时优先尝试内嵌数据
    if(location.protocol === 'file:'){
      const inline = readInline();
      if(inline) return inline;
    }

    // 检查缓存
    const cachedAt = Number(localStorage.getItem(CACHE_AT) || 0);
    const cached = localStorage.getItem(CACHE_KEY);
    const freshEnough = !force && cached && (Date.now() - cachedAt) < ONE_DAY;
    if(freshEnough){
      try{ return JSON.parse(cached); }catch(e){ console.warn('cache parse error', e); }
    }

    // 依次尝试多个候选地址
    const urls = getCandidateDataURLs();
    for(const url of urls){
      try{
        const res = await fetch(url + '?_=' + Date.now(), {cache:'no-cache'});
        if(res.ok){
          const data = await res.json();
          localStorage.setItem(CACHE_KEY, JSON.stringify(data));
          localStorage.setItem(CACHE_AT, String(Date.now()));
          return data;
        }
      }catch(err){
        // 忽略，继续尝试下一个候选
        console.debug('Failed to fetch from', url, err);
      }
    }

    // 通用兜底：若页面内提供了内嵌数据则使用
    const inline = readInline();
    if(inline){
      // 也缓存内嵌数据
      localStorage.setItem(CACHE_KEY, JSON.stringify(inline));
      localStorage.setItem(CACHE_AT, String(Date.now()));
      return inline;
    }

    // 最后尝试使用缓存（即使过期）
    if(cached){
      try{ return JSON.parse(cached); }catch(_){/* ignore */}
    }

    console.error('无法加载下载数据。尝试过的地址：', urls);
    return null;
  }

  function renderList(sectionTitle, blocks){
    if(!blocks || !blocks.length) return null;
    const wrap = el('div', {class:'card'});
    wrap.append(el('h3', {}, [document.createTextNode(sectionTitle)]));
    for(const block of blocks){
      const meta = el('p', {class:'text-muted mt-8'}, [
        document.createTextNode((block.timestamp || '') + (block.note ? ' · ' + block.note : ''))
      ]);
      wrap.append(meta);
      const ul = el('ul', {class:'disc'});
      for(const item of (block.items||[])){
        const href = (item.local && String(item.local).trim()) ? item.local : item.url;
        const a = el('a', {href: href || '#', target: href && href.startsWith('http') ? '_blank' : null, rel: href && href.startsWith('http') ? 'noreferrer noopener' : null}, [document.createTextNode(item.name)]);
        const md5 = item.md5 ? el('span', {class:'text-muted', style:'margin-left:8px'}, [document.createTextNode('MD5: '+item.md5)]) : null;
        const li = el('li');
        li.append(a);
        if(md5) li.append(md5);
        ul.append(li);
      }
      wrap.append(ul);
    }
    return wrap;
  }

  function renderEvents(events){
    if(!events || !events.length) return null;
    const wrap = el('div', {class:'card'});
    wrap.append(el('h3', {}, [document.createTextNode('赛题分享会')]));
    for(const ev of events){
      const p1 = el('p', {}, [document.createTextNode(ev.desc || '')]);
      const p2 = el('p', {class:'mt-8'}, [
        document.createTextNode('时间：' + (ev.time || ''))
      ]);
      const p3 = el('p', {class:'mt-8'}, [
        el('a', {href: ev.link, target:'_blank', rel:'noreferrer noopener'}, [document.createTextNode('报名进入线上会议室')]),
        document.createTextNode(ev.limit ? '（限' + ev.limit + '人）' : '')
      ]);
      wrap.append(p1,p2,p3);
    }
    return wrap;
  }

  function renderDocs(docs){
    if(!docs || !docs.length) return null;
    const wrap = el('p', {class:'mt-16 text-muted'});
    wrap.append(document.createTextNode('外部资源：'));
    docs.forEach((d, i)=>{
      if(i>0) wrap.append(document.createTextNode(' · '));
      wrap.append(el('a', {href:d.url, target:'_blank', rel:'noreferrer noopener'}, [document.createTextNode(d.name)]));
    });
    return wrap;
  }

  function renderNotices(notices){
    const fr = document.createDocumentFragment();
    for(const n of (notices||[])){
      const card = el('div', {class:'card mt-16'});
      card.append(el('h3', {}, [document.createTextNode(n.title)]));
      card.append(el('p', {class:'text-muted'}, [document.createTextNode(n.content)]));
      fr.append(card);
    }
    return fr;
  }

  function renderSample(sample){
    if(!sample) return null;
    const pre = el('pre');
    const code = el('code');
    code.textContent = JSON.stringify(sample, null, 2);
    pre.append(code);
    return pre;
  }

  function renderSubmission(sub){
    if(!sub) return null;
    const card = el('div', {class:'card mt-16'});
    card.append(el('h3', {}, [document.createTextNode('提交说明')]));
    if(sub.desc){ card.append(el('p', {}, [document.createTextNode(sub.desc)])); }
    if(Array.isArray(sub.rules)){
      const ul = el('ul', {class:'disc'});
      sub.rules.forEach(r=>ul.append(el('li', {}, [document.createTextNode(r)])));
      card.append(ul);
    }
    if(Array.isArray(sub.fields) && sub.fields.length){
      const tableWrap = el('div', {class:'table-wrap'});
      const table = el('table', {class:'table compact'});
      const thead = el('thead');
      thead.append(el('tr', {}, [
        el('th', {}, [document.createTextNode('字段名')]),
        el('th', {class:'center'}, [document.createTextNode('值')]),
        el('th', {}, [document.createTextNode('说明')])
      ]));
      table.append(thead);
      const tbody = el('tbody');
      sub.fields.forEach(f=>{
        const tr = el('tr');
        tr.append(el('td', {}, [document.createTextNode(f.name || '')]));
        tr.append(el('td', {class:'center'}, [document.createTextNode(f.value || '')]));
        tr.append(el('td', {}, [document.createTextNode(f.desc || '')]));
        tbody.append(tr);
      });
      table.append(tbody);
      tableWrap.append(table);
      card.append(tableWrap);
    }
    return card;
  }

  function renderFairplay(text){
    if(!text) return null;
    const card = el('div', {class:'card mt-16'});
    card.append(el('h3', {}, [document.createTextNode('公平竞技')]));
    card.append(el('p', {class:'text-muted'}, [document.createTextNode(text)]));
    return card;
  }

  // 从文件名自动生成显示名称
  function getDisplayName(item, lang){
    // 如果已经有 name 且不包含文件扩展名，直接使用
    if(item.name && !item.name.match(/\.(jsonl|json|zip|py)$/i)){
      return item.name;
    }
    
    // 否则从 local 路径解析
    const path = item.local || item.url || '';
    const filename = path.split('/').pop() || '';
    const match = filename.match(/^(lean|litex)_(\d{4})\.jsonl$/i);
    
    if(match){
      const track = match[1].charAt(0).toUpperCase() + match[1].slice(1); // Lean 或 Litex
      const dateStr = match[2]; // 例如 "1107"
      const month = dateStr.slice(0, 2);
      const day = dateStr.slice(2);
      
      if(lang === 'en'){
        const monthNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        const monthName = monthNames[parseInt(month)-1] || month;
        return `${monthName} ${day} ${track} Problems`;
      }else{
        return `${parseInt(month)}月${parseInt(day)}日 ${track} 赛题`;
      }
    }
    
    // 兜底：返回原始 name
    return item.name || filename || 'Unknown';
  }

  function renderInto(mount, data){
    // 仅保留"今日赛题"
    const lang = (document.documentElement.getAttribute('lang') || '').toLowerCase().startsWith('en') ? 'en' : 'zh';
    
    // 计算"期望显示的日期"：始终显示今天的日期（数据在23:00更新，但更新的是今天的赛题）
    const expectedDate = (function(){
      const now = new Date();
      const utc = now.getTime() + (now.getTimezoneOffset() * 60000);
      const bjTime = new Date(utc + (3600000 * 8));
      
      // 始终使用今天的日期（数据在23:00更新，但更新的是今天的赛题）
      const y = bjTime.getFullYear();
      const m = String(bjTime.getMonth()+1).padStart(2,'0');
      const dd = String(bjTime.getDate()).padStart(2,'0');
      return y+'-'+m+'-'+dd;
    })();
    
    const highlightP = document.querySelector('#downloads .card.highlight p');

    // 查找匹配期望日期的赛题块
    let targetBlock = null;
    if(data && Array.isArray(data.datasets) && data.datasets.length > 0){
      // 调试信息（仅在开发环境）
      if(window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'){
        console.log('期望日期:', expectedDate);
        console.log('可用数据集:', data.datasets.map(b => ({
          timestamp: b.timestamp,
          date: b.timestamp ? String(b.timestamp).slice(0,10) : null,
          itemsCount: b.items ? b.items.length : 0
        })));
      }
      
      // 首先尝试匹配今天的日期
      targetBlock = data.datasets.find(block => {
        if(!block.timestamp) return false;
        const ts = String(block.timestamp);
        // 支持多种时间格式：'2025-11-10 23:19:47' 或 '2025-11-10T23:19:47'
        const datePart = ts.slice(0,10);
        return datePart === expectedDate;
      });
      
      // 如果匹配不到今天的，就显示最新的数据块（第一个，因为数据是按时间倒序排列的）
      if(!targetBlock || !targetBlock.items || targetBlock.items.length === 0){
        targetBlock = data.datasets.find(block => {
          return block && block.items && Array.isArray(block.items) && block.items.length > 0;
        });
      }
    }
    
    const items = targetBlock && Array.isArray(targetBlock.items) ? targetBlock.items : [];
    const hasToday = targetBlock && items.length > 0;

    if(hasToday){
      if(highlightP){
        // 如果显示的不是今天的，提示用户这是最新的可用赛题
        const isToday = targetBlock && targetBlock.timestamp && String(targetBlock.timestamp).slice(0,10) === expectedDate;
        if(isToday){
          highlightP.textContent = lang==='en' ? "Today's challenge is published. See files below." : '今日赛题已发布，请查看下方文件。';
        }else{
          highlightP.textContent = lang==='en' ? "Latest available challenge. See files below." : '最新可用赛题，请查看下方文件。';
        }
      }
      const card = el('div', {class:'card'});
      card.append(el('h3', {}, [document.createTextNode(lang==='en' ? "Today's Challenge" : '今日赛题')]));
      const ul = el('ul', {class:'disc'});
      for(const item of items){
        const rawHref = (item.local && String(item.local).trim()) ? item.local : item.url;
        const href = normalizeHref(rawHref);
        const displayName = getDisplayName(item, lang);
        const a = el('a', {href: href || '#', target: href && href.startsWith('http') ? '_blank' : null, rel: href && href.startsWith('http') ? 'noreferrer noopener' : null}, [document.createTextNode(displayName)]);
        const li = el('li');
        li.append(a);
        if(item.md5){ li.append(el('span', {class:'text-muted', style:'margin-left:8px'}, [document.createTextNode('MD5: '+item.md5)])); }
        ul.append(li);
      }
      card.append(ul);
      mount.append(card);
    }else{
      if(highlightP){
        highlightP.textContent = lang==='en' ? "Today's challenge is not yet updated." : '今日赛题还未更新，请稍后再来。';
      }
      // 显示调试信息（仅在开发环境）
      const debugMsg = (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') 
        ? ` (期望日期: ${expectedDate}, 数据更新时间: ${data?.lastUpdated || 'N/A'})`
        : '';
      mount.append(el('p', {class:'text-muted'}, [document.createTextNode((lang==='en' ? 'No files available yet.' : '暂无可下载文件。') + debugMsg)]));
    }
  }

  async function main(){
    const mount = document.getElementById('downloads-dynamic');
    if(!mount) return;
    const data = await fetchData(false);
    if(!data){
      mount.append(el('p', {class:'text-muted'}, [document.createTextNode('下载信息暂不可用，请稍后重试。')]));
      return;
    }
    renderInto(mount, data);
  }

  // 暴露接口：强制刷新（每日任务或手动调用）
  window.DownloadsAPI = {
    refresh: async function(){
      localStorage.removeItem(CACHE_KEY);
      localStorage.removeItem(CACHE_AT);
      return await fetchData(true);
    },
    set: function(data){
      if(!data) return;
      localStorage.setItem(CACHE_KEY, JSON.stringify(data));
      localStorage.setItem(CACHE_AT, String(Date.now()));
      const mount = document.getElementById('downloads-dynamic');
      if(mount){ mount.innerHTML=''; renderInto(mount, data); }
    }
  };

  document.addEventListener('DOMContentLoaded', main);
})();


