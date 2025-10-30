(function(){
  'use strict';

  /**
   * 排行榜 API
   * 支持动态加载 JSON 数据或使用页面内嵌数据
   */
  const LeaderboardAPI = {
    // 数据源 URL（可配置为云端接口）
    dataURL: 'assets/data/leaderboard.json',
    
    // 缓存数据
    cache: null,

    /**
     * 获取排行榜数据
     * 优先从云端获取，失败时回退到页面内嵌数据
     */
    async fetch() {
      if (this.cache) {
        return this.cache;
      }

      try {
        // 尝试从云端获取
        const response = await fetch(this.dataURL + '?_=' + Date.now());
        if (response.ok) {
          const data = await response.json();
          this.cache = data;
          return data;
        }
      } catch (err) {
        console.warn('无法从云端获取排行榜数据，使用内嵌数据:', err);
      }

      // 回退到页面内嵌数据
      const embeddedScript = document.getElementById('leaderboard-data');
      if (embeddedScript) {
        try {
          const data = JSON.parse(embeddedScript.textContent);
          this.cache = data;
          return data;
        } catch (err) {
          console.error('解析内嵌排行榜数据失败:', err);
        }
      }

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
     * 渲染排行榜表格
     */
    async render() {
      const data = await this.fetch();
      
      if (!data) {
        this.showError('无法加载排行榜数据');
        return;
      }

      // 渲染今日排行榜
      const dailyContainer = document.getElementById('daily-leaderboard');
      if (dailyContainer && data.daily) {
        dailyContainer.innerHTML = this.renderTable(data.daily, 'daily');
      }

      // 渲染总排行榜
      const overallContainer = document.getElementById('overall-leaderboard');
      if (overallContainer && data.overall) {
        overallContainer.innerHTML = this.renderTable(data.overall, 'overall');
      }
    },

    /**
     * 生成表格 HTML
     */
    renderTable(entries, type) {
      if (!entries || entries.length === 0) {
        return '<p class="text-center text-muted">暂无数据</p>';
      }

      // 检测语言
      const isEn = document.documentElement.lang === 'en';

      const headers = isEn 
        ? ['Rank', 'Team Name', 'Members', 'Best Score', 'Last Submission', 'Submissions']
        : ['排名', '队伍名称', '成员', '最高得分', '最高分提交时间', '有效提交次数'];

      let html = '<div class="table-wrap"><table class="table">';
      html += '<thead><tr>';
      headers.forEach((h, idx) => {
        const align = (idx === 0 || idx === 3 || idx === 5) ? 'center' : 'left';
        html += `<th style="text-align:${align}">${h}</th>`;
      });
      html += '</tr></thead><tbody>';

      entries.forEach(entry => {
        const rankClass = entry.rank <= 3 ? 'prize' : '';
        html += '<tr>';
        html += `<td class="num ${rankClass}">${entry.rank}</td>`;
        html += `<td><strong>${this.escape(entry.teamName)}</strong></td>`;
        html += `<td class="text-muted">${this.escape(entry.members)}</td>`;
        html += `<td class="num">${entry.score.toFixed(2)}</td>`;
        html += `<td class="text-muted">${this.escape(entry.submitTime)}</td>`;
        html += `<td class="num">${entry.submissionCount}</td>`;
        html += '</tr>';
      });

      html += '</tbody></table></div>';
      return html;
    },

    /**
     * 显示错误信息
     */
    showError(message) {
      const dailyContainer = document.getElementById('daily-leaderboard');
      const overallContainer = document.getElementById('overall-leaderboard');
      
      const errorHTML = `<p class="text-center text-muted">${this.escape(message)}</p>`;
      
      if (dailyContainer) dailyContainer.innerHTML = errorHTML;
      if (overallContainer) overallContainer.innerHTML = errorHTML;
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

