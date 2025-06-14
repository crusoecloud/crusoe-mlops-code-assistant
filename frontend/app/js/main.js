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

async function getLlamaCompletion(prompt, onChunk) {
  const selectedModel = document.getElementById('model-select').value;
  
  const res = await fetch('/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Model': selectedModel // Add custom header for nginx routing
    },
    body: JSON.stringify({
      model: selectedModel,
      messages: [
        {
          role: "system",
          content: `You are an AI coding assistant that outputs ONLY code with no explanations, introductions, or outros. 
You will respond with pure, working code that directly solves the user's request. 
Your output should contain nothing but the code itself - no markdown formatting (no \`\`\` markers), no text descriptions, no explanations of what the code does.

Before generating any code, first determine if the request is actually asking for code generation. If the request is about:
- Personal questions (like 'How are you?', 'What's your name?')
- General knowledge or facts
- Opinions or advice unrelated to programming
- Writing essays, stories, or non-code content
- Harmful, unethical, or illegal activities

Then respond with exactly one comment:
# I can only provide programming code.
# I can't assist with [specific request type].
# However, I'd be happy to help you with any coding problems you might have.

Here are examples that show how you should response:

Request: "Write a function to check if a number is prime"
Response:
def is_prime(n):
    if n < 2: return False
    for i in range(2, int(n ** 0.5) + 1):
        if n % i == 0: return False
    return True

Request: "How was your day?"
Response:
# I can only provide programming code.
# I can't assist with personal conversations.
# However, I'd be happy to help you with any coding problems you might have.`
        },
        // Include previous chat history
        ...chatHistory.map(msg => ({
          role: msg.role,
          content: msg.content
        })),
        // Add the current prompt
        {
          role: "user",
          content: prompt
        }
      ],
      max_tokens: 1500,
      stream: true // Enable streaming
    })
  });

  if (!res.ok) {
    const errBody = await res.text();
    throw new Error(`API error ${res.status}: ${errBody}`);
  }

  const reader = res.body.getReader();
  const decoder = new TextDecoder();
  let buffer = '';

  while (true) {
    const { value, done } = await reader.read();
    if (done) break;

    buffer += decoder.decode(value, { stream: true });
    const lines = buffer.split('\n');
    buffer = lines.pop() || ''; // Keep the last incomplete line in the buffer

    for (const line of lines) {
      if (line.trim() === '') continue;
      if (line.trim() === 'data: [DONE]') continue;

      try {
        const jsonStr = line.replace(/^data: /, '').trim();
        if (!jsonStr) continue;

        const data = JSON.parse(jsonStr);
        const content = data.choices[0]?.delta?.content || '';
        
        if (content) {
          onChunk(content);
        }
      } catch (e) {
        console.error('Error parsing streaming response:', e);
      }
    }
  }
}

function addMessageToChat(role, content) {
  const messagesContainer = document.querySelector('.chat-messages');
  const messageEl = document.createElement('div');
  messageEl.className = `chat-message ${role}`;

  // Process content to render code blocks and regular text
  let formattedContent = '';

  if (role === 'assistant') {
    // Process markdown code blocks
    formattedContent = processCodeBlocks(content);
  } else {
    // For user messages, just ensure newlines and indentation are preserved
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

// Process markdown code blocks with ```
function processCodeBlocks(text) {
  // If no code block markers, just format text normally
  if (!text.includes('```')) {
    return text.replace(/\n/g, '<br>').replace(/  /g, '&nbsp;&nbsp;');
  }

  let result = '';
  let lastIndex = 0;

  // Regular expression to match code blocks with or without language specifier
  // ```language
  // code
  // ```
  // OR
  // ```
  // code
  // ```
  const regex = /```(?:(\w+)\n)?([\s\S]*?)```/g;
  let match;

  while ((match = regex.exec(text)) !== null) {
    // Add text before the code block
    if (match.index > lastIndex) {
      const textBefore = text.substring(lastIndex, match.index);
      result += formatPlainText(textBefore);
    }

    // Get language (if specified) and code content
    const language = match[1] || 'python'; // Default to Python if no language specified
    const code = match[2];

    // Format code with syntax highlighting
    result += formatCodeBlock(code, language);

    lastIndex = regex.lastIndex;
  }

  // Add any remaining text after the last code block
  if (lastIndex < text.length) {
    result += formatPlainText(text.substring(lastIndex));
  }

  return result;
}

// Helper function to format regular text
function formatPlainText(text) {
  return text.replace(/\n/g, '<br>').replace(/  /g, '&nbsp;&nbsp;');
}

// Helper function to format and highlight code
function formatCodeBlock(code, language) {
  const tempElement = document.createElement('div');
  tempElement.innerHTML = `<pre><code class="language-${language}">${escapeHtml(code)}</code></pre>`;

  try {
    // Apply Prism highlighting
    Prism.highlightElement(tempElement.querySelector('code'));
  } catch (error) {
    console.error('Error highlighting code:', error);
  }

  return tempElement.innerHTML;
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

  // Clear previous content
  codeEl.innerHTML = '';
  
  // Create a new code element for streaming
  const codeElement = document.createElement('code');
  codeElement.className = 'language-python';
  codeEl.appendChild(codeElement);
  codeEl.style.display = 'block';

  let fullCode = '';

  try {
    await getLlamaCompletion(prompt, (chunk) => {
      fullCode += chunk;
      // Escape HTML
      const escaped = chunk
        .replace(/&/g,'&amp;')
        .replace(/</g,'&lt;')
        .replace(/>/g,'&gt;');
      
      codeElement.innerHTML += escaped;
      Prism.highlightElement(codeElement);
      
      // Auto-scroll to keep up with the streaming content
      codeEl.scrollTop = codeEl.scrollHeight;
    });

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
