document.addEventListener('DOMContentLoaded', () => {
    document.getElementById('btn-generate')
            .addEventListener('click', generateCode);
    document.getElementById('btn-copy')
            .addEventListener('click', copyCode);
  });
  

  async function getCodeFromOpenAI(prompt) {
    // Provide your own API key here
    // Will not be used in the future
    const OPENAI_API_KEY = 'api_key';

    const res = await fetch('https://api.openai.com/v1/chat/completions', {
      method:  'POST',
      headers: {
        'Content-Type':  'application/json',
        'Authorization': `Bearer ${OPENAI_API_KEY}`
      },
      body: JSON.stringify({
        model:       'gpt-4',
        messages: [
          {
            role:    'system',
            content: 'You are a Python coding assistant. Return only valid Python code without any explanations or formatting.'
          },
          {
            role:    'user',
            content: prompt
          }
        ],
        temperature: 0.2,
        max_tokens: 1500,
        n:          1
      })
    });

    if (!res.ok) {
      const errBody = await res.text();
      throw new Error(`OpenAI API error ${res.status}: ${errBody}`);
    }

    const data = await res.json();
    return data.choices[0].message.content;
  }

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
      const code = await getCodeFromOpenAI(prompt);
      // Escape HTML
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
  