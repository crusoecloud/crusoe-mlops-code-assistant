document.addEventListener('DOMContentLoaded', () => {
  document.getElementById('btn-generate')
          .addEventListener('click', generateCode);
});

async function getLlamaCompletion(prompt) {
  const res = await fetch('/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      model: "meta-llama/Llama-3.2-1B-Instruct",
      messages: [
        {
          role: "system",
          content: "You are a coding assistant. Return ONLY valid code without any explanations, comments, or text. If not indicated otherwise, use Python."
        },
        {
          role: "user",
          content: prompt
        }
      ],
      max_tokens: 1500,
      stream: false
    })
  });

  if (!res.ok) {
    const errBody = await res.text();
    throw new Error(`API error ${res.status}: ${errBody}`);
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
    const code = await getLlamaCompletion(prompt);

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
