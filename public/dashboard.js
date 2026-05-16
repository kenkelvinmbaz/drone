let allShoes = [];

async function loadShoes() {
  try {
    const response = await fetch('/api/shoes');
    if (!response.ok) {
      window.location.href = '/login.html';
      return;
    }
    const data = await response.json();
    allShoes = data.shoes;
    renderShoes(allShoes);
  } catch (err) {
    showError('Failed to load shoes');
  }
}

async function search() {
  const query = document.getElementById('searchInput').value.trim();
  if (!query) {
    loadShoes();
    return;
  }

  try {
    const response = await fetch(`/api/shoes/search?q=${encodeURIComponent(query)}`);
    const data = await response.json();

    if (data.success) {
      renderShoes(data.results);
    } else {
      showError(data.error);
    }
  } catch (err) {
    showError('Search failed');
  }
}

function renderShoes(shoes) {
  const container = document.getElementById('shoesContainer');
  container.textContent = '';

  if (shoes.length === 0) {
    const empty = document.createElement('div');
    empty.className = 'loading';
    empty.textContent = 'No shoes found';
    container.appendChild(empty);
    return;
  }

  shoes.forEach(shoe => {
    const card = document.createElement('div');
    card.className = 'shoe-card';

    const img = document.createElement('div');
    img.className = 'shoe-image';
    img.textContent = '👟';

    const info = document.createElement('div');
    info.className = 'shoe-info';

    const brand = document.createElement('div');
    brand.className = 'shoe-brand';
    brand.textContent = shoe.brand;

    const model = document.createElement('div');
    model.className = 'shoe-model';
    model.textContent = shoe.model;

    const price = document.createElement('div');
    price.className = 'shoe-price';
    price.textContent = '$' + shoe.price;

    const btn = document.createElement('button');
    btn.className = 'shoe-button';
    btn.textContent = 'Add to Cart';

    info.appendChild(brand);
    info.appendChild(model);
    info.appendChild(price);
    info.appendChild(btn);
    card.appendChild(img);
    card.appendChild(info);
    container.appendChild(card);
  });
}

function showError(message) {
  const el = document.getElementById('errorMessage');
  el.textContent = message;
  el.style.display = 'block';
  setTimeout(() => el.style.display = 'none', 5000);
}

async function logout() {
  try {
    await fetch('/api/logout', { method: 'POST' });
    window.location.href = '/login.html';
  } catch (err) {
    console.error('Logout error:', err);
  }
}

async function loadUserInfo() {
  try {
    const response = await fetch('/api/user/profile');
    const data = await response.json();
    if (data.success) {
      document.getElementById('username').textContent = data.user.username;
    }
  } catch (err) {
    console.error('Failed to load user info');
  }
}

document.getElementById('searchInput').addEventListener('keypress', (e) => {
  if (e.key === 'Enter') search();
});

loadUserInfo();
loadShoes();
