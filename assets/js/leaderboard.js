(function(){
  'use strict';

  /**
   * 排行榜 API
   * 支持两个赛道：Litex 和 Lean
   * 每个赛道可以切换：今日排行榜 ↔ 总排行榜
   * 现阶段为练习赛
   */
  const LeaderboardAPI = {
    // 数据源 URL（可配置为云端接口）
    dataURL: 'assets/data/leaderboard.json',
    
    // 缓存数据
    cache: null,

    // 生成候选数据地址，兼容根目录与子目录页面
    getCandidateDataURLs() {
      const candidates = [];
      // 1) 原始相对路径（适用于根目录页面）
      candidates.push('assets/data/leaderboard.json');
      // 2) 上一级相对路径（适用于如 cn/ 或 en/ 等子目录页面）
      candidates.push('../assets/data/leaderboard.json');
      // 3) 推断 GitHub Pages 项目根（/repo-name/）
      const parts = window.location.pathname.split('/').filter(Boolean);
      if (parts.length > 0) {
        candidates.push('/' + parts[0] + '/assets/data/leaderboard.json');
      }
      // 4) 站点根绝对路径（自定义域名场景）
      candidates.push('/assets/data/leaderboard.json');
      // 去重
      return Array.from(new Set(candidates));
    },

    // file:// 场景：尝试从页面内嵌 JSON 读取
    readInline() {
      try {
        const node = document.getElementById('leaderboard-data');
        if (!node) return null;
        const text = (node.textContent || node.innerText || '').trim();
        if (!text) return null;
        return JSON.parse(text);
      } catch (err) {
        console.error('内嵌排行榜 JSON 解析失败', err);
        return null;
      }
    },

    /**
     * 获取排行榜数据
     * 仅从外部 JSON 加载，不再回退到页面内嵌数据
     */
    async fetch() {
      if (this.cache) {
        return this.cache;
      }

      // file:// 本地预览时优先尝试内嵌数据
      if (location.protocol === 'file:') {
        const inlineFirst = this.readInline();
        if (inlineFirst) {
          this.cache = inlineFirst;
          return inlineFirst;
        }
      }

      // 依次尝试多个候选地址
      const urls = this.getCandidateDataURLs();
      for (const url of urls) {
        try {
          const response = await fetch(url + '?_=' + Date.now());
          if (response.ok) {
            const data = await response.json();
            this.cache = data;
            return data;
          }
        } catch (err) {
          // 忽略，继续尝试下一个候选
        }
      }

      // 通用兜底：若页面内提供了内嵌数据则使用
      const inline = this.readInline();
      if (inline) {
        this.cache = inline;
        return inline;
      }

      console.error('无法加载排行榜数据。尝试过的地址：', urls);
      return null;
    },

    /**
     * 强制刷新数据
     */
    async refresh() {
      this.cache = null;
      await this.render();
    },

    /**
     * 直接设置数据（用于外部注入）
     */
    set(data) {
      this.cache = data;
      this.render();
    },

    /**
     * 渲染排行榜
     */
    async render() {
      const data = await this.fetch();
      
      if (!data) {
        this.showError('无法加载排行榜数据');
        return;
      }

      const isEn = document.documentElement.lang === 'en';

      // 渲染 Litex 赛道
      const litexContainer = document.getElementById('litex-leaderboard');
      if (litexContainer && data.litex) {
        this.renderTrack(litexContainer, 'litex', data.litex, isEn);
      }

      // 渲染 Lean 赛道
      const leanContainer = document.getElementById('lean-leaderboard');
      if (leanContainer && data.lean) {
        this.renderTrack(leanContainer, 'lean', data.lean, isEn);
      }
    },

    /**
     * 渲染单个赛道（包含切换功能）
     */
    renderTrack(container, trackId, trackData, isEn) {
      // 选择初始类型：若今日榜为空，则默认显示总榜
      const initialType = (Array.isArray(trackData.daily) && trackData.daily.length > 0) ? 'daily' : 'overall';
      const dailyActive = initialType === 'daily';

      // 创建切换按钮（根据初始类型设置 active）
      const switchHTML = `
        <div class="leaderboard-switch" style="text-align:center;margin-bottom:16px;">
          <button class="btn-switch ${dailyActive ? 'active' : ''}" data-track="${trackId}" data-type="daily">
            ${isEn ? 'Daily' : '今日榜'}
          </button>
          <button class="btn-switch ${!dailyActive ? 'active' : ''}" data-track="${trackId}" data-type="overall">
            ${isEn ? 'Overall' : '总榜'}
          </button>
        </div>
        <div id="${trackId}-table-container"></div>
        <div id="${trackId}-pagination" class="pagination-container"></div>
      `;

      container.innerHTML = switchHTML;

      // 初始显示
      const initialData = dailyActive ? trackData.daily : trackData.overall;
      this.renderTable(`${trackId}-table-container`, initialData, isEn, trackId, 1);

      // 绑定切换事件
      const buttons = container.querySelectorAll('.btn-switch');
      buttons.forEach(btn => {
        btn.addEventListener('click', (e) => {
          // 更新按钮状态
          buttons.forEach(b => b.classList.remove('active'));
          e.target.classList.add('active');

          // 切换表格
          const type = e.target.dataset.type;
          const tableData = type === 'daily' ? trackData.daily : trackData.overall;
          this.renderTable(`${trackId}-table-container`, tableData, isEn, trackId, 1);
        });
      });
    },

    /**
     * 渲染表格（带分页）
     */
    renderTable(containerId, entries, isEn, trackId, currentPage = 1) {
      const container = document.getElementById(containerId);
      if (!container) return;

      if (!entries || entries.length === 0) {
        container.innerHTML = `<p class="text-center text-muted">${isEn ? 'No data available' : '暂无数据'}</p>`;
        document.getElementById(`${trackId}-pagination`).innerHTML = '';
        return;
      }

      const itemsPerPage = 10;
      const totalPages = Math.ceil(entries.length / itemsPerPage);
      const startIndex = (currentPage - 1) * itemsPerPage;
      const endIndex = startIndex + itemsPerPage;
      const pageEntries = entries.slice(startIndex, endIndex);

      const headers = isEn 
        ? ['Rank', 'Team', 'Score']
        : ['排名', '队伍名称', '分数'];

      let html = '<div class="table-wrap"><table class="table leaderboard-table">';
      html += '<thead><tr>';
      html += `<th style="text-align:center;width:200px;">${headers[0]}</th>`;
      html += `<th style="text-align:left;padding-left:20px;">${headers[1]}</th>`;
      html += `<th style="text-align:center;width:200px;">${headers[2]}</th>`;
      html += '</tr></thead><tbody>';

      pageEntries.forEach(entry => {
        const rankClass = entry.rank <= 3 ? 'prize' : '';
        html += '<tr>';
        html += `<td class="num ${rankClass}" style="text-align:center;">${entry.rank}</td>`;
        html += `<td style="padding-left:20px;"><strong>${this.escape(entry.teamName)}</strong></td>`;
        html += `<td class="num" style="text-align:center;">${entry.score.toFixed(2)}</td>`;
        html += '</tr>';
      });

      html += '</tbody></table></div>';
      container.innerHTML = html;

      // 渲染分页
      this.renderPagination(`${trackId}-pagination`, currentPage, totalPages, isEn, () => {
        // 重新渲染当前类型的数据
        const activeBtn = container.closest('.card').querySelector('.btn-switch.active');
        const type = activeBtn ? activeBtn.dataset.type : 'daily';
        const trackData = this.cache[trackId];
        const tableData = type === 'daily' ? trackData.daily : trackData.overall;
        return { trackId, tableData, isEn };
      });
    },

    /**
     * 显示错误信息
     */
    showError(message) {
      const containers = ['litex-leaderboard', 'lean-leaderboard'];
      const errorHTML = `<p class="text-center text-muted">${this.escape(message)}</p>`;
      
      containers.forEach(id => {
        const container = document.getElementById(id);
        if (container) container.innerHTML = errorHTML;
      });
    },

    /**
     * 渲染分页控件
     */
    renderPagination(containerId, currentPage, totalPages, isEn, getDataCallback) {
      const container = document.getElementById(containerId);
      if (!container || totalPages <= 1) {
        container.innerHTML = '';
        return;
      }

      let html = '<div class="pagination">';
      
      // 上一页
      if (currentPage > 1) {
        html += `<button class="pagination-btn" data-page="${currentPage - 1}">
          ${isEn ? '← Previous' : '← 上一页'}
        </button>`;
      }

      // 页码按钮
      const maxVisiblePages = 5;
      let startPage = Math.max(1, currentPage - Math.floor(maxVisiblePages / 2));
      let endPage = Math.min(totalPages, startPage + maxVisiblePages - 1);
      
      if (endPage - startPage < maxVisiblePages - 1) {
        startPage = Math.max(1, endPage - maxVisiblePages + 1);
      }

      if (startPage > 1) {
        html += `<button class="pagination-btn" data-page="1">1</button>`;
        if (startPage > 2) {
          html += '<span class="pagination-ellipsis">...</span>';
        }
      }

      for (let i = startPage; i <= endPage; i++) {
        const activeClass = i === currentPage ? 'active' : '';
        html += `<button class="pagination-btn ${activeClass}" data-page="${i}">${i}</button>`;
      }

      if (endPage < totalPages) {
        if (endPage < totalPages - 1) {
          html += '<span class="pagination-ellipsis">...</span>';
        }
        html += `<button class="pagination-btn" data-page="${totalPages}">${totalPages}</button>`;
      }

      // 下一页
      if (currentPage < totalPages) {
        html += `<button class="pagination-btn" data-page="${currentPage + 1}">
          ${isEn ? 'Next →' : '下一页 →'}
        </button>`;
      }

      html += '</div>';
      container.innerHTML = html;

      // 绑定分页事件
      container.querySelectorAll('.pagination-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
          const page = parseInt(e.target.dataset.page);
          const { trackId, tableData, isEn } = getDataCallback();
          this.renderTable(`${trackId}-table-container`, tableData, isEn, trackId, page);
        });
      });
    },

    /**
     * HTML 转义
     */
    escape(str) {
      if (typeof str !== 'string') return '';
      const div = document.createElement('div');
      div.textContent = str;
      return div.innerHTML;
    }
  };

  // 页面加载时自动渲染
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => LeaderboardAPI.render());
  } else {
    LeaderboardAPI.render();
  }

  // 暴露 API 到全局（用于调试和外部调用）
  window.LeaderboardAPI = LeaderboardAPI;

})();
