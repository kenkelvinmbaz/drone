function toggleForm() {
  const login = document.getElementById('loginForm');
  const register = document.getElementById('registerForm');
  login.style.display = login.style.display === 'none' ? 'block' : 'none';
  register.style.display = register.style.display === 'none' ? 'block' : 'none';
}

function showError(id, message) {
  const el = document.getElementById(id);
  el.textContent = message;
  el.classList.add('show');
  setTimeout(() => el.classList.remove('show'), 5000);
}

document.getElementById('loginFormElement').addEventListener('submit', async (e) => {
  e.preventDefault();
  const email = document.getElementById('loginEmail').value;
  const password = document.getElementById('loginPassword').value;

  try {
    const response = await fetch('/api/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password })
    });
    const data = await response.json();

    if (data.success) {
      window.location.href = '/dashboard.html';
    } else {
      showError('loginError', data.error);
    }
  } catch (err) {
    showError('loginError', 'Network error');
  }
});

document.getElementById('registerFormElement').addEventListener('submit', async (e) => {
  e.preventDefault();
  const username = document.getElementById('registerUsername').value;
  const email = document.getElementById('registerEmail').value;
  const password = document.getElementById('registerPassword').value;

  try {
    const response = await fetch('/api/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, email, password })
    });
    const data = await response.json();

    if (data.success) {
      window.location.href = '/dashboard.html';
    } else {
      showError('registerError', data.error);
    }
  } catch (err) {
    showError('registerError', 'Network error');
  }
});
