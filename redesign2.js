<script nonce="{{ js_nonce }}">
(function () {
  function initialize() {
    var ops = document.getElementById('ops');
    if (!ops || document.getElementById('lan-more')) return;

    var brandStatus = document.querySelector('#lan-brand .lan-brand-status');
    if (brandStatus) {
      var statusText = Array.from(brandStatus.childNodes).find(function (node) { return node.nodeType === 3; });
      if (statusText) statusText.nodeValue = '局域网共享';
    }
    var subtitle = document.querySelector('#lan-brand .lan-brand-sub');
    if (subtitle) subtitle.textContent = '文件共享 · 轻松协作';

    ['opa_bup', 'opa_md', 'opa_msg', 'opa_auc', 'opa_cfg', 'opa_srch'].forEach(function (id) {
      var control = document.getElementById(id);
      if (control) control.classList.add('lan-extra');
    });
    var more = document.createElement('button');
    more.id = 'lan-more';
    more.type = 'button';
    more.className = 'lan-more-button';
    more.setAttribute('aria-expanded', 'false');
    more.textContent = '更多功能';
    more.addEventListener('click', function () {
      var expanded = ops.classList.toggle('lan-expanded');
      more.setAttribute('aria-expanded', expanded ? 'true' : 'false');
      more.textContent = expanded ? '收起更多' : '更多功能';
    });
    ops.appendChild(more);

    var meta = {
      op_unpost: ['撤销近期上传', '查看可撤销的上传，或中止未完成的上传。此处不是完整的上传历史。', '↶'],
      op_up2k: ['上传文件', '选择文件或文件夹，也可以直接拖放；支持中断后继续上传。', '↑'],
      op_bup: ['基础上传', '简易上传方式。普通上传遇到兼容问题时，可以在这里重试。', '↑'],
      op_mkdir: ['新建文件夹', '输入名称，在当前目录中新建文件夹。', '＋'],
      op_new_md: ['新建文本文件', '输入文件名和扩展名，在当前目录中创建。', '＋'],
      op_msg: ['服务器消息', '发送一条消息到服务器日志。', '✎'],
      op_player: ['媒体设置', '按需展开下方设置；日常文件共享无需调整。', '♫'],
      op_cfg: ['页面设置', '按需展开对应选项，调整当前浏览器的显示和操作方式。', '⚙'],
      op_search: ['搜索文件', '按条件筛选当前共享中的文件。', '⌕']
    };
    Object.keys(meta).forEach(function (id) {
      var panel = document.getElementById(id);
      if (!panel || panel.querySelector('.lan-panel-intro')) return;
      var item = meta[id];
      var head = document.createElement('div');
      head.className = 'lan-panel-intro';
      var icon = document.createElement('div');
      icon.className = 'lan-panel-icon'; icon.textContent = item[2]; icon.setAttribute('aria-hidden', 'true');
      var copy = document.createElement('div'); copy.className = 'lan-panel-copy';
      var eyebrow = document.createElement('div'); eyebrow.className = 'lan-panel-eyebrow'; eyebrow.textContent = '共享空间 / 功能';
      var heading = document.createElement('h2'); heading.textContent = item[0];
      var desc = document.createElement('p'); desc.textContent = item[1];
      var close = document.createElement('button'); close.type = 'button'; close.className = 'lan-panel-close'; close.textContent = '关闭';
      close.addEventListener('click', function () { var button = document.getElementById('opa_x'); if (button) button.click(); });
      copy.appendChild(eyebrow); copy.appendChild(heading); copy.appendChild(desc);
      head.appendChild(icon); head.appendChild(copy); head.appendChild(close);
      panel.insertBefore(head, panel.firstChild);
    });

    ['op_player', 'op_cfg'].forEach(function (id) {
      var panel = document.getElementById(id);
      if (!panel) return;
      Array.from(panel.children).filter(function (child) {
        return child.tagName === 'DIV' && !child.classList.contains('lan-panel-intro') && child.querySelector('h3');
      }).forEach(function (child) {
        var title = child.querySelector('h3');
        var group = document.createElement('details'); group.className = 'lan-advanced-group';
        var summary = document.createElement('summary'); summary.textContent = title.textContent.replace(/\s+/g, ' ').trim();
        panel.insertBefore(group, child); group.appendChild(summary); group.appendChild(child);
      });
    });

    var recordPanel = document.getElementById('op_unpost');
    if (recordPanel) {
      var input = document.getElementById('unpost_filt');
      if (input) input.placeholder = '输入路径或文件名筛选';
      Array.from(recordPanel.childNodes).forEach(function (node) {
        if (node.nodeType === 3 && node.nodeValue.indexOf('你可以删除') !== -1)
          node.nodeValue = '查看当前可操作的上传任务。 ';
      });
      function tidyStatus() {
        var result = document.getElementById('unpost');
        if (!result) return;
        var warning = result.querySelector('p');
        if (warning && warning.textContent.indexOf('服务器配置中未启用/不允许取消发布已上传完成的文件') !== -1) {
          Array.from(warning.childNodes).forEach(function (node) {
            if (node.nodeType === 3 && node.nodeValue.indexOf('服务器配置中未启用') !== -1)
              node.nodeValue = ' 当前不能在这里撤回已完成上传；如需删除，请在文件列表中选中文件后删除。';
          });
        }
        var empty = result.querySelector('em');
        if (empty && empty.textContent === '哎呀！没有最近上传的文件') empty.textContent = '暂无可显示的上传任务';
      }
      tidyStatus();
      var result = document.getElementById('unpost');
      if (result) new MutationObserver(tidyStatus).observe(result, {childList:true, subtree:true});
    }
    var mkdirName = document.querySelector('#op_mkdir input[name=name]');
    if (mkdirName) mkdirName.placeholder = '输入文件夹名称';
    var mdName = document.querySelector('#op_new_md input[name=name]');
    if (mdName) mdName.placeholder = '例如：会议记录.md';
    var bupSubmit = document.querySelector('#op_bup input[type=submit]');
    if (bupSubmit) bupSubmit.value = '开始上传';

    var tree = document.getElementById('treeul');
    if (tree) {
      function translateRoot() {
        tree.querySelectorAll('a').forEach(function (link) {
          if (link.textContent === '[root]') link.textContent = '共享文件';
        });
      }
      translateRoot();
      new MutationObserver(translateRoot).observe(tree, {childList:true, subtree:true});
    }
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', initialize);
  else initialize();
})();
</script>
