document.addEventListener('DOMContentLoaded', () => {
    document.getElementById('btn-generate')
            .addEventListener('click', generateCode);
    document.getElementById('btn-copy')
            .addEventListener('click', copyCode);
  });
  
  async function generateCode() {
    const promptEl = document.getElementById('prompt');
    const loading  = document.getElementById('loading');
    const codeEl   = document.getElementById('generatedCode');
    const btn      = document.getElementById('btn-generate');
    const prompt   = promptEl.value.trim();
  
    if (!prompt) {
      alert('Please enter a prompt first');
      return;
    }
  
    // Show loading
    loading.style.display = 'block';
    codeEl.style.display = 'none';
    btn.disabled = true;
  
    try {
      const res = await fetch('https://api.yourdomain.com/generate', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_API_KEY'
        },
        body: JSON.stringify({ prompt })
      });
      if (!res.ok) throw new Error(`API returned ${res.status}`);
      const { code } = await res.json();
  
      // Escape & inject
      const escaped = code
        .replace(/&/g,'&amp;')
        .replace(/</g,'&lt;')
        .replace(/>/g,'&gt;');
  
      codeEl.innerHTML = `<code class="language-python">${escaped}</code>`;
      Prism.highlightElement(codeEl.firstChild);
  
    } catch (err) {
      codeEl.innerHTML = `<div style="color: #fa5252">
        Error: ${err.message}
      </div>`;
    } finally {
      loading.style.display = 'none';
      codeEl.style.display = 'block';
      btn.disabled = false;
    }
  }
  
  function copyCode() {
    const codeEl = document.getElementById('generatedCode');
    const ta     = document.createElement('textarea');
    ta.value     = codeEl.textContent;
    document.body.appendChild(ta);
    ta.select();
    document.execCommand('copy');
    document.body.removeChild(ta);
  
    const btn = document.getElementById('btn-copy');
    btn.textContent = 'Copied!';
    setTimeout(() => btn.textContent = '📋 Copy Code', 2000);
  }
  