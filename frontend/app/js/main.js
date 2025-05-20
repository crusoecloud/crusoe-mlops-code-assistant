document.addEventListener('DOMContentLoaded', () => {
  document.getElementById('btn-generate')
          .addEventListener('click', generateCode);

  // Add event listener for Enter key in the prompt input
  document.getElementById('prompt')
          .addEventListener('keydown', function(e) {
            if (e.key === 'Enter' && !e.shiftKey) {
              e.preventDefault();
              generateCode();
            }
          });

  // Set up chat section resizing
  setupChatResize();
});

// Chat history array to store messages
const chatHistory = [];

// Function to handle chat panel resizing
function setupChatResize() {
  const resizeHandle = document.getElementById('resize-handle');
  const chatSection = document.querySelector('.chat-section');
  const mainContent = document.querySelector('.main-content');

  let isResizing = false;
  let startX, startWidth;

  // Mouse down on the resize handle
  resizeHandle.addEventListener('mousedown', (e) => {
    isResizing = true;
    startX = e.clientX;
    startWidth = parseInt(getComputedStyle(chatSection).width, 10);

    document.body.classList.add('resizing');
    e.preventDefault();
  });

  // Mouse move events for resizing
  document.addEventListener('mousemove', (e) => {
    if (!isResizing) return;

    // Calculate how far the mouse has moved
    const deltaX = startX - e.clientX;

    // Apply new width with constraints
    const newWidth = Math.max(250, Math.min(startWidth + deltaX, mainContent.offsetWidth * 0.7));
    chatSection.style.width = newWidth + 'px';

    e.preventDefault();
  });

  // Mouse up - stop resizing
  document.addEventListener('mouseup', () => {
    if (isResizing) {
      isResizing = false;
      document.body.classList.remove('resizing');
    }
  });
}

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

function addMessageToChat(role, content) {
  const messagesContainer = document.querySelector('.chat-messages');
  const messageEl = document.createElement('div');
  messageEl.className = `chat-message ${role}`;

  // For assistant messages, try to format code with syntax highlighting
  let formattedContent = content;

  if (role === 'assistant' && isProbablyCode(content)) {
    // Create a code element with Prism syntax highlighting
    const tempElement = document.createElement('div');
    tempElement.innerHTML = `<pre><code class="language-python">${escapeHtml(content)}</code></pre>`;

    // Apply Prism highlighting
    Prism.highlightElement(tempElement.querySelector('code'));

    formattedContent = tempElement.innerHTML;
  } else {
    // Regular text - just ensure newlines and indentation are preserved
    formattedContent = content
      .replace(/\n/g, '<br>')
      .replace(/  /g, '&nbsp;&nbsp;');
  }

  messageEl.innerHTML = `
    <div class="message-content">${formattedContent}</div>
  `;

  messagesContainer.appendChild(messageEl);
  messagesContainer.scrollTop = messagesContainer.scrollHeight;

  // Add to history array
  chatHistory.push({ role, content });
}

// Helper function to escape HTML entities
function escapeHtml(text) {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

// Simple heuristic to check if content is likely code
function isProbablyCode(text) {
  // Look for Python-like syntax
  const codePatterns = [
    /def\s+\w+\s*\(/,    // function definition
    /class\s+\w+/,       // class definition
    /import\s+\w+/,      // import statement
    /for\s+\w+\s+in\s+/, // for loop
    /if\s+.+:/,          // if statement
    /^\s*return\s+/m,    // return statement
    /^\s*#/m,            // Python comment
    /=\s*[{\[]/          // dictionary or list assignment
  ];

  return codePatterns.some(pattern => pattern.test(text));
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

  // If there's already content in the editor that isn't an error message, move it to chat history
  const existingCode = codeEl.innerText.trim();
  if (existingCode && existingCode !== "test code" && !codeEl.querySelector('.error')) {
    addMessageToChat('assistant', existingCode);
  }

  // Add user message to chat
  addMessageToChat('user', prompt);

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

    // Update the status indicator
    updateStatus('Code generated successfully', 'success');

  } catch (err) {
    codeEl.innerHTML = `<div class="error" style="color: #fa5252">
      Error: ${err.message}
    </div>`;

    // Update the status indicator
    updateStatus('Error generating code', 'error');
  } finally {
    loading.style.display = 'none';
    codeEl.style.display = 'block';
    btn.disabled = false;

    // Clear the prompt input
    promptEl.value = '';
  }
}

function updateStatus(message, type = 'default') {
  const statusIndicator = document.querySelector('.status-indicator');
  const statusText = document.querySelector('.status-item span');

  if (statusIndicator && statusText) {
    statusText.textContent = message;

    // Reset classes
    statusIndicator.className = 'status-indicator';

    // Add the appropriate class based on type
    if (type === 'success') {
      statusIndicator.style.background = 'var(--success-color)';
    } else if (type === 'error') {
      statusIndicator.style.background = 'var(--error-color)';
    } else if (type === 'warning') {
      statusIndicator.style.background = 'var(--warning-color)';
    } else {
      statusIndicator.style.background = 'var(--text-muted)';
    }

    // Make the indicator visible
    statusIndicator.style.opacity = '1';
  }
}
